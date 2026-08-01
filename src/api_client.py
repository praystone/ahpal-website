# ============================================================
# api_client.py - API 客戶端模組 v5.1 (Gemini 優先 + 強制修正)
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
    if force_api:
        api_name = force_api.lower()
    else:
        api_name = get_recommended_api()
    
    if api_name == "gemini":
        return {
            "name": "Gemini",
            "model": GEMINI_MODEL,
            "peak": is_peak_hour(),
            "price": "標準",
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

def call_api(prompt, force_api=None, max_retries=3, max_tokens=16384, system_prompt=None):
    """
    呼叫 AI API（強制傳遞 force_api 至底層）
    """
    # 🔧 關鍵修正：確保 force_api 正確傳遞
    api_info = get_current_api_info(force_api=force_api)
    api_name = api_info["name"].lower()
    
    logger.info(f"📡 使用 API：{api_info['name']} ({api_info['model']})")
    
    for attempt in range(max_retries):
        try:
            if api_name == "gemini":
                result = call_gemini_api(prompt, api_info["api_key"], max_tokens=max_tokens)
            else:
                result = call_deepseek_api(prompt, api_info["api_key"], max_tokens=max_tokens, system_prompt=system_prompt)
            
            if result:
                return result
            
            logger.warning(f"⚠️ API 呼叫失敗，重試 {attempt + 1}/{max_retries}")
            time.sleep(2 ** attempt)
            
        except Exception as e:
            logger.error(f"❌ API 呼叫異常：{e}")
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)
            else:
                raise
    
    raise Exception(f"API 呼叫失敗，已重試 {max_retries} 次")

def call_gemini_api(prompt, api_key, max_tokens=4096):
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
            "maxOutputTokens": max_tokens,
            "topP": 0.95
        }
    }
    
    try:
        response = requests.post(url, json=payload, timeout=120)
        response.raise_for_status()
        
        data = response.json()
        
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

def call_deepseek_api(prompt, api_key, max_tokens=4096, system_prompt=None):
    import requests
    
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json"
    }
    
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})
    
    payload = {
        "model": DEEPSEEK_MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": 0.7
    }
    
    try:
        response = requests.post(DEEPSEEK_API_URL, json=payload, headers=headers, timeout=120)
        
        if response.status_code != 200:
            error_data = response.json() if response.text else {}
            logger.error(f"❌ DeepSeek API 請求失敗 ({response.status_code}): {json.dumps(error_data, ensure_ascii=False)}")
            return None
        
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
# 時段相關函數
# ============================================================

def is_peak_hour():
    from src.config import is_peak_hour as config_is_peak_hour
    return config_is_peak_hour()

def get_next_off_peak_time():
    from datetime import datetime, timedelta
    now = datetime.now()
    if 9 <= now.hour < 18:
        return now.replace(hour=18, minute=0, second=0, microsecond=0)
    else:
        if now.hour >= 18:
            return (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
        else:
            return now.replace(hour=9, minute=0, second=0, microsecond=0)