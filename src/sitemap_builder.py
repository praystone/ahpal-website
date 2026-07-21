# ============================================================
# sitemap_builder.py - Sitemap 建構模組（增量更新版）
# ============================================================
# 功能：僅針對變更的檔案增量更新 Sitemap，節省構建時間
# 修正：日期格式符合 Google 標準（無微秒）
# ============================================================

import os
import xml.etree.ElementTree as ET
from datetime import datetime
from src.config import OUTPUT_DIR
from src.state_manager import get_state_manager

SITEMAP_PATH = os.path.join(OUTPUT_DIR, "sitemap.xml")
XML_NS = "http://www.sitemaps.org/schemas/sitemap/0.9"
ET.register_namespace('', XML_NS)

# ============================================================
# 日期格式輔助函數
# ============================================================

def get_now_iso():
    """取得符合 Google 標準的 ISO 8601 日期格式（無微秒）"""
    return datetime.now().replace(microsecond=0).isoformat() + "+00:00"

# ============================================================
# 核心函數
# ============================================================

def scan_all_html_files():
    """掃描所有 HTML 檔案（全量）"""
    html_files = []
    for root, dirs, files in os.walk(OUTPUT_DIR):
        for f in files:
            if f.endswith('.html'):
                rel_path = os.path.relpath(os.path.join(root, f), OUTPUT_DIR)
                html_files.append(rel_path.replace("\\", "/"))
    return html_files

def get_changed_files():
    """取得變更的檔案清單（從 state_manager）"""
    state_manager = get_state_manager()
    changed = []
    all_files = scan_all_html_files()
    
    for filepath in all_files:
        full_path = os.path.join(OUTPUT_DIR, filepath)
        if os.path.exists(full_path):
            current_hash = state_manager.get_file_hash(full_path)
            if state_manager.is_changed(full_path, current_hash):
                changed.append(filepath)
    
    return changed

def update_sitemap_incrementally(changed_files=None):
    """增量更新 Sitemap"""
    if changed_files is None:
        changed_files = get_changed_files()
    
    if not changed_files:
        print("📄 Sitemap 無變更，跳過更新")
        return
    
    # 如果 Sitemap 不存在或變更檔案過多（> 50），全量重建
    if not os.path.exists(SITEMAP_PATH) or len(changed_files) > 50:
        print("📄 執行全量 Sitemap 重建...")
        update_sitemap_full()
        return
    
    print(f"📄 增量更新 Sitemap（{len(changed_files)} 個變更）...")
    
    try:
        # 載入現有 Sitemap
        tree = ET.parse(SITEMAP_PATH)
        root = tree.getroot()
        
        # 建立 URL 路徑索引
        url_map = {}
        for url_elem in root.findall(f'.//{{{XML_NS}}}url'):
            loc_elem = url_elem.find(f'{{{XML_NS}}}loc')
            if loc_elem is not None and loc_elem.text:
                # 提取路徑（移除 domain）
                path = loc_elem.text.replace("https://www.ahpal.com/", "").replace("http://www.ahpal.com/", "")
                url_map[path] = url_elem
        
        # ✅ 修正：使用標準日期格式（無微秒）
        now = get_now_iso()
        
        for filepath in changed_files:
            if filepath in url_map:
                # 更新 existing entry
                url_elem = url_map[filepath]
                lastmod = url_elem.find(f'{{{XML_NS}}}lastmod')
                if lastmod is None:
                    lastmod = ET.SubElement(url_elem, 'lastmod')
                lastmod.text = now
                print(f"   ✅ 更新：{filepath}")
            else:
                # 新增 entry
                url_elem = ET.SubElement(root, 'url')
                loc = ET.SubElement(url_elem, 'loc')
                loc.text = f"https://www.ahpal.com/{filepath}"
                lastmod = ET.SubElement(url_elem, 'lastmod')
                lastmod.text = now
                changefreq = ET.SubElement(url_elem, 'changefreq')
                changefreq.text = "weekly"
                priority = ET.SubElement(url_elem, 'priority')
                priority.text = "0.8" if filepath.startswith("game/") else "0.5"
                print(f"   ✅ 新增：{filepath}")
        
        # 寫回檔案
        tree.write(SITEMAP_PATH, encoding='utf-8', xml_declaration=True)
        print(f"   ✅ Sitemap 增量更新完成")
        
        # 更新 state_manager
        state_manager = get_state_manager()
        for filepath in changed_files:
            full_path = os.path.join(OUTPUT_DIR, filepath)
            if os.path.exists(full_path):
                current_hash = state_manager.get_file_hash(full_path)
                state_manager.update_file(full_path, current_hash)
        state_manager.save()
        
    except Exception as e:
        print(f"   ⚠️ 增量更新失敗：{e}，執行全量重建...")
        update_sitemap_full()

