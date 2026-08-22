# ============================================================
# html_builder.py - HTML 建構模組 v7.4 (Emoji 修復 + Nature 支援)
# ============================================================
# 修復 (v7.3)：
#   - 🔧 恢復所有被破壞的 Emoji (🎮📊🤖📚🔍💬📖📄等)
#   - 🔧 修復 CATEGORY_EMOJI_MAP 映射
#   - 🔧 修復 SITE_HEADER 和 SITE_FOOTER 中的 Emoji
#   - 🔧 修復 create_default_index() 中的分類顯示
#   - 🔧 修復 GOOGLE_CSE 中的搜尋圖示
#   - ✅ 繼承 v7.2 所有功能
#
# v7.4 變更：
#   - 🆕 CATEGORY_EMOJI_MAP 新增 "🌳": "🌳 動植物生態"
#   - 🆕 category_dirs 新增 "nature": "🌳 動植物生態"
#   - 🆕 create_default_index() 分類網格自動支援 nature/
#   - 🆕 generate_categories_page() 自動讀取 config.py 中的 CATEGORIES
#   - 🆕 generate_category_pages() 自動讀取 config.py 中的 CATEGORIES
# ============================================================

import hashlib
import json
import os
import re
from datetime import datetime
from pathlib import Path

from src.config import (
    OUTPUT_DIR, ADSENSE_CLIENT, GA4_ID,
    CATEGORIES, CURRENT_YEAR, CURRENT_DATE_STR
)

# ============================================================
# 增量構建 - MD5 比對
# ============================================================

STATE_FILE = Path(__file__).parent.parent / "build-state.json"

def get_file_hash(filepath):
    if not Path(filepath).exists():
        return None
    with open(filepath, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()

def load_build_state():
    if STATE_FILE.exists():
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"files": {}}

def save_build_state(state):
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

def needs_rebuild(filepath, current_hash):
    state = load_build_state()
    file_key = str(filepath).replace("\\", "/")
    previous_hash = state["files"].get(file_key)
    return previous_hash != current_hash

def mark_built(filepath, hash_value):
    state = load_build_state()
    file_key = str(filepath).replace("\\", "/")
    state["files"][file_key] = hash_value
    save_build_state(state)


# ============================================================
# 🆕 CSS 靜態資產管理 (v7.0 保護機制)
# ============================================================

CSS_VERSION = "1.2"
CSS_MIN_SIZE = 10000  # 10KB

