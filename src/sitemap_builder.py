# ============================================================
# sitemap_builder.py - Sitemap 產生模組
# ============================================================
# 功能：掃描所有 HTML 檔案並產生 sitemap.xml
# ============================================================

import os
from datetime import datetime
from src.config import OUTPUT_DIR

# ============================================================
# 掃描所有 HTML 檔案
# ============================================================

def scan_all_html_files():
    """掃描所有 HTML 檔案"""
    html_files = []
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith(".html"):
                rel_path = os.path.relpath(os.path.join(root, f), OUTPUT_DIR)
                html_files.append({"filename": rel_path})
    return html_files

# ============================================================
# 更新 Sitemap
# ============================================================

def update_sitemap():
    """更新 sitemap.xml"""
    print("📄 更新 Sitemap...")
    
    all_files = []
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith(".html") or f.endswith(".xml"):
                rel_path = os.path.relpath(os.path.join(root, f), OUTPUT_DIR)
                all_files.append(rel_path)
    
    sitemap_content = '''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
'''
    for file_path in all_files:
        if file_path.startswith("game/") or file_path.startswith("tech/") or file_path.startswith("life/") or file_path.startswith("review/") or file_path.startswith("philosophy/") or file_path.startswith("trend/"):
            priority = "0.8"
        elif file_path.startswith("category-"):
            priority = "0.7"
        elif file_path == "index.html":
            priority = "1.0"
        else:
            priority = "0.5"
        sitemap_content += f'''  <url>
    <loc>https://ahpal.com/{file_path}</loc>
    <lastmod>{datetime.now().strftime('%Y-%m-%d')}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>{priority}</priority>
  </url>
'''
    
    sitemap_content += '</urlset>'
    
    with open(os.path.join(OUTPUT_DIR, "sitemap.xml"), "w", encoding="utf-8") as f:
        f.write(sitemap_content)
    print("✅ Sitemap 更新完成！")
