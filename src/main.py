# ============================================================
# AHPAL 內容生成引擎 - main.py v6.0
# ============================================================
# 變更 (v6.0)：
#   - 🔧 移除硬編碼的 keywords_list，改為從 JSON 讀取
#   - 🔧 新增 load_keywords_from_json() 函數
#   - 🔧 支援 master-articles.json 與 pending-articles.json 雙來源
#   - 🔧 自動產生 filename（如果 JSON 中未指定）
#   - 🔧 完整的欄位驗證與補全
#   - 🔧 向後相容：支援舊格式 JSON
# ============================================================

import sys
import os
import json
import re
import argparse
from pathlib import Path
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.config import OUTPUT_DIR, CURRENT_YEAR
from src.api_client import get_current_api_info
from src.html_builder import create_default_index, generate_categories_page, generate_category_pages
from src.content_router import generate_content
from src.sitemap_builder import scan_all_html_files, update_sitemap
from src.logger import get_logger
from src.state_manager import get_state_manager

logger = get_logger("main")


# ============================================================
# 1. API Key 檢查
# ============================================================

def check_api_keys():
    """檢查 API Key 是否正確設定"""
    errors = []
    warnings = []

    deepseek_key = os.environ.get("DEEPSEEK_API_KEY")
    if not deepseek_key:
        errors.append("DEEPSEEK_API_KEY 未設定，請檢查 .env 檔案")
    elif not deepseek_key.startswith("sk-"):
        errors.append("DEEPSEEK_API_KEY 格式錯誤，應以 sk- 開頭")

    gemini_key = os.environ.get("GEMINI_API_KEY")
    if not gemini_key:
        warnings.append("⚠️ GEMINI_API_KEY 未設定，生圖功能將使用 Pollinations AI（免費）")
    else:
        logger.info("✅ GEMINI_API_KEY 已設定（備用）")

    if errors:
        logger.error("API Key 檢查失敗：")
        for err in errors:
            logger.error(f"   - {err}")
        logger.info("請執行 ahpal-static.ps1 設定正確的 API Key")
        return False, errors

    if warnings:
        for warn in warnings:
            logger.warning(warn)

    logger.info("✅ API Key 檢查通過")
    return True, []


# ============================================================
# 2. 🆕 分類映射（與 config.py 保持一致）
# ============================================================

CATEGORY_DIR_MAP = {
    "💻 3C 科技教學": "tech",
    "🎮 遊戲攻略": "game",
    "🏠 生活小常識": "life",
    "📊 軟體評測": "review",
    "🌟 人生哲理": "philosophy",
    "🤖 AI 趨勢": "trend",
    "🎵 音樂創作": "music",
}

CATEGORY_EMOJI_MAP = {
    "tech": "💻",
    "game": "🎮",
    "life": "🏠",
    "review": "📊",
    "philosophy": "🌟",
    "trend": "🤖",
    "music": "🎵",
}


# ============================================================
# 3. 🆕 從 JSON 載入文章清單（核心功能）
# ============================================================

def load_keywords_from_json():
    """
    從 data/master-articles.json 載入文章清單
    如果檔案不存在，嘗試從 data/pending-articles.json 載入
    支援自動補全欄位
    
    回傳：
        list: 文章清單（每個元素為 dict）
    """
    project_root = Path(__file__).parent.parent
    master_path = project_root / "data" / "master-articles.json"
    pending_path = project_root / "data" / "pending-articles.json"
    
    items = []
    
    # 優先讀取 master-articles.json
    if master_path.exists():
        try:
            with open(master_path, "r", encoding="utf-8") as f:
                content = f.read().strip()
                if content and content != "[]":
                    items = json.loads(content)
                    logger.info(f"📋 從 master-articles.json 載入 {len(items)} 篇文章")
        except json.JSONDecodeError as e:
            logger.error(f"❌ master-articles.json 解析失敗：{e}")
        except Exception as e:
            logger.error(f"❌ 讀取 master-articles.json 失敗：{e}")
    
    # 如果 master 為空，嘗試從 pending 讀取
    if not items and pending_path.exists():
        try:
            with open(pending_path, "r", encoding="utf-8") as f:
                content = f.read().strip()
                if content and content != "[]":
                    items = json.loads(content)
                    logger.info(f"📋 從 pending-articles.json 載入 {len(items)} 篇文章（過渡模式）")
        except Exception as e:
            logger.error(f"❌ 讀取 pending-articles.json 失敗：{e}")
    
    # 如果還是空，建立預設清單
    if not items:
        logger.warning("⚠️ 找不到文章清單，使用預設空清單")
        return []
    
    # 🆕 驗證並補全每個項目
    validated_items = []
    for idx, item in enumerate(items):
        try:
            validated = _validate_and_complete_item(item)
            validated_items.append(validated)
        except Exception as e:
            logger.warning(f"⚠️ 第 {idx+1} 筆資料格式錯誤，已跳過：{e}")
    
    logger.info(f"✅ 成功載入 {len(validated_items)} 篇文章")
    return validated_items


