# ============================================================
# song_generator.py - 音樂文章生成模組 v2.0
# ============================================================
# 功能：生成含 YouTube 嵌入、歌詞、台羅拼音的音樂文章
# 位置：C:\Users\User\ahpal-static\src\song_generator.py
#
# v2.0 修復與優化：
#   - 🆕 整合 Responses API + Reasoning（啟用思維鏈）
#   - 🆕 支援從 JSON 讀取 use_responses_api / enable_reasoning
#   - 🆕 新增台羅拼音自動生成功能（使用 Reasoning）
#   - 🆕 新增迷因/時事改編文章支援
#   - 🆕 文章結構強化：背景、歌詞解析、詞彙小教室、聆聽場景
#   - 🔧 重試與降級邏輯（與 article_generator 一致）
#   - 🔧 完整的日誌記錄
# ============================================================

import os
import re
import time
import urllib.parse
from pathlib import Path
from datetime import datetime

from src.config import OUTPUT_DIR
from src.html_builder import build_article_html
from src.quality_checker import check_article_quality
from src.api_client import APIClient
from src.model_router import ModelRouter
from src.logger import get_logger

# 取得日誌器
logger = get_logger("song_generator")


# ============================================================
# YouTube 嵌入函數（與 article_generator 共用）
# ============================================================

def create_youtube_embed(video_id):
    """建立 YouTube 影片嵌入 HTML（響應式 16:9）"""
    if not video_id:
        return ""
    
    return f'''
<div class="youtube-embed" style="margin:20px 0;position:relative;padding-bottom:56.25%;height:0;overflow:hidden;border-radius:12px;box-shadow:0 4px 12px rgba(0,0,0,0.1);">
    <iframe style="position:absolute;top:0;left:0;width:100%;height:100%;border:none;"
        src="https://www.youtube.com/embed/{video_id}"
        title="YouTube video player"
        loading="lazy"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowfullscreen>
    </iframe>
</div>
'''


# ============================================================
# 🆕 台羅拼音生成函數
# ============================================================

def generate_lyrics_with_tailo(lyrics_text, keyword):
    """
    使用 Responses API + Reasoning 生成歌詞的台羅拼音與解析
    
    參數：
        lyrics_text: 原始歌詞文字
        keyword: 歌曲關鍵字（用於日誌）
    
    回傳：
        str: 台羅拼音 + 解析的 HTML 區塊
    """
    if not lyrics_text or len(lyrics_text) < 10:
        return ""
    
    print("   🗣️ 正在生成台羅拼音與詞彙解析...")
    logger.info(f"生成台羅拼音：{keyword}")
    
    client = APIClient()
    
    prompt = f"""
    請為以下歌詞提供完整的台羅拼音（Tâi-lô）與詞彙解析：

    歌詞：
    {lyrics_text}

    請輸出以下格式：
    1. 逐句歌詞 + 台羅拼音對照
    2. 關鍵詞彙解析（挑選 3-5 個特殊詞彙，解釋其意義與文化背景）
    3. 整首歌的意境總結

    要求：
    - 台羅拼音請使用教育部標準系統
    - 解析要深入淺出，適合對台語不熟悉的讀者
    - 風格溫暖、親切
    """
    
    try:
        result = client.generate_with_responses_api(
            prompt=prompt,
            instructions="你是台語文化專家，擅長台羅拼音教學與歌詞意境解析。",
            enable_reasoning=True,
            max_tokens=4096,
            keyword=keyword,
            category="🎵 音樂創作"
        )
        
        if result and len(result) > 50:
            # 將純文字轉換為 HTML 區塊
            html_parts = []
            html_parts.append('<div class="tailo-section" style="background:#f8f4f0;padding:24px;border-radius:12px;margin:24px 0;border-left:4px solid #d4a373;">')
            html_parts.append(f'<h3 style="color:#6b4c3b;">📖 台羅拼音與詞彙解析</h3>')
            
            # 將結果分段
            paragraphs = result.split('\n\n')
            for para in paragraphs:
                if para.strip():
                    # 檢查是否為標題行
                    if re.match(r'^[\d]+[.、]', para.strip()) or re.match(r'^[一二三四五六七八九十]+[、.]', para.strip()):
                        html_parts.append(f'<h4 style="color:#8b5e3c;margin:12px 0 6px 0;">{para.strip()}</h4>')
                    else:
                        html_parts.append(f'<p style="line-height:1.8;margin:6px 0;">{para.strip()}</p>')
            
            html_parts.append('</div>')
            logger.info(f"✅ 台羅拼音生成成功：{keyword}")
            return '\n'.join(html_parts)
        else:
            logger.warning(f"⚠️ 台羅拼音生成結果過短：{keyword}")
            return ""
            
    except Exception as e:
        logger.error(f"❌ 台羅拼音生成失敗：{e}")
        return ""