def generate_main_css():
    """
    產生統一的 main.css 檔案 — 僅在不存在或損壞時建立
    main.css 現已視為靜態資產，不自動覆蓋
    
    v7.0 保護機制：
        1. 如果 CSS 存在且完整 (≥ 10KB)，跳過
        2. 如果 CSS 存在但過小，警告但不覆蓋
        3. 只有 CSS 不存在時才建立
    """
    style_dir = Path(OUTPUT_DIR) / "style"
    style_dir.mkdir(exist_ok=True)
    css_path = style_dir / "main.css"
    
    # 🆕 保護機制 1：CSS 存在且完整
    if css_path.exists() and css_path.stat().st_size >= CSS_MIN_SIZE:
        print(f"ℹ️ main.css 已存在且完整 ({css_path.stat().st_size} bytes, v{CSS_VERSION})，跳過生成")
        return css_path
    
    # 🆕 保護機制 2：CSS 存在但過小 (損壞)
    if css_path.exists() and css_path.stat().st_size < CSS_MIN_SIZE:
        print(f"⚠️ main.css 檔案過小 ({css_path.stat().st_size} bytes)，可能不完整")
        print(f"📌 請手動還原完整的 main.css (v{CSS_VERSION})")
        print(f"📌 或刪除後重新執行本函數以建立新檔案")
        return css_path
    
    # 只有 CSS 不存在時才建立 (內嵌完整 CSS)
    print(f"📄 建立 main.css (v{CSS_VERSION} 完整版)")
    css_content = """/* ============================================================
   AHPAL 統一全域樣式表 v1.3 — 完整修復版
   最後更新：2026-08-09
   ============================================================ */

/* ----- 全域設定 ----- */
* { margin: 0; padding: 0; box-sizing: border-box; }

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif;
    background: #F7F9FC;
    color: #1A202C;
    line-height: 1.8;
    font-size: 16px;
}

/* ----- 主要佈局 (側邊欄) ----- */
.main-wrapper {
    max-width: 1200px;
    margin: 28px auto;
    padding: 0 24px;
    display: grid;
    grid-template-columns: 1fr 300px;
    gap: 30px;
    align-items: start;
}
@media (max-width: 992px) {
    .main-wrapper { grid-template-columns: 1fr; }
}

/* ----- 主要內容區域 ----- */
.main-content {
    min-width: 0;
}

/* ----- 容器與卡片 ----- */
.container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }
.content-card {
    background: #FFFFFF;
    padding: 36px 40px;
    border-radius: 14px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.06);
    margin-bottom: 24px;
    border: 1px solid #E2E8F0;
}
@media (max-width: 640px) { .content-card { padding: 24px 18px; } }

/* ============================================================
   🆕 側邊欄 (完整修復)
   ============================================================ */
.sidebar {
    display: flex;
    flex-direction: column;
    gap: 24px;
}

.widget {
    background: #FFFFFF;
    padding: 20px 22px;
    border-radius: 14px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.06);
    border: 1px solid #E2E8F0;
}

.widget h3,
.widget .widget-title {
    font-size: 16px;
    font-weight: 700;
    color: #005A9C;
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 2px solid #E2E8F0;
}

.widget p {
    font-size: 14px;
    color: #4A5568;
    line-height: 1.7;
}

.widget ul {
    list-style: none;
    padding: 0;
    margin: 0;
}

.widget ul li {
    margin-bottom: 8px;
    padding: 6px 0;
    border-bottom: 1px solid #F0F4F8;
    font-size: 14px;
}

.widget ul li:last-child {
    border-bottom: none;
}

.widget ul li a {
    color: #2D3748;
    text-decoration: none;
    font-size: 14px;
    transition: color 0.2s;
    display: block;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.widget ul li a:hover {
    color: #005A9C;
    text-decoration: underline;
}

/* ----- 側邊欄內的分類標籤 (小尺寸) ----- */
.widget .tag-cloud {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
}

.widget .tag-cloud a {
    background: #F7F9FC;
    padding: 4px 12px;
    border-radius: 20px;
    font-size: 12px;
    color: #4A5568;
    text-decoration: none;
    border: 1px solid #E2E8F0;
    transition: all 0.2s;
}

.widget .tag-cloud a:hover {
    border-color: #00A86B;
    color: #1A202C;
}

/* ============================================================
   🆕 分類網格 (主內容區，非側邊欄)
   ============================================================ */
.category-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: 14px;
    margin: 20px 0 28px 0;
}

@media (max-width: 768px) {
    .category-grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 480px) {
    .category-grid { grid-template-columns: repeat(2, 1fr); }
}

.category-card {
    display: block;
    background: #F7F9FC;
    padding: 18px 12px;
    border-radius: 14px;
    text-decoration: none;
    text-align: center;
    border: 1px solid #E2E8F0;
    transition: all 0.25s ease;
}

.category-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 25px rgba(0,0,0,0.10);
    border-color: #00A86B;
}

.category-card .icon {
    font-size: 28px;
    display: block;
    margin-bottom: 4px;
}

.category-card .name {
    font-size: 13px;
    font-weight: 600;
    color: #1A202C;
}

.category-card .count {
    font-size: 11px;
    color: #718096;
    display: block;
    margin-top: 2px;
}

/* ----- 索引標籤網格 ----- */
.index-section { margin: 24px 0 8px 0; }
.index-section .cat-title {
    font-size: 14px;
    font-weight: 600;
    color: #1A202C;
    border-left: 3px solid #00A86B;
    padding-left: 12px;
    margin: 18px 0 10px 0;
    display: flex;
    align-items: center;
    gap: 10px;
}
.index-section .cat-title .count { font-size: 12px; font-weight: 400; color: #718096; }
.index-tag-grid { display: flex; flex-wrap: wrap; gap: 8px; }
.index-tag {
    background: white;
    padding: 6px 16px;
    border-radius: 20px;
    font-size: 13px;
    color: #4A5568;
    text-decoration: none;
    border: 1px solid #E2E8F0;
    transition: all 0.2s;
}
.index-tag:hover { border-color: #00A86B; color: #1A202C; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }

/* ----- 遊戲入口卡片 ----- */
.game-entry-card {
    display: block;
    background: linear-gradient(135deg, #005A9C 0%, #003d66 100%);
    color: white;
    padding: 20px 16px;
    border-radius: 14px;
    text-decoration: none;
    text-align: center;
    margin: 20px 0 32px 0;
}
.game-entry-card:hover { transform: translateY(-4px); box-shadow: 0 8px 25px rgba(0,0,0,0.10); }
.game-entry-card .emoji { font-size: 36px; display: block; margin-bottom: 6px; }
.game-entry-card .title { font-size: 18px; font-weight: 700; }
.game-entry-card .desc { font-size: 13px; opacity: 0.8; margin-top: 2px; }
.game-entry-card .badge {
    display: inline-block;
    background: rgba(255,255,255,0.2);
    padding: 2px 14px;
    border-radius: 20px;
    font-size: 11px;
    margin-top: 6px;
}

/* ----- 文章列表 ----- */
#article-list {
    list-style: none;
    padding: 0;
    margin: 0 0 32px 0;
}
#article-list li {
    background: white;
    padding: 14px 18px;
    border-radius: 10px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.04);
    margin-bottom: 8px;
    display: flex;
    align-items: center;
    gap: 12px;
    border: 1px solid #E2E8F0;
    transition: all 0.2s;
}
#article-list li:hover { box-shadow: 0 8px 25px rgba(0,0,0,0.10); border-color: #00A86B; }
#article-list li .category {
    background: #005A9C;
    color: white;
    font-size: 11px;
    font-weight: 600;
    padding: 2px 12px;
    border-radius: 20px;
    white-space: nowrap;
}
#article-list li a { flex: 1; color: #1A202C; text-decoration: none; font-size: 15px; font-weight: 500; }
#article-list li a:hover { color: #005A9C; }
#article-list li .post-date { font-size: 12px; color: #718096; white-space: nowrap; }
@media (max-width: 600px) {
    #article-list li { flex-wrap: wrap; padding: 12px 14px; }
    #article-list li a { font-size: 14px; }
}

/* ----- Google 自訂搜尋 ----- */
.google-search {
    max-width: 800px;
    margin: 20px auto;
    padding: 16px;
    background: #F7F9FC;
    border-radius: 12px;
    border: 1px solid #E2E8F0;
}
.google-search h3 { font-size: 16px; font-weight: 700; color: #1A202C; margin-bottom: 8px; }
.google-search p { font-size: 13px; color: #4A5568; margin-bottom: 12px; }

/* ----- 網站標頭 ----- */
.site-header {
    background: #005A9C;
    color: white;
    padding: 12px 0;
    position: sticky;
    top: 0;
    z-index: 50;
}
.header-inner {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 24px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-wrap: wrap;
    gap: 10px;
}
.logo {
    font-size: 20px;
    font-weight: 700;
    color: white;
    text-decoration: none;
    letter-spacing: 0.5px;
}
.logo:hover { color: rgba(255,255,255,0.85); }
.nav-links {
    display: flex;
    gap: 20px;
    font-size: 14px;
    align-items: center;
    flex-wrap: wrap;
}
.nav-links a { color: rgba(255,255,255,0.85); text-decoration: none; }
.nav-links a:hover { color: white; border-bottom: 2px solid #00A86B; }
.nav-links .game-link {
    background: rgba(255,255,255,0.15);
    padding: 4px 14px;
    border-radius: 20px;
    font-weight: 500;
}
.nav-links .game-link:hover { background: rgba(255,255,255,0.25); border-bottom: none; }

/* ----- 文章標題與中繼資訊 ----- */
.post-category {
    display: inline-block;
    background: #00A86B;
    color: white;
    padding: 2px 14px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
}
.meta-info { font-size: 14px; color: #718096; margin: 8px 0 16px 0; }

/* ----- 文章內容 ----- */
h1 { font-size: 2.2em; color: #1A202C; margin: 20px 0 16px 0; line-height: 1.3; }
h2 {
    font-size: 1.6em;
    color: #005A9C;
    margin: 28px 0 12px 0;
    border-left: 4px solid #00A86B;
    padding-left: 16px;
}
h3 { font-size: 1.3em; color: #2D3748; margin: 20px 0 10px 0; }
p { margin-bottom: 16px; line-height: 1.8; }
ul, ol { margin: 12px 0 16px 24px; }
li { margin-bottom: 6px; }
a { color: #005A9C; text-decoration: none; }
a:hover { text-decoration: underline; }

/* ----- 圖片 ----- */
img { max-width: 100%; height: auto; }
.article-image { margin: 24px 0; }
.youtube-embed {
    margin: 20px 0;
    position: relative;
    padding-bottom: 56.25%;
    height: 0;
    overflow: hidden;
    border-radius: 12px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
.youtube-embed iframe {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    border: none;
}

/* ----- 相關文章與留言 ----- */
.related-articles {
    background-color: #fff;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 20px;
    margin-top: 50px;
}
.related-articles h4 {
    margin-top: 0;
    color: #333;
    border-bottom: 1px solid #eee;
    padding-bottom: 10px;
}
.related-articles ul { list-style: none; padding-left: 0; margin: 0; }
.related-articles ul li { margin-bottom: 10px; }
.related-articles ul li a { color: #0056b3; text-decoration: none; }

.giscus-wrapper {
    max-width: 800px;
    margin: 40px auto;
    padding: 24px;
    background: #F7F9FC;
    border-radius: 14px;
    border: 1px solid #E2E8F0;
}
.giscus-wrapper h3 {
    font-size: 18px;
    font-weight: 700;
    color: #1A202C;
    margin-bottom: 16px;
    display: flex;
    align-items: center;
    gap: 8px;
}

/* ----- 頁尾 ----- */
.site-footer {
    background: #2D3748;
    color: #A0AEC0;
    padding: 40px 0 28px 0;
    margin-top: 40px;
    font-size: 14px;
}
.footer-inner {
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 24px;
    text-align: center;
}
.footer-inner .copy { font-size: 13px; color: #718096; }
.footer-links {
    margin-top: 12px;
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
    gap: 12px 24px;
}
.footer-links a {
    color: #CBD5E0;
    text-decoration: none;
    font-size: 13px;
    transition: color 0.2s ease, text-decoration 0.2s ease;
}
.footer-links a:hover { color: #FFFFFF; text-decoration: underline; }

/* ----- 返回頂部 ----- */
#back-to-top {
    position: fixed;
    bottom: 30px;
    right: 30px;
    background: #005A9C;
    color: white;
    border: none;
    padding: 12px 16px;
    border-radius: 50px;
    font-size: 16px;
    font-weight: bold;
    cursor: pointer;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    transition: opacity 0.3s, transform 0.3s;
    opacity: 0.7;
    z-index: 999;
}
#back-to-top:hover { opacity: 1; transform: scale(1.05); background: #003d66; }

/* ----- 響應式微調 ----- */
@media (max-width: 768px) {
    .header-inner { flex-direction: column; align-items: center; }
    .nav-links { justify-content: center; gap: 12px; }
    body { padding: 12px; }
    .content-card { padding: 16px 14px; }
    h1 { font-size: 1.6em; }
    h2 { font-size: 1.3em; }
}
"""
    
    with open(css_path, "w", encoding="utf-8") as f:
        f.write(css_content)
    
    print(f"✅ 已建立 main.css (v{CSS_VERSION})：{css_path}")
    return css_path


