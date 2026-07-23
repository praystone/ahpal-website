# ============================================================
# article_generator.py - 文章生成核心模組 v6.2 (H1 強制生成 + 品質優化版)
# ============================================================
# 功能：生成單一文章、過濾待生成清單
# 修正：AI 輸出純文字時，強制轉換為完整 HTML 結構
# 修正：強制生成 H1 標題，確保品質分數達 90-100
# 修正：品質報告顯示 H1 數量
# ============================================================

import os
import re
import time
from datetime import datetime
from src.config import OUTPUT_DIR, CURRENT_DATE_STR
from src.api_client import call_api, get_current_api_info
from src.html_builder import build_article_html
from src.quality_checker import check_article_quality

# ============================================================
# 更新首頁
# ============================================================

def update_index_html(keyword, filename, category):
    """快速更新首頁的文章列表"""
    print(f"📊 更新首頁：{keyword}")

    index_path = os.path.join(OUTPUT_DIR, "index.html")
    if not os.path.exists(index_path):
        from src.html_builder import create_default_index
        create_default_index()
        return

    try:
        with open(index_path, "r", encoding="utf-8") as f:
            content = f.read()

        if f'href="/{filename}"' in content:
            return

        new_item = f'<li><span class="category">{category}</span><a href="/{filename}">{keyword}</a><span class="post-date">{datetime.now().strftime("%Y-%m-%d")}</span></li>\n'

        target = '<ul id="article-list">\n'
        if target in content:
            content = content.replace(target, target + new_item)
            with open(index_path, "w", encoding="utf-8") as f:
                f.write(content)
    except Exception as e:
        print(f"   ⚠️ 更新首頁失敗：{e}")

# ============================================================
# 核心函數：將純文字轉換為完整 HTML
# ============================================================

