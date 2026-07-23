# ============================================================
# html_builder.py - HTML 建構模組 v4.4 (最終除錯版)
# ============================================================
# 功能：建構所有 HTML（首頁、分類頁、文章頁面）
# 修正：統一頁頂品牌標示為可點擊超連結
# 修復：導覽列加入隱私權政策連結
# 修復：底部導航連結顏色修正（#CBD5E0 → hover #FFFFFF）
# 修復：SITE_FOOTER 和 BACK_TO_TOP 花括號轉義（避免 .format() 衝突）
# ============================================================

# ============================================================
# 增量構建 - MD5 比對
# ============================================================

import hashlib
import json
from pathlib import Path

# 狀態檔案路徑
STATE_FILE = Path(__file__).parent.parent / "build-state.json"

def get_file_hash(filepath):
    """計算檔案的 MD5 雜湊值"""
    if not Path(filepath).exists():
        return None
    with open(filepath, 'rb') as f:
        return hashlib.md5(f.read()).hexdigest()

def load_build_state():
    """載入上次構建狀態"""
    if STATE_FILE.exists():
        with open(STATE_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {"files": {}}

def save_build_state(state):
    """儲存構建狀態"""
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

def needs_rebuild(filepath, current_hash):
    """檢查檔案是否需要重新構建"""
    state = load_build_state()
    file_key = str(filepath).replace("\\", "/")
    previous_hash = state["files"].get(file_key)
    return previous_hash != current_hash

def mark_built(filepath, hash_value):
    """標記檔案已構建"""
    state = load_build_state()
    file_key = str(filepath).replace("\\", "/")
    state["files"][file_key] = hash_value
    save_build_state(state)


import os
import re
from datetime import datetime
from src.config import (
    OUTPUT_DIR, ADSENSE_CLIENT, GA4_ID,
    CATEGORIES, CURRENT_YEAR, CURRENT_DATE_STR
)

# ============================================================
# 通用頁面元件
# ============================================================

# 頁頂品牌標示（統一為可點擊超連結）
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

# 頁尾（已修正底部導航連結顏色）- 使用雙花括號轉義 CSS
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

# 返回頂部按鈕 - 使用雙花括號轉義 CSS
BACK_TO_TOP = '''<button id="back-to-top" onclick="window.scrollTo({{top: 0, behavior: 'smooth'}});">⬆ TOP</button>
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

# 返回首頁連結（頁尾用）
HOME_LINK = '<p style="text-align:center; margin:20px 0;"><a href="/" style="color:#005A9C; font-weight:500;">🏠 返回首頁</a></p>'

# 品牌標示（頁頂用，可點擊）
BRAND_LINK = '<p style="font-size:14px; color:#666; text-align:center; margin:10px 0;"><a href="/" style="color:#005A9C; text-decoration:none; font-weight:bold;">🏠 雅寶社區 · 頂客論壇 (AHPAL.COM)</a></p>'

# AdSense 程式碼
ADSENSE_CODE = f'<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={ADSENSE_CLIENT}" crossorigin="anonymous"></script>'

# GA4 程式碼
GA4_CODE = f'''<script async src="https://www.googletagmanager.com/gtag/js?id={GA4_ID}"></script>
<script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){{dataLayer.push(arguments);}}
    gtag('js', new Date());
    gtag('config', '{GA4_ID}');