# ============================================================
# 🆕 Google 自訂搜尋 (CSE)
# ============================================================

GOOGLE_CSE = '''
<div class="google-search" style="max-width: 800px; margin: 20px auto; padding: 16px; background: #F7F9FC; border-radius: 12px; border: 1px solid #E2E8F0;">
    <h3 style="font-size: 16px; font-weight: 700; color: #1A202C; margin-bottom: 8px;">🔍 站內搜尋</h3>
    <p style="font-size: 13px; color: #4A5568; margin-bottom: 12px;">搜尋雅寶社區 · 頂客論壇的所有文章</p>
    <form action="https://cse.google.com/cse" target="_blank" style="display:flex; gap:8px; flex-wrap:wrap;">
        <input type="hidden" name="cx" value="940a30ae4765c4e72">
        <input type="text" name="q" placeholder="輸入關鍵字搜尋..." style="flex:1; min-width:200px; padding:10px 16px; border-radius:8px; border:1px solid #E2E8F0; font-size:14px; outline:none;">
        <button type="submit" style="padding:10px 24px; background:#005A9C; color:white; border:none; border-radius:8px; font-weight:600; cursor:pointer; white-space:nowrap;">🔍 搜尋</button>
    </form>
    <p style="font-size:12px; color:#A0AEC0; margin-top:8px;">由 Google 提供技術支援</p>
</div>
'''


# ============================================================
# 🆕 Schema.org 結構化資料
# ============================================================

def build_music_schema(keyword, video_id=None, category=None):
    """
    當文章為音樂創作時，自動嵌入 MusicRecording Schema.org 結構化資料
    """
    if category and "🎵 音樂創作" not in category:
        return ""

    url_path = f"https://www.ahpal.com/music/{keyword}.html"

    schema = f'''
<script type="application/ld+json">
{{
  "@context": "https://schema.org",
  "@type": "MusicRecording",
  "name": "{keyword}",
  "url": "{url_path}"
'''
    if video_id:
        schema += f''',
  "video": {{
    "@type": "VideoObject",
    "embedUrl": "https://www.youtube.com/embed/{video_id}"
  }}
'''
    schema += '''
}}
</script>'''
    return schema


# ============================================================
# 通用頁面元件（CSS 連結已統一）
# ============================================================

UNIFIED_CSS_LINK = '<link rel="stylesheet" href="/style/main.css">'

SITE_HEADER = '''<header class="site-header">
    <div class="header-inner">
        <a href="/" class="logo">雅寶社區 · 頂客論壇</a>
        <nav class="nav-links">
            <a href="/">首頁</a>
            <a href="/categories.html">📚 全部分類</a>
            <a href="/about.html">📖 關於我們</a>
            <a href="/contact.html">📧 聯絡我們</a>
            <a href="/privacy-policy.html">🔒 隱私權政策</a>
            <a href="/game/" class="game-link">🎮 遊戲間</a>
        </nav>
    </div>
</header>'''

SITE_FOOTER = '''<footer class="site-footer">
    <div class="footer-inner">
        <div class="copy">&copy; {year} 雅寶社區 · 頂客論壇 (AHPAL.COM)</div>
        <div class="footer-links">
            <a href="/">🏠 首頁</a>
            <a href="/categories.html">📚 全部分類</a>
            <a href="/about.html">📖 關於我們</a>
            <a href="/contact.html">📧 聯絡我們</a>
            <a href="/privacy-policy.html">🔒 隱私權政策</a>
            <a href="/terms-of-service.html">📋 服務條款</a>
            <a href="/sitemap.xml">📄 Sitemap</a>
        </div>
    </div>
</footer>

<style>
    .site-footer .footer-links {{
        margin-top: 12px;
        display: flex;
        flex-wrap: wrap;
        justify-content: center;
        gap: 12px 24px;
    }}
    .site-footer .footer-links a {{
        color: #CBD5E0;
        text-decoration: none;
        font-size: 13px;
        transition: color 0.2s ease, text-decoration 0.2s ease;
    }}
    .site-footer .footer-links a:hover {{
        color: #FFFFFF;
        text-decoration: underline;
    }}
</style>'''