def update_sitemap_full():
    """全量重建 Sitemap（日期格式已修正）"""
    html_files = scan_all_html_files()
    
    root = ET.Element('urlset', xmlns=XML_NS)
    # ✅ 修正：使用標準日期格式（無微秒）
    now = get_now_iso()
    
    # 首頁
    url_elem = ET.SubElement(root, 'url')
    loc = ET.SubElement(url_elem, 'loc')
    loc.text = "https://www.ahpal.com/"
    lastmod = ET.SubElement(url_elem, 'lastmod')
    lastmod.text = now
    changefreq = ET.SubElement(url_elem, 'changefreq')
    changefreq.text = "daily"
    priority = ET.SubElement(url_elem, 'priority')
    priority.text = "1.0"
    
    # 分類頁
    for cat in ["tech", "game", "life", "review", "philosophy", "trend"]:
        cat_file = f"category-{cat}.html"
        if cat_file in html_files:
            url_elem = ET.SubElement(root, 'url')
            loc = ET.SubElement(url_elem, 'loc')
            loc.text = f"https://www.ahpal.com/{cat_file}"
            lastmod = ET.SubElement(url_elem, 'lastmod')
            lastmod.text = now
            changefreq = ET.SubElement(url_elem, 'changefreq')
            changefreq.text = "weekly"
            priority = ET.SubElement(url_elem, 'priority')
            priority.text = "0.8"
    
    # 所有文章（排除系統頁面）
    exclude_files = [
        "index.html", "categories.html", "sitemap.xml", 
        "404.html", "memorial.html", "royal_dragon_karma.html", 
        "ads.txt", "search-results.html", "test.html"
    ]
    
    for filepath in html_files:
        # 跳過排除檔案
        if filepath in exclude_files:
            continue
        if filepath.startswith("category-"):
            continue
        # 跳過 docs/ 目錄（內部文件）
        if filepath.startswith("docs/"):
            continue
        
        url_elem = ET.SubElement(root, 'url')
        loc = ET.SubElement(url_elem, 'loc')
        loc.text = f"https://www.ahpal.com/{filepath}"
        lastmod = ET.SubElement(url_elem, 'lastmod')
        lastmod.text = now
        changefreq = ET.SubElement(url_elem, 'changefreq')
        changefreq.text = "weekly"
        priority = ET.SubElement(url_elem, 'priority')
        priority.text = "0.6" if filepath.startswith("game/") else "0.5"
    
    tree = ET.ElementTree(root)
    tree.write(SITEMAP_PATH, encoding='utf-8', xml_declaration=True)
    print(f"   ✅ Sitemap 全量重建完成（{len(html_files)} 個 URL）")
    
    # 更新 state_manager
    state_manager = get_state_manager()
    for filepath in html_files:
        if filepath in exclude_files or filepath.startswith("docs/"):
            continue
        full_path = os.path.join(OUTPUT_DIR, filepath)
        if os.path.exists(full_path):
            current_hash = state_manager.get_file_hash(full_path)
            state_manager.update_file(full_path, current_hash)
    state_manager.save()

# ============================================================
# 對外 API
# ============================================================

def update_sitemap():
    """更新 Sitemap（自動判斷全量/增量）"""
    update_sitemap_incrementally()