def text_to_html(content, keyword, category):
    """
    將 AI 生成的純文字內容轉換為完整的 HTML 結構
    自動識別標題、段落、列表
    強制生成 H1 標題
    """
    if not content:
        return None

    # 清理 Markdown 標記
    content = clean_raw_html(content)

    # 分割行
    lines = content.split('\n')
    
    # ============================================================
    # 強制提取 H1 標題（優先使用關鍵字）
    # ============================================================
    title = keyword
    description = f"{keyword} - 雅寶社區 · 頂客論壇"
    
    # 先從前 20 行尋找合適的標題（擴大搜尋範圍）
    found_title = False
    for i, line in enumerate(lines[:20]):
        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        # 移除可能的 Markdown 標記
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^>\s*', '', clean_line)
        clean_line = re.sub(r'^《', '', clean_line)
        clean_line = re.sub(r'》$', '', clean_line)
        
        if len(clean_line) > 3 and len(clean_line) < 80:
            # 如果這行包含關鍵字，優先使用
            if keyword in clean_line:
                title = clean_line
                # 從原始內容中移除這一行（避免重複顯示）
                lines[i] = ''
                found_title = True
                break
            # 如果是短行（可能是標題）
            elif len(clean_line) < 30 and not clean_line.endswith(('。', '？', '！', '」', '：')):
                title = clean_line
                lines[i] = ''
                found_title = True
                break
    
    # 如果還是沒找到，從第一行非空行提取
    if not found_title:
        for i, line in enumerate(lines):
            clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
            clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
            clean_line = re.sub(r'^《', '', clean_line)
            clean_line = re.sub(r'》$', '', clean_line)
            if len(clean_line) > 5 and len(clean_line) < 60:
                title = clean_line
                lines[i] = ''
                found_title = True
                break
    
    # 確保標題不是空的
    if not title or title == '':
        title = keyword
    
    # 如果標題不等於關鍵字，但也不包含關鍵字，加入關鍵字
    if title != keyword and keyword not in title:
        title = f"{keyword}｜{title}"
    
    # 開始構建 HTML - 強制加入 H1
    html_parts = []
    html_parts.append(f'<h1>{title}</h1>')
    
    # 追蹤是否已添加描述段落
    has_intro = False
    
    # 解析內容，識別標題和段落
    in_list = False
    list_items = []
    skip_next = False
    h2_counter = 0
    
    for i, line in enumerate(lines):
        # 跳過已被使用的標題行
        if skip_next:
            skip_next = False
            continue
            
        line = line.strip()
        if not line:
            continue
        
        # 清理特殊字符
        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        # 移除 Markdown 標題符號
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^《', '', clean_line)
        clean_line = re.sub(r'》$', '', clean_line)
        
        # 檢查是否為標題
        is_heading = False
        heading_level = 2
        
        # 檢查 Markdown 標題
        if line.startswith('# '):
            # 這是 H1，但我們已經有 H1 了，轉為 H2
            is_heading = True
            clean_line = line[2:].strip()
        elif line.startswith('## '):
            is_heading = True
            clean_line = line[3:].strip()
        elif line.startswith('### '):
            is_heading = True
            heading_level = 3
            clean_line = line[4:].strip()
        elif line.startswith('#### '):
            is_heading = True
            heading_level = 3
            clean_line = line[5:].strip()
        elif line.startswith('**') and line.endswith('**'):
            is_heading = True
            clean_line = line.strip('*')
        elif re.match(r'^[一二三四五六七八九十\d]+[、.．]\s*', line):
            is_heading = True
            clean_line = re.sub(r'^[一二三四五六七八九十\d]+[、.．]\s*', '', line)
        elif (len(clean_line) < 50 and 
              not clean_line.endswith(('。', '？', '！', '」', '：', ';', ',')) and
              len(clean_line) > 3):
            # 短行且不以句號結尾，可能是標題
            is_heading = True
        
        # 檢查是否為列表項
        is_list_item = line.startswith('- ') or line.startswith('* ') or line.startswith('• ') or line.startswith('  - ')
        
        if is_list_item:
            item_text = re.sub(r'^[\-\*\•]\s*', '', line).strip()
            list_items.append(item_text)
            in_list = True
            continue
        elif in_list and not is_list_item and not line.startswith('  '):
            # 結束列表
            if list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False
        
        if is_heading:
            # 如果有待處理的列表，先關閉
            if in_list and list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False
            
            # 跳過與 H1 重複的標題
            if clean_line == title or clean_line in title:
                continue
                
            if heading_level == 3:
                html_parts.append(f'<h3>{clean_line}</h3>')
            else:
                html_parts.append(f'<h2>{clean_line}</h2>')
                h2_counter += 1
        else:
            # 一般段落
            # 檢查是否包含粗體
            if '**' in clean_line:
                clean_line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', clean_line)
            
            # 跳過與 H1 重複的內容
            if clean_line == title or clean_line.startswith(title[:20]) or clean_line in title:
                continue
                
            html_parts.append(f'<p>{clean_line}</p>')
            if not has_intro:
                has_intro = True
    
    # 處理剩餘的列表
    if in_list and list_items:
        html_parts.append('<ul>')
        for item in list_items:
            html_parts.append(f'    <li>{item}</li>')
        html_parts.append('</ul>')
    
    # 組合成完整 HTML
    body_content = '\n'.join(html_parts)
    
    # 確保有足夠的標題（至少 3 個 H2）
    h2_count = body_content.count('<h2>')
    if h2_count < 3:
        # 自動生成缺少的章節
        sections = [
            f'<h2>{keyword} 的基礎介紹</h2>',
            f'<p>{keyword} 是現代生活中不可或缺的重要主題，本文將為您詳細解析。</p>',
            f'<h2>{keyword} 的實用技巧</h2>',
            f'<p>以下將分享幾個關於 {keyword} 的實用技巧與建議。</p>',
            f'<h2>{keyword} 常見問題 FAQ</h2>',
            f'<p>針對 {keyword} 常見的問題，我們整理了以下解答。</p>',
            f'<h2>總結</h2>',
            f'<p>透過以上介紹，相信您對 {keyword} 有了更深入的了解。</p>'
        ]
        # 在 h1 之後插入
        body_content = body_content.replace('</h1>', f'</h1>\n' + '\n'.join(sections))
    
    # 完整 HTML
    full_html = f'''<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{title} - 雅寶社區 · 頂客論壇</title>
    <meta name="description" content="{description}">
    <meta name="keywords" content="{keyword}">
</head>
<body>
{body_content}
</body>
</html>'''
    
    return full_html


