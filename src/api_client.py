# ============================================================
# api_client.py - API 客戶端模組 v4.3
# ============================================================

import os
import json
import time
from datetime import datetime
from src.config import (
    DEEPSEEK_API_KEY, DEEPSEEK_API_URL, DEEPSEEK_MODEL,
    GEMINI_API_KEY, GEMINI_API_URL, GEMINI_MODEL,
    is_peak_hour, get_recommended_api
)
from src.logger import get_logger

logger = get_logger("api_client")

# ============================================================
# API 資訊
# ============================================================

def get_current_api_info(force_api=None):
    """
    取得當前使用的 API 資訊
    參數：
        force_api: 強制使用的 API（'gemini' 或 'deepseek'）
    回傳：
        dict: 包含 name, model, peak, price 等資訊
    """
    # 決定使用哪個 API
    if force_api:
        api_name = force_api.lower()
    else:
        api_name = get_recommended_api()
    
    if api_name == "gemini":
        return {
            "name": "Gemini",
            "model": GEMINI_MODEL,
            "peak": is_peak_hour(),
            "price": "免費" if not GEMINI_API_KEY else "標準",
            "api_key": GEMINI_API_KEY
        }
    else:
        return {
            "name": "DeepSeek",
            "model": DEEPSEEK_MODEL,
            "peak": is_peak_hour(),
            "price": "低",
            "api_key": DEEPSEEK_API_KEY
        }

def call_api(prompt, force_api=None, max_retries=3):
    """
    呼叫 AI API（自動選擇或強制指定）
    參數：
        prompt: 提示詞
        force_api: 強制使用的 API（'gemini' 或 'deepseek'）
        max_retries: 最大重試次數
    回傳：
        str: API 回應內容
    """
    api_info = get_current_api_info(force_api=force_api)
    api_name = api_info["name"].lower()
    
    logger.info(f"📡 使用 API：{api_info['name']} ({api_info['model']})")
    
    for attempt in range(max_retries):
        try:
            if api_name == "gemini":
                result = call_gemini_api(prompt, api_info["api_key"])
            else:
                result = call_deepseek_api(prompt, api_info["api_key"])
            
            if result:
                return result
            
            logger.warning(f"⚠️ API 呼叫失敗，重試 {attempt + 1}/{max_retries}")
            time.sleep(2 ** attempt)  # 指數退避
            
        except Exception as e:
            logger.error(f"❌ API 呼叫異常：{e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise
    
    raise Exception(f"API 呼叫失敗，已重試 {max_retries} 次")

def call_gemini_api(prompt, api_key):
    """呼叫 Gemini API"""
    import requests
    
    url = f"{GEMINI_API_URL}?key={api_key}"
    
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ],
        "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 4096,
            "topP": 0.95
        }
    }
    
    try:
        response = requests.post(url, json=payload, timeout=60)
        response.raise_for_status()
        
        data = response.json()
        
        # 解析 Gemini 回應
        if "candidates" in data and len(data["candidates"]) > 0:
            candidate = data["candidates"][0]
            if "content" in candidate and "parts" in candidate["content"]:
                parts = candidate["content"]["parts"]
                if len(parts) > 0 and "text" in parts[0]:
                    return parts[0]["text"]
        
        logger.error(f"❌ 無法解析 Gemini 回應：{json.dumps(data, ensure_ascii=False)[:500]}")
        return None
        
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ Gemini API 請求失敗：{e}")
        return None

def call_deepseek_api(prompt, api_key):
    """呼叫 DeepSeek API"""
    import requests
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "model": DEEPSEEK_MODEL,
        "messages": [
            {"role": "user", "content": prompt}
        ],
        "max_tokens": 4096,
        "temperature": 0.7
    }
    
    try:
        response = requests.post(DEEPSEEK_API_URL, json=payload, headers=headers, timeout=60)
        response.raise_for_status()
        
        data = response.json()
        
        if "choices" in data and len(data["choices"]) > 0:
            choice = data["choices"][0]
            if "message" in choice and "content" in choice["message"]:
                return choice["message"]["content"]
        
        logger.error(f"❌ 無法解析 DeepSeek 回應：{json.dumps(data, ensure_ascii=False)[:500]}")
        return None
        
    except requests.exceptions.RequestException as e:
        logger.error(f"❌ DeepSeek API 請求失敗：{e}")
        return None

# ============================================================
# 時段相關函數（從 config 匯出）
# ============================================================

def is_peak_hour():
    """檢查目前是否為尖峰時段"""
    from src.config import is_peak_hour as config_is_peak_hour
    return config_is_peak_hour()

def get_next_off_peak_time():
    """取得下次離峰時段開始時間"""
    from datetime import datetime, timedelta
    now = datetime.now()
    
    # 尖峰時段：9:00 - 18:00
    if 9 <= now.hour < 18:
        # 今天 18:00
        return now.replace(hour=18, minute=0, second=0, microsecond=0)
    else:
        # 明天 18:00（如果現在是 18:00 之後）
        if now.hour >= 18:
            return (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
        else:
            # 現在是 0:00 - 9:00，今天 9:00 開始是尖峰
            # 但我們要找的是離峰開始時間，所以是明天 18:00
            return (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)