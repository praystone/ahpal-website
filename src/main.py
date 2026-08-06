# ============================================================
# AHPAL 文章生成引擎 - main.py v5.1
# ============================================================
# 變更：
#   - 整合 model_router.py（Pollinations AI 生圖）
#   - 優化 API 資訊顯示
#   - 完善錯誤處理與日誌
#   - 支援生圖功能開關
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
# 2. 文章關鍵字列表 (keywords_list)
# ============================================================

keywords_list = [
    # tech/ - 3C 科技教學
    {"keyword": "暗黑破壞神 IV 賽季5 主流流派終極指南 全職業T0/T1配置與實戰技巧", "category": "🎮 遊戲攻略", "filename": "game/diablo4-season5-meta.html"},
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
    {"keyword": "CMS 面板測試文章 2026", "category": "💻 3C 科技教學", "filename": "tech/CMS面板測試文章2026.html"},
    {"keyword": "2026 年 7 月 Antigravity 系統驗證測試文章", "category": "💻 3C 科技教學", "filename": "tech/2026年7月Antigravity系統驗證測試文章.html"},
    {"keyword": "2026 年最佳 DAW 數位音樂工作站入門指南", "category": "📊 軟體評測", "filename": "review/2026年最佳DAW數位音樂工作站入門指南.html"},
    {"keyword": "2026 年免費雲端筆記工具完整評測", "category": "📊 軟體評測", "filename": "review/2026年免費雲端筆記工具完整評測.html"},
    {"keyword": "2026 年最佳免費 AI 繪圖工具完整評測", "category": "🤖 AI 趨勢", "filename": "trend/2026年最佳免費AI繪圖工具完整評測.html"},
    {"keyword": "Windows 11 隱藏版實用快捷鍵大全", "category": "💻 3C 科技教學", "filename": "tech/Windows11隱藏版實用快捷鍵大全.html"},
    {"keyword": "居家辦公室佈置指南：提升工作效率的 10 個秘訣", "category": "🏠 生活小常識", "filename": "life/居家辦公室佈置指南提升工作效率的10個秘訣.html"},
    {"keyword": "2026 年免費防毒軟體排名與比較", "category": "📊 軟體評測", "filename": "review/2026年免費防毒軟體排名與比較.html"},
    {"keyword": "人生的意義：從哲學觀點重新思考自我價值", "category": "🌟 人生哲理", "filename": "philosophy/人生的意義從哲學觀點重新思考自我價值.html"},
    {"keyword": "AI 時代來臨：哪些工作不會被取代？", "category": "🤖 AI 趨勢", "filename": "trend/AI時代來臨哪些工作不會被取代.html"},
    {"keyword": "手機充電正確方式：延長電池壽命的 5 個技巧", "category": "💻 3C 科技教學", "filename": "tech/手機充電正確方式延長電池壽命的5個技巧.html"},
    {"keyword": "超簡單室內植栽照顧指南：新手也能養活", "category": "🏠 生活小常識", "filename": "life/超簡單室內植栽照顧指南新手也能養活.html"},
    {"keyword": "Notion 與 Obsidian 對決：哪個更適合你？", "category": "📊 軟體評測", "filename": "review/Notion與Obsidian對決哪個更適合你.html"},
    {"keyword": "每天 10 分鐘冥想：改變人生的習慣", "category": "🌟 人生哲理", "filename": "philosophy/每天10分鐘冥想改變人生的習慣.html"},
    {"keyword": "2026 年最佳獨立遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳獨立遊戲推薦.html"},
    {"keyword": "2026 年最佳 RPG 遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳RPG遊戲推薦.html"},
    {"keyword": "2026 年免費射擊遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年免費射擊遊戲推薦.html"},
    {"keyword": "2026 年最佳 Switch 遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳Switch遊戲推薦.html"},
    {"keyword": "2026 年最佳多人合作遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳多人合作遊戲推薦.html"},
    {"keyword": "2026 年最受期待 AAA 大作推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最受期待AAA大作推薦.html"},
    {"keyword": "2026 年最佳 Roguelite 遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳Roguelite遊戲推薦.html"},
    {"keyword": "2026 年最佳手機遊戲推薦 Top 10", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳手機遊戲推薦Top10.html"},
    {"keyword": "2026 年 Steam 夏季特賣必買遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年Steam夏季特賣必買遊戲推薦.html"},
    {"keyword": "2026 年最佳獨立遊戲必玩清單", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳獨立遊戲必玩清單.html"},
    {"keyword": "2026 年最期待遊戲發售表", "category": "🎮 遊戲攻略", "filename": "game/2026年最期待遊戲發售表.html"},
    {"keyword": "2026 年最佳射擊遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最佳射擊遊戲推薦.html"},
    {"keyword": "2026 年最佳 AI 繪圖工具推薦 TOP 5", "category": "🤖 AI 趨勢", "filename": "trend/2026年最佳AI繪圖工具推薦TOP5.html"},
    {"keyword": "2026 年最新居家收納技巧大全", "category": "🏠 生活小常識", "filename": "life/2026年最新居家收納技巧大全.html"},
    {"keyword": "2026 年高效工作法：5 個科學驗證的專注力策略", "category": "💻 3C 科技教學", "filename": "tech/2026年高效工作法5個科學驗證的專注力策略.html"},
    {"keyword": "在數位噪音中保持清醒——一位老編輯的 30 年注意力管理手記", "category": "🌟 人生哲理", "filename": "philosophy/在數位噪音中保持清醒一位老編輯的30年注意力管理手記.html"},
    {"keyword": "2026 年知識變現完整攻略：從0到1打造你的數位產品｜創業者必讀", "category": "📊 軟體評測", "filename": "review/2026年知識變現完整攻略從0到1打造你的數位產品創業者必讀.html"},
    {"keyword": "普通人也能懂的AI時代生存指南：不被取代的5個核心能力｜深度分析", "category": "🤖 AI 趨勢", "filename": "trend/普通人也能懂的AI時代生存指南不被取代的5個核心能力深度分析.html"},
    {"keyword": "撒迦利亞書第 12 章解析：耶路撒冷的救贖與列國的審判（中英對照）", "category": "🌟 人生哲理", "filename": "philosophy/撒迦利亞書第12章解析耶路撒冷的救贖與列國的審判中英對照.html"},
    {"keyword": "2026 年高效工作法：5 個科學驗證的專注力策略｜完整實戰指南", "category": "💻 3C 科技教學", "filename": "tech/2026年高效工作法5個科學驗證的專注力策略完整實戰指南.html"},
    {"keyword": "從破碎到修復：一個平凡家庭的財務重建筆記｜真實故事", "category": "🌟 人生哲理", "filename": "philosophy/從破碎到修復一個平凡家庭的財務重建筆記真實故事.html"},
    {"keyword": "尋找內心平靜的極簡生活哲學：在喧囂世界中安頓心靈的指引", "category": "🌟 人生哲理", "filename": "philosophy/尋找內心平靜的極簡生活哲學在喧囂世界中安頓心靈的指引.html"},
    {"keyword": "正念飲食全攻略：如何透過專注飲食吃出健康與心靈自由", "category": "🌟 人生哲理", "filename": "philosophy/正念飲食全攻略如何透過專注飲食吃出健康與心靈自由.html"},
    {"keyword": "極簡主義與幸福的辯證關係：擁有的越少，為什麼反而越快樂？", "category": "🌟 人生哲理", "filename": "philosophy/極簡主義與幸福的辯證關係擁有的越少為什麼反而越快樂.html"},
    {"keyword": "撒迦利亞書第 1 章解析：呼召悔改與八個異象的開端（中英對照）", "category": "🌟 人生哲理", "filename": "philosophy/撒迦利亞書第1章解析呼召悔改與八個異象的開端中英對照.html"},
    {"keyword": "撒迦利亞書第 2-6 章解析：準繩、金燈台與四輛戰車的異象（中英對照）", "category": "🌟 人生哲理", "filename": "philosophy/撒迦利亞書第2-6章解析準繩金燈台與四輛戰車的異象中英對照.html"},
    {"keyword": "撒迦利亞書第 7-8 章解析：真實的禁食與耶路撒冷的復興（中英對照）", "category": "🌟 人生哲理", "filename": "philosophy/撒迦利亞書第7-8章解析真實的禁食與耶路撒冷的復興中英對照.html"},
    {"keyword": "撒迦利亞書第 9-10 章解析：審判列國與錫安君王的降臨（中英對照）", "category": "🌟 人生哲理", "filename": "philosophy/撒迦利亞書第9-10章解析審判列國與錫安君王的降臨中英對照.html"},
    {"keyword": "冥想入門指南每天10分鐘提升專注力與情緒管理", "category": "🌟 人生哲理", "filename": "philosophy/meditation-guide-10-minutes.html"},
    {"keyword": "原子習慣如何用微小改變打造長期競爭力", "category": "🌟 人生哲理", "filename": "philosophy/atomic-habits-guide.html"},
    {"keyword": "成長型思維vs固定型思維決定人生成敗的關鍵心態", "category": "🌟 人生哲理", "filename": "philosophy/growth-mindset-vs-fixed-mindset.html"},
    {"keyword": "數位時代的專注力訓練方法與實踐指南", "category": "🌟 人生哲理", "filename": "philosophy/digital-focus-training-guide.html"},
    {"keyword": "財務自由之路被動收入建立完全攻略", "category": "🌟 人生哲理", "filename": "philosophy/financial-freedom-passive-income-guide.html"},
    {"keyword": "正念冥想減壓技巧與日常練習方法", "category": "🌟 人生哲理", "filename": "philosophy/mindfulness-stress-reduction-guide.html"},
    {"keyword": "2026 年 Thunderbolt 5 完全解析：速度、應用與選購指南", "category": "💻 3C 科技教學", "filename": "tech/2026年Thunderbolt5完全解析速度應用與選購指南.html"},
    {"keyword": "Windows 11 2026 更新實測：新功能與效能表現", "category": "💻 3C 科技教學", "filename": "tech/Windows112026更新實測新功能與效能表現.html"},
    {"keyword": "2026 年最受期待的 10 款獨立遊戲推薦", "category": "🎮 遊戲攻略", "filename": "game/2026年最受期待的10款獨立遊戲推薦.html"},
    {"keyword": "2026 年遊戲 PC 性價比最高的配置組合攻略", "category": "🎮 遊戲攻略", "filename": "game/2026年遊戲PC性價比最高的配置組合攻略.html"},
    {"keyword": "2026 年智慧家庭中樞選購指南：Apple Home vs Google Home vs Amazon Alexa", "category": "🏠 生活小常識", "filename": "life/2026年智慧家庭中樞選購指南AppleHomevsGoogleHomevsAmazonAlexa.html"},
    {"keyword": "2026 年颱風季防災準備清單：必備物資與應變計畫", "category": "🏠 生活小常識", "filename": "life/2026年颱風季防災準備清單必備物資與應變計畫.html"},
    {"keyword": "2026 年最佳免費 DNS 服務評測：速度、隱私與安全性對比", "category": "📊 軟體評測", "filename": "review/2026年最佳免費DNS服務評測速度隱私與安全性對比.html"},
    {"keyword": "2026 年跨平台剪貼簿工具評測：效率提升神器", "category": "📊 軟體評測", "filename": "review/2026年跨平台剪貼簿工具評測效率提升神器.html"},
    {"keyword": "2026 年職場生存指南：AI 時代的不可替代能力", "category": "🌟 人生哲理", "filename": "philosophy/2026年職場生存指南AI時代的不可替代能力.html"},
    {"keyword": "一年讀完 52 本書：建立閱讀習慣的科學方法與實戰策略", "category": "🌟 人生哲理", "filename": "philosophy/一年讀完52本書建立閱讀習慣的科學方法與實戰策略.html"},
    {"keyword": "2026 年 AI 代理全面解析：應用場景與未來趨勢", "category": "🤖 AI 趨勢", "filename": "trend/2026年AI代理全面解析應用場景與未來趨勢.html"},
    {"keyword": "2026 年開源 AI 模型盤點：Llama 4、DeepSeek-V4 與其他強者對決", "category": "🤖 AI 趨勢", "filename": "trend/2026年開源AI模型盤點Llama4DeepSeek-V4與其他強者對決.html"},
    {"keyword": "2026 年 MacBook Neo 購買指南：M5 晶片、規格與價格完整解析", "category": "💻 3C 科技教學", "filename": "tech/macbook-neo-buying-guide-2026.html"},
    {"keyword": "2026 年 AI 生成圖片版權爭議與法律規範完整指南", "category": "🤖 AI 趨勢", "filename": "trend/ai-image-copyright-law-2026.html"},
    {"keyword": "2026 年最值得投資的 5 款加密貨幣：比特幣、以太坊與新興幣種完整分析", "category": "🤖 AI 趨勢", "filename": "trend/crypto-investment-guide-2026.html"},

    {"keyword": "2026 年最新居家智慧裝置選購指南：從入門到進階的完整攻略", "category": "🏠 生活小常識", "filename": "life/smart-home-devices-guide-2026.html"},

    {"keyword": "2026 年開源軟體推薦：完全免費、替代付費軟體的終極指南", "category": "📊 軟體評測", "filename": "review/open-source-software-guide-2026.html"},

    {"keyword": "2026 年最佳免費防毒軟體完整評測：效能、防護與隱私全面對比", "category": "📊 軟體評測", "filename": "review/best-free-antivirus-2026.html"},

    {"keyword": "如何在數位時代保持內心平靜：正念與專注力的科學實踐指南", "category": "🌟 人生哲理", "filename": "philosophy/mindfulness-digital-age-guide-2026.html"},

    {"keyword": "2026 年 Thunderbolt 5 完整解析：速度、應用與選購指南", "category": "💻 3C 科技教學", "filename": "tech/thunderbolt-5-guide-2026.html"},

    {"keyword": "2026 年 Wi-Fi 7 路由器選購指南：速度、覆蓋與價格完整分析", "category": "💻 3C 科技教學", "filename": "tech/wi-fi-7-router-guide-2026.html"},
    {"keyword": "2026 年最佳多人連線遊戲推薦：與朋友同樂的 10 款必玩之作", "category": "🎮 遊戲攻略", "filename": "game/best-multiplayer-games-2026.html"},
    {"keyword": "2026 年居家節能省電全攻略：電費帳單輕鬆砍半的 15 個實用技巧", "category": "🏠 生活小常識", "filename": "life/energy-saving-guide-2026.html"},
    {"keyword": "2026 年最佳筆記軟體全面對比：Notion、Obsidian、Logseq 與其他 5 款深度評測", "category": "📊 軟體評測", "filename": "review/best-note-taking-apps-2026.html"},
    {"keyword": "2026 年建立成長型思維的 7 個日常練習：從固定心態到無限可能的轉變指南", "category": "🌟 人生哲理", "filename": "philosophy/growth-mindset-daily-practice-2026.html"},
    {"keyword": "2026 年 AI 代理全面解析：從自動化客服到自主決策的未來趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-agent-complete-guide-2026.html"},

    {"keyword": "2026 年小宅改造術：5 招打破空間限制，打造高效收納與舒適生活", "category": "🏠 生活小常識", "filename": "life/small-space-renovation-2026.html"},
    {"keyword": "2026 年最佳 AI 寫作助手全面評測：ChatGPT、Claude、Gemini 與其他 6 款深度比較", "category": "📊 軟體評測", "filename": "review/ai-writing-assistant-2026.html"},
    {"keyword": "2026 年告別拖延症的科學方法：從心理學到行為設計的完整實踐指南", "category": "🌟 人生哲理", "filename": "philosophy/stop-procrastination-guide-2026.html"},
    {"keyword": "2026 年 AI 監管政策全球盤點：歐盟、美國、中國與台灣的法規發展趨勢", "category": "🤖 AI 趨勢", "filename": "trend/ai-regulation-2026.html"},

    {"keyword": "2026 年極簡生活實踐指南：斷捨離、數位排毒與心靈自由的完整攻略", "category": "🌟 人生哲理", "filename": "philosophy/minimalism-guide-2026.html"},

]

# ============================================================
# 3. 獲取待生成文章列表
# ============================================================

def get_pending_articles():
    """取得所有待生成的文章"""
    pending = []
    output_dir = os.environ.get("AHPAL_OUTPUT_DIR", "C:\\Users\\User\\ahpal-static")
    
    for item in keywords_list:
        filename = item["filename"]
        file_path = Path(output_dir) / filename
        if not file_path.exists():
            pending.append(item)
        else:
            # 檢查檔案是否過小（可能損壞）
            try:
                if file_path.stat().st_size < 5120:
                    pending.append(item)
            except:
                pending.append(item)
    
    return pending

# ============================================================
# 4. 執行文章生成管線
# ============================================================

def run_pipeline(force_api=None, dry_run=False):
    """執行文章生成管線"""
    logger.info("=" * 70)
    logger.info(f"🦞 AHPAL.COM 文章生成引擎 v5.1 - {CURRENT_YEAR}")
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
    
    # 顯示生圖資訊
    logger.info(f"🖼️ 配圖生成：Pollinations AI（免費、免 API Key）")
    
    # 3. 取得待生成文章
    pending_articles = get_pending_articles()
    
    if dry_run:
        logger.info(f"\n📋 待生成文章清單 ({len(pending_articles)} 篇)：")
        for item in pending_articles:
            logger.info(f"   - {item['keyword']} ({item['category']})")
        return len(pending_articles)
    
    # 4. 建立首頁與分類頁
    logger.info("📄 建立首頁與分類頁...")
    create_default_index()
    generate_categories_page()
    
    # 5. 生成文章
    if pending_articles:
        logger.info(f"\n📝 開始生成 {len(pending_articles)} 篇文章...")
        for idx, item in enumerate(pending_articles, 1):
            logger.info(f"\n--- 進度 {idx}/{len(pending_articles)} ---")
            try:
                generate_article(item)
            except Exception as e:
                logger.error(f"❌ 生成失敗：{item['keyword']} - {e}")
                continue
    else:
        logger.info("\n✅ 所有文章已存在，無需生成")
    
    # 6. 更新分類頁與 Sitemap
    logger.info("📂 更新分類頁與 Sitemap...")
    generate_category_pages()
    all_existing_html = scan_all_html_files()
    update_sitemap()
    
    # 7. 完成
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
    parser = argparse.ArgumentParser(description='AHPAL 文章生成引擎 v5.1')
    parser.add_argument('--force', choices=['deepseek', 'gemini'], help='強制使用指定的 API（已棄用，僅供向後相容）')
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