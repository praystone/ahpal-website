# ============================================================
# article_generator.py - 文章生成核心模組 v8.3
# ============================================================
# 修復與優化 (v8.3)：
#   - 🔧 強化 text_to_html 內容邊界偵測
#   - 🔧 自動過濾 CSS 程式碼區塊
#   - 🔧 優先使用 AI 生成的標題
#   - 🔧 防止 CSS 選擇器被誤判為 H2 標題
#   - 🔧 配圖分類映射新增「🎵 音樂創作」支援
#   - 🔧 同步 config.py 分類名稱變更
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
from src.logger import get_logger

# 取得日誌器
logger = get_logger("article_generator")


# ============================================================
# YouTube 嵌入函數
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
# 更新首頁
# ============================================================

def update_index_html(keyword, filename, category):
    """快速更新首頁的文章列表"""
    print(f"📊 更新首頁：{keyword}")
    logger.info(f"更新首頁：{keyword} -> {filename}")

    index_path = os.path.join(OUTPUT_DIR, "index.html")
    if not os.path.exists(index_path):
        from src.html_builder import create_default_index
        create_default_index()
        return

    try:
        with open(index_path, "r", encoding="utf-8") as f:
            content = f.read()

        if f'href="/{filename}"' in content:
            logger.debug(f"文章已存在於首頁：{filename}")
            return

        new_item = f'<li><span class="category">{category}</span><a href="/{filename}">{keyword}</a><span class="post-date">{datetime.now().strftime("%Y-%m-%d")}</span></li>\n'

        target = '<ul id="article-list">\n'
        if target in content:
            content = content.replace(target, target + new_item)
            with open(index_path, "w", encoding="utf-8") as f:
                f.write(content)
            logger.info(f"首頁已更新：{keyword}")
        else:
            logger.warning(f"無法找到文章列表目標位置：{filename}")
    except Exception as e:
        logger.error(f"更新首頁失敗：{e}")
        print(f"   ⚠️ 更新首頁失敗：{e}")


# ============================================================
# 清理 AI 原始內容
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


# ============================================================
# 核心函數：將純文字轉換為完整 HTML (v8.3 強化版)
# ============================================================

