# ============================================================
# song_generator.py - 音樂文章生成模組 v1.0
# ============================================================
# 功能：生成含 YouTube 嵌入、歌詞、台羅拼音的音樂文章
# 位置：C:\Users\User\ahpal-static\src\song_generator.py
# ============================================================

import os
import re
import time
from pathlib import Path
from datetime import datetime

from src.config import OUTPUT_DIR
from src.html_builder import build_article_html
from src.quality_checker import check_article_quality
from src.api_client import APIClient
from src.model_router import ModelRouter


# ============================================================
# YouTube 嵌入函數（與 article_generator 共用）
# ============================================================

def create_youtube_embed(video_id):
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
# 生成音樂文章
# ============================================================

def generate_song(item):
    """
    生成音樂文章（含 YouTube 影片、歌詞、解析）
    
    參數：
        item: dict，包含：
            - keyword: 文章標題
            - category: 分類（應為 🎵 音樂創作）
            - filename: 輸出路徑
            - video_id: YouTube 影片 ID（必填）
            - song_title: 歌曲名稱（可選）
            - artist: 演唱者（可選）
            - composer: 作曲（可選）
            - lyricist: 作詞（可選）
            - year: 發表年份（可選）
            - lyrics: 歌詞結構化資料（可選）
            - vocabulary: 詞彙解析（可選）
    """
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    video_id = item.get("video_id", "")
    file_path = os.path.join(OUTPUT_DIR, filename)

    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    # 檢查是否已存在
    if os.path.exists(file_path):
        file_size = os.path.getsize(file_path)
        if file_size >= 5120:
            print(f"⏩ 跳過：{filename} 已存在（{file_size} bytes）")
            return
        else:
            print(f"⚠️ 檔案過小（{file_size} bytes），重新生成：{filename}")

    print(f"🎵 正在生成音樂文章：{keyword}（分類：{category}）")

    # ============================================================
    # 1. 生成文章內容
    # ============================================================
    client = APIClient()
    
    # 構建音樂文章專用提示詞
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

    raw_content = client.generate_article(
        keyword=keyword,
        category=category,
        max_tokens=16384
    )

    if not raw_content or len(raw_content) < 100:
        print("   ⚠️ 第一次生成結果較短，嘗試重新生成...")
        raw_content = client.generate_article(
            keyword=keyword,
            category=category,
            max_tokens=16384
        )

    if not raw_content:
        print(f"❌ 生成失敗：{keyword}")
        return

    # ============================================================
    # 2. 轉換為完整 HTML（使用一般文章的 text_to_html）
    # ============================================================
    print("   🔧 將內容轉換為完整 HTML 結構...")
    from src.article_generator import text_to_html
    html_content = text_to_html(raw_content, keyword, category)

    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
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
    print(f"   └─ 配圖：{'✅ 已生成' if image_generated else '⚠️ 未生成'}")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")

    # ============================================================
    # 7. 寫入檔案
    # ============================================================
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")

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
    print("  🧪 song_generator.py v1.0 測試")
    print("="*50 + "\n")

    test_item = {
        "keyword": "望春風 Lo-fi 翻唱 歌詞 台羅拼音 解析",
        "category": "🎵 音樂創作",
        "filename": "music/test-song.html",
        "video_id": "A9Zw-QHEOqQ"
    }

    generate_song(test_item)
    print("\n✅ 測試完成")