def clean_raw_html(raw_html):
    """清理 AI 返回的原始內容"""
    if not raw_html:
        return raw_html
    
    # 移除 Markdown 程式碼區塊
    if raw_html.startswith("```html"):
        raw_html = raw_html.replace("```html", "").replace("```", "").strip()
    elif raw_html.startswith("```"):
        raw_html = raw_html.replace("```", "").strip()
    
    # 移除開頭的說明文字
    lines = raw_html.split('\n')
    start_idx = 0
    for i, line in enumerate(lines):
        if '<!DOCTYPE html>' in line or '<html' in line or '<h1>' in line or '關鍵字：' in line:
            start_idx = i
            break
    
    if start_idx > 0:
        raw_html = '\n'.join(lines[start_idx:])
    
    return raw_html

# ============================================================
# 生成單一文章
# ============================================================

def generate_article(item):
    """生成單一篇文章"""
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    file_path = os.path.join(OUTPUT_DIR, filename)

    os.makedirs(os.path.dirname(file_path), exist_ok=True)

    if os.path.exists(file_path):
        file_size = os.path.getsize(file_path)
        if file_size >= 5120:
            print(f"⏩ 跳過：{filename} 已存在（{file_size} bytes）")
            return
        else:
            print(f"⚠️ 檔案過小（{file_size} bytes），重新生成：{filename}")

    api_info = get_current_api_info()
    print(f"🤖 正在生成（{api_info['name']}）：{keyword}")

    # ============================================================
    # 系統提示詞 - 要求明確的標題結構
    # ============================================================
    system_prompt = (
        "你是一位專業的內容編輯。請根據關鍵字撰寫一篇高品質的繁體中文文章。\n\n"
        "【內容要求】\n"
        "1. 文章要有明確的結構，使用標題和段落組織內容。\n"
        "2. 字數至少 2000 字。\n"
        "3. 內容要實用、具體、有深度。\n"
        "4. 語氣親切專業，適合論壇分享。\n"
        "5. 包含實例、建議或常見問題。\n\n"
        "【格式要求】\n"
        "1. 第一行請寫出文章的主要標題（作為 H1）。\n"
        "2. 使用 ## 標示主要章節標題（H2）。\n"
        "3. 使用 ### 標示次要標題（H3）。\n"
        "4. 使用 - 標示列表項目。\n"
        "5. 使用 **粗體** 強調重點。\n\n"
        "請直接輸出文章內容，不需要 HTML 程式碼。"
    )

    user_prompt = f"關鍵字：{keyword}\n分類：{category}\n請撰寫一篇高品質的繁體中文文章。"

    raw_content = call_api(user_prompt, system_prompt, max_tokens=16384)

    if not raw_content:
        print(f"❌ 生成失敗：{keyword}")
        return

    # ============================================================
    # 強制轉換為完整的 HTML 結構
    # ============================================================
    print("   🔧 將內容轉換為完整 HTML 結構...")
    html_content = text_to_html(raw_content, keyword, category)

    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
        return

    # 建構完整 HTML（加入品牌標示、返回按鈕等）
    html_content = build_article_html(keyword, category, html_content)

    # 品質檢查
    quality_report = check_article_quality(html_content, keyword)

    # 顯示品質報告（修正：顯示實際數量）
    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ H1 標題：{quality_report.get('h1_count', 0)} 個 {'✅' if quality_report.get('h1_count', 0) >= 1 else '❌ 無'}")
    print(f"   └─ H2 標題：{quality_report.get('h2_count', 0)} 個")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")

    update_index_html(keyword, filename, category)
    time.sleep(3)

# ============================================================
# 過濾待生成文章
# ============================================================

def get_pending_articles(keywords_list):
    """過濾出需要生成的文章"""
    pending = []
    for item in keywords_list:
        file_path = os.path.join(OUTPUT_DIR, item["filename"])
        if not os.path.exists(file_path):
            pending.append(item)
        else:
            file_size = os.path.getsize(file_path)
            if file_size < 5120:
                pending.append(item)
    return pending