# ============================================================
# AHPAL 文章生成引擎 - main.py v4.4 (修正 force_api 傳遞)
# ============================================================

import sys
import os
import argparse
from pathlib import Path

# 將專案根目錄加入 sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime
from src.config import OUTPUT_DIR, CURRENT_YEAR
from src.api_client import get_current_api_info, is_peak_hour, get_next_off_peak_time
from src.html_builder import create_default_index, generate_categories_page, generate_category_pages
from src.article_generator import generate_article
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
        warnings.append("GEMINI_API_KEY 未設定，僅使用 DeepSeek 模式")
    
    if errors:
        logger.error("API Key 檢查失敗：")
        for err in errors:
            logger.error(f"   - {err}")
        logger.info("請執行 ahpal-static.ps1 設定正確的 API Key")
        return False, errors
    
    if warnings:
        logger.warning("API Key 檢查有警告：")
        for warn in warnings:
            logger.warning(f"   - {warn}")
    
    logger.info("✅ API Key 檢查通過")
    return True, []

# ============================================================
# 2. 文章關鍵字列表 (keywords_list)
# ============================================================

keywords_list = [
    # tech/ - 3C 科技教學
    {"keyword": "2026 年最佳電競筆電推薦與評測", "category": "💻 3C 科技教學", "filename": "tech/best-gaming-laptops-2026.html"},
    {"keyword": "AI 繪圖工具 Midjourney vs Stable Diffusion 比較", "category": "💻 3C 科技教學", "filename": "tech/ai-art-tools-comparison-2026.html"},
    {"keyword": "2026 年 5G 手機選購指南", "category": "💻 3C 科技教學", "filename": "tech/5g-phone-guide-2026.html"},
    {"keyword": "2026 旗艦摺疊手機選購指南 三星華為谷歌對比", "category": "💻 3C 科技教學", "filename": "tech/2026旗艦摺疊手機選購指南三星華為谷歌對比.html"},
    {"keyword": "Wi-Fi 7 路由器完整評測 速度延遲覆蓋範圍實測", "category": "💻 3C 科技教學", "filename": "tech/Wi-Fi7路由器完整評測速度延遲覆蓋範圍實測.html"},
    {"keyword": "品質日誌測試文章 2026", "category": "💻 3C 科技教學", "filename": "tech/品質日誌測試文章2026.html"},
    {"keyword": "Gemini 效能測試文章 2026", "category": "💻 3C 科技教學", "filename": "tech/Gemini效能測試文章2026.html"},
    {"keyword": "2026 年智慧家庭生態系統完整指南 Apple Google Samsung 對比", "category": "💻 3C 科技教學", "filename": "tech/2026年智慧家庭生態系統完整指南AppleGoogleSamsung對比.html"},
    {"keyword": "家用 NAS 完整選購指南 2026 年最值得買的型號", "category": "💻 3C 科技教學", "filename": "tech/家用NAS完整選購指南2026年最值得買的型號.html"},
    # game/ - 遊戲攻略
    {"keyword": "魔物獵人荒野 太刀新手進階連招技巧攻略", "category": "🎮 遊戲攻略", "filename": "game/魔物獵人荒野太刀新手進階連招技巧攻略.html"},
    {"keyword": "GTA 6 搶先體驗心得 地圖載具任務系統解析", "category": "🎮 遊戲攻略", "filename": "game/GTA6搶先體驗心得地圖載具任務系統解析.html"},
    # life/ - 生活小常識
    {"keyword": "居家甲醛去除方法與空氣淨化實測", "category": "🏠 生活小常識", "filename": "life/home-formaldehyde-removal-guide.html"},
    {"keyword": "居家收納改造 小空間最大化利用的 10 個秘訣", "category": "🏠 生活小常識", "filename": "life/居家收納改造小空間最大化利用的10個秘訣.html"},
    {"keyword": "超簡單 30 分鐘快速料理 上班族必學省時晚餐食譜", "category": "🏠 生活小常識", "filename": "life/超簡單30分鐘快速料理上班族必學省時晚餐食譜.html"},
    {"keyword": "居家安全監控系統選購指南 2026 年最推薦方案", "category": "🏠 生活小常識", "filename": "life/居家安全監控系統選購指南2026年最推薦方案.html"},
    # review/ - 軟體評測
    {"keyword": "密碼管理工具怎麼選：2026 完整指南", "category": "📊 軟體評測", "filename": "review/password-manager-guide-2026.html"},
    {"keyword": "Notion 新手入門：從零開始建立知識庫", "category": "📊 軟體評測", "filename": "review/notion-beginner-guide.html"},
    {"keyword": "2026 平價 Android 平板對比 小米聯想三星誰最超值", "category": "📊 軟體評測", "filename": "review/2026平價Android平板對比小米聯想三星誰最超值.html"},
    {"keyword": "Notion vs Obsidian vs Anytype 筆記軟體終極對決", "category": "📊 軟體評測", "filename": "review/NotionvsObsidianvsAnytype筆記軟體終極對決.html"},
    {"keyword": "2026 年免費防毒軟體評測 5 款實測對比", "category": "📊 軟體評測", "filename": "review/2026年免費防毒軟體評測5款實測對比.html"},
    # philosophy/ - 人生哲理
    {"keyword": "建立高效能習慣：原子習慣實戰指南", "category": "🌟 人生哲理", "filename": "philosophy/atomic-habits-guide-2026.html"},
    {"keyword": "財務自由之路：被動收入建立完全攻略", "category": "🌟 人生哲理", "filename": "philosophy/passive-income-guide-2026.html"},
    {"keyword": "原子習慣 如何用微小改變打造長期競爭力", "category": "🌟 人生哲理", "filename": "philosophy/原子習慣如何用微小改變打造長期競爭力.html"},
    {"keyword": "成長型思維 vs 固定型思維 決定人生成敗的關鍵心態", "category": "🌟 人生哲理", "filename": "philosophy/成長型思維vs固定型思維決定人生成敗的關鍵心態.html"},
    {"keyword": "冥想入門指南 每天 10 分鐘提升專注力與情緒管理", "category": "🌟 人生哲理", "filename": "philosophy/冥想入門指南每天10分鐘提升專注力與情緒管理.html"},
    # trend/ - AI 趨勢
    {"keyword": "生成式 AI 資安風險與防護策略", "category": "🤖 AI 趨勢", "filename": "trend/generative-ai-security-2026.html"},
    {"keyword": "AI 代理與自動化工作流程應用", "category": "🤖 AI 趨勢", "filename": "trend/ai-agent-workflow-2026.html"},
    {"keyword": "2026 生成式 AI 企業應用趨勢 自動化客服內容生成", "category": "🤖 AI 趨勢", "filename": "trend/2026生成式AI企業應用趨勢自動化客服內容生成.html"},
    {"keyword": "GPT-5 vs Gemini 3.0 語言模型評測比較分析", "category": "🤖 AI 趨勢", "filename": "trend/GPT-5vsGemini30語言模型評測比較分析.html"},
    {"keyword": "2026 年 5 大 AI 工具推薦 提升工作效率必備", "category": "🤖 AI 趨勢", "filename": "trend/2026年5大AI工具推薦提升工作效率必備.html"},
]

