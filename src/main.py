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
# 關鍵字清單（所有文章來源）
# ============================================================

keywords_list = [
    # === tech/ - 3C 科技教學 ===
    {"keyword": "摺疊手機購買指南 2026", "category": "💻 3C 科技教學", "filename": "tech/folding-phone-buying-guide-2026.html"},
    {"keyword": "5G 手機選購 2026", "category": "💻 3C 科技教學", "filename": "tech/5g-phone-guide-2026.html"},
    {"keyword": "筆電選購指南 2026", "category": "💻 3C 科技教學", "filename": "tech/laptop-buying-guide-2026.html"},
    {"keyword": "藍牙耳機推薦 2026", "category": "💻 3C 科技教學", "filename": "tech/earbuds-guide-2026.html"},
    {"keyword": "智慧手錶選購 2026", "category": "💻 3C 科技教學", "filename": "tech/smartwatch-guide-2026.html"},
    {"keyword": "手機拍照技巧 2026", "category": "💻 3C 科技教學", "filename": "tech/phone-photography-tips-2026.html"},
    {"keyword": "平板電腦比較 2026", "category": "💻 3C 科技教學", "filename": "tech/tablet-comparison-2026.html"},
    {"keyword": "電競螢幕選購 2026", "category": "💻 3C 科技教學", "filename": "tech/gaming-monitor-guide-2026.html"},
    {"keyword": "機械鍵盤推薦 2026", "category": "💻 3C 科技教學", "filename": "tech/mechanical-keyboard-guide-2026.html"},
    {"keyword": "行動電源選購 2026", "category": "💻 3C 科技教學", "filename": "tech/power-bank-guide-2026.html"},
    {"keyword": "WiFi 路由器推薦 2026", "category": "💻 3C 科技教學", "filename": "tech/wifi-router-guide-2026.html"},
    {"keyword": "NAS 選購指南 2026", "category": "💻 3C 科技教學", "filename": "tech/nas-buying-guide-2026.html"},
    {"keyword": "USB-C 擴充座推薦", "category": "💻 3C 科技教學", "filename": "tech/usb-c-hub-guide-2026.html"},
    {"keyword": "3D 列印機入門", "category": "💻 3C 科技教學", "filename": "tech/3d-printer-guide-2026.html"},
    {"keyword": "空拍機選購 2026", "category": "💻 3C 科技教學", "filename": "tech/drone-buying-guide-2026.html"},
    {"keyword": "電動車充電樁安裝", "category": "💻 3C 科技教學", "filename": "tech/ev-charger-install-guide-2026.html"},

    # === game/ - 遊戲攻略 ===
    {"keyword": "2026 最夯 5 款獨立遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/best-indie-games-2026.html"},
    {"keyword": "2026 年最佳 RPG Top 5", "category": "🎮 遊戲攻略", "filename": "game/best-rpg-2026.html"},
    {"keyword": "2026 最耐玩 Switch 遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/best-switch-games-2026.html"},
    {"keyword": "暗黑破壞神 IV 賽季 5 最強流派", "category": "🎮 遊戲攻略", "filename": "game/diablo4-season5-meta.html"},
    {"keyword": "艾爾登法環 DLC 全 Boss 攻略", "category": "🎮 遊戲攻略", "filename": "game/elden-ring-dlc-boss-guide.html"},
    {"keyword": "2026 免費 PC 射擊遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/free-shooter-games-2026.html"},
    {"keyword": "原神 5.0 隱藏任務全攻略", "category": "🎮 遊戲攻略", "filename": "game/genshin-5-0-quest.html"},
    {"keyword": "原神 5.1 新角色配隊攻略", "category": "🎮 遊戲攻略", "filename": "game/genshin-5-1-team-guide.html"},

    # === life/ - 生活小常識 ===
    {"keyword": "居家收納技巧 2026", "category": "🏠 生活小常識", "filename": "life/home-organization-tips-2026.html"},
    {"keyword": "省錢生活智慧 2026", "category": "🏠 生活小常識", "filename": "life/money-saving-tips-2026.html"},
    {"keyword": "廚房清潔秘訣", "category": "🏠 生活小常識", "filename": "life/kitchen-cleaning-tips-2026.html"},
    {"keyword": "衣物收納技巧", "category": "🏠 生活小常識", "filename": "life/clothing-storage-tips-2026.html"},
    {"keyword": "家事管理 APP 推薦", "category": "🏠 生活小常識", "filename": "life/household-apps-2026.html"},
    {"keyword": "節能省電技巧", "category": "🏠 生活小常識", "filename": "life/energy-saving-tips-2026.html"},
    {"keyword": "陽台種菜入門", "category": "🏠 生活小常識", "filename": "life/balcony-gardening-2026.html"},
    {"keyword": "寵物用品推薦", "category": "🏠 生活小常識", "filename": "life/pet-supplies-guide-2026.html"},
    {"keyword": "親子居家活動", "category": "🏠 生活小常識", "filename": "life/kids-home-activities-2026.html"},
    {"keyword": "二手物品買賣平台", "category": "🏠 生活小常識", "filename": "life/second-hand-platforms-2026.html"},
    {"keyword": "居家安全檢查", "category": "🏠 生活小常識", "filename": "life/home-safety-checklist-2026.html"},
    {"keyword": "搬家打包技巧", "category": "🏠 生活小常識", "filename": "life/moving-packing-tips-2026.html"},
    {"keyword": "掃地機器人選購", "category": "🏠 生活小常識", "filename": "life/robot-vacuum-guide-2026.html"},
    {"keyword": "空氣清淨機推薦", "category": "🏠 生活小常識", "filename": "life/air-purifier-guide-2026.html"},
    {"keyword": "除濕機選購指南", "category": "🏠 生活小常識", "filename": "life/dehumidifier-guide-2026.html"},

    # === review/ - 軟體評測 ===
    {"keyword": "免費剪片軟體推薦 2026", "category": "📊 軟體評測", "filename": "review/free-video-editor-2026.html"},
    {"keyword": "遠端桌面軟體比較", "category": "📊 軟體評測", "filename": "review/remote-desktop-comparison-2026.html"},
    {"keyword": "密碼管理軟體推薦", "category": "📊 軟體評測", "filename": "review/password-manager-2026.html"},
    {"keyword": "雲端硬碟比較 2026", "category": "📊 軟體評測", "filename": "review/cloud-storage-comparison-2026.html"},
    {"keyword": "PDF 編輯軟體推薦", "category": "📊 軟體評測", "filename": "review/pdf-editor-2026.html"},
    {"keyword": "螢幕錄影軟體比較", "category": "📊 軟體評測", "filename": "review/screen-recorder-comparison-2026.html"},
    {"keyword": "筆記軟體推薦 2026", "category": "📊 軟體評測", "filename": "review/note-taking-apps-2026.html"},
    {"keyword": "AI 繪圖軟體評測", "category": "📊 軟體評測", "filename": "review/ai-art-generator-review-2026.html"},
    {"keyword": "影片下載軟體推薦", "category": "📊 軟體評測", "filename": "review/video-downloader-2026.html"},
    {"keyword": "音樂串流平台比較", "category": "📊 軟體評測", "filename": "review/music-streaming-comparison-2026.html"},
    {"keyword": "VPN 服務推薦 2026", "category": "📊 軟體評測", "filename": "review/vpn-service-review-2026.html"},
    {"keyword": "防毒軟體比較 2026", "category": "📊 軟體評測", "filename": "review/antivirus-comparison-2026.html"},
    {"keyword": "檔案同步工具推薦", "category": "📊 軟體評測", "filename": "review/file-sync-tools-2026.html"},
    {"keyword": "開源軟體推薦 2026", "category": "📊 軟體評測", "filename": "review/open-source-software-2026.html"},
    {"keyword": "AI 寫作工具評測", "category": "📊 軟體評測", "filename": "review/ai-writing-tools-review-2026.html"},

    # === philosophy/ - 人生哲理 ===
    {"keyword": "成功習慣養成", "category": "🌟 人生哲理", "filename": "philosophy/success-habits-2026.html"},
    {"keyword": "時間管理技巧", "category": "🌟 人生哲理", "filename": "philosophy/time-management-tips-2026.html"},
    {"keyword": "職涯規劃指南", "category": "🌟 人生哲理", "filename": "philosophy/career-planning-guide-2026.html"},
    {"keyword": "情緒管理方法", "category": "🌟 人生哲理", "filename": "philosophy/emotional-management-2026.html"},
    {"keyword": "健康生活習慣", "category": "🌟 人生哲理", "filename": "philosophy/healthy-lifestyle-habits-2026.html"},
    {"keyword": "人際關係經營", "category": "🌟 人生哲理", "filename": "philosophy/relationship-building-2026.html"},
    {"keyword": "財務自由規劃", "category": "🌟 人生哲理", "filename": "philosophy/financial-freedom-plan-2026.html"},
    {"keyword": "學習方法優化", "category": "🌟 人生哲理", "filename": "philosophy/learning-methods-2026.html"},
    {"keyword": "壓力紓解技巧", "category": "🌟 人生哲理", "filename": "philosophy/stress-relief-techniques-2026.html"},
    {"keyword": "人生目標設定", "category": "🌟 人生哲理", "filename": "philosophy/goal-setting-guide-2026.html"},
    {"keyword": "正念冥想入門", "category": "🌟 人生哲理", "filename": "philosophy/mindfulness-meditation-2026.html"},
    {"keyword": "團隊合作技巧", "category": "🌟 人生哲理", "filename": "philosophy/teamwork-skills-2026.html"},
    {"keyword": "領導力培養", "category": "🌟 人生哲理", "filename": "philosophy/leadership-development-2026.html"},
    {"keyword": "創意思考方法", "category": "🌟 人生哲理", "filename": "philosophy/creative-thinking-methods-2026.html"},
    {"keyword": "人生哲學經典", "category": "🌟 人生哲理", "filename": "philosophy/life-philosophy-classics-2026.html"},

    # === trend/ - AI 趨勢 ===
    {"keyword": "AI 工具推薦 2026", "category": "🤖 AI 趨勢", "filename": "trend/ai-tools-2026.html"},
    {"keyword": "ChatGPT 應用技巧", "category": "🤖 AI 趨勢", "filename": "trend/chatgpt-applications-2026.html"},
    {"keyword": "AI 繪圖工具比較", "category": "🤖 AI 趨勢", "filename": "trend/ai-art-tools-comparison-2026.html"},
    {"keyword": "數位轉型策略", "category": "🤖 AI 趨勢", "filename": "trend/digital-transformation-strategy-2026.html"},
    {"keyword": "AI 未來趨勢預測", "category": "🤖 AI 趨勢", "filename": "trend/ai-future-trends-2026.html"},
    {"keyword": "AI 自動化工具", "category": "🤖 AI 趨勢", "filename": "trend/ai-automation-tools-2026.html"},
    {"keyword": "AI 行銷應用案例", "category": "🤖 AI 趨勢", "filename": "trend/ai-marketing-cases-2026.html"},
    {"keyword": "AI 數據分析工具", "category": "🤖 AI 趨勢", "filename": "trend/ai-data-analysis-tools-2026.html"},
    {"keyword": "AI 客服系統比較", "category": "🤖 AI 趨勢", "filename": "trend/ai-customer-service-2026.html"},
    {"keyword": "AI 人才培養趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-talent-development-2026.html"},
    {"keyword": "AI 倫理與法規", "category": "🤖 AI 趨勢", "filename": "trend/ai-ethics-regulations-2026.html"},
    {"keyword": "AI 金融應用趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-finance-applications-2026.html"},
    {"keyword": "AI 醫療應用趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-healthcare-applications-2026.html"},
    {"keyword": "AI 教育應用趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-education-applications-2026.html"},
    {"keyword": "AI 新創公司推薦", "category": "🤖 AI 趨勢", "filename": "trend/ai-startups-2026.html"},
]

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
# 3. 主程式入口
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