BACK_TO_TOP = '''<button id="back-to-top" onclick="window.scrollTo({top: 0, behavior: 'smooth'});">⬆ TOP</button>
<style>
    #back-to-top {{
        position: fixed;
        bottom: 30px;
        right: 30px;
        background: #005A9C;
        color: white;
        border: none;
        padding: 12px 16px;
        border-radius: 50px;
        font-size: 16px;
        font-weight: bold;
        cursor: pointer;
        box-shadow: 0 4px 10px rgba(0,0,0,0.2);
        transition: opacity 0.3s, transform 0.3s;
        opacity: 0.7;
        z-index: 999;
    }}
    #back-to-top:hover {{
        opacity: 1;
        transform: scale(1.05);
        background: #003d66;
    }}
</style>'''

HOME_LINK = '<p style="text-align:center; margin:20px 0;"><a href="/" style="color:#005A9C; font-weight:500;">🏠 返回首頁</a></p>'

BRAND_LINK = '<p style="font-size:14px; color:#666; text-align:center; margin:10px 0;"><a href="/" style="color:#005A9C; text-decoration:none; font-weight:bold;">🏠 雅寶社區 · 頂客論壇 (AHPAL.COM)</a></p>'

RELATED_ARTICLES_BLOCK = '''
<div class="related-articles" style="background-color:#fff;border:1px solid #ddd;border-radius:8px;padding:20px;margin-top:50px;">
    <h4 style="margin-top:0;color:#333;border-bottom:1px solid #eee;padding-bottom:10px;">📖 相關文章推薦</h4>
    <ul style="list-style:none;padding-left:0;margin:0;">
        <li style="margin-bottom:10px;"><a href="/" style="color:#0056b3;text-decoration:none;">🏠 返回首頁瀏覽更多</a></li>
        <li style="margin-bottom:10px;"><a href="/categories.html" style="color:#0056b3;text-decoration:none;">📚 查看全部分類</a></li>
        <li style="margin-bottom:10px;"><a href="/game/" style="color:#0056b3;text-decoration:none;">🎮 雅寶遊戲間</a></li>
    </ul>
</div>
'''

ADSENSE_CODE = f'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={ADSENSE_CLIENT}" crossorigin="anonymous"></script>'
GA4_CODE = f'''<script async src="https://www.googletagmanager.com/gtag/js?id={GA4_ID}"></script>
<script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){{dataLayer.push(arguments);}}
    gtag('js', new Date());
    gtag('config', '{GA4_ID}');
</script>'''


# ============================================================
# 黃金樣板 Header 範本
# ============================================================
GOLDEN_HEADER_TEMPLATE = f'''<header>
    <div class="site-title"><a href="/" style="color:#666;text-decoration:none;">雅寶社區 · 頂客論壇 (AHPAL.COM)</a></div>
    <div style="margin-top: 15px;">
        <span class="post-category">{{category}}</span>
    </div>
    <h1>{{title}}</h1>
    <div class="meta-info">
        發表時間：{CURRENT_DATE_STR} | 更新日期：{CURRENT_DATE_STR} | 編輯：雅寶社區編輯團隊
    </div>
</header>'''


# ============================================================
# 🆕 Giscus 留言區塊 v6.9（完整載入版 — 不受正則清理影響）
# ============================================================
GISCUS_COMMENT = '''
<!-- ============================================================
     Giscus 留言系統 (v6.9 完整載入版)
     ============================================================ -->
<div class="giscus-wrapper" style="max-width: 800px; margin: 40px auto; padding: 24px; background: #F7F9FC; border-radius: 14px; border: 1px solid #E2E8F0;">
    <h3 style="font-size: 18px; font-weight: 700; color: #1A202C; margin-bottom: 16px; display: flex; align-items: center; gap: 8px;">
        💬 留言討論
    </h3>
    <p style="font-size: 14px; color: #4A5568; margin-bottom: 16px;">
        歡迎在下方留言，分享您的想法、心得或疑問。所有留言都會透過 <strong>GitHub 帳號</strong> 進行驗證。
    </p>
    <div class="giscus" 
        data-repo="praystone/ahpal-website"
        data-repo-id="R_kgDOTbvurg"
        data-category="General"
        data-category-id="DIC_kwDOTbvurs4DBhel"
        data-mapping="pathname"
        data-strict="0"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="top"
        data-theme="light"
        data-lang="zh-TW"
        data-loading="lazy">
    </div>
</div>
<script src="https://giscus.app/client.js"
    data-repo="praystone/ahpal-website"
    data-repo-id="R_kgDOTbvurg"
    data-category="General"
    data-category-id="DIC_kwDOTbvurs4DBhel"
    data-mapping="pathname"
    data-strict="0"
    data-reactions-enabled="1"
    data-emit-metadata="0"
    data-input-position="top"
    data-theme="light"
    data-lang="zh-TW"
    data-loading="lazy"
    crossorigin="anonymous"
    async>
</script>
'''


# ============================================================
# 🆕 分類 Emoji 映射（完整版 — 已修復 + Nature 支援）
# ============================================================
CATEGORY_EMOJI_MAP = {
    "💻": "💻 3C 科技教學",
    "🎮": "🎮 遊戲攻略",
    "🏠": "🏠 生活小常識",
    "📊": "📊 軟體評測",
    "🌟": "🌟 人生哲理",
    "🤖": "🤖 AI 趨勢",
    "🎵": "🎵 音樂創作",
    "📜": "📜 歷史腦洞",
    "🌳": "🌳 動植物生態",      # 🆕 新增
}


# ============================================================
# 🆕 標題提取強化函數（強化 DOCTYPE 過濾）
# ============================================================

