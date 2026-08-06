# ============================================================
# article_generator.py - 文章生成核心模組 v7.7
# ============================================================
# 修復：
#   - 🔧 CSS 圖片變形：加入 object-fit:cover + aspect-ratio:16/9
#   - 🔧 圖文不符：改用英文視覺提示詞 + 分類風格映射
#   - 🔧 抽象概念翻譯：建立關鍵字詞庫，將中文主題轉為具體英文視覺描述
#   - 🔧 輸出品質提升：加入專業風格關鍵字（flat vector, clean, professional）
#   - 🆕 YouTube 影片嵌入：支援 video_id 自動嵌入文章開頭
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
# 🆕 YouTube 嵌入函數
# ============================================================

def create_youtube_embed(video_id):
    """
    建立 YouTube 影片嵌入 HTML（響應式 16:9）
    """
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
# 🖼️ 智慧配圖系統 v3.1 - 專業版（v7.6）
# ============================================================

# ---- 分類視覺風格映射 ----
CATEGORY_VISUALS = {
    "🌟 人生哲理": "a person meditating peacefully in a modern minimalist room, digital detox concept, laptop on desk, soft natural lighting, calm serene atmosphere",
    "💻 3C 科技教學": "modern workspace with laptop, smartphone, tablet, clean technology gadgets on wooden desk, minimal background",
    "📊 軟體評測": "computer screen showing data visualization dashboard, sleek software interface, modern office setup, blue and white color scheme",
    "🏠 生活小常識": "cozy home interior with organized spaces, warm lighting, comfortable living room, bright daylight",
    "🎮 遊戲攻略": "gaming setup with RGB keyboard, gaming monitor, headset, vibrant neon lighting, esports style",
    "🤖 AI 趨勢": "artificial intelligence concept, digital brain, futuristic tech network, glowing circuit board, cyan and blue lights"
}

# ---- 風格關鍵字 ----
STYLE_SUFFIX = "vector illustration, clean line art, minimal corporate editorial style, soft color palette, professional design, crisp details, 8k"

def _build_english_visual_prompt(keyword, category):
    """
    將主題轉化為適合 AI 生圖的英文視覺提示詞
    核心修復：抽象中文 → 具體英文視覺描述
    """
    # 1. 優先使用分類對應的視覺場景
    base_visual = CATEGORY_VISUALS.get(category)
    if not base_visual:
        base_visual = f"concept visualization for {keyword}, modern professional setting"
    
    # 2. 特殊關鍵字強化（針對文章主題增加細節）
    keyword_hints = []
    
    # 人生哲理類特殊處理
    if "正念" in keyword or "平靜" in keyword or "專注" in keyword:
        keyword_hints.append("meditation, calmness, focus, mindfulness")
    if "數位" in keyword or "科技" in keyword:
        keyword_hints.append("digital device screen, technology interface")
    if "壓力" in keyword or "焦慮" in keyword:
        keyword_hints.append("stress relief, peaceful environment")
    
    # 3C/科技類特殊處理
    if "評測" in keyword or "比較" in keyword:
        keyword_hints.append("product comparison chart, side by side view")
    if "教學" in keyword or "指南" in keyword:
        keyword_hints.append("instructional step by step guide style")
    
    # 4. 組裝最終提示詞
    full_prompt = base_visual
    if keyword_hints:
        full_prompt += f", {', '.join(keyword_hints)}"
    full_prompt += f", {STYLE_SUFFIX}"
    
    return full_prompt


def _make_responsive_image(img_tag):
    """
    將圖片標籤轉為響應式，並防止變形
    修復：加入 aspect-ratio:16/9 + object-fit:cover
    """
    return img_tag.replace(
        'width="800"',
        'style="width:100%;max-width:800px;height:auto;aspect-ratio:16/9;object-fit:cover;border-radius:12px;margin:20px 0;box-shadow:0 4px 12px rgba(0,0,0,0.08);"'
    )


