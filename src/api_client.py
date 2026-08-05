# ============================================================
# api_client.py - AHPAL 唯一 API 調度中心 v3.2
# ============================================================
# 統一管理所有模型調用：
#   - 生文：DeepSeek Flash (deepseek-v4-flash)
#   - 生圖：Gemini 3.1 Flash Image (gemini-3.1-flash-image)
# 包含：自動重試、錯誤處理、配額管理
# 向後相容：完整支援 main.py 所需的 dict 結構
# ============================================================

import os
import re
import time
import json
import requests
from pathlib import Path
from datetime import datetime, timedelta
from dotenv import load_dotenv
from google import genai
from google.genai import types

# --- 載入 .env ---
load_dotenv()

# --- 設定日誌 ---
from src.logger import get_logger
logger = get_logger("api_client")

# ============================================================
# 🔧 唯一調度中心
# ============================================================
class APIClient:
    """AHPAL 唯一的 AI 呼叫入口 — 所有模型調度都在這裡"""

    def __init__(self):
        # ---- DeepSeek ----
        self.deepseek_api_key = os.environ.get("DEEPSEEK_API_KEY")
        self.deepseek_model = "deepseek-v4-flash"          # ✅ 固定 Flash
        self.deepseek_base_url = "https://api.deepseek.com"

        # ---- Gemini ----
        self.gemini_api_key = os.environ.get("GEMINI_API_KEY")
        self.gemini_model = "gemini-3.1-flash-image"       # ✅ 固定生圖專用

        # ---- 輸出目錄 ----
        self.image_dir = Path("images")
        self.image_dir.mkdir(exist_ok=True)

        # ---- 初始化 Gemini ----
        self.gemini_client = None
        if self.gemini_api_key:
            try:
                self.gemini_client = genai.Client(api_key=self.gemini_api_key)
                logger.info("✅ Gemini 客戶端初始化成功")
            except Exception as e:
                logger.error(f"❌ Gemini 初始化失敗：{e}")

        logger.info(f"🔧 API 客戶端初始化完成 | DeepSeek: {self.deepseek_model} | Gemini: {self.gemini_model}")

    # ============================================================
    # 📝 生文：DeepSeek Flash
    # ============================================================
    def generate_article(self, keyword, category, max_tokens=8192):
        """
        唯一文章生成方法 — 固定使用 deepseek-v4-flash
        """
        if not self.deepseek_api_key:
            return "<p>❌ 未設定 DEEPSEEK_API_KEY</p>"

        headers = {
            "Authorization": f"Bearer {self.deepseek_api_key}",
            "Content-Type": "application/json"
        }

        prompt = self._build_article_prompt(keyword, category)
        payload = {
            "model": self.deepseek_model,
            "messages": [
                {"role": "system", "content": "你是專業的繁體中文內容創作者，擅長 SEO 友善文章。"},
                {"role": "user", "content": prompt}
            ],
            "max_tokens": max_tokens,
            "temperature": 0.7
        }

        try:
            resp = requests.post(
                f"{self.deepseek_base_url}/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=180
            )
            resp.raise_for_status()
            result = resp.json()["choices"][0]["message"]["content"]
            logger.info(f"✅ DeepSeek 生成成功：{keyword} (字數: {len(result)})")
            return result
        except Exception as e:
            logger.error(f"❌ DeepSeek 生成失敗：{e}")
            return f"<p>文章生成失敗：{e}</p>"

    def _build_article_prompt(self, keyword, category):
        return f"""
        請為「雅寶社區 · 頂客論壇」撰寫一篇高品質繁體中文文章。
        主題：{keyword}
        分類：{category}
        要求：至少 4500 字，含 H1、H2（≥3個）、H3（≥2個），純 HTML 內容。
        """

    # ============================================================
    # 🖼️ 生圖：Gemini 3.1 Flash Image
    # ============================================================
    def generate_image(self, prompt, filename, seo_keywords=None,
                       aspect_ratio="16:9", image_size="1K", max_retries=3):
        """
        唯一圖片生成方法 — 固定使用 gemini-3.1-flash-image
        """
        if not self.gemini_client:
            return {"img_tag": "", "error": "Gemini 客戶端未初始化"}

        full_prompt = self._build_image_prompt(prompt, seo_keywords)

        for attempt in range(max_retries):
            try:
                response = self.gemini_client.models.generate_content(
                    model=self.gemini_model,
                    contents=full_prompt,
                    config=types.GenerateContentConfig(
                        temperature=0.7,
                        response_modalities=["IMAGE"],
                        image_config=types.ImageConfig(
                            aspect_ratio=aspect_ratio,
                            image_size=image_size
                        )
                    )
                )

                for part in response.candidates[0].content.parts:
                    if part.inline_data:
                        ext = part.inline_data.mime_type.split("/")[-1]
                        filepath = self.image_dir / f"{filename}.{ext}"
                        with open(filepath, "wb") as f:
                            f.write(part.inline_data.data)

                        alt = self._generate_alt(prompt, seo_keywords)
                        return {
                            "img_tag": f'<img src="/images/{filename}.{ext}" alt="{alt}" loading="lazy" width="800">',
                            "filepath": str(filepath),
                            "alt": alt,
                            "size": len(part.inline_data.data)
                        }
                return {"img_tag": "", "error": "未收到圖片資料"}

            except Exception as e:
                error_str = str(e)
                if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                    wait_time = (attempt + 1) * 20
                    logger.warning(f"   ⏳ 配額已滿，等待 {wait_time} 秒後重試 ({attempt+1}/{max_retries})...")
                    time.sleep(wait_time)
                else:
                    logger.error(f"❌ Gemini 生成圖片失敗：{e}")
                    return {"img_tag": "", "error": error_str}

        return {"img_tag": "", "error": f"重試 {max_retries} 次後仍然失敗"}

    def _build_image_prompt(self, prompt, keywords):
        kw = "，".join(keywords[:3]) if keywords else ""
        return f"生成一張 16:9 配圖，主題：{prompt}。SEO 關鍵詞：{kw}。風格清晰專業。"

    def _generate_alt(self, prompt, keywords):
        alt = prompt[:30]
        if keywords:
            alt += f" — {', '.join(keywords[:2])}"
        return alt[:150]

    # ============================================================
    # 🚀 整合：文章 + 配圖 (一鍵完成)
    # ============================================================
    def generate_article_with_images(self, keyword, category, image_count=1):
        """一鍵完成：生文（Flash）+ 生圖（Gemini）"""
        html = self.generate_article(keyword, category)
        concepts = self._extract_concepts(html, image_count)

        images = []
        for i, c in enumerate(concepts):
            result = self.generate_image(
                prompt=f"{keyword} — {c}",
                filename=f"{keyword.replace(' ', '_')}_{i}",
                seo_keywords=[keyword, c]
            )
            if result.get("img_tag"):
                images.append(result)

        final_html = self._embed_images(html, images)
        return {"title": keyword, "content": final_html, "images": images}

    def _extract_concepts(self, html, count=3):
        h2s = re.findall(r'<h2[^>]*>(.*?)</h2>', html)
        return [h2.strip()[:20] for h2 in h2s[:count]] or [f"主題配圖{i+1}" for i in range(count)]

    def _embed_images(self, html, images):
        if not images:
            return html
        result = html
        for i, img in enumerate(images):
            tag = img["img_tag"]
            div = f'<div class="article-image" style="margin:20px 0;">{tag}</div>'
            if i == 0 and '</h1>' in result:
                result = result.replace('</h1>', f'</h1>{div}', 1)
            else:
                pattern = r'(<h2[^>]*>.*?</h2>)'
                matches = list(re.finditer(pattern, result, re.IGNORECASE))
                if len(matches) >= i:
                    pos = matches[i-1].end() if i-1 < len(matches) else len(result)
                    result = result[:pos] + div + result[pos:]
        return result

    # ============================================================
    # 🔍 向後相容與診斷
    # ============================================================
    def get_current_api_info(self):
        """回傳目前使用的模型資訊（完整結構）"""
        return {
            "deepseek_model": self.deepseek_model,
            "gemini_model": self.gemini_model,
            "gemini_available": self.gemini_client is not None,
            "name": "DeepSeek Flash",
            "model": self.deepseek_model,
            "peak": False,
            "price": "低",
            "api_key": self.deepseek_api_key,
            "provider": "DeepSeek"
        }


