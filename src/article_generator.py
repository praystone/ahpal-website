# ============================================================
# article_generator.py - 文章生成核心模組 v7.5
# ============================================================
# 修復：
#   - 強制使用繁體中文（正體中文）
#   - 圖片響應式大小（max-width:100%）
#   - 優化圖片 alt 文本長度
#   - 🆕 智慧配圖 v3.0：URL 編碼、16:9 橫圖、</p> 插入
#   - 🆕 多重 Fallback：H2 → 開頭段落 → 英文備案
#   - 🆕 特殊符號過濾，避免 Pollinations 解析失敗
# ============================================================

import os
import re
import time
import urllib.parse
from pathlib import Path
from datetime import datetime

from src.config import OUTPUT_DIR, CURRENT_DATE_STR
from src.api_client import APIClient
from src.html_builder import build_article_html
from src.quality_checker import check_article_quality
from src.model_router import ModelRouter


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

def clean_raw_html(raw_html):
    """清理 AI 返回的原始內容，去除 Markdown 與多餘註解"""
    if not raw_html:
        return raw_html

    if raw_html.startswith("```html"):
        raw_html = raw_html.replace("```html", "").replace("```", "").strip()
    elif raw_html.startswith("```"):
        raw_html = raw_html.replace("```", "").strip()

    lines = raw_html.split('\n')
    start_idx = 0
    for i, line in enumerate(lines):
        if '<!DOCTYPE html>' in line or '<html' in line or '<h1>' in line or '關鍵字：' in line:
            start_idx = i
            break

    if start_idx > 0:
        raw_html = '\n'.join(lines[start_idx:])

    return raw_html


def text_to_html(content, keyword, category):
    """
    將 AI 生成的純文字內容轉換為完整的 HTML 結構
    自動識別標題、段落、列表
    強制生成 H1 標題
    """
    if not content:
        return None

    content = clean_raw_html(content)
    lines = content.split('\n')

    # ============================================================
    # 強制提取 H1 標題（優先使用關鍵字）
    # ============================================================
    title = keyword
    description = f"{keyword} - 雅寶社區 · 頂客論壇"

    found_title = False
    for i, line in enumerate(lines[:20]):
        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^>\s*', '', clean_line)
        clean_line = re.sub(r'^《', '', clean_line)
        clean_line = re.sub(r'》$', '', clean_line)

        if len(clean_line) > 3 and len(clean_line) < 80:
            if keyword in clean_line:
                title = clean_line
                lines[i] = ''
                found_title = True
                break
            elif len(clean_line) < 30 and not clean_line.endswith(('。', '？', '！', '」', '：')):
                title = clean_line
                lines[i] = ''
                found_title = True
                break

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

    if not title or title == '':
        title = keyword

    if title != keyword and keyword not in title:
        title = f"{keyword}｜{title}"

    # ============================================================
    # 開始構建 HTML
    # ============================================================
    html_parts = []
    html_parts.append(f'<h1>{title}</h1>')

    in_list = False
    list_items = []
    skip_next = False

    for i, line in enumerate(lines):
        if skip_next:
            skip_next = False
            continue

        line = line.strip()
        if not line:
            continue

        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^《', '', clean_line)
        clean_line = re.sub(r'》$', '', clean_line)

        is_heading = False
        heading_level = 2

        if line.startswith('# '):
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
            is_heading = True

        is_list_item = line.startswith('- ') or line.startswith('* ') or line.startswith('• ') or line.startswith('  - ')

        if is_list_item:
            item_text = re.sub(r'^[\-\*\•]\s*', '', line).strip()
            list_items.append(item_text)
            in_list = True
            continue
        elif in_list and not is_list_item and not line.startswith('  '):
            if list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False

        if is_heading:
            if in_list and list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False

            if clean_line == title or clean_line in title:
                continue

            if heading_level == 3:
                html_parts.append(f'<h3>{clean_line}</h3>')
            else:
                html_parts.append(f'<h2>{clean_line}</h2>')
        else:
            if '**' in clean_line:
                clean_line = re.sub(r'\*\*(.*?)\*\*', r'<strong>\1</strong>', clean_line)

            if clean_line == title or clean_line.startswith(title[:20]) or clean_line in title:
                continue

            html_parts.append(f'<p>{clean_line}</p>')

    if in_list and list_items:
        html_parts.append('<ul>')
        for item in list_items:
            html_parts.append(f'    <li>{item}</li>')
        html_parts.append('</ul>')

    body_content = '\n'.join(html_parts)

    h2_count = body_content.count('<h2>')
    if h2_count < 3:
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
        body_content = body_content.replace('</h1>', f'</h1>\n' + '\n'.join(sections))

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