def generate_and_embed_image(html_content, keyword, category):
    """
    使用 Pollinations AI 生成配圖，並嵌入文章
    v3.1 專業版：
        - 英文視覺提示詞（解決圖文不符）
        - 分類風格映射（確保風格一致）
        - 防止變形 CSS（aspect-ratio + object-fit）
        - 16:9 橫圖比例（文章配圖視覺最佳）
    """
    print("   🖼️ 正在生成配圖（Pollinations AI）...")
    
    try:
        router = ModelRouter()
        
        # ---- 1. 建構專業英文提示詞 ----
        visual_prompt = _build_english_visual_prompt(keyword, category)
        # 限制長度，避免 URL 過長（Pollinations 建議 < 200 字符）
        if len(visual_prompt) > 180:
            visual_prompt = visual_prompt[:180]
        
        # URL 編碼
        encoded_prompt = urllib.parse.quote(visual_prompt)
        print(f"   📝 生圖提示詞（英文）：{visual_prompt[:80]}...")
        
        safe_filename = re.sub(r'[\\/*?:"<>|]', '', keyword)[:50]
        
        # ---- 2. 生成圖片（16:9 橫圖） ----
        result = router.generate_image_pollinations(
            prompt=encoded_prompt,
            filename=f"article_{safe_filename}",
            width=1024,
            height=576
        )
        
        if result.get("img_tag"):
            # 響應式圖片（防止變形）
            responsive_img = _make_responsive_image(result["img_tag"])
            
            # ---- 3. 插入圖片（使用 </p> 匹配） ----
            p_close_match = re.search(r'</p>', html_content, re.IGNORECASE)
            if p_close_match:
                pos = p_close_match.end()
                html_content = html_content[:pos] + '\n' + responsive_img + '\n' + html_content[pos:]
                print(f"   ✅ 配圖已插入文章第一個段落之後")
            else:
                h2_match = re.search(r'<h2', html_content, re.IGNORECASE)
                if h2_match:
                    pos = h2_match.start()
                    html_content = html_content[:pos] + responsive_img + '\n' + html_content[pos:]
                    print(f"   ✅ 配圖已插入文章第一個 H2 之前")
                else:
                    body_match = re.search(r'<body[^>]*>', html_content, re.IGNORECASE)
                    if body_match:
                        pos = body_match.end()
                        html_content = html_content[:pos] + '\n' + responsive_img + '\n' + html_content[pos:]
                        print(f"   ✅ 配圖已插入文章 body 開頭")
                    else:
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


# ============================================================
# 🆕 生成單一文章（加入 YouTube 嵌入支援）
# ============================================================

def generate_article(item):
    """
    生成單一篇文章，並自動生成配圖，並支援 YouTube 影片嵌入
    
    參數：
        item: dict，包含 keyword, category, filename, video_id (可選)
    
    流程：
        1. 檢查檔案是否已存在
        2. 使用 APIClient 生成文章
        3. 轉換為完整 HTML
        4. 🆕 如果有 video_id，嵌入 YouTube 影片
        5. 生成專業配圖（英文提示詞 + 分類風格映射）
        6. 品質檢查
        7. 寫入檔案
        8. 更新首頁
    """
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    video_id = item.get("video_id", "")  # 🆕 讀取 video_id（如果有的話）
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

    # ============================================================
    # 3. 🆕 如果有 video_id，在文章開頭嵌入 YouTube 影片
    # ============================================================
    if video_id:
        youtube_embed = create_youtube_embed(video_id)
        # 在 <body> 之後、文章內容之前插入
        if '<body>' in html_content:
            html_content = html_content.replace('<body>', f'<body>\n{youtube_embed}')
        else:
            html_content = youtube_embed + html_content
        print(f"   ✅ 已嵌入 YouTube 影片：{video_id}")

    # 建構完整 HTML（加入品牌標示、返回按鈕等）
    html_content = build_article_html(keyword, category, html_content)

    # ============================================================
    # 4. 生成專業配圖（傳入 category 用於風格映射）
    # ============================================================
    html_content, image_generated = generate_and_embed_image(html_content, keyword, category)

    # ============================================================
    # 5. 品質檢查
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
    # 6. 寫入檔案
    # ============================================================
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")

    # ============================================================
    # 7. 更新首頁
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
    print("  🧪 article_generator.py v7.7 測試（YouTube 嵌入版）")
    print("="*50 + "\n")

    test_item = {
        "keyword": "望春風 Lo-fi 翻唱 歌詞 台羅拼音 解析",
        "category": "🎵 台語音樂",
        "filename": "test/test-song.html",
        "video_id": "RMam6RpUzNI"
    }

    generate_article(test_item)
    print("\n✅ 測試完成")