def extract_clean_title(html_content, filename):
    """
    從 HTML 內容中提取乾淨的標題
    修復：處理空標題、HTML 標籤殘留、特殊字符、DOCTYPE
    """
    if not html_content:
        return filename.replace(".html", "").replace("-", " ").title()

    # 🆕 先移除所有 DOCTYPE 和 HTML 標籤宣告
    html_content = re.sub(r'<!DOCTYPE.*?>', '', html_content, flags=re.IGNORECASE | re.DOTALL)
    html_content = re.sub(r'<html.*?>', '', html_content, flags=re.IGNORECASE | re.DOTALL)
    html_content = re.sub(r'<head.*?>.*?</head>', '', html_content, flags=re.IGNORECASE | re.DOTALL)

    # 策略 1：從 <title> 標籤提取
    title_match = re.search(r'<title>(.*?)</title>', html_content, re.IGNORECASE | re.DOTALL)
    if title_match:
        title = title_match.group(1).strip()
        title = re.sub(r'\s*[—\-|]\s*雅寶社區\s*[·.]?\s*頂客論壇.*$', '', title)
        title = re.sub(r'<[^>]+>', '', title)
        title = re.sub(r'<!DOCTYPE.*?>', '', title, flags=re.IGNORECASE)
        title = re.sub(r'<html.*?>', '', title, flags=re.IGNORECASE)
        title = title.strip()
        if title:
            return title

    # 策略 2：從 <h1> 標籤提取
    h1_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.IGNORECASE | re.DOTALL)
    if h1_match:
        title = h1_match.group(1).strip()
        title = re.sub(r'<[^>]+>', '', title)
        title = re.sub(r'<!DOCTYPE.*?>', '', title, flags=re.IGNORECASE)
        title = title.strip()
        if title and len(title) > 3:
            return title

    # 策略 3：從第一個 <p> 提取（備案）
    p_match = re.search(r'<p>(.*?)</p>', html_content, re.IGNORECASE | re.DOTALL)
    if p_match:
        title = p_match.group(1).strip()
        title = re.sub(r'<[^>]+>', '', title)
        title = title[:60]
        if title and len(title) > 5:
            return title

    # 策略 4：使用 filename 作為最終備案
    return filename.replace(".html", "").replace("-", " ").title()


# ============================================================
# 清理 AI 頁頂註解文字
# ============================================================

def clean_ai_header(html_content):
    if not html_content:
        return html_content

    if html_content.lstrip().startswith("<!DOCTYPE html") or html_content.lstrip().startswith("<html"):
        return html_content

    doctype_match = re.search(r'<!DOCTYPE html>|<html', html_content, re.IGNORECASE)
    if doctype_match:
        cleaned = html_content[doctype_match.start():]
        print("   🔧 已自動清理頁頂註解文字")
        return cleaned

    head_match = re.search(r'<head[^>]*>|<body[^>]*>', html_content, re.IGNORECASE)
    if head_match:
        cleaned = html_content[head_match.start():]
        print("   🔧 已自動清理頁頂註解文字（從 head/body 開始）")
        return cleaned

    return html_content


# ============================================================
# 🆕 分類提取輔助函數
# ============================================================

def extract_category_from_content(html_content):
    """
    從文章內容中提取分類
    優先從 emoji 映射，否則從關鍵字判斷
    """
    # 方法 1：從 post-category 標籤提取
    category_match = re.search(r'<span[^>]*class=[\'"]?post-category[\'"]?[^>]*>(.*?)</span>', html_content, re.IGNORECASE | re.DOTALL)
    if category_match:
        return category_match.group(1).strip()

    # 方法 2：從 emoji 映射
    for emoji, cat_name in CATEGORY_EMOJI_MAP.items():
        if emoji in html_content:
            return cat_name

    # 方法 3：從關鍵字判斷
    if "音樂" in html_content or "歌曲" in html_content or "歌詞" in html_content:
        return "🎵 音樂創作"
    if "AI" in html_content or "人工智慧" in html_content:
        return "🤖 AI 趨勢"
    if "遊戲" in html_content:
        return "🎮 遊戲攻略"
    if "科技" in html_content or "3C" in html_content or "手機" in html_content:
        return "💻 3C 科技教學"
    if "生活" in html_content or "居家" in html_content or "收納" in html_content:
        return "🏠 生活小常識"
    if "評測" in html_content or "比較" in html_content or "軟體" in html_content:
        return "📊 軟體評測"
    if "人生" in html_content or "哲理" in html_content or "成長" in html_content:
        return "🌟 人生哲理"
    if "動物" in html_content or "植物" in html_content or "生態" in html_content:
        return "🌳 動植物生態"      # 🆕 新增

    return "🌟 人生哲理"  # 預設


# ============================================================
# 🆕 文章 HTML 增強（核心功能 + Giscus + 統一 CSS + Schema）
# ============================================================

def enhance_article_html(html_content, keyword=None, category=None, video_id=None):
    """
    增強文章 HTML：強制加入品牌標示、首頁連結、TOP按鈕、相關文章推薦、統一CSS、黃金Header、Giscus留言、Schema.org

    🆕 v7.0：不再自動生成 CSS，僅連結現有 CSS
    """
    if not html_content:
        return html_content

    # 清理 AI 頁頂註解
    html_content = clean_ai_header(html_content)

    # ============================================================
    # 0. 在 <head> 中插入統一 CSS 連結（移除內嵌樣式）
    #    🆕 v7.0：不再自動生成 CSS，僅檢查是否存在
    # ============================================================
    html_content = re.sub(r'<style>.*?</style>', '', html_content, flags=re.IGNORECASE | re.DOTALL)
    html_content = re.sub(r'<link[^>]*main\.css[^>]*>', '', html_content, flags=re.IGNORECASE)

    # 🆕 v7.0：檢查 CSS 是否存在，不存在則警告
    css_path = Path(OUTPUT_DIR) / "style" / "main.css"
    if not css_path.exists():
        print(f"   ⚠️ main.css 不存在！請手動建立 style/main.css")
        print(f"   📌 執行 generate_main_css() 可建立初始版本")

    if '<head>' in html_content:
        if 'main.css' not in html_content:
            html_content = html_content.replace('<head>', '<head>\n    ' + UNIFIED_CSS_LINK)
            print("   ✅ 已加入統一 CSS 連結")
    else:
        html_content = UNIFIED_CSS_LINK + '\n' + html_content

    # ============================================================
    # 0.5 🆕 嵌入 Schema.org 結構化資料（音樂文章）
    # ============================================================
    if keyword and category and "🎵 音樂創作" in category:
        schema = build_music_schema(keyword, video_id, category)
        if schema:
            html_content = html_content.replace('</head>', schema + '\n</head>')
            print("   ✅ 已嵌入 MusicRecording Schema.org")

    # ============================================================
    # 1. 提取標題與分類（優先使用傳入參數）
    # ============================================================
    if keyword and len(keyword.strip()) > 0:
        title = keyword.strip()
    else:
        title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.IGNORECASE | re.DOTALL)
        if title_match:
            raw_title = title_match.group(1).strip()
            title = re.sub(r'\s*[—\-|]\s*雅寶社區\s*[·.]?\s*頂客論壇.*$', '', raw_title)
            title = re.sub(r'<[^>]+>', '', title)
            title = re.sub(r'<!DOCTYPE.*?>', '', title, flags=re.IGNORECASE)
            title = title.strip()
        else:
            title = "文章標題"

    if category:
        final_category = category
    else:
        final_category = extract_category_from_content(html_content)

    # ============================================================
    # 2. 移除原有的 <h1> 標籤（避免重複）
    # ============================================================
    html_content = re.sub(r'<h1[^>]*>.*?</h1>', '', html_content, flags=re.IGNORECASE | re.DOTALL)
    html_content = re.sub(r'<header>.*?</header>', '', html_content, flags=re.IGNORECASE | re.DOTALL)

    # ============================================================
    # 3. 強制插入黃金樣板 Header
    # ============================================================
    golden_header = GOLDEN_HEADER_TEMPLATE.replace('{title}', title).replace('{category}', final_category)

    if '<body>' in html_content:
        html_content = html_content.replace('<body>', '<body>\n' + golden_header)
        print(f"   ✅ 已插入黃金樣板 Header（標題：{title[:30]}...）")
    else:
        html_content = golden_header + '\n' + html_content
        print("   ✅ 已插入黃金樣板 Header")

    # ============================================================
    # 4. 品牌標示（避免重複）
    # ============================================================
    if '<body>' in html_content:
        if '雅寶社區 · 頂客論壇 (AHPAL.COM)' not in html_content or '<a href="/"' not in html_content:
            html_content = html_content.replace('<body>', '<body>\n' + BRAND_LINK)
            print("   ✅ 已強制加入品牌標示（可點擊回首頁）")
    else:
        html_content = BRAND_LINK + '\n' + html_content
        print("   ✅ 已強制加入品牌標示（可點擊回首頁）")

    # ============================================================
    # 5. 🆕 v7.0：強制加入相關文章推薦 + Giscus + 返回首頁 + 返回頂部
    # ============================================================
    # 移除相關文章區塊（保留 Giscus 不清理）
    html_content = re.sub(r'<div class="related-articles".*?</div>', '', html_content, flags=re.IGNORECASE | re.DOTALL)

    # 檢查是否已有 Giscus（避免重複插入）
    if 'giscus-wrapper' not in html_content and 'giscus.app/client.js' not in html_content:
        footer_components = RELATED_ARTICLES_BLOCK + '\n' + GISCUS_COMMENT + '\n' + HOME_LINK + '\n' + BACK_TO_TOP

        if '</body>' in html_content:
            html_content = html_content.replace('</body>', footer_components + '\n</body>')
            print("   ✅ [v7.0] 已強制插入 Giscus 留言板與頁尾元件")
        else:
            html_content = html_content + '\n' + footer_components
            print("   ✅ [v7.0] 已強制插入頁尾元件（無 </body> 標籤）")
    else:
        print("   ℹ️ [v7.0] Giscus 已存在，跳過插入")

    # ============================================================
    # 6. 確保 AdSense 程式碼存在
    # ============================================================
    if 'pagead2.googlesyndication.com' not in html_content:
        html_content = html_content.replace('</head>', ADSENSE_CODE + '\n' + GA4_CODE + '\n</head>')
        print("   ✅ 已加入 AdSense 程式碼")

    return html_content


