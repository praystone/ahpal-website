# ============================================================
# config.py - 設定管理模組 v4.2
# ============================================================
# 功能：管理所有設定（API Key、路徑、時段、分類）
# 支援：直接讀取 .env 檔案（不依賴 PowerShell 環境變數）
# 更新：放寬 Gemini API Key 格式檢查（支援新格式）
# ============================================================

import os
from datetime import datetime
from pathlib import Path

# ============================================================
# 0. 讀取 .env 檔案（直接解析，不依賴 python-dotenv）
# ============================================================

def load_env_file():
    """直接從 .env 檔案讀取環境變數（不依賴外部套件）"""
    env_vars = {}
    
    # 尋找 .env 檔案（從當前目錄往上找）
    current_dir = Path(__file__).parent.parent  # src/ 的上一層 = 專案根目錄
    env_file = current_dir / ".env"
    
    print(f"📄 讀取 .env 檔案：{env_file}")
    
    if env_file.exists():
        with open(env_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                # 跳過空行和註解
                if not line or line.startswith('#'):
                    continue
                if '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip()
                    env_vars[key] = value
                    # 同時設定到 os.environ 供其他模組使用
                    os.environ[key] = value
        print(f"   ✅ 已載入 {len(env_vars)} 個環境變數")
        for key in env_vars:
            value = env_vars[key]
            if "KEY" in key or "key" in key:
                masked = value[:4] + "..." + value[-4:] if len(value) > 8 else "***"
                print(f"      {key}：{masked}")
    else:
        print(f"   ⚠️ .env 檔案不存在：{env_file}")
        print("   請執行：Copy-Item .env.template .env")
        print("   然後編輯 .env 填入 API Key")
    
    return env_vars

# 載入 .env
_ENV_VARS = load_env_file()

# ============================================================
# 1. 取得 API Key（優先從環境變數，再從 .env）
# ============================================================

def get_api_key(key_name):
    """取得 API Key，優先從環境變數，再從 .env"""
    # 先從環境變數取得（可能已由 PowerShell 設定）
    value = os.environ.get(key_name)
    if value:
        return value
    # 再從 .env 字典取得
    return _ENV_VARS.get(key_name)

# DeepSeek API
DEEPSEEK_API_KEY = get_api_key("DEEPSEEK_API_KEY")
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"
DEEPSEEK_MODEL = "deepseek-chat"

# Google Gemini API
GEMINI_API_KEY = get_api_key("GEMINI_API_KEY")
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
GEMINI_MODEL = "gemini-2.0-flash"

# ============================================================
# 2. 驗證 API Key（放寬格式檢查）
# ============================================================

def validate_api_keys():
    """驗證 API Key 是否已正確設定（支援新舊格式）"""
    errors = []
    warnings = []
    
    print("\n🔑 API Key 狀態：")
    
    # 檢查 Gemini API Key（放寬檢查，只要有值且非空即可）
    if not GEMINI_API_KEY:
        warnings.append("GEMINI_API_KEY 未設定（尖峰時段可能需要）")
        print("   ⚠️ Gemini API Key：未設定")
    else:
        masked = GEMINI_API_KEY[:4] + "..." + GEMINI_API_KEY[-4:] if len(GEMINI_API_KEY) > 8 else "***"
        print(f"   ✅ Gemini API Key：{masked}")
    
    # 檢查 DeepSeek API Key
    if not DEEPSEEK_API_KEY:
        errors.append("DEEPSEEK_API_KEY 未設定（離峰時段需要）")
        print("   ❌ DeepSeek API Key：未設定")
    else:
        masked = DEEPSEEK_API_KEY[:4] + "..." + DEEPSEEK_API_KEY[-4:] if len(DEEPSEEK_API_KEY) > 8 else "***"
        print(f"   ✅ DeepSeek API Key：{masked}")
    
    if errors:
        print("\n❌ API Key 檢查失敗：")
        for err in errors:
            print(f"   - {err}")
        print("\n💡 請在 .env 檔案中設定 API Key：")
        print(f"   C:\\Users\\User\\ahpal-static\\.env")
        print("   格式範例：")
        print("   GEMINI_API_KEY=你的Gemini金鑰")
        print("   DEEPSEEK_API_KEY=sk-你的DeepSeek金鑰")
        return False
    
    if warnings:
        print("\n⚠️ API Key 檢查有警告：")
        for warn in warnings:
            print(f"   - {warn}")
    
    print("   ✅ API Key 檢查通過")
    return True

# ============================================================
# 3. 輸出目錄
# ============================================================

OUTPUT_DIR = os.environ.get("AHPAL_OUTPUT_DIR")
if not OUTPUT_DIR:
    OUTPUT_DIR = "C:\\Users\\User\\ahpal-static"

os.makedirs(OUTPUT_DIR, exist_ok=True)

# ============================================================
# 4. 時段設定（北京時間）
# ============================================================

PEAK_START = 9    # 尖峰開始（早上 9 點）
PEAK_END = 18     # 尖峰結束（下午 6 點）

def is_peak_hour():
    """檢查目前是否為尖峰時段"""
    current_hour = datetime.now().hour
    return PEAK_START <= current_hour < PEAK_END

def get_recommended_api(force_api=None):
    """根據時段或強制參數，建議使用的 API"""
    if force_api:
        return force_api
    return "gemini" if is_peak_hour() else "deepseek"

# ============================================================
# 5. AdSense 和 GA4
# ============================================================

ADSENSE_CLIENT = "ca-pub-8637791667872348"
GA4_ID = "G-XXGG1VTGPB"

# ============================================================
# 6. 日期資訊
# ============================================================

CURRENT_YEAR = datetime.now().year
CURRENT_MONTH = datetime.now().month
CURRENT_DAY = datetime.now().day
CURRENT_DATE_STR = f"{CURRENT_YEAR} 年 {CURRENT_MONTH} 月 {CURRENT_DAY} 日"

# ============================================================
# 7. 品質門檻
# ============================================================

MIN_WORDS = 1200
MIN_HEADINGS = 3

# ============================================================
# 8. 分類對照表
# ============================================================

CATEGORIES = {
    "tech": {"name": "💻 3C 科技教學", "desc": "手機、電腦、3C 產品教學與技巧"},
    "game": {"name": "🎮 遊戲攻略", "desc": "熱門遊戲攻略、密技與推薦"},
    "life": {"name": "🏠 生活小常識", "desc": "居家、收納、清潔、省錢生活智慧"},
    "review": {"name": "📊 軟體評測", "desc": "免費軟體評測、工具推薦與教學"},
    "philosophy": {"name": "🌟 人生哲理", "desc": "成功習慣、健康、職涯、人生成長"},
    "trend": {"name": "🤖 AI 趨勢", "desc": "AI 技術趨勢、數位轉型、未來職業"}
}

# ============================================================
# 9. 顯示設定摘要（用於測試）
# ============================================================

def show_config_summary():
    """顯示設定摘要"""
    print("\n" + "=" * 50)
    print("📋 設定摘要")
    print("=" * 50)
    print(f"📁 專案根目錄：{Path(__file__).parent.parent}")
    print(f"📁 輸出目錄：{OUTPUT_DIR}")
    print("")
    validate_api_keys()
    print("")
    print(f"⏰ 目前時段：{'🔴 尖峰' if is_peak_hour() else '🟢 離峰'}")
    print(f"📡 建議 API：{get_recommended_api()}")
    print("=" * 50)

# 如果是直接執行此腳本，顯示設定摘要
if __name__ == "__main__":
    show_config_summary()