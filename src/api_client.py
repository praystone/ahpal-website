# ============================================================
# api_client.py - API 呼叫模組
# ============================================================
# 功能：封裝 Gemini 與 DeepSeek API 呼叫
# ============================================================

import os
import requests
from datetime import datetime, timedelta
from src.config import (
    DEEPSEEK_API_KEY, DEEPSEEK_API_URL, DEEPSEEK_MODEL,
    GEMINI_API_KEY, GEMINI_API_URL, GEMINI_MODEL,
    PEAK_START, PEAK_END
)

# ============================================================
# 時段判斷函數
# ============================================================

def is_peak_hour():
    """判斷當前是否為尖峰時段"""
    now = datetime.now()
    hour = now.hour
    return PEAK_START <= hour < PEAK_END

def get_next_off_peak_time():
    """計算下一個離峰時段的開始時間"""
    now = datetime.now()
    hour = now.hour
    
    if PEAK_START <= hour < PEAK_END:
        next_start = now.replace(hour=PEAK_END, minute=0, second=0, microsecond=0)
        if next_start <= now:
            next_start += timedelta(days=1)
        return next_start
    else:
        return now

# ============================================================
# API 呼叫函數
# ============================================================

def call_gemini(prompt, system_prompt=None, max_tokens=16384):
    """呼叫 Google Gemini API（無格式限制）"""
    if not GEMINI_API_KEY:
        print("❌ Gemini API Key 未設定")
        return None

    full_prompt = ""
    if system_prompt:
        full_prompt += system_prompt + "\n\n"
    full_prompt += prompt

    headers = {"Content-Type": "application/json"}
    payload = {
        "contents": [{"parts": [{"text": full_prompt}]}],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": max_tokens,
            "topP": 0.9
        }
    }

    try:
        response = requests.post(
            f"{GEMINI_API_URL}?key={GEMINI_API_KEY}",
            headers=headers,
            json=payload,
            timeout=180
        )

        if response.status_code == 200:
            result = response.json()
            if "candidates" in result and len(result["candidates"]) > 0:
                return result["candidates"][0]["content"]["parts"][0]["text"]
            else:
                print(f"❌ Gemini 回應異常")
                return None
        else:
            print(f"❌ Gemini API 錯誤 ({response.status_code})")
            return None
    except Exception as e:
        print(f"❌ Gemini 請求失敗: {e}")
        return None

def call_deepseek(prompt, system_prompt=None, max_tokens=16384):
    """呼叫 DeepSeek API（無格式限制）"""
    if not DEEPSEEK_API_KEY:
        print("❌ DeepSeek API Key 未設定")
        return None

    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json"
    }

    payload = {
        "model": DEEPSEEK_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.7,
        "stream": False
    }

    try:
        response = requests.post(
            DEEPSEEK_API_URL,
            headers=headers,
            json=payload,
            timeout=180
        )

        if response.status_code == 200:
            result = response.json()
            return result["choices"][0]["message"]["content"]
        else:
            print(f"❌ DeepSeek API 錯誤 ({response.status_code})")
            return None
    except Exception as e:
        print(f"❌ DeepSeek 請求失敗: {e}")
        return None

def get_force_api():
    """從環境變數讀取強制 API 設定"""
    force = os.environ.get("FORCE_API", "").lower()
    if force in ["deepseek", "gemini"]:
        return force
    return None

def call_api(prompt, system_prompt=None, max_tokens=16384):
    """自動選擇 API 呼叫（支援環境變數強制切換）"""
    force_api = get_force_api()

    if force_api == "deepseek":
        print("   📡 強制使用 DeepSeek")
        return call_deepseek(prompt, system_prompt, max_tokens)

    if force_api == "gemini":
        print("   📡 強制使用 Gemini")
        return call_gemini(prompt, system_prompt, max_tokens)

    # 自動切換
    hour = datetime.now().hour
    if PEAK_START <= hour < PEAK_END:
        print("   📡 使用 Gemini（尖峰時段）")
        return call_gemini(prompt, system_prompt, max_tokens)
    else:
        print("   📡 使用 DeepSeek（離峰時段）")
        return call_deepseek(prompt, system_prompt, max_tokens)

def get_current_api_info():
    """獲取當前使用的 API 資訊（包含 peak 欄位）"""
    force = get_force_api()

    if force == "deepseek":
        return {
            "name": "DeepSeek（強制）",
            "model": DEEPSEEK_MODEL,
            "price": "¥0.28/百萬 tokens",
            "peak": False
        }
    if force == "gemini":
        return {
            "name": "Google Gemini（強制）",
            "model": GEMINI_MODEL,
            "price": "~$0.15/百萬 tokens",
            "peak": True
        }

    hour = datetime.now().hour
    if PEAK_START <= hour < PEAK_END:
        return {
            "name": "Google Gemini（自動）",
            "model": GEMINI_MODEL,
            "price": "~$0.15/百萬 tokens",
            "peak": True
        }
    else:
        return {
            "name": "DeepSeek（自動）",
            "model": DEEPSEEK_MODEL,
            "price": "¥0.28/百萬 tokens",
            "peak": False
        }