# ============================================================
# 建構文章 HTML（對外介面）
# ============================================================

def build_article_html(keyword, category, raw_html, video_id=None):
    """建構完整品牌 HTML，支援傳入 video_id 以嵌入 Schema.org"""
    return enhance_article_html(raw_html, keyword=keyword, category=category, video_id=video_id)


# ============================================================
# 🆕 建構首頁（v7.4 — Emoji 修復 + Nature 支援）
# ============================================================

def create_default_index():
    """建立完整功能的首頁 index.html（完整版 — 含品牌介紹、分類索引、熱門文章）"""
    print("📄 建立全新首頁 index.html...")

    # 🆕 v7.0：僅檢查 CSS 是否存在，不自動生成
    css_path = Path(OUTPUT_DIR) / "style" / "main.css"
    if not css_path.exists():
        print(f"   ⚠️ main.css 不存在！請手動建立 style/main.css")

    category_dirs = {
        "history": "📜 歷史腦洞",
        "tech": "💻 3C 科技教學",
        "game": "🎮 遊戲攻略",
        "life": "🏠 生活小常識",
        "review": "📊 軟體評測",
        "philosophy": "🌟 人生哲理",
        "trend": "🤖 AI 趨勢",
        "music": "🎵 音樂創作",
        "nature": "🌳 動植物生態",      # 🆕 新增
    }

    EXCLUDED_FILES = [
        "index.html", "404.html", "memorial.html",
        "royal_dragon_karma.html", "search-results.html",
        "categories.html", "index111.html", "test.html"
    ]

    EXCLUDED_DIRS = [
        "docs", "backups", "logs", "images",
        "scripts", "src", "data", "test", "__pycache__",
        "ahpal-AI-archive", "ahpal-backup"
    ]

    # 計算各分類文章數量
    article_counts = {}
    for cat_dir in category_dirs.keys():
        dir_path = os.path.join(OUTPUT_DIR, cat_dir)
        if os.path.exists(dir_path):
            count = len([f for f in os.listdir(dir_path) if f.endswith('.html')])
            article_counts[cat_dir] = count
        else:
            article_counts[cat_dir] = 0

    total_count = sum(article_counts.values())

    # 掃描所有文章
    all_articles = []
    for root, dirs, files in os.walk(OUTPUT_DIR):
        rel_path = os.path.relpath(root, OUTPUT_DIR)
        should_skip = False
        for excluded in EXCLUDED_DIRS:
            if rel_path == excluded or rel_path.startswith(excluded + os.sep):
                should_skip = True
                break
        if should_skip:
            continue

        for f in files:
            if f.endswith(".html") and f not in EXCLUDED_FILES:
                if not f.startswith("category-"):
                    rel_path_file = os.path.relpath(os.path.join(root, f), OUTPUT_DIR)
                    rel_path_file = rel_path_file.replace('\\', '/')

                    cat_key = "其他"
                    for cat_dir, cat_name in category_dirs.items():
                        if rel_path_file.startswith(cat_dir + "/"):
                            cat_key = cat_name
                            break

                    file_path = os.path.join(root, f)
                    try:
                        with open(file_path, "r", encoding="utf-8") as file:
                            content = file.read()
                            title = extract_clean_title(content, f)
                    except Exception as e:
                        print(f"   ⚠️ 讀取文章失敗：{f} - {e}")
                        title = f.replace(".html", "").replace("-", " ").title()

                    mtime = os.path.getmtime(file_path)
                    all_articles.append({
                        "filename": rel_path_file,
                        "title": title,
                        "category": cat_key,
                        "mtime": mtime
                    })

    all_articles.sort(key=lambda x: x["mtime"], reverse=True)
    latest_articles = all_articles[:31]

    category_articles = {}
    for cat_dir in category_dirs.keys():
        cat_articles = [a for a in all_articles if a["filename"].startswith(cat_dir + "/")]
        category_articles[cat_dir] = cat_articles

    # 建立首頁 HTML
    index_html = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>雅寶社區 · 頂客論壇 | AHPAL.COM</title>
    <meta name="description" content="雅寶社區 · 頂客論壇 — 提供 3C 科技教學、遊戲攻略、生活小常識、軟體評測、人生哲理與 AI 趨勢，超過 200 篇精選文章。">
    <meta name="keywords" content="科技教學,遊戲攻略,生活小常識,軟體評測,人生哲理,AI趨勢,音樂創作">
    {ADSENSE_CODE}
    {GA4_CODE}
    {UNIFIED_CSS_LINK}
