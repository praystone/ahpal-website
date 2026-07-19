# ============================================================
# config.py - 設定管理模組
# ============================================================
# 功能：管理所有設定（API Key、路徑、時段、分類）
# ============================================================

import os
from datetime import datetime

# ============================================================
# 1. API 金鑰設定（從環境變數讀取）
# ============================================================

# DeepSeek API
DEEPSEEK_API_KEY = os.environ.get("DEEPSEEK_API_KEY")
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"
DEEPSEEK_MODEL = "deepseek-chat"

# Google Gemini API
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
GEMINI_MODEL = "gemini-2.0-flash"

# ============================================================
# 2. 輸出目錄
# ============================================================

OUTPUT_DIR = os.environ.get("AHPAL_OUTPUT_DIR")
if not OUTPUT_DIR:
    OUTPUT_DIR = "C:\\Users\\User\\ahpal-static"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# 3. 時段設定（北京時間）
# ============================================================

PEAK_START = 9    # 尖峰開始（早上 9 點）
PEAK_END = 18     # 尖峰結束（下午 6 點）

# ============================================================
# 4. AdSense 和 GA4
# ============================================================

ADSENSE_CLIENT = "ca-pub-8637791667872348"
GA4_ID = "G-XXGG1VTGPB"

# ============================================================
# 5. 日期資訊
# ============================================================

CURRENT_YEAR = datetime.now().year
CURRENT_MONTH = datetime.now().month
CURRENT_DAY = datetime.now().day
CURRENT_DATE_STR = f"{CURRENT_YEAR} 年 {CURRENT_MONTH} 月 {CURRENT_DAY} 日"

# ============================================================
# 6. 品質門檻
# ============================================================

MIN_WORDS = 1200
MIN_HEADINGS = 3

# ============================================================
# 7. 分類對照表
# ============================================================

CATEGORIES = {
    "tech": {"name": "💻 3C 科技教學", "desc": "手機、電腦、3C 產品教學與技巧"},
    "game": {"name": "🎮 遊戲攻略", "desc": "熱門遊戲攻略、密技與推薦"},
    "life": {"name": "🏠 生活小常識", "desc": "居家、收納、清潔、省錢生活智慧"},
    "review": {"name": "📊 軟體評測", "desc": "免費軟體評測、工具推薦與教學"},
    "philosophy": {"name": "🌟 人生哲理", "desc": "成功習慣、健康、職涯、人生成長"},
    "trend": {"name": "🤖 AI 趨勢", "desc": "AI 技術趨勢、數位轉型、未來職業"}
}