def text_to_html(content, keyword, category):
    """
    將 AI 生成的純文字內容轉換為完整的 HTML 結構
    自動識別標題、段落、列表
    強制生成 H1 標題
    🆕 強化內容邊界偵測：跳過 CSS 程式碼、HTML 標籤宣告
    🆕 優先使用 AI 生成的 H1 標題
    🆕 強化清單識別：支援純文字編號清單
    🆕 清理標題中的 HTML 標籤殘留
    🆕 防止 CSS 選擇器被誤判為 H2 標題
    """
    if not content:
        return None

    content = clean_raw_html(content)
    lines = content.split('\n')

    # ============================================================
    # 🆕 強化：偵測並跳過 CSS 程式碼區塊
    # ============================================================
    css_patterns = [
        r'^[a-zA-Z\-_]+\s*\{',           # CSS 選擇器
        r'^font-family:',
        r'^line-height:',
        r'^color:',
        r'^max-width:',
        r'^margin:',
        r'^padding:',
        r'^background-',
        r'^display:',
        r'^text-align:',
        r'^border-',
        r'^font-size:',
        r'^font-weight:',
        r'^@media',
        r'^\.',
        r'^#',
        r'^[a-zA-Z\-_]+\s*\{',           # 任何 CSS 選擇器
    ]

    # 過濾掉 CSS 程式碼行
    filtered_lines = []
    in_css_block = False

    for line in lines:
        line_stripped = line.strip()
        if not line_stripped:
            filtered_lines.append(line)
            continue

        # 檢查 CSS 區塊開始
        if re.search(r'^[a-zA-Z\-_\.#]+\s*\{', line_stripped):
            in_css_block = True
            continue

        # 檢查 CSS 區塊結束
        if line_stripped == '}' or line_stripped.endswith('}'):
            in_css_block = False
            continue

        # 如果在 CSS 區塊內，跳過
        if in_css_block:
            continue

        # 檢查是否為 CSS 屬性
        is_css = False
        for pattern in css_patterns:
            if re.search(pattern, line_stripped, re.IGNORECASE):
                is_css = True
                break

        # 檢查是否為 CSS 註解
        if line_stripped.startswith('/*') or line_stripped.startswith('*'):
            is_css = True

        # 檢查是否為 CSS 屬性（含冒號）
        if ':' in line_stripped and '{' not in line_stripped and '}' not in line_stripped:
            parts = line_stripped.split(':', 1)
            if len(parts) == 2:
                prop = parts[0].strip()
                css_props = ['font', 'color', 'margin', 'padding', 'border', 'background',
                            'display', 'width', 'height', 'max', 'min', 'line', 'text',
                            'vertical', 'position', 'top', 'bottom', 'left', 'right',
                            'z-index', 'opacity', 'overflow', 'box', 'transform', 'transition',
                            'flex', 'grid', 'align', 'justify', 'gap', 'float', 'clear',
                            'list', 'table', 'content', 'cursor', 'pointer', 'hover',
                            'outline', 'visibility', 'white-space', 'word', 'letter',
                            'text-decoration', 'text-transform', 'vertical-align']
                if any(prop.startswith(p) for p in css_props):
                    is_css = True

        if not is_css:
            filtered_lines.append(line)

    lines = filtered_lines

    # ============================================================
    # 🆕 強化：偵測真正的內容起始位置
    # ============================================================
    start_idx = 0
    found_content_start = False

    for i, line in enumerate(lines):
        line_stripped = line.strip()
        if not line_stripped:
            continue

        # 跳過明顯的 HTML 標籤宣告
        if line_stripped.startswith('<!DOCTYPE') or line_stripped.startswith('<html'):
            continue
        if line_stripped.startswith('<head') or line_stripped.startswith('<body'):
            continue
        if line_stripped.startswith('<header') or line_stripped.startswith('<footer'):
            continue
        if line_stripped.startswith('<div') or line_stripped.startswith('<section'):
            continue

        # 偵測真實內容開始：標題、段落、列表標記
        content_indicators = [
            r'^[#*⃣]\s*',           # Markdown 標題
            r'^[一二三四五六七八九十\d]+[、.．]\s*',  # 編號標題
            r'^[A-Za-z\u4e00-\u9fa5]',  # 中文或英文開頭
            r'^<h[1-6]',            # HTML 標題標籤
            r'^<p>',                # HTML 段落標籤
            r'^<ul>',               # HTML 列表
            r'^<ol>',               # HTML 有序列表
            r'^<blockquote',        # HTML 引用
        ]

        for indicator in content_indicators:
            if re.search(indicator, line_stripped):
                start_idx = i
                found_content_start = True
                break

        if found_content_start:
            break

    # 如果沒有找到內容起始，從第一個非空行開始
    if not found_content_start:
        for i, line in enumerate(lines):
            if line.strip():
                start_idx = i
                break

    lines = lines[start_idx:] if start_idx < len(lines) else lines

    # ============================================================
    # 強制提取 H1 標題（優先使用 AI 生成的標題）
    # ============================================================
    title = keyword
    description = f"{keyword} - 雅寶社區 · 頂客論壇"
    found_title = False

    # 🆕 優先從 AI 內容中提取 H1 標題
    for i, line in enumerate(lines[:30]):
        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^>\s*', '', clean_line)

        # 檢查是否為有效的標題（長度適中，不是 CSS 或程式碼）
        if len(clean_line) > 3 and len(clean_line) < 80:
            # 跳過 CSS 選擇器
            if re.match(r'^[a-zA-Z\-_\.#]+\s*\{', clean_line):
                continue
            # 跳過純數字或符號
            if re.match(r'^[\d\s\.]+$', clean_line):
                continue
            # 跳過 CSS 屬性
            if ':' in clean_line and '{' not in clean_line:
                continue
            # 跳過以 CSS 屬性開頭的行
            css_props_start = ['font', 'color', 'margin', 'padding', 'border', 'background',
                              'display', 'width', 'height', 'text', 'line', 'vertical']
            if any(clean_line.startswith(p) for p in css_props_start):
                continue

            title = clean_line
            lines[i] = ''
            found_title = True
            break

    # 如果沒找到合適的標題，使用 keyword
    if not found_title:
        title = keyword

    # 確保標題不包含 keyword 重複（如果 keyword 已包含在標題中）
    if title != keyword and keyword not in title:
        title = f"{keyword}｜{title}"

    # ============================================================
    # 開始構建 HTML
    # ============================================================
    html_parts = []
    html_parts.append(f'<h1>{title}</h1>')

    in_list = False
    in_ordered_list = False
    list_items = []
    ordered_items = []
    skip_next = False

    for i, line in enumerate(lines):
        if skip_next:
            skip_next = False
            continue

        line = line.strip()
        if not line:
            if in_list and list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False
            if in_ordered_list and ordered_items:
                html_parts.append('<ol>')
                for item in ordered_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ol>')
                ordered_items = []
                in_ordered_list = False
            continue

        # 跳過明顯的 HTML 標籤行
        html_tags_to_skip = [
            '<html', '</html>', '<head', '</head>',
            '<body', '</body>', '<!DOCTYPE',
            '<meta', '<link', '<script', '<title', '</title>',
            '<header', '</header>', '<article', '</article>',
            '<footer', '</footer>', '<main', '</main>',
            '<style', '</style>'
        ]
        should_skip = False
        for tag in html_tags_to_skip:
            if line.lower().startswith(tag.lower()):
                should_skip = True
                break
        if should_skip:
            continue

        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^《', '', clean_line)
        clean_line = re.sub(r'》$', '', clean_line)

        is_heading = False
        heading_level = 2

        # 檢查是否為標題
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
            # 🆕 跳過 CSS 選擇器
            if not re.match(r'^[a-zA-Z\-_\.#]+\s*\{', clean_line):
                # 🆕 跳過 CSS 屬性
                if not any(clean_line.startswith(p) for p in ['font', 'color', 'margin', 'padding', 'border', 'background', 'display', 'width', 'height', 'text', 'line']):
                    is_heading = True

        # 檢查是否為清單項目
        is_unordered_item = line.startswith('- ') or line.startswith('* ') or line.startswith('• ') or line.startswith('  - ')
        is_ordered_item = bool(re.match(r'^\d+[.、)）]\s', line))

        if not is_ordered_item:
            is_ordered_item = bool(re.match(r'^\d+[.、)）]\s+', line))

        if is_unordered_item:
            item_text = re.sub(r'^[\-\*\•]\s*', '', line).strip()
            if in_ordered_list and ordered_items:
                html_parts.append('<ol>')
                for item in ordered_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ol>')
                ordered_items = []
                in_ordered_list = False
            list_items.append(item_text)
            in_list = True
            continue

        if is_ordered_item:
            item_text = re.sub(r'^\d+[.、)）]\s*', '', line).strip()
            if in_list and list_items:
                html_parts.append('<ul>')
                for item in list_items:
                    html_parts.append(f'    <li>{item}</li>')
                html_parts.append('</ul>')
                list_items = []
                in_list = False
            ordered_items.append(item_text)
            in_ordered_list = True
            continue

        if in_list and list_items and not is_unordered_item:
            html_parts.append('<ul>')
            for item in list_items:
                html_parts.append(f'    <li>{item}</li>')
            html_parts.append('</ul>')
            list_items = []
            in_list = False

        if in_ordered_list and ordered_items and not is_ordered_item:
            html_parts.append('<ol>')
            for item in ordered_items:
                html_parts.append(f'    <li>{item}</li>')
            html_parts.append('</ol>')
            ordered_items = []
            in_ordered_list = False

        if is_heading:
            if clean_line == title or clean_line in title:
                continue

            # 清理標題中的 HTML 標籤殘留
            clean_line = re.sub(r'<[^>]+>', '', clean_line).strip()

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

    if in_ordered_list and ordered_items:
        html_parts.append('<ol>')
        for item in ordered_items:
            html_parts.append(f'    <li>{item}</li>')
        html_parts.append('</ol>')

    body_content = '\n'.join(html_parts)

    # 確保至少有 H2
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
# 🖼️ 智慧配圖系統 v3.3 - 分類同步版
# ============================================================