</script>'''

# ============================================================
# 清理 AI 頁頂註解文字
# ============================================================

def clean_ai_header(html_content):
    """移除 AI 在頁頂留下的對話註解文字"""
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
# 文章 HTML 增強（統一加入品牌、首頁連結、TOP按鈕）
# ============================================================

def enhance_article_html(html_content):
    """增強文章 HTML：加入品牌標示、首頁連結、TOP按鈕"""
    if not html_content:
        return html_content
    
    # 清理 AI 頁頂註解
    html_content = clean_ai_header(html_content)
    
    # 1. 確保 <body> 開頭有品牌標示（可點擊的超連結）
    if '雅寶社區 · 頂客論壇' not in html_content:
        # 在 <body> 後插入品牌標示
        html_content = html_content.replace('<body>', '<body>\n' + BRAND_LINK)
        print("   ✅ 已加入品牌標示（可點擊回首頁）")
    
    # 2. 確保頁尾有「返回首頁」連結（雙重保障）
    if '返回首頁' not in html_content or 'ahpal.com' not in html_content:
        html_content = html_content.replace('</body>', HOME_LINK + '\n' + BACK_TO_TOP + '\n</body>')
        print("   ✅ 已加入返回首頁連結")
    else:
        # 即使已有，也確保 BACK_TO_TOP 存在
        if 'back-to-top' not in html_content:
            html_content = html_content.replace('</body>', BACK_TO_TOP + '\n</body>')
            print("   ✅ 已加入返回頂部按鈕")
    
    # 3. 確保 AdSense 程式碼存在
    if 'pagead2.googlesyndication.com' not in html_content:
        html_content = html_content.replace('</head>', ADSENSE_CODE + '\n' + GA4_CODE + '\n</head>')
        print("   ✅ 已加入 AdSense 程式碼")
    
    return html_content

# ============================================================
# 建構文章 HTML（對外介面）
# ============================================================

def build_article_html(keyword, category, raw_html):
    """建構完整的文章 HTML（對外介面）"""
    return enhance_article_html(raw_html)

# ============================================================
# 建構首頁
# ============================================================

def create_default_index():
    """建立完整功能的首頁 index.html"""
    print("📄 建立全新首頁 index.html...")
    
    article_counts = {}
    category_dirs = {
        "tech": "💻 3C 科技教學",
        "game": "🎮 遊戲攻略",
        "life": "🏠 生活小常識",
        "review": "📊 軟體評測",
        "philosophy": "🌟 人生哲理",
        "trend": "🤖 AI 趨勢"
    }
    
    for cat_dir in category_dirs.keys():
        dir_path = os.path.join(OUTPUT_DIR, cat_dir)
        if os.path.exists(dir_path):
            count = len([f for f in os.listdir(dir_path) if f.endswith('.html')])
            article_counts[cat_dir] = count
        else:
            article_counts[cat_dir] = 0
    
    total_count = sum(article_counts.values())
    
    all_articles = []
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith(".html") and f not in ["index.html", "404.html", "memorial.html", "royal_dragon_karma.html", "search-results.html", "categories.html"]:
                if not f.startswith("category-"):
                    rel_path = os.path.relpath(os.path.join(root, f), OUTPUT_DIR)
                    cat_key = "其他"
                    for cat_dir, cat_name in category_dirs.items():
                        if rel_path.startswith(cat_dir + "/"):
                            cat_key = cat_name
                            break
                    try:
                        with open(os.path.join(root, f), "r", encoding="utf-8") as file:
                            content = file.read()
                            title_match = re.search(r'<title>(.*?)</title>', content, re.IGNORECASE)
                            title = title_match.group(1) if title_match else f.replace(".html", "")
                            title = re.sub(r'\s*[—\-|]\s*雅寶社區\s*[·.]?\s*頂客論壇.*$', '', title)
                    except:
                        title = f.replace(".html", "")
                    mtime = os.path.getmtime(os.path.join(root, f))
                    all_articles.append({
                        "filename": rel_path,
                        "title": title,
                        "category": cat_key,
                        "mtime": mtime
                    })
    
    all_articles.sort(key=lambda x: x["mtime"], reverse=True)
    latest_articles = all_articles[:30]
    
    category_articles = {}
    for cat_dir in category_dirs.keys():
        cat_articles = [a for a in all_articles if a["filename"].startswith(cat_dir + "/")]
        category_articles[cat_dir] = cat_articles
    
    html_content = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>雅寶社區 · 頂客論壇 | AHPAL.COM</title>
    <meta name="description" content="雅寶社區 · 頂客論壇 — 提供 3C 科技教學、遊戲攻略、生活小常識、軟體評測、人生哲理與 AI 趨勢，超過 200 篇精選文章。">
    <meta name="keywords" content="科技教學,遊戲攻略,生活小常識,軟體評測,人生哲理,AI趨勢">
    {ADSENSE_CODE}
    {GA4_CODE}
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif; background: #F7F9FC; color: #1A202C; line-height: 1.8; font-size: 16px; }}
        .site-header {{ background: #005A9C; color: white; padding: 12px 0; position: sticky; top: 0; z-index: 50; }}
        .header-inner {{ max-width: 1200px; margin: 0 auto; padding: 0 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; }}
        .logo {{ font-size: 20px; font-weight: 700; color: white; text-decoration: none; letter-spacing: 0.5px; }}
        .logo:hover {{ color: rgba(255,255,255,0.85); }}
        .nav-links {{ display: flex; gap: 20px; font-size: 14px; align-items: center; flex-wrap: wrap; }}
        .nav-links a {{ color: rgba(255,255,255,0.85); text-decoration: none; }}
        .nav-links a:hover {{ color: white; border-bottom: 2px solid #00A86B; }}
        .nav-links .game-link {{ background: rgba(255,255,255,0.15); padding: 4px 14px; border-radius: 20px; font-weight: 500; }}
        .nav-links .game-link:hover {{ background: rgba(255,255,255,0.25); border-bottom: none; }}
        .main-wrapper {{ max-width: 1200px; margin: 28px auto; padding: 0 24px; display: grid; grid-template-columns: 1fr 300px; gap: 30px; align-items: start; }}
        @media (max-width: 992px) {{ .main-wrapper {{ grid-template-columns: 1fr; }} }}
        .content-card {{ background: white; padding: 36px 40px; border-radius: 14px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); }}
        @media (max-width: 640px) {{ .content-card {{ padding: 24px 18px; }} }}
        .hero-title {{ font-size: 30px; font-weight: 700; color: #1A202C; margin-bottom: 2px; line-height: 1.3; }}
        .hero-title .highlight {{ color: #00A86B; }}
        .hero-sub {{ font-size: 14px; color: #718096; letter-spacing: 2px; margin-bottom: 12px; font-weight: 300; }}
        .hero-desc {{ font-size: 15px; color: #4A5568; line-height: 1.9; }}
        .category-grid {{ display: grid; grid-template-columns: repeat(6, 1fr); gap: 14px; margin: 28px 0 32px 0; }}
        @media (max-width: 768px) {{ .category-grid {{ grid-template-columns: repeat(3, 1fr); }} }}
        @media (max-width: 480px) {{ .category-grid {{ grid-template-columns: repeat(2, 1fr); }} }}
        .category-card {{ display: block; background: #F7F9FC; padding: 18px 12px; border-radius: 14px; text-decoration: none; text-align: center; border: 1px solid #E2E8F0; transition: all 0.25s ease; }}
        .category-card:hover {{ transform: translateY(-4px); box-shadow: 0 8px 25px rgba(0,0,0,0.10); border-color: #00A86B; }}
        .category-card .emoji {{ font-size: 28px; display: block; margin-bottom: 4px; }}
        .category-card .cat-name {{ font-size: 13px; font-weight: 600; color: #1A202C; }}
        .category-card .cat-count {{ font-size: 11px; color: #718096; display: block; margin-top: 2px; }}
        .game-entry-card {{ display: block; background: linear-gradient(135deg, #005A9C 0%, #003d66 100%); color: white; padding: 20px 16px; border-radius: 14px; text-decoration: none; text-align: center; margin: 20px 0 32px 0; }}
        .game-entry-card:hover {{ transform: translateY(-4px); box-shadow: 0 8px 25px rgba(0,0,0,0.10); }}
        .game-entry-card .emoji {{ font-size: 36px; display: block; margin-bottom: 6px; }}
        .game-entry-card .title {{ font-size: 18px; font-weight: 700; }}
        .game-entry-card .desc {{ font-size: 13px; opacity: 0.8; margin-top: 2px; }}
        .game-entry-card .badge {{ display: inline-block; background: rgba(255,255,255,0.2); padding: 2px 14px; border-radius: 20px; font-size: 11px; margin-top: 6px; }}
        .section-title {{ font-size: 20px; font-weight: 700; color: #1A202C; margin: 0 0 16px 0; }}
        .section-title small {{ font-weight: 400; font-size: 14px; color: #718096; margin-left: 10px; }}
        #article-list {{ list-style: none; padding: 0; margin: 0 0 32px 0; }}
        #article-list li {{ background: white; padding: 14px 18px; border-radius: 10px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); margin-bottom: 8px; display: flex; align-items: center; gap: 12px; border: 1px solid #E2E8F0; transition: all 0.2s; }}
        #article-list li:hover {{ box-shadow: 0 8px 25px rgba(0,0,0,0.10); border-color: #00A86B; }}
        #article-list li .category {{ background: #005A9C; color: white; font-size: 11px; font-weight: 600; padding: 2px 12px; border-radius: 20px; white-space: nowrap; }}
        #article-list li a {{ flex: 1; color: #1A202C; text-decoration: none; font-size: 15px; font-weight: 500; }}
        #article-list li a:hover {{ color: #005A9C; }}
        #article-list li .post-date {{ font-size: 12px; color: #718096; white-space: nowrap; }}
        @media (max-width: 600px) {{ #article-list li {{ flex-wrap: wrap; padding: 12px 14px; }} #article-list li a {{ font-size: 14px; }} }}
        .index-section {{ margin: 24px 0 8px 0; }}
        .index-section .cat-title {{ font-size: 14px; font-weight: 600; color: #1A202C; border-left: 3px solid #00A86B; padding-left: 12px; margin: 18px 0 10px 0; display: flex; align-items: center; gap: 10px; }}
        .index-section .cat-title .count {{ font-size: 12px; font-weight: 400; color: #718096; }}
        .index-tag-grid {{ display: flex; flex-wrap: wrap; gap: 8px; }}
        .index-tag {{ background: white; padding: 6px 16px; border-radius: 20px; font-size: 13px; color: #4A5568; text-decoration: none; border: 1px solid #E2E8F0; transition: all 0.2s; }}
        .index-tag:hover {{ border-color: #00A86B; color: #1A202C; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }}
        .sidebar {{ display: flex; flex-direction: column; gap: 24px; }}
        .sidebar .widget {{ background: white; padding: 24px 20px; border-radius: 14px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); border: 1px solid #E2E8F0; }}
        .sidebar .widget-title {{ font-size: 16px; font-weight: 700; color: #1A202C; margin-bottom: 14px; border-bottom: 2px solid #005A9C; padding-bottom: 8px; }}
        .sidebar .widget p {{ font-size: 14px; color: #4A5568; line-height: 1.7; }}
        .sidebar .widget ul {{ list-style: none; padding: 0; margin: 0; }}
        .sidebar .widget ul li {{ margin-bottom: 6px; font-size: 14px; }}
        .sidebar .widget ul li a {{ color: #4A5568; text-decoration: none; display: block; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }}
        .sidebar .widget ul li a:hover {{ color: #005A9C; }}
        .sidebar .widget .tag-cloud {{ display: flex; flex-wrap: wrap; gap: 6px; }}
        .sidebar .widget .tag-cloud a {{ background: #F7F9FC; padding: 4px 12px; border-radius: 20px; font-size: 12px; color: #4A5568; text-decoration: none; border: 1px solid #E2E8F0; }}
        .sidebar .widget .tag-cloud a:hover {{ border-color: #00A86B; color: #1A202C; }}
        .site-footer {{ background: #2D3748; color: #A0AEC0; padding: 40px 0 28px 0; margin-top: 40px; font-size: 14px; }}
        .footer-inner {{ max-width: 1200px; margin: 0 auto; padding: 0 24px; text-align: center; }}
        .footer-inner .copy {{ font-size: 13px; color: #718096; }}
        .footer-inner .declaration {{ font-size: 12px; color: #FF6F61; letter-spacing: 1px; font-weight: 300; margin-top: 4px; }}
        .site-footer .footer-links {{ margin-top: 12px; display: flex; flex-wrap: wrap; justify-content: center; gap: 12px 24px; }}
        .site-footer .footer-links a {{ color: #CBD5E0; text-decoration: none; font-size: 13px; transition: color 0.2s ease, text-decoration 0.2s ease; }}
        .site-footer .footer-links a:hover {{ color: #FFFFFF; text-decoration: underline; }}
        {BACK_TO_TOP}
    </style>
</head>
<body>
    {SITE_HEADER}

    <div class="main-wrapper">
        <div class="content-card">
            <h1 class="hero-title">雅寶社區 <span class="highlight">·</span> 頂客論壇</h1>
            <p class="hero-sub">歲月 · 知識 · 共創</p>
            <p class="hero-desc">
                這裡記錄了 <strong>頂客論壇</strong> 二十多年的歲月迴聲，
                並以 AI 精選 <strong>科技、遊戲、生活、軟體、哲理、AI 趨勢</strong> 六大領域的實用內容。
                從數位工具到人生成長，每一篇文章都經過編輯策展，為讀者提供真正有價值的資訊。
            </p>

            <div class="category-grid">
                <a href="/category-tech.html" class="category-card">
                    <span class="emoji">💻</span>
                    <span class="cat-name">3C 科技教學</span>
                    <span class="cat-count">{article_counts.get('tech', 0)} 篇</span>
                </a>
                <a href="/category-game.html" class="category-card">
                    <span class="emoji">🎮</span>
                    <span class="cat-name">遊戲攻略</span>
                    <span class="cat-count">{article_counts.get('game', 0)} 篇</span>
                </a>
                <a href="/category-life.html" class="category-card">
                    <span class="emoji">🏠</span>
                    <span class="cat-name">生活小常識</span>
                    <span class="cat-count">{article_counts.get('life', 0)} 篇</span>
                </a>
                <a href="/category-review.html" class="category-card">
                    <span class="emoji">📊</span>
                    <span class="cat-name">軟體評測</span>
                    <span class="cat-count">{article_counts.get('review', 0)} 篇</span>
                </a>
                <a href="/category-philosophy.html" class="category-card">
                    <span class="emoji">🌟</span>
                    <span class="cat-name">人生哲理</span>
                    <span class="cat-count">{article_counts.get('philosophy', 0)} 篇</span>
                </a>
                <a href="/category-trend.html" class="category-card">
                    <span class="emoji">🤖</span>
                    <span class="cat-name">AI 趨勢</span>
                    <span class="cat-count">{article_counts.get('trend', 0)} 篇</span>
                </a>
            </div>

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
        category = article['category']
        title = article['title'][:60] + '...' if len(article['title']) > 60 else article['title']
        date = datetime.fromtimestamp(article['mtime']).strftime('%Y-%m-%d')
        html_content += f'                <li><span class="category">{category}</span><a href="/{article["filename"]}">{title}</a><span class="post-date">{date}</span></li>\n'

    html_content += f'''            </ul>

            <div class="index-section">
                <h2 class="section-title">📖 全部分類索引 <small>共 {total_count} 篇文章</small></h2>