# ============================================================
# 3. 獲取待生成文章列表
# ============================================================

def get_pending_articles():
    pending = []
    output_dir = os.environ.get("AHPAL_OUTPUT_DIR", "C:\\Users\\User\\ahpal-static")
    
    for item in keywords_list:
        filename = item["filename"]
        file_path = Path(output_dir) / filename
        if not file_path.exists():
            pending.append(item)
    
    return pending

# ============================================================
# 4. 執行文章生成管線 (修正：正確傳遞 force_api)
# ============================================================

def run_pipeline(force_api=None, dry_run=False):
    logger.info("=" * 70)
    logger.info(f"🦞 AHPAL.COM 文章生成引擎 v4.4 - {CURRENT_YEAR}")
    logger.info(f"📅 {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    logger.info("=" * 70)
    
    passed, errors = check_api_keys()
    if not passed:
        logger.error("❌ 請修正 API Key 後重新執行")
        return None
    
    if force_api:
        logger.info(f"🔧 強制使用 API：{force_api.upper()}")
        os.environ["FORCE_API"] = force_api
    else:
        logger.info("🔄 默認模式：Gemini 優先（備援 DeepSeek）")
        os.environ.pop("FORCE_API", None)
    
    # 🔧 將 force_api 傳遞給 get_current_api_info
    api_info = get_current_api_info(force_api=force_api)
    logger.info(f"📡 當前 API：{api_info['name']}")
    logger.info(f"   🤖 模型：{api_info['model']}")
    logger.info(f"   ⏰ 時段：{'尖峰' if api_info['peak'] else '離峰'}")
    logger.info(f"   💰 價格：{api_info['price']}")
    
    if not force_api and is_peak_hour():
        next_time = get_next_off_peak_time()
        logger.info(f"💡 將於 {next_time.strftime('%H:%M')} 自動切換至 DeepSeek，節省成本")
        logger.info("   💡 可按 [A] 強制使用 DeepSeek 立即執行")
    
    pending_articles = get_pending_articles()
    
    if dry_run:
        logger.info(f"\n📋 待生成文章清單 ({len(pending_articles)} 篇)：")
        for item in pending_articles:
            logger.info(f"   - {item['keyword']} ({item['category']})")
        return len(pending_articles)
    
    logger.info("📄 建立首頁與分類頁...")
    create_default_index()
    generate_categories_page()
    
    if pending_articles:
        logger.info(f"\n📝 開始生成 {len(pending_articles)} 篇文章...")
        for idx, item in enumerate(pending_articles, 1):
            logger.info(f"\n--- 進度 {idx}/{len(pending_articles)} ---")
            try:
                # 🔧 關鍵修正：將 force_api 傳遞給 generate_article
                generate_article(item, force_api=force_api)
            except Exception as e:
                logger.error(f"❌ 生成失敗：{item['keyword']} - {e}")
                continue
    else:
        logger.info("\n✅ 所有文章已存在，無需生成")
    
    logger.info("📂 更新分類頁與 Sitemap...")
    generate_category_pages()
    all_existing_html = scan_all_html_files()
    update_sitemap()
    
    logger.info("\n" + "=" * 70)
    logger.info("✅ 文章生成流程完成！")
    logger.info(f"📊 總文章數：{len(all_existing_html)} 篇")
    logger.info("📌 請執行 npx wrangler pages deploy 部署至 Cloudflare")
    logger.info("=" * 70)
    
    return len(all_existing_html)

# ============================================================
# 5. 主程式入口
# ============================================================

def main():
    parser = argparse.ArgumentParser(description='AHPAL 文章生成引擎')
    parser.add_argument('--force', choices=['deepseek', 'gemini'], help='強制使用指定的 API')
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
    
    run_pipeline(args.force, args.dry_run)

if __name__ == "__main__":
    main()