</head>
<body>
    {SITE_HEADER}

    <div class="main-wrapper">
        <div class="main-content">
            <div class="container">
                <div class="content-card">
                    <h1 class="hero-title">雅寶社區 <span class="highlight">·</span> 頂客論壇</h1>
                    <p class="hero-sub">歲月 · 知識 · 共創</p>
                    <p class="hero-desc">
                        這裡記錄了 <strong>頂客論壇</strong> 二十多年的歲月迴聲，
                        並以 AI 精選 <strong>科技、遊戲、生活、軟體、哲理、AI 趨勢、音樂創作、歷史腦洞</strong> 八大領域的實用內容。
                        從數位工具到人生成長，每一篇文章都經過編輯策展，為讀者提供真正有價值的資訊。
                    </p>

                    <div class="category-grid">
'''
    for cat_dir, cat_name in category_dirs.items():
        count = article_counts.get(cat_dir, 0)
        icon = cat_name.split()[0] if cat_name else "📁"
        index_html += f'''                        <a href="/category-{cat_dir}.html" class="category-card">
                            <span class="icon">{icon}</span>
                            <span class="name">{cat_name}</span>
                            <span class="count">{count} 篇</span>
                        </a>
'''

    index_html += f'''                </div>

                    <a href="/game/" class="game-entry-card">
                        <span class="emoji">🎮</span>
                        <span class="title">雅寶遊戲間</span>
                        <span class="desc">閱讀之餘，放鬆一下！2048、數獨，免下載即開即玩</span>
                        <span class="badge">🎯 立即遊玩 →</span>
                    </a>

                    <h2 class="section-title">📌 最新文章 <small>持續更新中</small></h2>
                    <ul id="article-list">
'''

    for article in latest_articles:
        safe_title = article['title'].replace('"', '&quot;').replace('<', '&lt;').replace('>', '&gt;')
        date = datetime.fromtimestamp(article['mtime']).strftime('%Y-%m-%d')
        index_html += f'''                        <li><span class="category">{article['category']}</span><a href="/{article['filename']}">{safe_title}</a><span class="post-date">{date}</span></li>
'''

    index_html += f'''                    </ul>

                    <div class="index-section">
                        <h2 class="section-title">📖 全部分類索引 <small>共 {total_count} 篇文章</small></h2>
'''

    for cat_dir, cat_name in category_dirs.items():
        cat_articles = category_articles.get(cat_dir, [])[:20]
        index_html += f'''
                        <div class="cat-title">{cat_name} <span class="count">({article_counts.get(cat_dir, 0)}篇)</span></div>
                        <div class="index-tag-grid" id="tag-{cat_dir}">
'''
        for article in cat_articles[:15]:
            title = article['title'][:30] + '...' if len(article['title']) > 30 else article['title']
            index_html += f'                            <a href="/{article["filename"]}" class="index-tag">{title}</a>\n'
        if len(cat_articles) > 15:
            index_html += f'                            <span class="index-tag" style="background:#e2e8f0;color:#4a5568;">+{len(cat_articles)-15} 篇</span>\n'
        index_html += '                        </div>\n'

    index_html += f'''                    </div>

                    <p style="text-align:center; margin-top:20px;"><a href="/categories.html" style="color:#005A9C; font-weight:500;">📚 查看全部分類</a></p>
                </div>
                {GOOGLE_CSE}
            </div>
        </div>

        <div class="sidebar">
            <div class="widget">
                <h3>⚖️ 關於本站</h3>
                <p>雅寶社區 · 頂客論壇 (AHPAL.COM) 致力於提供高品質的生活、科技、遊戲與理財資訊。從歲月記憶到知識共創，我們相信：<strong>誠實守信，是文明社會永恆的基石。</strong></p>
                <p style="margin-top:8px;"><a href="/about.html" style="color:#005A9C;font-weight:500;">📖 了解更多 →</a></p>
            </div>

            <div class="widget">
                <h3>🎮 雅寶遊戲間</h3>
                <p style="font-size:13px; margin-bottom:12px;">閱讀之餘，放鬆一下！免下載、即開即玩。</p>
                <a href="/game/" style="display:inline-block; background:#005A9C; color:white; padding:8px 20px; border-radius:20px; text-decoration:none; font-size:14px; font-weight:500;">🎮 進入遊戲間</a>
            </div>

            <div class="widget">
                <h3>🔥 熱門文章</h3>
                <ul>
                    <li><a href="/tech/best-gaming-laptops-2026.html">2026 年 5 款最強電競筆電推薦與評測</a></li>
                    <li><a href="/game/best-indie-games-2026.html">2026 最夯 5 款獨立遊戲推薦</a></li>
                    <li><a href="/life/smart-home-guide-2026.html">2026 年居家智慧裝置選購指南</a></li>
                    <li><a href="/review/best-ai-presentation-tools-2026.html">2026 年 5 款最佳 AI 簡報生成工具評測</a></li>
                    <li><a href="/trend/ai-agent-trends-2026.html">2026 年 AI 代理人趨勢全解析</a></li>
                </ul>
            </div>

            <div class="widget">
                <h3>🏷️ 分類標籤</h3>
                <div class="tag-cloud">
                    <a href="/category-tech.html">💻 3C</a>
                    <a href="/category-game.html">🎮 遊戲</a>
                    <a href="/category-life.html">🏠 生活</a>
                    <a href="/category-review.html">📊 評測</a>
                    <a href="/category-philosophy.html">🌟 哲理</a>
                    <a href="/category-trend.html">🤖 AI</a>
                    <a href="/category-music.html">🎵 音樂</a>
                    <a href="/category-history.html">📜 歷史</a>
                    <a href="/category-nature.html">🌳 動植物</a>      <!-- 🆕 新增 -->
                    <a href="/game/">🎮 遊戲間</a>
                    <a href="/categories.html">📚 全部分類</a>
                    <a href="/about.html">📖 關於我們</a>
                    <a href="/contact.html">📧 聯絡我們</a>
                </div>
            </div>
        </div>
    </div>

    {SITE_FOOTER.format(year=CURRENT_YEAR)}
    {BACK_TO_TOP}