'''
    for cat_dir, cat_name in category_dirs.items():
        cat_articles = category_articles.get(cat_dir, [])[:20]
        html_content += f'''
                <div class="cat-title">{cat_name} <span class="count">({article_counts.get(cat_dir, 0)}篇)</span></div>
                <div class="index-tag-grid" id="tag-{cat_dir}">
'''
        for article in cat_articles[:15]:
            title = article['title'][:30] + '...' if len(article['title']) > 30 else article['title']
            html_content += f'                    <a href="/{article["filename"]}" class="index-tag">{title}</a>\n'
        if len(cat_articles) > 15:
            html_content += f'                    <span class="index-tag" style="background:#e2e8f0;color:#4a5568;">+{len(cat_articles)-15} 篇</span>\n'
        html_content += '                </div>\n'

    html_content += f'''            </div>

        </div>

        <aside class="sidebar">
            <div class="widget">
                <div class="widget-title">⚖️ 關於本站</div>
                <p>雅寶社區 · 頂客論壇 (AHPAL.COM) 致力於提供高品質的生活、科技、遊戲與理財資訊。從歲月記憶到知識共創，我們相信：<strong>誠實守信，是文明社會永恆的基石。</strong></p>
                <p style="margin-top:8px;"><a href="/about.html" style="color:#005A9C;font-weight:500;">📖 了解更多 →</a></p>
            </div>

            <div class="widget">
                <div class="widget-title">🎮 雅寶遊戲間</div>
                <p style="font-size:13px; margin-bottom:12px;">閱讀之餘，放鬆一下！免下載、即開即玩。</p>
                <a href="/game/" style="display:inline-block; background:#005A9C; color:white; padding:8px 20px; border-radius:20px; text-decoration:none; font-size:14px; font-weight:500;">🎮 進入遊戲間</a>
            </div>

            <div class="widget">
                <div class="widget-title">🔥 熱門文章</div>
                <ul id="hot-articles">
                    <li><a href="/tech/best-gaming-laptops-2026.html">2026 年 5 款最強電競筆電推薦與評測</a></li>
                    <li><a href="/game/best-indie-games-2026.html">2026 最夯 5 款獨立遊戲推薦</a></li>
                    <li><a href="/life/smart-home-guide-2026.html">2026 年居家智慧裝置選購指南</a></li>
                    <li><a href="/review/best-ai-presentation-tools-2026.html">2026 年 5 款最佳 AI 簡報生成工具評測</a></li>
                    <li><a href="/trend/ai-agent-trends-2026.html">2026 年 AI 代理人趨勢全解析</a></li>
                </ul>
            </div>

            <div class="widget">
                <div class="widget-title">🏷️ 分類標籤</div>
                <div class="tag-cloud">
                    <a href="/category-tech.html">💻 3C</a>
                    <a href="/category-game.html">🎮 遊戲</a>
                    <a href="/category-life.html">🏠 生活</a>
                    <a href="/category-review.html">📊 評測</a>
                    <a href="/category-philosophy.html">🌟 哲理</a>
                    <a href="/category-trend.html">🤖 AI</a>
                    <a href="/game/">🎮 遊戲間</a>
                    <a href="/categories.html">📚 全部分類</a>
                    <a href="/about.html">📖 關於我們</a>
                    <a href="/contact.html">📧 聯絡我們</a>
                </div>
            </div>
        </aside>
    </div>

    {SITE_FOOTER.format(year=CURRENT_YEAR)}
    {BACK_TO_TOP}
    {HOME_LINK}