# ============================================================
# 🖼️ 智慧配圖系統 v3.0 - 穩定版
# ============================================================

def _extract_clean_prompt(html_content, keyword):
    """
    從文章內容提取乾淨、安全的生圖提示詞
    修復：過濾特殊符號、URL 編碼、16:9 橫圖、英文備案
    """
    # ---- 策略 1：提取第一個 H2 標題 ----
    h2_match = re.search(r'<h2[^>]*>(.*?)</h2>', html_content, re.IGNORECASE | re.DOTALL)
    if h2_match:
        clean_h2 = re.sub(r'<[^>]+>', '', h2_match.group(1)).strip()
        # 過濾特殊符號，只保留中英文、數字、空白
        clean_h2 = re.sub(r'[^\w\s\u4e00-\u9fa5]', '', clean_h2)
        if clean_h2 and len(clean_h2) > 5:
            # 限制長度，避免 URL 過長
            if len(clean_h2) > 40:
                clean_h2 = clean_h2[:40] + "..."
            return f"{keyword} {clean_h2} 示意圖"
    
    # ---- 策略 2：提取開頭段落的前 60 個字 ----
    first_p = re.search(r'<p>(.*?)</p>', html_content, re.IGNORECASE | re.DOTALL)
    if first_p:
        p_text = re.sub(r'<[^>]+>', '', first_p.group(1)).strip()
        p_text = re.sub(r'[^\w\s\u4e00-\u9fa5]', '', p_text)
        if p_text and len(p_text) > 10:
            if len(p_text) > 60:
                p_text = p_text[:60] + "..."
            return f"{keyword} {p_text} 示意圖"
    
    # ---- 策略 3：英文備案（當中文解析失敗時） ----
    # 提取關鍵字的英文翻譯（簡化版）
    english_keywords = {
        "防毒軟體": "antivirus software",
        "開源軟體": "open source software",
        "免費": "free",
        "評測": "review",
        "指南": "guide",
        "推薦": "recommendation",
        "完整": "complete",
        "對比": "comparison",
        "效能": "performance",
        "隱私": "privacy"
    }
    eng_prompt = ""
    for zh, en in english_keywords.items():
        if zh in keyword:
            eng_prompt += f"{en} "
    if eng_prompt:
        return f"{eng_prompt}illustration technology concept"
    
    # ---- 策略 4：最終備案 ----
    return f"technology software illustration concept"


def generate_and_embed_image(html_content, keyword):
    """
    使用 Pollinations AI 生成配圖，並嵌入文章
    修復 v3.0：
        - URL 編碼安全（urllib.parse.quote）
        - 16:9 橫圖比例（文章配圖視覺效果最佳）
        - 使用 </p> 匹配（解決帶屬性標籤問題）
        - 多重插入備案
    """
    print("   🖼️ 正在生成配圖（Pollinations AI）...")
    
    try:
        router = ModelRouter()
        
        # 1. 提取乾淨的提示詞
        raw_prompt = _extract_clean_prompt(html_content, keyword)
        # URL 編碼（確保中英文特殊字元都被正確編碼）
        encoded_prompt = urllib.parse.quote(raw_prompt)
        print(f"   📝 生圖提示詞（編碼後）：{encoded_prompt[:60]}...")
        
        safe_filename = re.sub(r'[\\/*?:"<>|]', '', keyword)[:50]
        
        # 2. 生成圖片（16:9 橫圖，文章配圖視覺最佳）
        result = router.generate_image_pollinations(
            prompt=encoded_prompt,      # 傳入已編碼的提示詞
            filename=f"article_{safe_filename}",
            width=1024,
            height=576                 # 16:9 比例
        )
        
        if result.get("img_tag"):
            # 響應式圖片
            responsive_img = _make_responsive_image(result["img_tag"])
            
            # ---- 3. 插入圖片（使用 </p> 匹配） ----
            # 策略 A：插入在第一個 </p> 之後（支援帶屬性的 <p> 標籤）
            p_close_match = re.search(r'</p>', html_content, re.IGNORECASE)
            if p_close_match:
                pos = p_close_match.end()
                html_content = html_content[:pos] + '\n' + responsive_img + '\n' + html_content[pos:]
                print(f"   ✅ 配圖已插入文章第一個段落之後")
            else:
                # 策略 B：插入在第一個 <h2> 之前
                h2_match = re.search(r'<h2', html_content, re.IGNORECASE)
                if h2_match:
                    pos = h2_match.start()
                    html_content = html_content[:pos] + responsive_img + '\n' + html_content[pos:]
                    print(f"   ✅ 配圖已插入文章第一個 H2 之前")
                else:
                    # 策略 C：插入在 <body> 之後
                    body_match = re.search(r'<body[^>]*>', html_content, re.IGNORECASE)
                    if body_match:
                        pos = body_match.end()
                        html_content = html_content[:pos] + '\n' + responsive_img + '\n' + html_content[pos:]
                        print(f"   ✅ 配圖已插入文章 body 開頭")
                    else:
                        # 策略 D：直接插入在開頭
                        html_content = responsive_img + '\n' + html_content
                        print(f"   ✅ 配圖已插入文章開頭")
            
            return html_content, True
        else:
            error_msg = result.get('error', 'API 無回應') if result else '無回傳內容'
            print(f"   ⚠️ 配圖生成失敗：{error_msg}")
            return html_content, False
            
    except Exception as e:
        print(f"   ⚠️ 配圖生成異常：{e}")
        return html_content, False