</body>
</html>
'''

    index_path = Path(OUTPUT_DIR) / "index.html"
    with open(index_path, "w", encoding="utf-8") as f:
        f.write(index_html)

    print(f"✅ 首頁已建立：{index_path} (共 {len(latest_articles)} 篇文章)")
    return index_path


# ============================================================
# 建構分類入口頁（v7.2 — Emoji 修復版）
# ============================================================

def generate_categories_page():
    """建立完整的分類入口頁 categories.html"""
    print("📄 建立統一分類入口頁 categories.html...")

    css_path = Path(OUTPUT_DIR) / "style" / "main.css"
    if not css_path.exists():
        print(f"   ⚠️ main.css 不存在！請手動建立 style/main.css")

    from src.config import CATEGORIES as CATEGORIES_CONFIG

    html_content = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📚 全部分類 - 雅寶社區 · 頂客論壇</title>
    <meta name="description" content="雅寶社區 · 頂客論壇 — 八大知識分類總覽。">
    {ADSENSE_CODE}
    {GA4_CODE}
    {UNIFIED_CSS_LINK}
</head>
<body>
    {SITE_HEADER}

    <div class="main-wrapper">
        <div class="main-content">
            <div class="container">
                <div class="content-card">
                    <h1>📚 全部分類</h1>
                    <p class="hero-desc" style="font-size:15px; color:#4A5568; margin-bottom:20px;">八大知識領域，超過 600 篇精選文章，讓你一次掌握。</p>
                    <div class="category-grid" style="grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));">
'''

    for cat_id, cat_info in CATEGORIES_CONFIG.items():
        dir_path = os.path.join(OUTPUT_DIR, cat_id)
        count = 0
        if os.path.exists(dir_path):
            count = len([f for f in os.listdir(dir_path) if f.endswith('.html')])
        icon = cat_info['name'].split()[0] if cat_info['name'] else "📁"
        html_content += f'''
                        <a href="/category-{cat_id}.html" class="category-card">
                            <span class="icon">{icon}</span>
                            <span class="name">{cat_info['name']}</span>
                            <span class="count">{count} 篇文章</span>
                            <span style="font-size:12px; color:#718096; margin-top:4px; display:block;">{cat_info['desc']}</span>
                        </a>
'''

    html_content += f'''                    </div>
                    <p style="text-align:center; margin-top:20px;"><a href="/" style="color:#005A9C; font-weight:500;">🏠 返回首頁</a></p>
                </div>
            </div>
        </div>
        <div class="sidebar">
            <div class="widget">
                <h3>📊 本站統計</h3>
                <ul>
                    <li>📝 文章總數：{sum(1 for _ in Path(OUTPUT_DIR).rglob('*.html') if _.name not in ['index.html','404.html','categories.html'])} 篇</li>
                    <li>📂 分類數量：{len(CATEGORIES_CONFIG)} 類</li>
                    <li>📅 更新日期：{CURRENT_DATE_STR}</li>
                </ul>
            </div>
        </div>
    </div>

    {SITE_FOOTER.format(year=CURRENT_YEAR)}
    {BACK_TO_TOP}
</body>
</html>
'''

    with open(os.path.join(OUTPUT_DIR, "categories.html"), "w", encoding="utf-8") as f:
        f.write(html_content)
    print("✅ 統一分類入口頁 categories.html 建立完成！")


# ============================================================
# 生成各分類獨立頁面（v7.2 — Emoji 修復版）
# ============================================================

def generate_category_pages():
    """生成各分類的獨立頁面（與原 ahpal_generator.py 相容）"""
    print("📄 正在生成分類頁面...")

    from src.config import CATEGORIES as CATEGORIES_CONFIG

    css_path = Path(OUTPUT_DIR) / "style" / "main.css"
    if not css_path.exists():
        print(f"   ⚠️ main.css 不存在！請手動建立 style/main.css")

    for cat_id, cat_info in CATEGORIES_CONFIG.items():
        page_path = os.path.join(OUTPUT_DIR, f"category-{cat_id}.html")

        dir_path = os.path.join(OUTPUT_DIR, cat_id)
articles = []
if os.path.exists(dir_path):
    for f in os.listdir(dir_path):
        if f.endswith('.html'):
            file_path = os.path.join(dir_path, f)
            try:
                with open(file_path, "r", encoding="utf-8") as file:
                    content = file.read()
                    title = extract_clean_title(content, f)
            except:
                title = f.replace(".html", "").replace("-", " ").title()
            # 🆕 取得檔案修改時間
            mtime = os.path.getmtime(file_path)
            articles.append({"filename": f"{cat_id}/{f}", "title": title, "mtime": mtime})

# 🆕 依照修改時間降冪排列（最新的在前）
articles.sort(key=lambda x: x.get("mtime", 0), reverse=True)

        html_content = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{cat_info['name']} - 雅寶社區 · 頂客論壇</title>
    <meta name="description" content="{cat_info['desc']} - 雅寶社區 · 頂客論壇">
    {ADSENSE_CODE}
    {GA4_CODE}
    {UNIFIED_CSS_LINK}
</head>
<body>
    {SITE_HEADER}

    <div class="main-wrapper">
        <div class="main-content">
            <div class="container">
                <div class="content-card">
                    <h1>{cat_info['name']}</h1>
                    <p class="hero-desc" style="font-size:15px; color:#4A5568;">{cat_info['desc']}</p>
                    <p style="font-size:14px; color:#718096; margin-bottom:16px;">共 {len(articles)} 篇文章</p>

                    <h2>📖 全部文章</h2>
                    <ul id="article-list">
'''

        if articles:
            for article in articles:
                html_content += f'                        <li><a href="/{article["filename"]}">{article["title"]}</a></li>\n'
        else:
            html_content += '                        <li style="color:#718096;">目前尚無文章，敬請期待！</li>\n'

        html_content += f'''                    </ul>
                    <p style="text-align:center; margin-top:20px;"><a href="/" style="color:#005A9C; font-weight:500;">🏠 返回首頁</a></p>
                </div>
            </div>
        </div>
        <div class="sidebar">
            <div class="widget">
                <h3>📂 全部分類</h3>
                <ul>
'''

        for cid, cinfo in CATEGORIES_CONFIG.items():
            html_content += f'                    <li><a href="/category-{cid}.html">{cinfo["name"]}</a></li>\n'

        html_content += f'''                </ul>
            </div>
        </div>
    </div>

    {SITE_FOOTER.format(year=CURRENT_YEAR)}
    {BACK_TO_TOP}
</body>
</html>
'''
        with open(page_path, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"   ✅ 生成分類頁面：category-{cat_id}.html（{len(articles)} 篇文章）")

    print("✅ 所有分類頁面生成完畢！")