</body>
</html>
'''

    with open(os.path.join(OUTPUT_DIR, "index.html"), "w", encoding="utf-8") as f:
        f.write(html_content)
    print("✅ 全新首頁建立完成！")

# ============================================================
# 建構分類入口頁
# ============================================================

def generate_categories_page():
    """建立完整的分類入口頁 categories.html"""
    print("📄 建立統一分類入口頁 categories.html...")
    
    html_content = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📚 全部分類 - 雅寶社區 · 頂客論壇</title>
    <meta name="description" content="雅寶社區 · 頂客論壇 — 六大知識分類總覽。">
    {ADSENSE_CODE}
    {GA4_CODE}
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif; background: #F7F9FC; color: #1A202C; padding: 20px; line-height: 1.7; }}
        .container {{ max-width: 1200px; margin: 0 auto; }}
        .header {{ display: flex; justify-content: space-between; align-items: center; border-bottom: 3px solid #005A9C; padding-bottom: 16px; margin-bottom: 30px; flex-wrap: wrap; gap: 12px; }}
        .header h1 {{ color: #005A9C; font-size: 28px; margin: 0; }}
        .header a {{ color: #005A9C; text-decoration: none; font-weight: 500; }}
        .header a:hover {{ text-decoration: underline; }}
        .subtitle {{ color: #4A5568; margin-bottom: 28px; font-size: 15px; }}
        .category-grid {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 24px; }}
        @media (max-width: 768px) {{ .category-grid {{ grid-template-columns: repeat(2, 1fr); }} }}
        @media (max-width: 480px) {{ .category-grid {{ grid-template-columns: 1fr; }} }}
        .category-card {{ background: white; border-radius: 14px; padding: 24px 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.06); border: 1px solid #E2E8F0; text-decoration: none; color: inherit; transition: all 0.25s ease; }}
        .category-card:hover {{ transform: translateY(-4px); box-shadow: 0 8px 25px rgba(0,0,0,0.10); border-color: #00A86B; }}
        .category-card .emoji {{ font-size: 32px; display: block; margin-bottom: 6px; }}
        .category-card h3 {{ font-size: 18px; font-weight: 700; color: #1A202C; margin-bottom: 2px; }}
        .category-card .desc {{ font-size: 13px; color: #4A5568; margin-bottom: 8px; }}
        .category-card .count {{ font-size: 12px; color: #718096; }}
        .back-link {{ display: inline-block; margin-top: 30px; color: #005A9C; text-decoration: none; }}
        .back-link:hover {{ text-decoration: underline; }}
        .footer {{ margin-top: 40px; text-align: center; color: #888; font-size: 13px; border-top: 1px solid #E2E8F0; padding-top: 20px; }}
        .footer a {{ color: #718096; text-decoration: none; transition: color 0.2s ease; }}
        .footer a:hover {{ color: #005A9C; text-decoration: underline; }}
        {BACK_TO_TOP}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📚 全部分類</h1>
            <a href="/">🏠 返回首頁</a>
        </div>
        <p class="subtitle">六大知識領域，超過 200 篇精選文章，讓你一次掌握。</p>
        <div class="category-grid">
'''

    for cat_id, cat_info in CATEGORIES.items():
        dir_path = os.path.join(OUTPUT_DIR, cat_id)
        count = 0
        if os.path.exists(dir_path):
            count = len([f for f in os.listdir(dir_path) if f.endswith('.html')])
        html_content += f'''
            <a href="/category-{cat_id}.html" class="category-card">
                <span class="emoji">{cat_info['name'].split(' ')[0]}</span>
                <h3>{cat_info['name']}</h3>
                <p class="desc">{cat_info['desc']}</p>
                <span class="count">📄 {count} 篇文章</span>
            </a>
'''

    html_content += f'''
        </div>
        <a href="/" class="back-link">← 返回首頁</a>
        <div class="footer">
            &copy; {CURRENT_YEAR} 雅寶社區 · 頂客論壇 — 全部分類
            <div style="margin-top:6px;font-size:12px;">
                <a href="/sitemap.xml">📄 Sitemap</a>
                <a href="/">🏠 首頁</a>
                <a href="/game/">🎮 遊戲間</a>
            </div>
        </div>
    </div>
    {BACK_TO_TOP}
    {HOME_LINK}
</body>
</html>
'''

    with open(os.path.join(OUTPUT_DIR, "categories.html"), "w", encoding="utf-8") as f:
        f.write(html_content)
    print("✅ 統一分類入口頁 categories.html 建立完成！")