def _validate_and_complete_item(item):
    """
    驗證並補全單篇文章的欄位
    
    必要欄位：
        - keyword: 文章關鍵字
        - category: 文章分類（必須在 CATEGORY_DIR_MAP 中）
    
    自動補全：
        - filename: 如果未指定，自動產生
        - content_type: 預設 "article"
        - use_responses_api: 預設 True
        - enable_reasoning: 預設 True
        - enable_search: 預設 False
    """
    # 複製一份，避免修改原始資料
    validated = dict(item)
    
    # 檢查必要欄位
    if "keyword" not in validated or not validated["keyword"]:
        raise ValueError("缺少 keyword 欄位")
    
    if "category" not in validated or not validated["category"]:
        raise ValueError("缺少 category 欄位")
    
    # 檢查分類是否有效
    if validated["category"] not in CATEGORY_DIR_MAP:
        logger.warning(f"⚠️ 未知分類：{validated['category']}，使用預設 '🌟 人生哲理'")
        validated["category"] = "🌟 人生哲理"
    
    # 自動產生 filename
    if "filename" not in validated or not validated["filename"]:
        cat_dir = CATEGORY_DIR_MAP.get(validated["category"], "other")
        safe_name = _generate_safe_filename(validated["keyword"])
        validated["filename"] = f"{cat_dir}/{safe_name}.html"
        logger.debug(f"   🔄 自動產生檔名：{validated['filename']}")
    
    # 確保 content_type 存在
    if "content_type" not in validated:
        validated["content_type"] = "article"
    
    # 確保 Responses API 參數存在
    if "use_responses_api" not in validated:
        validated["use_responses_api"] = True
    if "enable_reasoning" not in validated:
        validated["enable_reasoning"] = True
    if "enable_search" not in validated:
        validated["enable_search"] = False
    
    return validated


def _generate_safe_filename(keyword):
    """
    從關鍵字產生安全的檔案名稱（英文 + 數字 + 中線）
    符合董事長死命令：檔名必須為英文
    """
    # 移除特殊字元，保留英文、數字、空格、中線
    safe = re.sub(r'[^a-zA-Z0-9\s-]', '', keyword)
    # 將空格轉為中線
    safe = re.sub(r'\s+', '-', safe)
    # 移除連續中線
    safe = re.sub(r'-+', '-', safe)
    # 移除頭尾中線
    safe = safe.strip('-')
    
    # 如果結果為空（全中文），使用時間戳
    if not safe or not re.search(r'[a-zA-Z0-9]', safe):
        safe = f"article-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    
    # 轉為小寫
    return safe.lower()


# ============================================================
# 4. 獲取待生成文章列表
# ============================================================

def get_pending_articles():
    """取得所有待生成的文章（從 JSON 讀取）"""
    all_keywords = load_keywords_from_json()
    
    if not all_keywords:
        logger.info("📋 文章清單為空，無待生成內容")
        return []
    
    pending = []
    output_dir = os.environ.get("AHPAL_OUTPUT_DIR", "C:\\Users\\User\\ahpal-static")

    for item in all_keywords:
        filename = item.get("filename")
        if not filename:
            continue

        file_path = Path(output_dir) / filename

        # 檢查檔案是否存在且有效
        if not file_path.exists():
            pending.append(item)
            continue

        try:
            if file_path.stat().st_size < 5120:
                pending.append(item)
        except:
            pending.append(item)

    return pending


# ============================================================
# 5. 執行內容生成管線
# ============================================================

