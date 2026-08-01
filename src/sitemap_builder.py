# ============================================================
# sitemap_builder.py - Sitemap 建構模組 v4.3
# ============================================================

import os
import hashlib
import json
from datetime import datetime
from pathlib import Path
from src.config import OUTPUT_DIR

# ============================================================
# 狀態檔案路徑
# ============================================================

STATE_FILE = Path(__file__).parent.parent / "sitemap-state.json"

def load_sitemap_state():
    """載入 Sitemap 狀態"""
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, 'r', encoding='utf-8') as f:
                return json.load(f)
        except:
            return {"files": {}, "last_update": None}
    return {"files": {}, "last_update": None}

def save_sitemap_state(state):
    """儲存 Sitemap 狀態"""
    with open(STATE_FILE, 'w', encoding='utf-8') as f:
        json.dump(state, f, indent=2, ensure_ascii=False)

def get_file_hash(filepath):
    """計算檔案的 MD5 雜湊值"""
    if not Path(filepath).exists():
        return None
    try:
        with open(filepath, 'rb') as f:
            return hashlib.md5(f.read()).hexdigest()
    except:
        return None

def get_changed_files():
    """獲取變更的檔案列表"""
    state = load_sitemap_state()
    changed_files = []
    
    # 掃描輸出目錄
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith('.html') or f == 'sitemap.xml':
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, OUTPUT_DIR)
                current_hash = get_file_hash(full_path)
                
                if current_hash is None:
                    continue
                
                previous_hash = state["files"].get(rel_path)
                if previous_hash != current_hash:
                    changed_files.append(rel_path)
                    state["files"][rel_path] = current_hash
    
    # 儲存狀態
    state["last_update"] = datetime.now().isoformat()
    save_sitemap_state(state)
    
    return changed_files

# ============================================================
# 掃描所有 HTML 檔案
# ============================================================

def scan_all_html_files():
    """掃描輸出目錄中的所有 HTML 檔案"""
    html_files = []
    exclude_files = ["index.html", "404.html", "memorial.html", "royal_dragon_karma.html", "search-results.html", "categories.html"]
    
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith('.html') and f not in exclude_files:
                if not f.startswith("category-"):
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, OUTPUT_DIR)
                    
                    # 取得最後修改時間
                    try:
                        mtime = os.path.getmtime(full_path)
                        lastmod = datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')
                    except:
                        lastmod = datetime.now().strftime('%Y-%m-%d')
                    
                    html_files.append({
                        "path": rel_path.replace("\\", "/"),
                        "lastmod": lastmod
                    })
    
    return html_files

# ============================================================
# 更新 Sitemap
# ============================================================

def update_sitemap():
    """更新 sitemap.xml（完整重建）"""
    print("📄 更新 Sitemap...")
    
    html_files = scan_all_html_files()
    
    # 按路徑排序
    html_files.sort(key=lambda x: x["path"])
    
    today = datetime.now().strftime('%Y-%m-%d')
    
    # 產生 Sitemap XML
    sitemap_content = f'''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    <url>
        <loc>https://www.ahpal.com/</loc>
        <lastmod>{today}</lastmod>
        <changefreq>daily</changefreq>
        <priority>1.0</priority>
    </url>
'''
    
    # 分類頁面
    categories = ["tech", "game", "life", "review", "philosophy", "trend"]
    for cat in categories:
        sitemap_content += f'''    <url>
        <loc>https://www.ahpal.com/category-{cat}.html</loc>
        <lastmod>{today}</lastmod>
        <changefreq>weekly</changefreq>
        <priority>0.8</priority>
    </url>
'''
    
    # 文章頁面
    for item in html_files:
        path = item["path"]
        lastmod = item["lastmod"]
        sitemap_content += f'''    <url>
        <loc>https://www.ahpal.com/{path}</loc>
        <lastmod>{lastmod}</lastmod>
        <changefreq>monthly</changefreq>
        <priority>0.6</priority>
    </url>
'''
    
    sitemap_content += '''</urlset>'''
    
    # 寫入檔案
    sitemap_path = os.path.join(OUTPUT_DIR, "sitemap.xml")
    with open(sitemap_path, "w", encoding="utf-8") as f:
        f.write(sitemap_content)
    
    print(f"   ✅ Sitemap 已更新：{len(html_files)} 篇文章，共 {len(html_files) + 7} 個 URL")
    
    return sitemap_path

def update_sitemap_incrementally():
    """增量更新 Sitemap（直接呼叫完整重建）"""
    update_sitemap()

# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    update_sitemap()