# ============================================================
# 🔄 向後相容函數（讓 main.py 能正常運作）
# ============================================================

def is_peak_hour():
    """已棄用 - 統一由 APIClient 管理，保留供 main.py 向後相容"""
    current_hour = datetime.now().hour
    return 9 <= current_hour < 18


def get_next_off_peak_time():
    """已棄用 - 統一由 APIClient 管理，保留供 main.py 向後相容"""
    now = datetime.now()
    if 9 <= now.hour < 18:
        return now.replace(hour=18, minute=0, second=0, microsecond=0)
    else:
        if now.hour >= 18:
            return (now + timedelta(days=1)).replace(hour=9, minute=0, second=0, microsecond=0)
        else:
            return now.replace(hour=9, minute=0, second=0, microsecond=0)


def get_current_api_info(force_api=None):
    """
    向後相容函數 - 回傳完整字典結構供 main.py 使用
    """
    client = APIClient()
    # 🔧 直接回傳完整結構，確保 main.py 能取得所有需要的欄位
    return {
        "name": "DeepSeek Flash",
        "model": client.deepseek_model,
        "provider": "DeepSeek",
        "peak": is_peak_hour(),
        "price": "低",
        "api_key": client.deepseek_api_key,
        "deepseek_model": client.deepseek_model,
        "gemini_model": client.gemini_model,
        "gemini_available": client.gemini_client is not None
    }


def call_api(prompt, force_api=None, max_retries=3, max_tokens=16384, system_prompt=None):
    """
    已棄用 - 統一由 APIClient 管理，保留供 article_generator 向後相容
    """
    client = APIClient()
    # 從 prompt 中提取 keyword（簡化版）
    keyword = "系統呼叫"
    category = "一般"
    if "關鍵字：" in prompt:
        try:
            keyword = prompt.split("關鍵字：")[1].split("\n")[0].strip()
        except:
            pass
    if "分類：" in prompt:
        try:
            category = prompt.split("分類：")[1].split("\n")[0].strip()
        except:
            pass
    return client.generate_article(keyword, category, max_tokens)


# ============================================================
# 保留 ModelRouter 別名以向後相容
# ============================================================
ModelRouter = APIClient


# ============================================================
# 🧪 測試
# ============================================================
if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🦞 AHPAL API 客戶端測試 v3.2")
    print("="*50)
    client = APIClient()
    info = client.get_current_api_info()
    print(f"   DeepSeek: {info['deepseek_model']}")
    print(f"   Gemini: {info['gemini_model']}")
    print(f"   Gemini 狀態: {'✅ 可用' if info['gemini_available'] else '❌ 未初始化'}")
    print("✅ 測試完成")