# ============================================================
# 新增：generate_category_pages（供 main.py 呼叫）
# ============================================================

def generate_category_pages():
    """生成各分類的獨立頁面（與原 ahpal_generator.py 相容）"""
    print("📄 正在生成分類頁面...")
    
    # 直接使用 CATEGORIES（從 config 導入）
    from src.config import CATEGORIES as CATEGORIES_CONFIG
    
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
                            title_match = re.search(r'<title>(.*?)</title>', content, re.IGNORECASE)
                            title = title_match.group(1) if title_match else f.replace(".html", "")
                    except:
                        title = f.replace(".html", "")
                    articles.append({"filename": f"{cat_id}/{f}", "title": title})
        
        articles.sort(key=lambda x: x["filename"])
        
        html_content = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{cat_info['name']} - 雅寶社區 · 頂客論壇</title>
    <meta name="description" content="{cat_info['desc']} - 雅寶社區 · 頂客論壇">
    {ADSENSE_CODE}
    {GA4_CODE}
    <style>
        :root {{ --color-primary: #005A9C; --color-secondary: #00A86B; --color-bg: #F7F9FC; --color-card: #FFFFFF; --color-text: #1A202C; --color-text-light: #4A5568; --color-border: #E2E8F0; --shadow-card: 0 4px 12px rgba(0,0,0,0.06); --radius-card: 14px; }}
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif; background: var(--color-bg); color: var(--color-text); line-height: 1.8; font-size: 16px; }}
        .site-header {{ background: #005A9C; color: white; padding: 12px 0; position: sticky; top: 0; z-index: 50; }}
        .header-inner {{ max-width: 1200px; margin: 0 auto; padding: 0 24px; display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; }}
        .logo {{ font-size: 20px; font-weight: 700; color: white; text-decoration: none; letter-spacing: 0.5px; }}
        .logo:hover {{ color: rgba(255,255,255,0.85); }}
        .nav-links {{ display: flex; gap: 20px; font-size: 14px; align-items: center; flex-wrap: wrap; }}
        .nav-links a {{ color: rgba(255,255,255,0.85); text-decoration: none; }}
        .nav-links a:hover {{ color: white; border-bottom: 2px solid #00A86B; }}
        .nav-links .game-link {{ background: rgba(255,255,255,0.15); padding: 4px 14px; border-radius: 20px; font-weight: 500; }}
        .nav-links .game-link:hover {{ background: rgba(255,255,255,0.25); border-bottom: none; }}
        .breadcrumb {{ max-width: 1200px; margin: 16px auto 0; padding: 0 24px; font-size: 14px; color: #718096; }}
        .breadcrumb a {{ color: var(--color-primary); text-decoration: none; }}
        .main-wrapper {{ max-width: 1200px; margin: 24px auto; padding: 0 24px; }}
        .content-card {{ background: var(--color-card); padding: 36px 40px; border-radius: var(--radius-card); box-shadow: var(--shadow-card); }}
        @media (max-width: 640px) {{ .content-card {{ padding: 24px 18px; }} }}
        .hero-title {{ font-size: 28px; font-weight: 700; color: var(--color-text); margin-bottom: 4px; }}
        .hero-sub {{ font-size: 16px; color: #718096; margin-bottom: 8px; }}
        .hero-desc {{ font-size: 15px; color: var(--color-text-light); }}
        .section-title {{ font-size: 22px; font-weight: 700; color: var(--color-text); margin: 28px 0 16px 0; }}
        .article-list {{ list-style: none; padding: 0; margin: 0; }}
        .article-list li {{ background: var(--color-bg); padding: 14px 18px; border-radius: 10px; margin-bottom: 8px; display: flex; align-items: center; gap: 14px; border: 1px solid var(--color-border); transition: all 0.2s; }}
        .article-list li:hover {{ box-shadow: 0 8px 25px rgba(0,0,0,0.10); border-color: var(--color-secondary); }}
        .article-list li a {{ flex: 1; color: var(--color-text); text-decoration: none; font-size: 15px; font-weight: 500; }}
        .article-list li a:hover {{ color: var(--color-primary); }}
        .back-link {{ display: inline-block; margin-top: 24px; color: var(--color-primary); text-decoration: none; font-weight: 500; }}
        .back-link:hover {{ text-decoration: underline; }}
        .site-footer {{ background: #2D3748; color: #A0AEC0; padding: 40px 0 28px 0; margin-top: 40px; font-size: 14px; }}
        .footer-inner {{ max-width: 1200px; margin: 0 auto; padding: 0 24px; text-align: center; }}
        .footer-inner .copy {{ font-size: 13px; color: #718096; }}
        .footer-inner .declaration {{ font-size: 12px; color: #FF6F61; letter-spacing: 1px; font-weight: 300; margin-top: 4px; }}
        .site-footer .footer-links {{ margin-top: 12px; display: flex; flex-wrap: wrap; justify-content: center; gap: 12px 24px; }}
        .site-footer .footer-links a {{ color: #CBD5E0; text-decoration: none; font-size: 13px; transition: color 0.2s ease, text-decoration 0.2s ease; }}
        .site-footer .footer-links a:hover {{ color: #FFFFFF; text-decoration: underline; }}
        {BACK_TO_TOP}
    </style>
</head>
<body>
    {SITE_HEADER}

    <div class="breadcrumb"><a href="/">首頁</a> &gt; {cat_info['name']}</div>

    <div class="main-wrapper">
        <div class="content-card">
            <h1 class="hero-title">{cat_info['name']}</h1>
            <p class="hero-sub">{cat_info['desc']}</p>
            <p class="hero-desc">共 {len(articles)} 篇文章</p>

            <h2 class="section-title">📖 全部文章</h2>
            <ul class="article-list">
'''
        if articles:
            for article in articles:
                html_content += f'                <li><a href="/{article["filename"]}">{article["title"]}</a></li>\n'
        else:
            html_content += '                <li style="color:#718096;">目前尚無文章，敬請期待！</li>\n'

        html_content += f'''            </ul>
            <a href="/" class="back-link">← 返回首頁</a>
        </div>
    </div>

    {SITE_FOOTER.format(year=CURRENT_YEAR)}
    {BACK_TO_TOP}
    {HOME_LINK}
</body>
</html>
'''
        with open(page_path, "w", encoding="utf-8") as f:
            f.write(html_content)
        print(f"   ✅ 生成分類頁面：category-{cat_id}.html（{len(articles)} 篇文章）")
    
    print("✅ 所有分類頁面生成完畢！")