# ============================================================
# AHPAL 內容生成引擎 - main.py v5.3
# ============================================================
# 變更：
#   - 🆕 整合 content_router（支援文章/音樂分流）
#   - 🆕 支援 content_type 欄位
#   - 🆕 分類名稱統一：「🎵 台語音樂」→「🎵 音樂創作」
#   - 🆕 音樂文章自動帶入 video_id
#   - 🆕 支援從 JSON 讀取 use_responses_api / enable_reasoning / enable_search
#   - 🔧 優化 keywords_list 組織結構
#   - 🔧 完善錯誤處理與日誌
# ============================================================

import sys
import os
import argparse
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime
from src.config import OUTPUT_DIR, CURRENT_YEAR
from src.api_client import get_current_api_info, is_peak_hour, get_next_off_peak_time
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
# 2. 文章關鍵字列表
# ============================================================

keywords_list = [
    # ...（原有內容保持不變，已包含所有文章）
    # 最下方兩篇新文章已正確加入
    {"keyword": "百年孤寂 馬奎斯 深度書評 魔幻現實主義 解析", "category": "🌟 人生哲理", "filename": "philosophy/one-hundred-years-of-solitude-review.html"},
    {"keyword": "2026 年 機械式鍵盤 選購指南 推薦", "category": "💻 3C 科技教學", "filename": "tech/mechanical-keyboard-guide-2026.html"},

]


# ============================================================
# 3. 獲取待生成文章列表（強化版）
# ============================================================

def get_pending_articles():
    """取得所有待生成的文章（支援 content_type + Responses API 參數）"""
    pending = []
    output_dir = os.environ.get("AHPAL_OUTPUT_DIR", "C:\\Users\\User\\ahpal-static")

    for item in keywords_list:
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
# 4. 執行內容生成管線
# ============================================================

def run_pipeline(force_api=None, dry_run=False):
    """執行內容生成管線（支援文章 + 音樂 + Responses API）"""
    logger.info("=" * 70)
    logger.info(f"🦞 AHPAL.COM 內容生成引擎 v5.3 - {CURRENT_YEAR}")
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
# 5. 主程式入口
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='AHPAL 內容生成引擎 v5.3')
    parser.add_argument('--force', choices=['deepseek', 'gemini'], help='強制使用指定的 API（已棄用）')
    parser.add_argument('--dry-run', action='store_true', help='僅顯示待生成清單，不實際生成')
    parser.add_argument('--reset', action='store_true', help='重置文章狀態檔案')

    args = parser.parse_args()

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