# ============================================================
# 🆕 生成迷因改編音樂文章
# ============================================================

def generate_meme_song(item):
    """
    生成迷因/時事改編音樂文章
    
    參數：
        item: dict，包含：
            - keyword: 文章標題
            - category: 分類（🎵 音樂創作）
            - filename: 輸出路徑
            - meme_source: 迷因/時事來源（可選）
            - video_id: YouTube 影片 ID（可選）
            - use_responses_api: 是否使用 Responses API
            - enable_reasoning: 是否啟用思維鏈
    """
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    meme_source = item.get("meme_source", "網路迷因")
    video_id = item.get("video_id", "")
    
    use_responses_api = item.get("use_responses_api", True)
    enable_reasoning = item.get("enable_reasoning", True)
    enable_search = item.get("enable_search", False)
    
    file_path = os.path.join(OUTPUT_DIR, filename)
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    if os.path.exists(file_path):
        file_size = os.path.getsize(file_path)
        if file_size >= 5120:
            print(f"⏩ 跳過：{filename} 已存在（{file_size} bytes）")
            return
        else:
            print(f"⚠️ 檔案過小（{file_size} bytes），重新生成：{filename}")
    
    print(f"🎵 正在生成迷因改編文章：{keyword}（分類：{category}）")
    logger.info(f"開始生成迷因文章：{keyword}")
    
    client = APIClient()
    raw_content = None
    generation_attempts = 0
    max_attempts = 2
    
    # 建構迷因改編專用提示詞
    meme_prompt = f"""
    請根據以下迷因/時事內容，創作一篇音樂改編文章：

    迷因/時事來源：{meme_source}
    主題：{keyword}

    文章應包含：
    1. 迷因/時事背景介紹（幽默、輕鬆的語氣）
    2. 原創改編歌詞（根據主題創作，風格可為流行、搖滾、民謠等）
    3. 歌詞意境解析（為什麼這樣改編？）
    4. 聆聽場景推薦（適合什麼時候聽？）

    要求：
    - 歌詞必須 100% 原創，不能抄襲任何現有歌曲
    - 風格輕鬆幽默，但保持專業
    - 字數：至少 2000 字
    - 語言：繁體中文
    """
    
    while generation_attempts < max_attempts:
        generation_attempts += 1
        try:
            if use_responses_api:
                raw_content = client.generate_with_responses_api(
                    prompt=meme_prompt,
                    instructions="你是專業的音樂創作人與文化評論者，擅長將時事迷因轉化為音樂創作。",
                    enable_reasoning=enable_reasoning,
                    enable_search=enable_search,
                    max_tokens=16384,
                    keyword=keyword,
                    category=category
                )
            else:
                raw_content = client.generate_article(
                    keyword=keyword,
                    category=category,
                    max_tokens=16384
                )
            
            if raw_content and len(raw_content) >= 100:
                break
                
            print(f"   ⚠️ 生成結果較短，嘗試重新生成...")
            logger.warning(f"生成結果較短，重試 {generation_attempts}/{max_attempts}")
            
            if use_responses_api and generation_attempts == 1:
                print("   🔄 降級到 Chat API 重新生成...")
                use_responses_api = False
                continue
                
        except Exception as e:
            logger.error(f"生成異常 (嘗試 {generation_attempts}/{max_attempts})：{e}")
            print(f"   ⚠️ 生成異常：{e}")
            if generation_attempts >= max_attempts:
                raw_content = None
                break
            time.sleep(2)
    
    if not raw_content:
        print(f"❌ 生成失敗：{keyword}")
        logger.error(f"文章生成失敗：{keyword}")
        return
    
    # 轉換為完整 HTML
    print("   🔧 將內容轉換為完整 HTML 結構...")
    from src.article_generator import text_to_html
    html_content = text_to_html(raw_content, keyword, category)
    
    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
        logger.error(f"HTML 轉換失敗：{keyword}")
        return
    
    # 建構完整品牌 HTML
    html_content = build_article_html(keyword, category, html_content)
    
    # 嵌入 YouTube 影片（如果有）
    if video_id:
        youtube_embed = create_youtube_embed(video_id)
        if '<body>' in html_content:
            html_content = html_content.replace('<body>', f'<body>\n{youtube_embed}', 1)
        else:
            html_content = youtube_embed + html_content
        print(f"   ✅ 已嵌入 YouTube 影片：{video_id}")
    
    # 生成配圖
    from src.article_generator import generate_and_embed_image
    html_content, image_generated = generate_and_embed_image(html_content, keyword, category)
    
    # 品質檢查
    quality_report = check_article_quality(html_content, keyword)
    
    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ 配圖：{'✅ 已生成' if image_generated else '⚠️ 未生成'}")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")
    
    # 寫入檔案
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")
    logger.info(f"文章已寫入：{file_path}")
    
    # 更新首頁
    from src.article_generator import update_index_html
    update_index_html(keyword, filename, category)
    
    time.sleep(2)


