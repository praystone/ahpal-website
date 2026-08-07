# ============================================================
# api_client.py - AHPAL 唯一 API 調度中心 v4.1
# ============================================================
# 統一管理所有模型調用：
#   - 生文：DeepSeek Flash (deepseek-v4-flash) + Responses API
#   - 生圖：Gemini 3.1 Flash Image (gemini-3.1-flash-image)
# 包含：自動重試、錯誤處理、配額管理、Responses API 雙軌支援
# 向後相容：完整支援 main.py 所需的 dict 結構
#
# v4.1 修復與優化：
#   - 🔧 新增 build_article_prompt 公開方法（修復 AttributeError）
#   - 🔧 強化 _build_article_prompt 支援文章類型參數
#   - 🔧 修復降級時 max_tokens 傳遞問題
#   - 🆕 加入 API 呼叫耗時記錄
#   - 🆕 加入圖片生成緩存機制（避免重複生成）
# ============================================================

import os
import re
import time
import json
import hashlib
import requests
from pathlib import Path
from datetime import datetime, timedelta
from dotenv import load_dotenv
from google import genai
from google.genai import types
from openai import OpenAI

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

        # ---- OpenAI 客戶端（Responses API） ----
        self.openai_client = None
        if self.deepseek_api_key:
            try:
                self.openai_client = OpenAI(
                    api_key=self.deepseek_api_key,
                    base_url=self.deepseek_base_url
                )
                logger.info("✅ OpenAI 客戶端初始化成功（Responses API 就緒）")
            except Exception as e:
                logger.error(f"❌ OpenAI 客戶端初始化失敗：{e}")

        # ---- Gemini ----
        self.gemini_api_key = os.environ.get("GEMINI_API_KEY")
        self.gemini_model = "gemini-3.1-flash-image"       # ✅ 固定生圖專用

        # ---- 輸出目錄 ----
        self.image_dir = Path("images")
        self.image_dir.mkdir(exist_ok=True)

        # ---- 圖片緩存目錄 ----
        self.cache_dir = Path("images/.cache")
        self.cache_dir.mkdir(exist_ok=True)

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
    # 📝 公開方法：建構文章提示詞
    # ============================================================

    def build_article_prompt(self, keyword, category, content_type="article"):
        """
        公開方法：建構文章提示詞（供外部呼叫）

        參數：
            keyword: 文章關鍵字
            category: 文章分類
            content_type: 內容類型（article / song / review）

        回傳：
            str: 完整提示詞
        """
        return self._build_article_prompt(keyword, category, content_type)

    def _build_article_prompt(self, keyword, category, content_type="article"):
        """
        內部方法：建構文章提示詞

        參數：
            keyword: 文章關鍵字
            category: 文章分類
            content_type: 內容類型（article / song / review）

        回傳：
            str: 完整提示詞
        """
        # 根據內容類型調整提示詞結構
        type_instructions = {
            "article": "撰寫一篇高品質繁體中文文章，包含完整的 H1、H2（≥3個）、H3（≥2個）標題結構。",
            "song": "撰寫一篇音樂深度解析文章，包含歌曲背景、歌詞意境、聆聽感受與文化脈絡。",
            "review": "撰寫一篇專業評測文章，包含產品介紹、規格對比、優缺點分析與購買建議。"
        }

        instruction = type_instructions.get(content_type, type_instructions["article"])

        return f"""
        請為「雅寶社區 · 頂客論壇」{instruction}
        主題：{keyword}
        分類：{category}
        要求：至少 4500 字，純 HTML 內容，段落分明，結構完整。
        """

    # ============================================================
    # 📝 生文：DeepSeek Flash (Chat API — 原有方法)
    # ============================================================

    def generate_article(self, keyword, category, max_tokens=8192, content_type="article"):
        """
        文章生成方法 — 使用 deepseek-v4-flash (Chat API)
        保留此方法確保向後相容

        參數：
            keyword: 文章關鍵字
            category: 文章分類
            max_tokens: 最大輸出 token
            content_type: 內容類型（article / song / review）
        """
        if not self.deepseek_api_key:
            logger.error("❌ DEEPSEEK_API_KEY 未設定")
            return "<p>❌ 未設定 DEEPSEEK_API_KEY</p>"

        headers = {
            "Authorization": f"Bearer {self.deepseek_api_key}",
            "Content-Type": "application/json"
        }

        prompt = self._build_article_prompt(keyword, category, content_type)
        payload = {
            "model": self.deepseek_model,
            "messages": [
                {"role": "system", "content": "你是專業的繁體中文內容創作者，擅長 SEO 友善文章。"},
                {"role": "user", "content": prompt}
            ],
            "max_tokens": max_tokens,
            "temperature": 0.7
        }

        start_time = time.time()
        try:
            resp = requests.post(
                f"{self.deepseek_base_url}/v1/chat/completions",
                headers=headers,
                json=payload,
                timeout=180
            )
            resp.raise_for_status()
            result = resp.json()["choices"][0]["message"]["content"]
            elapsed = time.time() - start_time
            logger.info(f"✅ DeepSeek (Chat API) 生成成功：{keyword} (字數: {len(result)}, 耗時: {elapsed:.2f}s)")
            return result
        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(f"❌ DeepSeek (Chat API) 生成失敗：{e} (耗時: {elapsed:.2f}s)")
            return f"<p>文章生成失敗：{e}</p>"

    # ============================================================
    # 🆕 生文：DeepSeek Responses API (雙軌並行)
    # ============================================================

    def generate_with_responses_api(
        self,
        prompt: str,
        instructions: str = "你是專業的繁體中文內容創作者，擅長 SEO 友善文章。",
        enable_reasoning: bool = False,
        enable_search: bool = False,
        max_tokens: int = 16384,
        temperature: float = 0.7,
        stream: bool = False,
        keyword: str = None,
        category: str = None,
        content_type: str = "article"
    ):
        """
        使用 DeepSeek Responses API 生成內容（支援 Reasoning + Web Search）

        參數：
            prompt: 用戶提示詞
            instructions: 系統指令
            enable_reasoning: 是否啟用思維鏈（提升品質檢查精度）
            enable_search: 是否啟用網頁搜尋（事實查核）
            max_tokens: 最大輸出 token
            temperature: 溫度參數
            stream: 是否串流輸出
            keyword: 用於日誌記錄的文章關鍵字
            category: 用於日誌記錄的分類
            content_type: 內容類型（article / song / review）

        回傳：
            str: 生成的內容（或 generator 如果 stream=True）
        """
        if not self.deepseek_api_key:
            logger.error("❌ DEEPSEEK_API_KEY 未設定")
            return "<p>❌ 未設定 DEEPSEEK_API_KEY</p>"

        if not self.openai_client:
            logger.error("❌ OpenAI 客戶端未初始化")
            return "<p>❌ OpenAI 客戶端未初始化</p>"

        # 如果沒有傳入 keyword，從 prompt 嘗試提取
        if not keyword:
            keyword_match = re.search(r'主題[：:]\s*(.+?)(?:\n|$)', prompt)
            if keyword_match:
                keyword = keyword_match.group(1).strip()[:30]
            else:
                keyword = "Responses API 生成"

        # 建構 tools（如有啟用）
        tools = []
        if enable_search:
            tools.append({"type": "web_search"})

        # 建構 reasoning（如有啟用）
        reasoning_config = {"effort": "medium"} if enable_reasoning else None

        start_time = time.time()
        try:
            logger.info(f"🆕 使用 Responses API 生成：{keyword} (Reasoning: {enable_reasoning}, Search: {enable_search})")

            response = self.openai_client.responses.create(
                model="deepseek-v4-flash",
                instructions=instructions,
                input=prompt,
                max_output_tokens=max_tokens,
                temperature=temperature,
                reasoning=reasoning_config,
                tools=tools if tools else None,
                stream=stream
            )

            if stream:
                # 串流模式：回傳 generator
                return self._process_stream(response, keyword)
            else:
                # 一般模式：回傳完整文字
                output_text = response.output_text
                elapsed = time.time() - start_time
                logger.info(f"✅ Responses API 生成成功：{keyword} (字數: {len(output_text)}, 耗時: {elapsed:.2f}s)")
                return output_text

        except Exception as e:
            elapsed = time.time() - start_time
            logger.error(f"❌ Responses API 生成失敗：{e} (耗時: {elapsed:.2f}s)")

            # 降級方案：自動切換到 Chat API
            logger.warning(f"⚠️ 降級到 Chat API 繼續生成：{keyword}")
            if keyword and category:
                return self.generate_article(keyword, category, max_tokens, content_type)
            return f"<p>文章生成失敗：{e}</p>"

    def _process_stream(self, stream_response, keyword="串流"):
        """處理 Responses API 的串流事件"""
        full_text = ""
        reasoning_text = ""
        event_count = 0
        start_time = time.time()

        for event in stream_response:
            event_count += 1

            if event.type == "response.output_text.delta":
                full_text += event.delta
                yield event.delta

            elif event.type == "response.reasoning_text.delta":
                reasoning_text += event.delta
                if len(reasoning_text) < 200:
                    logger.debug(f"🧠 思維鏈：{event.delta[:50]}...")

            elif event.type == "response.reasoning_text.done":
                logger.debug(f"🧠 思維鏈完成，總長度：{len(reasoning_text)} 字")

            elif event.type == "response.output_text.done":
                elapsed = time.time() - start_time
                logger.info(f"✅ Responses API 串流完成：{keyword}，輸出 {len(full_text)} 字，耗時 {elapsed:.2f}s")

            elif event.type == "response.completed":
                logger.info(f"✅ Responses API 完成事件：{keyword}，共 {event_count} 個事件")

            elif event.type == "response.failed":
                error_msg = getattr(event, 'error', '未知錯誤')
                logger.error(f"❌ Responses API 失敗：{error_msg}")

            elif event.type == "response.incomplete":
                logger.warning(f"⚠️ Responses API 回應不完整：{keyword}")

        if not full_text:
            full_text = ""

        return full_text

    # ============================================================
    # 🆕 文章生成統一入口（可選擇 API 版本）
    # ============================================================

    def generate_article_advanced(
        self,
        keyword: str,
        category: str,
        use_responses_api: bool = False,
        enable_reasoning: bool = False,
        enable_search: bool = False,
        max_tokens: int = 16384,
        content_type: str = "article"
    ):
        """
        進階文章生成：可選擇使用 Chat API 或 Responses API

        參數：
            keyword: 文章關鍵字
            category: 文章分類
            use_responses_api: 是否使用 Responses API（預設 False）
            enable_reasoning: 是否啟用思維鏈（僅 Responses API）
            enable_search: 是否啟用網頁搜尋（僅 Responses API）
            max_tokens: 最大輸出 token
            content_type: 內容類型（article / song / review）
        """
        if use_responses_api:
            prompt = self._build_article_prompt(keyword, category, content_type)
            return self.generate_with_responses_api(
                prompt=prompt,
                instructions="你是專業的繁體中文內容創作者，擅長 SEO 友善文章。",
                enable_reasoning=enable_reasoning,
                enable_search=enable_search,
                max_tokens=max_tokens,
                keyword=keyword,
                category=category,
                content_type=content_type
            )
        else:
            return self.generate_article(keyword, category, max_tokens, content_type)

    # ============================================================
    # 🖼️ 生圖：Gemini 3.1 Flash Image + 緩存
    # ============================================================

    def _get_cache_key(self, prompt, aspect_ratio, image_size):
        """生成圖片緩存鍵"""
        key_str = f"{prompt}_{aspect_ratio}_{image_size}"
        return hashlib.md5(key_str.encode('utf-8')).hexdigest()

    def _get_cached_image(self, cache_key):
        """檢查緩存中是否有圖片"""
        cache_path = self.cache_dir / f"{cache_key}.png"
        if cache_path.exists():
            # 檢查檔案是否有效（> 1KB）
            if cache_path.stat().st_size > 1024:
                return cache_path
        return None

    def _save_to_cache(self, cache_key, data):
        """儲存圖片到緩存"""
        cache_path = self.cache_dir / f"{cache_key}.png"
        with open(cache_path, "wb") as f:
            f.write(data)
        return cache_path

    def generate_image(self, prompt, filename, seo_keywords=None,
                       aspect_ratio="16:9", image_size="1K", max_retries=3,
                       use_cache=True):
        """
        唯一圖片生成方法 — 固定使用 gemini-3.1-flash-image
        🆕 加入緩存機制，避免重複生成相同圖片
        """
        if not self.gemini_client:
            logger.warning("Gemini 客戶端未初始化，無法生成圖片")
            return {"img_tag": "", "error": "Gemini 客戶端未初始化"}

        full_prompt = self._build_image_prompt(prompt, seo_keywords)

        # 檢查緩存
        cache_key = self._get_cache_key(full_prompt, aspect_ratio, image_size)
        cached_path = self._get_cached_image(cache_key)

        if cached_path and use_cache:
            logger.info(f"✅ 使用緩存圖片：{cached_path}")
            ext = "png"
            filepath = self.image_dir / f"{filename}.{ext}"
            import shutil
            shutil.copy(cached_path, filepath)
            alt = self._generate_alt(prompt, seo_keywords)
            return {
                "img_tag": f'<img src="/images/{filename}.{ext}" alt="{alt}" loading="lazy" width="800">',
                "filepath": str(filepath),
                "alt": alt,
                "size": cached_path.stat().st_size,
                "cached": True
            }

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

                        # 儲存圖片
                        with open(filepath, "wb") as f:
                            f.write(part.inline_data.data)

                        # 儲存到緩存
                        self._save_to_cache(cache_key, part.inline_data.data)

                        alt = self._generate_alt(prompt, seo_keywords)
                        logger.info(f"✅ 圖片已生成：{filepath} ({len(part.inline_data.data)} bytes)")
                        return {
                            "img_tag": f'<img src="/images/{filename}.{ext}" alt="{alt}" loading="lazy" width="800">',
                            "filepath": str(filepath),
                            "alt": alt,
                            "size": len(part.inline_data.data),
                            "cached": False
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
            "responses_api_available": self.openai_client is not None,
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
    return {
        "name": "DeepSeek Flash",
        "model": client.deepseek_model,
        "provider": "DeepSeek",
        "peak": is_peak_hour(),
        "price": "低",
        "api_key": client.deepseek_api_key,
        "deepseek_model": client.deepseek_model,
        "gemini_model": client.gemini_model,
        "gemini_available": client.gemini_client is not None,
        "responses_api_available": client.openai_client is not None
    }


def call_api(prompt, force_api=None, max_retries=3, max_tokens=16384, system_prompt=None):
    """
    已棄用 - 統一由 APIClient 管理，保留供 article_generator 向後相容
    """
    client = APIClient()
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
    print("  🦞 AHPAL API 客戶端測試 v4.1")
    print("="*50)

    client = APIClient()
    info = client.get_current_api_info()
    print(f"   DeepSeek: {info['deepseek_model']}")
    print(f"   Gemini: {info['gemini_model']}")
    print(f"   Gemini 狀態: {'✅ 可用' if info['gemini_available'] else '❌ 未初始化'}")
    print(f"   Responses API: {'✅ 可用' if info['responses_api_available'] else '❌ 未初始化'}")

    # 測試 1：Chat API
    print("\n📝 測試 1：Chat API")
    chat_result = client.generate_article("Python 基礎教學", "💻 3C 科技教學", max_tokens=500)
    print(f"   結果：{chat_result[:100]}..." if len(chat_result) > 100 else f"   結果：{chat_result}")

    # 測試 2：Responses API + Reasoning
    print("\n📝 測試 2：Responses API + Reasoning")
    test_result = client.generate_with_responses_api(
        prompt="請用一段話介紹 DeepSeek AI 的特點。",
        instructions="你是專業的 AI 技術編輯。",
        enable_reasoning=True,
        max_tokens=500,
        keyword="DeepSeek 介紹"
    )
    print(f"   結果：{test_result[:100]}..." if len(test_result) > 100 else f"   結果：{test_result}")

    # 測試 3：build_article_prompt 公開方法
    print("\n📝 測試 3：build_article_prompt 公開方法")
    prompt = client.build_article_prompt("NAS 選購指南", "💻 3C 科技教學", "review")
    print(f"   提示詞長度：{len(prompt)} 字")
    print(f"   提示詞預覽：{prompt[:100]}...")

    print("\n✅ 測試完成")