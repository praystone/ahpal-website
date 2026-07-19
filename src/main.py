# ============================================================
# main.py - 主要入口模組（優化版）
# ============================================================

import sys
import os
import argparse

# 確保可以匯入 src 模組
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime
from src.config import OUTPUT_DIR, CURRENT_YEAR
from src.api_client import get_force_api, get_current_api_info, is_peak_hour, get_next_off_peak_time
from src.html_builder import create_default_index, generate_categories_page, generate_category_pages
from src.article_generator import generate_article, get_pending_articles
from src.sitemap_builder import scan_all_html_files, update_sitemap
from src.logger import get_logger
from src.state_manager import get_state_manager

logger = get_logger("main")

# ============================================================
# 1. 預檢檢查
# ============================================================

def check_api_keys():
    """檢查 API Key 是否有效，回傳 (是否通過, 錯誤訊息列表)"""
    errors = []
    warnings = []
    
    # 檢查必要金鑰
    deepseek_key = os.environ.get("DEEPSEEK_API_KEY")
    if not deepseek_key:
        errors.append("DEEPSEEK_API_KEY 未設定（離峰時段需要）")
    elif not deepseek_key.startswith("sk-"):
        errors.append("DEEPSEEK_API_KEY 格式錯誤（應以 sk- 開頭）")
    
    gemini_key = os.environ.get("GEMINI_API_KEY")
    if not gemini_key:
        warnings.append("GEMINI_API_KEY 未設定（尖峰時段需使用）")
    
    if errors:
        logger.error("API Key 檢查失敗")
        for err in errors:
            logger.error(f"   - {err}")
        logger.info("💡 請在 ahpal-static.ps1 中設定 API Key")
        return False, errors
    
    if warnings:
        logger.warning("API Key 檢查有警告")
        for warn in warnings:
            logger.warning(f"   - {warn}")
    
    logger.info("✅ API Key 檢查通過")
    return True, []

# ============================================================
# 2. 主管道執行函數
# ============================================================

def run_pipeline(force_api=None, dry_run=False):
    """執行完整文章生成管道"""
    logger.info("=" * 70)
    logger.info(f"🚀 AHPAL.COM 重構版 v4.0 - {CURRENT_YEAR}")
    logger.info(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 70)
    
    # 預檢檢查
    passed, errors = check_api_keys()
    if not passed:
        logger.error("⚠️ 請修正 API Key 後重新執行")
        return None
    
    # 顯示當前設定
    if force_api:
        logger.info(f"🔧 強制模式：{force_api.upper()}")
    else:
        logger.info("🔄 自動切換模式")
    
    api_info = get_current_api_info()
    logger.info(f"📡 當前 API：{api_info['name']}")
    logger.info(f"   ├─ 模型：{api_info['model']}")
    logger.info(f"   ├─ 時段：{'🔴 尖峰' if api_info['peak'] else '🟢 離峰'}")
    logger.info(f"   └─ 價格：{api_info['price']}")
    
    if not force_api and is_peak_hour():
        next_time = get_next_off_peak_time()
        logger.info(f"⏰ 將在 {next_time.strftime('%H:%M')} 自動切換到 DeepSeek（離峰）")
        logger.info("   💡 按 [A] 強制 DeepSeek 可立即切換")
    
    # Dry Run 模式
    state_manager = get_state_manager()
    pending_articles = state_manager.get_pending_articles(keywords_list)
    
    if dry_run:
        logger.info(f"\n📋 待生成文章：{len(pending_articles)} 篇")
        for item in pending_articles:
            logger.info(f"   - {item['keyword']} ({item['category']})")
        return len(pending_articles)
    
    # 初始化頁面
    logger.info("📄 初始化頁面...")
    create_default_index()
    generate_categories_page()
    
    if pending_articles:
        logger.info(f"\n📝 需要生成 {len(pending_articles)} 篇文章\n")
        
        for idx, item in enumerate(pending_articles, 1):
            logger.info(f"\n--- 進度：{idx}/{len(pending_articles)} ---")
            try:
                generate_article(item)
            except Exception as e:
                logger.error(f"❌ 生成失敗：{item['keyword']} - {e}")
                state_manager.mark_failed(item['filename'], str(e))
                continue
    else:
        logger.info("\n✅ 所有文章都已存在且完整，無需生成！")
    
    # 更新分類頁面和 Sitemap
    logger.info("📄 更新分類頁面與 Sitemap...")
    generate_category_pages()
    all_existing_html = scan_all_html_files()
    update_sitemap()
    
    # 顯示摘要
    summary = state_manager.get_summary()
    logger.info("\n" + "=" * 70)
    logger.info("🏁 所有文章生成、分類頁面、Sitemap 更新完畢！")
    logger.info(f"📊 總文章數：{len(all_existing_html)} 篇")
    logger.info(f"📊 狀態摘要：總計 {summary['total']} 篇，已生成 {summary['generated']} 篇，失敗 {summary['failed']} 篇")
    logger.info("📌 下一步：執行 npx wrangler pages deploy")
    logger.info("=" * 70)
    
    return len(all_existing_html)

# ============================================================
# 3. 關鍵字清單（已載入）
# ============================================================

# 保留原有 keywords_list（此處省略，保持與原檔案一致）

# ============================================================
# 4. 主程式入口
# ============================================================

def main():
    """主要入口（支援命令列參數）"""
    parser = argparse.ArgumentParser(description='AHPAL 文章生成引擎')
    parser.add_argument('--force', choices=['deepseek', 'gemini'], help='強制使用指定 API')
    parser.add_argument('--dry-run', action='store_true', help='僅顯示待生成文章，不執行')
    parser.add_argument('--reset', action='store_true', help='重置狀態檔（清除所有生成紀錄）')
    
    args = parser.parse_args()
    
    if args.reset:
        logger.warning("⚠️ 重置狀態檔...")
        state_manager = get_state_manager()
        state_manager.manifest["articles"] = {}
        state_manager.manifest["stats"] = {"total": 0, "generated": 0, "pending": 0, "failed": 0}
        state_manager.save()
        logger.info("✅ 狀態檔已重置")
        return
    
    run_pipeline(args.force, args.dry_run)

if __name__ == "__main__":
    main()