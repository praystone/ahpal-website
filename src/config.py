# ============================================================
# config.py - 設定管理模組 v5.0 (Gemini 優先)
# ============================================================
# 功能：管理所有設定（API Key、路徑、時段、分類）
# 更新：Gemini 設為默認優先 API
# ============================================================
MAX_TOKENS = 4096

import os
from datetime import datetime
from pathlib import Path

# ============================================================
# 0. 讀取 .env 檔案
# ============================================================

def load_env_file():
    env_vars = {}
    current_dir = Path(__file__).parent.parent
    env_file = current_dir / ".env"
    
    print(f"📄 讀取 .env 檔案：{env_file}")
    
    if env_file.exists():
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    env_vars[key] = value
                    os.environ[key] = value
        print(f"   ✅ 已載入 {len(env_vars)} 個環境變數")
        for key in env_vars:
            value = env_vars[key]
            if "KEY" in key or "key" in key:
                masked = value[:4] + "..." + value[-4:] if len(value) > 8 else "***"
                print(f"      {key}：{masked}")
    else:
        print(f"   ⚠️ .env 檔案不存在：{env_file}")
    
    return env_vars

_ENV_VARS = load_env_file()

# ============================================================
# 1. 取得 API Key
# ============================================================

def get_api_key(key_name):
    value = os.environ.get(key_name)
    if value:
        return value
    return _ENV_VARS.get(key_name)

# Google Gemini API (默認優先)
GEMINI_API_KEY = get_api_key("GEMINI_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
GEMINI_MODEL = "gemini-2.0-flash"

# DeepSeek API (備援)
DEEPSEEK_API_KEY = get_api_key("DEEPSEEK_API_KEY")
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"
DEEPSEEK_MODEL = "deepseek-v4-pro"

# ============================================================
# 2. API 優先策略 (Gemini 優先)
# ============================================================

def get_recommended_api(force_api=None):
    """根據時段與策略，建議使用的 API (Gemini 優先)"""
    if force_api:
        return force_api
    
    # 🔧 Gemini 優先策略：無論尖峰/離峰，預設使用 Gemini
    return "gemini"

def is_peak_hour():
    current_hour = datetime.now().hour
    return 9 <= current_hour < 18

# ============================================================
# 3. 輸出目錄
# ============================================================

OUTPUT_DIR = os.environ.get("AHPAL_OUTPUT_DIR")
if not OUTPUT_DIR:
    OUTPUT_DIR = "C:\\Users\\User\\ahpal-static"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# 4. 其他設定
# ============================================================

ADSENSE_CLIENT = "ca-pub-8637791667872348"
GA4_ID = "G-XXGG1VTGPB"

CURRENT_YEAR = datetime.now().year
CURRENT_MONTH = datetime.now().month
CURRENT_DAY = datetime.now().day
CURRENT_DATE_STR = f"{CURRENT_YEAR} 年 {CURRENT_MONTH} 月 {CURRENT_DAY} 日"

MIN_WORDS = 1200
MIN_HEADINGS = 3

CATEGORIES = {
    "tech": {"name": "💻 3C 科技教學", "desc": "手機、電腦、3C 產品教學與技巧"},
    "game": {"name": "🎮 遊戲攻略", "desc": "熱門遊戲攻略、密技與推薦"},
    "life": {"name": "🏠 生活小常識", "desc": "居家、收納、清潔、省錢生活智慧"},
    "review": {"name": "📊 軟體評測", "desc": "免費軟體評測、工具推薦與教學"},
    "philosophy": {"name": "🌟 人生哲理", "desc": "成功習慣、健康、職涯、人生成長"},
    "trend": {"name": "🤖 AI 趨勢", "desc": "AI 技術趨勢、數位轉型、未來職業"}
}

# ============================================================
# 5. 設定摘要
# ============================================================

def show_config_summary():
    print("\n" + "=" * 50)
    print("📋 設定摘要 (Gemini 優先模式)")
    print("=" * 50)
    print(f"📁 專案根目錄：{Path(__file__).parent.parent}")
    print(f"📁 輸出目錄：{OUTPUT_DIR}")
    print("")
    print("🔑 API Key 狀態：")
    if GEMINI_API_KEY:
        print(f"   ✅ Gemini API Key：{GEMINI_API_KEY[:4]}...{GEMINI_API_KEY[-4:]}")
    else:
        print("   ❌ Gemini API Key：未設定")
    if DEEPSEEK_API_KEY:
        print(f"   ✅ DeepSeek API Key：{DEEPSEEK_API_KEY[:4]}...{DEEPSEEK_API_KEY[-4:]}")
    else:
        print("   ❌ DeepSeek API Key：未設定")
    print("")
    print(f"⏰ 目前時段：{'🔴 尖峰' if is_peak_hour() else '🟢 離峰'}")
    print(f"📡 建議 API：{get_recommended_api()} (Gemini 優先)")
    print("=" * 50)

if __name__ == "__main__":
    show_config_summary()