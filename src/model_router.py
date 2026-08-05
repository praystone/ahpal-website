# ============================================================
# src/model_router.py - AHPAL 雙模路由 v2.3
# ============================================================
# 功能：
#   - 生文：Gemini（備用，配額有限）
#   - 生圖：Pollinations AI（免費、無需 API Key）
#   - 已驗證端點：image.pollinations.ai/prompt/
# ============================================================

import os
import re
import time
import requests
import urllib.parse
from pathlib import Path
from dotenv import load_dotenv

# ============================================================
# 🔧 載入 .env
# ============================================================
_current_dir = Path(__file__).parent
_project_root = _current_dir.parent
_env_path = _project_root / ".env"

if _env_path.exists():
    load_dotenv(_env_path)
else:
    load_dotenv()


# ============================================================
# 🦞 模型路由
# ============================================================
class ModelRouter:
    def __init__(self):
        # ---- Gemini（生文備用） ----
        self.gemini_api_key = os.environ.get("GEMINI_API_KEY")
        
        # ---- 圖片輸出目錄 ----
        self.image_dir = Path("images")
        self.image_dir.mkdir(exist_ok=True)

    # ============================================================
    # 📝 生文：Gemini（備用）
    # ============================================================
    def generate_text(self, prompt, max_tokens=8192):
        """使用 Gemini 生成文字（備用）"""
        if not self.gemini_api_key:
            return "❌ 未設定 GEMINI_API_KEY"
        
        try:
            from google import genai
            from google.genai import types
            client = genai.Client(api_key=self.gemini_api_key)
            response = client.models.generate_content(
                model='gemini-2.0-flash',
                contents=prompt,
                config=types.GenerateContentConfig(
                    max_output_tokens=max_tokens,
                    temperature=0.7
                )
            )
            return response.text
        except Exception as e:
            return f"❌ Gemini 生成失敗：{e}"

    # ============================================================
    # 🖼️ 生圖：Pollinations AI（已驗證端點）
    # ============================================================
    def generate_image_pollinations(self, prompt, filename, width=1024, height=1024, max_retries=3):
        """
        使用 Pollinations.ai 免費生成圖片
        已驗證端點：image.pollinations.ai/prompt/
        """
        clean_prompt = prompt.strip()
        encoded_prompt = urllib.parse.quote(clean_prompt)
        
        # ✅ 只保留已驗證成功的端點
        url = f"https://image.pollinations.ai/prompt/{encoded_prompt}?width={width}&height={height}&nologo=true"
        
        for attempt in range(max_retries):
            try:
                print(f"   🎨 正在生成圖片（嘗試 {attempt+1}/{max_retries}）...")
                
                response = requests.get(url, timeout=90, headers={
                    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
                })
                
                if response.status_code == 200:
                    content_type = response.headers.get('content-type', '')
                    
                    if 'image' in content_type:
                        ext = 'png'
                        filepath = self.image_dir / f"{filename}.{ext}"
                        with open(filepath, "wb") as f:
                            f.write(response.content)
                        
                        alt = self._generate_alt(clean_prompt)
                        size = len(response.content)
                        
                        print(f"   ✅ 圖片已儲存：{filepath} ({size} bytes)")
                        return {
                            "img_tag": f'<img src="/images/{filename}.{ext}" alt="{alt}" loading="lazy" width="800">',
                            "filepath": str(filepath),
                            "alt": alt,
                            "size": size
                        }
                    else:
                        error_text = response.text[:100] if response.text else "空回應"
                        print(f"   ⚠️ 回應不是圖片：{error_text}...")
                else:
                    print(f"   ⚠️ HTTP {response.status_code}")
                
                if attempt < max_retries - 1:
                    print(f"   ⏳ 等待 3 秒後重試...")
                    time.sleep(3)
                    
            except Exception as e:
                print(f"   ⚠️ 請求失敗：{e}")
                if attempt < max_retries - 1:
                    time.sleep(3)
        
        return {"img_tag": "", "filepath": "", "alt": "", "error": "Pollinations 生成失敗"}

    def _generate_alt(self, prompt):
        """生成 SEO 友好的 alt 文本"""
        alt = prompt[:50]
        if len(prompt) > 50:
            alt += "..."
        return alt


# ============================================================
# 🧪 測試
# ============================================================
if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🦞 AHPAL 雙模路由測試 v2.3")
    print("="*50 + "\n")
    
    router = ModelRouter()
    
    # 測試圖片生成
    print("🖼️ 測試 Pollinations AI 生圖...")
    result = router.generate_image_pollinations(
        prompt="一隻可愛的龍蝦戴著工程師帽，在電腦前寫程式，數位插畫風格",
        filename="lobster_coder_final",
        width=1024,
        height=1024
    )
    
    if result.get("img_tag"):
        print(f"\n   ✅ 成功！")
        print(f"   📁 位置：{result['filepath']}")
        print(f"   📝 Alt：{result['alt']}")
        print(f"   📦 大小：{result['size']} bytes")
    else:
        print(f"\n   ❌ 失敗：{result.get('error', '未知錯誤')}")
    
    print("\n✅ 測試完成")