def _make_responsive_image(img_tag):
    """將圖片標籤轉為響應式（16:9 橫圖專用）"""
    return img_tag.replace(
        'width="800"',
        'style="max-width:100%;height:auto;width:100%;max-width:800px;border-radius:8px;margin:16px 0;box-shadow:0 2px 8px rgba(0,0,0,0.08);aspect-ratio:16/9;object-fit:cover;"'
    )


# ============================================================
# 生成單一文章（核心改良版 + 智慧配圖 v3.0）
# ============================================================

def generate_article(item):
    """
    生成單一篇文章，並自動生成配圖
    
    參數：
        item: dict，包含 keyword, category, filename
    
    流程：
        1. 檢查檔案是否已存在
        2. 使用 APIClient 生成文章
        3. 轉換為完整 HTML
        4. 🆕 生成 Pollinations AI 配圖並嵌入文章（v3.0 穩定版）
        5. 品質檢查
        6. 寫入檔案
        7. 更新首頁
    """
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
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

    print(f"🤖 正在生成：{keyword}（分類：{category}）")

    # ============================================================
    # 1. 使用 APIClient 生成文章
    # ============================================================
    client = APIClient()
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
    # 2. 轉換為完整 HTML
    # ============================================================
    print("   🔧 將內容轉換為完整 HTML 結構...")
    html_content = text_to_html(raw_content, keyword, category)

    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
        return

    # 建構完整 HTML（加入品牌標示、返回按鈕等）
    html_content = build_article_html(keyword, category, html_content)

    # ============================================================
    # 3. 🆕 生成配圖並嵌入文章（Pollinations AI - v3.0 穩定版）
    # ============================================================
    html_content, image_generated = generate_and_embed_image(html_content, keyword)

    # ============================================================
    # 4. 品質檢查
    # ============================================================
    quality_report = check_article_quality(html_content, keyword)

    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ H1 標題：{quality_report.get('h1_count', 0)} 個 {'✅' if quality_report.get('h1_count', 0) >= 1 else '❌ 無'}")
    print(f"   └─ H2 標題：{quality_report.get('h2_count', 0)} 個")
    print(f"   └─ 配圖：{'✅ 已生成' if image_generated else '⚠️ 未生成'}")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")

    # ============================================================
    # 5. 寫入檔案
    # ============================================================
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")

    # ============================================================
    # 6. 更新首頁
    # ============================================================
    update_index_html(keyword, filename, category)

    # 短暫延遲，避免 API 過度請求
    time.sleep(2)


# ============================================================
# 過濾待生成文章
# ============================================================

def get_pending_articles(keywords_list):
    """
    過濾出需要生成的文章
    
    參數：
        keywords_list: 所有文章的清單
    
    回傳：
        list: 待生成的文章清單
    """
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


# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🧪 article_generator.py v7.5 測試（智慧配圖 v3.0）")
    print("="*50 + "\n")

    test_item = {
        "keyword": "2026 年最新 AI 工具推薦（繁體測試）",
        "category": "🤖 AI 趨勢",
        "filename": "test/test-article.html"
    }

    generate_article(test_item)
    print("\n✅ 測試完成")