CATEGORY_VISUALS = {
    "🌟 人生哲理": "a person meditating peacefully in a modern minimalist room, digital detox concept, laptop on desk, soft natural lighting, calm serene atmosphere",
    "💻 3C 科技教學": "modern workspace with laptop, smartphone, tablet, clean technology gadgets on wooden desk, minimal background",
    "📊 軟體評測": "computer screen showing data visualization dashboard, sleek software interface, modern office setup, blue and white color scheme",
    "🏠 生活小常識": "cozy home interior with organized spaces, warm lighting, comfortable living room, bright daylight",
    "🎮 遊戲攻略": "gaming setup with RGB keyboard, gaming monitor, headset, vibrant neon lighting, esports style",
    "🤖 AI 趨勢": "artificial intelligence concept, digital brain, futuristic tech network, glowing circuit board, cyan and blue lights",
    "🎵 音樂創作": "musical instruments, vinyl record, warm studio lighting, creative atmosphere, music production",
    "🎵 台語音樂": "musical instruments, vinyl record, warm studio lighting, creative atmosphere, music production",
}

STYLE_SUFFIX = "vector illustration, clean line art, minimal corporate editorial style, soft color palette, professional design, crisp details, 8k"


def _build_english_visual_prompt(keyword, category):
    """將主題轉化為適合 AI 生圖的英文視覺提示詞"""
    base_visual = CATEGORY_VISUALS.get(category)
    if not base_visual:
        base_visual = f"concept visualization for {keyword}, modern professional setting"

    keyword_hints = []

    if "正念" in keyword or "平靜" in keyword or "專注" in keyword:
        keyword_hints.append("meditation, calmness, focus, mindfulness")
    if "數位" in keyword or "科技" in keyword:
        keyword_hints.append("digital device screen, technology interface")
    if "壓力" in keyword or "焦慮" in keyword:
        keyword_hints.append("stress relief, peaceful environment")
    if "評測" in keyword or "比較" in keyword:
        keyword_hints.append("product comparison chart, side by side view")
    if "教學" in keyword or "指南" in keyword:
        keyword_hints.append("instructional step by step guide style")
    if "NAS" in keyword or "雲端" in keyword or "儲存" in keyword:
        keyword_hints.append("network attached storage device, data server, cloud storage concept")

    full_prompt = base_visual
    if keyword_hints:
        full_prompt += f", {', '.join(keyword_hints)}"
    full_prompt += f", {STYLE_SUFFIX}"

    return full_prompt