# ============================================================
# 🆕 生成音樂文章（強化版 v2.0）
# ============================================================

def generate_song(item):
    """
    生成音樂文章（含 YouTube 影片、歌詞、台羅拼音解析）
    
    參數：
        item: dict，包含：
            - keyword: 文章標題
            - category: 分類（應為 🎵 音樂創作）
            - filename: 輸出路徑
            - video_id: YouTube 影片 ID（必填）
            - content_type: "song"（自動識別）
            - use_responses_api: 是否使用 Responses API（預設 True）
            - enable_reasoning: 是否啟用思維鏈（預設 True）
            - enable_search: 是否啟用網頁搜尋（預設 False）
            - meme_source: 迷因來源（可選，有則視為迷因改編）
            - lyrics: 歌詞結構化資料（可選）
            - vocabulary: 詞彙解析（可選）
    """
    # 檢查是否為迷因改編文章
    if item.get("meme_source"):
        return generate_meme_song(item)
    
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    video_id = item.get("video_id", "")
    
    # 🆕 從 JSON 讀取 Responses API 設定
    use_responses_api = item.get("use_responses_api", True)
    enable_reasoning = item.get("enable_reasoning", True)
    enable_search = item.get("enable_search", False)
    
    file_path = os.path.join(OUTPUT_DIR, filename)
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    # 檢查是否已存在
    if os.path.exists(file_path):
        file_size = os.path.getsize(file_path)
        if file_size >= 5120:
            print(f"⏩ 跳過：{filename} 已存在（{file_size} bytes）")
            logger.info(f"跳過已存在文章：{filename} ({file_size} bytes)")
            return
        else:
            print(f"⚠️ 檔案過小（{file_size} bytes），重新生成：{filename}")
            logger.warning(f"檔案過小，重新生成：{filename} ({file_size} bytes)")
    
    api_label = "Responses API" if use_responses_api else "Chat API"
    if use_responses_api:
        features = []
        if enable_reasoning:
            features.append("🧠 Reasoning")
        if enable_search:
            features.append("🌐 Web Search")
        feature_str = f" ({', '.join(features)})" if features else ""
        print(f"🎵 正在生成音樂文章：{keyword}（分類：{category}）[API: {api_label}{feature_str}]")
    else:
        print(f"🎵 正在生成音樂文章：{keyword}（分類：{category}）[API: {api_label}]")
    
    logger.info(f"開始生成音樂文章：{keyword} (API: {api_label}, Reasoning: {enable_reasoning}, Search: {enable_search})")
    
    # ============================================================
    # 1. 生成文章內容（使用 Responses API 或 Chat API）
    # ============================================================
    client = APIClient()
    raw_content = None
    generation_attempts = 0
    max_attempts = 2
    
    # 建構音樂文章專用提示詞
    song_prompt = f"""
    請撰寫一篇關於歌曲《{keyword}》的深度音樂文章，內容應包含：

    1. 歌曲背景與歷史文化脈絡
    2. 歌詞深度解析（若為台語歌，需含台羅拼音）
    3. 詞彙小教室（關鍵詞解釋）
    4. 聆聽場景與情感記憶
    5. 結語

    文章風格：溫暖、專業、貼近讀者
    字數：至少 3000 字
    語言：繁體中文
    """
    
    while generation_attempts < max_attempts:
        generation_attempts += 1
        try:
            if use_responses_api:
                raw_content = client.generate_with_responses_api(
                    prompt=song_prompt,
                    instructions="你是專業的音樂評論家與台語文化專家，擅長深度音樂解析。",
                    enable_reasoning=enable_reasoning,
                    enable_search=enable_search,
                    max_tokens=16384,
                    keyword=keyword,
                    category=category
                )
            else:
                raw_content = client.generate_article(
                    keyword=keyword,
                    category=category,
                    max_tokens=16384
                )
            
            if raw_content and len(raw_content) >= 100:
                break
                
            print(f"   ⚠️ 生成結果較短，嘗試重新生成...")
            logger.warning(f"生成結果較短，重試 {generation_attempts}/{max_attempts}")
            
            if use_responses_api and generation_attempts == 1:
                print("   🔄 降級到 Chat API 重新生成...")
                logger.info("降級到 Chat API")
                use_responses_api = False
                continue
                
        except Exception as e:
            logger.error(f"生成異常 (嘗試 {generation_attempts}/{max_attempts})：{e}")
            print(f"   ⚠️ 生成異常：{e}")
            if generation_attempts >= max_attempts:
                raw_content = None
                break
            time.sleep(2)
    
    if not raw_content:
        print(f"❌ 生成失敗：{keyword}")
        logger.error(f"文章生成失敗：{keyword}")
        return
    
    # ============================================================
    # 2. 轉換為完整 HTML
    # ============================================================
    print("   🔧 將內容轉換為完整 HTML 結構...")
    from src.article_generator import text_to_html
    html_content = text_to_html(raw_content, keyword, category)
    
    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
        logger.error(f"HTML 轉換失敗：{keyword}")
        return
    
    # ============================================================
    # 3. 建構完整品牌 HTML
    # ============================================================
    html_content = build_article_html(keyword, category, html_content)
    
    # ============================================================
    # 4. 嵌入 YouTube 影片（置頂）
    # ============================================================
    if video_id:
        youtube_embed = create_youtube_embed(video_id)
        if '<body>' in html_content:
            html_content = html_content.replace('<body>', f'<body>\n{youtube_embed}', 1)
        else:
            html_content = youtube_embed + html_content
        print(f"   ✅ 已嵌入 YouTube 影片：{video_id}")
        logger.info(f"已嵌入 YouTube 影片：{video_id}")
    
    # ============================================================
    # 5. 生成配圖
    # ============================================================
    from src.article_generator import generate_and_embed_image
    html_content, image_generated = generate_and_embed_image(html_content, keyword, category)
    
    # ============================================================
    # 6. 品質檢查
    # ============================================================
    quality_report = check_article_quality(html_content, keyword)
    
    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ H1 標題：{quality_report.get('h1_count', 0)} 個 {'✅' if quality_report.get('h1_count', 0) >= 1 else '❌ 無'}")
    print(f"   └─ H2 標題：{quality_report.get('h2_count', 0)} 個")
    print(f"   └─ 配圖：{'✅ 已生成' if image_generated else '⚠️ 未生成'}")
    print(f"   └─ API：{'Responses' if item.get('use_responses_api', True) else 'Chat'}")
    if item.get('enable_reasoning', True):
        print(f"   └─ 思維鏈：✅ 已啟用")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")
    
    logger.info(f"品質報告：{keyword} 分數 {quality_report['score']}/100，通過 {quality_report['passed']}")
    
    # ============================================================
    # 7. 寫入檔案
    # ============================================================
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")
    logger.info(f"文章已寫入：{file_path}")
    
    # ============================================================
    # 8. 更新首頁
    # ============================================================
    from src.article_generator import update_index_html
    update_index_html(keyword, filename, category)
    
    time.sleep(2)


# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🧪 song_generator.py v2.0 測試")
    print("="*50 + "\n")
    
    # 測試 1：一般音樂文章
    print("📝 測試 1：一般音樂文章（Responses API + Reasoning）")
    test_item_1 = {
        "keyword": "望春風 Lo-fi 翻唱 歌詞 台羅拼音 解析",
        "category": "🎵 音樂創作",
        "filename": "music/test-song-v2.html",
        "video_id": "A9Zw-QHEOqQ",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    }
    generate_song(test_item_1)
    
    # 測試 2：迷因改編文章
    print("\n📝 測試 2：迷因改編文章")
    test_item_2 = {
        "keyword": "打工人心酸語錄 原創歌曲",
        "category": "🎵 音樂創作",
        "filename": "music/test-meme-song.html",
        "meme_source": "PTT 熱門廢文 - 打工人日常",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    }
    generate_song(test_item_2)
    
    print("\n✅ 測試完成")