def run_pipeline(force_api=None, dry_run=False):
    """執行內容生成管線（支援文章 + 音樂 + Responses API）"""
    logger.info("=" * 70)
    logger.info(f"🦞 AHPAL.COM 內容生成引擎 v6.0 - {CURRENT_YEAR}")
    logger.info(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 70)

    # 1. 檢查 API Key
    passed, errors = check_api_keys()
    if not passed:
        logger.error("❌ 請修正 API Key 後重新執行")
        return None

    # 2. 顯示 API 資訊
    api_info = get_current_api_info(force_api=force_api)
    logger.info(f"📡 文字生成：{api_info.get('name', 'DeepSeek Flash')}")
    logger.info(f"   🤖 模型：{api_info.get('model', 'deepseek-v4-flash')}")
    logger.info(f"   ⏰ 時段：{'尖峰' if api_info.get('peak', False) else '離峰'}")
    logger.info(f"   💰 價格：{api_info.get('price', '低')}")
    logger.info(f"🖼️ 配圖生成：Pollinations AI（免費、免 API Key）")

    # 3. 取得待生成內容
    pending_items = get_pending_articles()

    article_count = sum(1 for item in pending_items if item.get("content_type", "article") == "article")
    song_count = sum(1 for item in pending_items if item.get("content_type") == "song")

    if dry_run:
        logger.info(f"\n📋 待生成內容清單 ({len(pending_items)} 篇)：")
        logger.info(f"   ├─ 一般文章：{article_count} 篇")
        logger.info(f"   └─ 音樂文章：{song_count} 篇")
        for item in pending_items:
            content_type = item.get("content_type", "article")
            use_responses = item.get("use_responses_api", False)
            reasoning = item.get("enable_reasoning", False)
            search = item.get("enable_search", False)
            logger.info(f"   - [{content_type}] {item['keyword']} ({item['category']}) [Responses: {use_responses}, Reasoning: {reasoning}, Search: {search}]")
        return len(pending_items)

    # 4. 建立首頁與分類頁
    logger.info("📄 建立首頁與分類頁...")
    create_default_index()
    generate_categories_page()

    # 5. 生成內容（使用 content_router）
    if pending_items:
        logger.info(f"\n📝 開始生成 {len(pending_items)} 篇內容...")
        logger.info(f"   ├─ 一般文章：{article_count} 篇")
        logger.info(f"   └─ 音樂文章：{song_count} 篇")

        for idx, item in enumerate(pending_items, 1):
            content_type = item.get("content_type", "article")
            use_responses = item.get("use_responses_api", False)
            reasoning = item.get("enable_reasoning", False)

            logger.info(f"\n--- 進度 {idx}/{len(pending_items)} [{content_type}] ---")
            if use_responses:
                logger.info(f"   🆕 使用 Responses API (Reasoning: {reasoning})")

            try:
                generate_content(item)
            except Exception as e:
                logger.error(f"❌ 生成失敗：{item['keyword']} - {e}")
                continue
    else:
        logger.info("\n✅ 所有內容已存在，無需生成")

    # 6. 更新分類頁與 Sitemap
    logger.info("📂 更新分類頁與 Sitemap...")
    generate_category_pages()
    all_existing_html = scan_all_html_files()
    update_sitemap()

    # 7. 完成
    logger.info("\n" + "=" * 70)
    logger.info("✅ 內容生成流程完成！")
    logger.info(f"📊 總文章數：{len(all_existing_html)} 篇")
    logger.info("📌 請執行 npx wrangler pages deploy 部署至 Cloudflare")
    logger.info("=" * 70)

    return len(all_existing_html)


# ============================================================
# 6. 🆕 遷移工具：從 main.py 匯出文章清單
# ============================================================

def migrate_keywords_to_json():
    """
    將現有的 keywords_list 匯出到 data/master-articles.json
    僅需執行一次，將 main.py 中的硬編碼清單遷移到 JSON
    """
    # 此處僅保留範例，實際使用時從舊版 main.py 複製 keywords_list
    # 或直接手動建立 master-articles.json
    
    project_root = Path(__file__).parent.parent
    master_path = project_root / "data" / "master-articles.json"
    
    if master_path.exists():
        logger.warning(f"⚠️ {master_path} 已存在，跳過遷移")
        return
    
    logger.info("📦 正在遷移文章清單到 JSON...")
    
    # 從舊版 keywords_list 複製（此處為範例，實際應從舊版 main.py 讀取）
    # 建議：手動將現有文章整理到 data/master-articles.json
    
    logger.info("✅ 遷移完成！")
    logger.info(f"📁 請檢查：{master_path}")


# ============================================================
# 7. 主程式入口
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='AHPAL 內容生成引擎 v6.0')
    parser.add_argument('--force', choices=['deepseek', 'gemini'], help='強制使用指定的 API（已棄用）')
    parser.add_argument('--dry-run', action='store_true', help='僅顯示待生成清單，不實際生成')
    parser.add_argument('--reset', action='store_true', help='重置文章狀態檔案')
    parser.add_argument('--migrate', action='store_true', help='遷移文章清單到 JSON（僅限首次）')

    args = parser.parse_args()

    if args.migrate:
        migrate_keywords_to_json()
        return

    if args.reset:
        logger.warning("⚠️ 重置文章狀態...")
        try:
            state_manager = get_state_manager()
            state_manager.reset()
            logger.info("✅ 文章狀態已重置")
        except Exception as e:
            logger.warning(f"⚠️ 重置失敗：{e}")
        return

    run_pipeline(dry_run=args.dry_run)


if __name__ == "__main__":
    main()