def _make_responsive_image(img_tag):
    """將圖片標籤轉為響應式，並防止變形"""
    return img_tag.replace(
        'width="800"',
        'style="width:100%;max-width:800px;height:auto;aspect-ratio:16/9;object-fit:cover;border-radius:12px;margin:20px 0;box-shadow:0 4px 12px rgba(0,0,0,0.08);"'
    )


def generate_and_embed_image(html_content, keyword, category, retry_count=1):
    """使用 Pollinations AI 生成配圖，並嵌入文章"""
    print("   🖼️ 正在生成配圖（Pollinations AI）...")
    logger.info(f"生成配圖：{keyword}")

    try:
        router = ModelRouter()

        visual_prompt = _build_english_visual_prompt(keyword, category)
        if len(visual_prompt) > 180:
            visual_prompt = visual_prompt[:180]

        encoded_prompt = urllib.parse.quote(visual_prompt)
        print(f"   📝 生圖提示詞（英文）：{visual_prompt[:80]}...")
        logger.debug(f"生圖提示詞：{visual_prompt}")

        safe_filename = re.sub(r'[\\/*?:"<>|]', '', keyword)[:50]

        result = router.generate_image_pollinations(
            prompt=encoded_prompt,
            filename=f"article_{safe_filename}",
            width=1024,
            height=576
        )

        if result.get("img_tag"):
            responsive_img = _make_responsive_image(result["img_tag"])

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

            logger.info(f"配圖生成成功：{keyword}")
            return html_content, True

        else:
            error_msg = result.get('error', 'API 無回應') if result else '無回傳內容'
            print(f"   ⚠️ 配圖生成失敗：{error_msg}")
            logger.warning(f"配圖生成失敗 (嘗試 {retry_count})：{error_msg}")

            if retry_count < 3:
                print(f"   🔄 3 秒後重試... (第 {retry_count + 1} 次)")
                time.sleep(3)
                return generate_and_embed_image(html_content, keyword, category, retry_count + 1)

            return html_content, False

    except Exception as e:
        print(f"   ⚠️ 配圖生成異常：{e}")
        logger.error(f"配圖生成異常：{e}")
        return html_content, False


# ============================================================
# 生成單一文章
# ============================================================

def generate_article(item):
    """生成單一篇文章，並自動生成配圖，並支援 YouTube 影片嵌入"""
    keyword = item["keyword"]
    category = item["category"]
    filename = item["filename"]
    video_id = item.get("video_id", "")

    use_responses_api = item.get("use_responses_api", False)
    enable_reasoning = item.get("enable_reasoning", False)
    enable_search = item.get("enable_search", False)

    file_path = os.path.join(OUTPUT_DIR, filename)

    os.makedirs(os.path.dirname(file_path), exist_ok=True)

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
        print(f"🤖 正在生成：{keyword}（分類：{category}）[API: {api_label}{feature_str}]")
    else:
        print(f"🤖 正在生成：{keyword}（分類：{category}）[API: {api_label}]")

    logger.info(f"開始生成文章：{keyword} (API: {api_label}, Reasoning: {enable_reasoning}, Search: {enable_search})")

    client = APIClient()
    raw_content = None
    generation_attempts = 0
    max_attempts = 2

    while generation_attempts < max_attempts:
        generation_attempts += 1
        try:
            if use_responses_api:
                prompt = client.build_article_prompt(keyword, category)
                raw_content = client.generate_with_responses_api(
                    prompt=prompt,
                    instructions="你是專業的繁體中文內容創作者，擅長 SEO 友善文章。",
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

            print(f"   ⚠️ 生成結果較短 ({len(raw_content) if raw_content else 0} 字)，嘗試重新生成...")
            logger.warning(f"生成結果較短 ({len(raw_content) if raw_content else 0} 字)，重試 {generation_attempts}/{max_attempts}")

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

    print("   🔧 將內容轉換為完整 HTML 結構...")
    html_content = text_to_html(raw_content, keyword, category)

    if not html_content:
        print(f"❌ HTML 轉換失敗：{keyword}")
        logger.error(f"HTML 轉換失敗：{keyword}")
        return

    html_content = build_article_html(keyword=keyword, category=category, raw_html=html_content, video_id=video_id)

    if video_id:
        youtube_embed = create_youtube_embed(video_id)
        if '<body>' in html_content:
            html_content = html_content.replace('<body>', f'<body>\n{youtube_embed}', 1)
        else:
            html_content = youtube_embed + html_content
        print(f"   ✅ 已嵌入 YouTube 影片：{video_id}")
        logger.info(f"已嵌入 YouTube 影片：{video_id}")

    html_content, image_generated = generate_and_embed_image(html_content, keyword, category)

    quality_report = check_article_quality(html_content, keyword)

    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ H1 標題：{quality_report.get('h1_count', 0)} 個 {'✅' if quality_report.get('h1_count', 0) >= 1 else '❌ 無'}")
    print(f"   └─ H2 標題：{quality_report.get('h2_count', 0)} 個")
    print(f"   └─ 配圖：{'✅ 已生成' if image_generated else '⚠️ 未生成'}")
    print(f"   └─ API：{'Responses' if item.get('use_responses_api', False) else 'Chat'}")
    if item.get('enable_reasoning', False):
        print(f"   └─ 思維鏈：✅ 已啟用")
    if item.get('enable_search', False):
        print(f"   └─ 網頁搜尋：✅ 已啟用")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標（仍會寫入）'}")

    logger.info(f"品質報告：{keyword} 分數 {quality_report['score']}/100，通過 {quality_report['passed']}")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"✨ 成功寫入：{file_path}")
    logger.info(f"文章已寫入：{file_path}")

    update_index_html(keyword, filename, category)

    time.sleep(2)


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


# ============================================================
# 測試（僅在直接執行時觸發）
# ============================================================

if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("  🧪 article_generator.py v8.3 測試")
    print("=" * 50 + "\n")

    # 測試 1：Chat API
    print("📝 測試 1：Chat API")
    test_item_1 = {
        "keyword": "2026 年 AI 趨勢簡介",
        "category": "🤖 AI 趨勢",
        "filename": "test/test-chat-api-v83.html",
        "use_responses_api": False
    }
    generate_article(test_item_1)

    # 測試 2：Responses API + Reasoning
    print("\n📝 測試 2：Responses API + Reasoning")
    test_item_2 = {
        "keyword": "2026 年 AI 趨勢深度分析（含思維鏈）",
        "category": "🤖 AI 趨勢",
        "filename": "test/test-responses-reasoning-v83.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    }
    generate_article(test_item_2)

    print("\n✅ 測試完成")