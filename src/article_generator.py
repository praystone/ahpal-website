# ============================================================
# article_generator.py - 文章生成核心模組 v8.6
# ============================================================
# 修復與優化 (v8.6)：
#   - 🔧 徹底重構 _clean_css_residue()，完整清除所有 CSS 殘留
#   - 🔧 包含 .table-of-contents、@media、完整 CSS 區塊
#   - 🔧 修正 H2 計數邏輯：在 Markdown 轉換為 HTML 之後才計算
#   - 🔧 移除強制插入「xxx 的基礎介紹」模板 (防止萬用標題)
#   - 🔧 統一 description 定義，避免 NameError
#   - 🔧 強化二次防護過濾，徹底清除 CSS 屬性與選擇器
#   - 🔧 測試區改用 📜 歷史腦洞 分類
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
# 🆕 v8.6: 徹底清除 CSS 殘留 (完整版)
# ============================================================

def _clean_css_residue(content):
    """
    強力過濾所有 CSS 語法殘留，防範 Markdown 誤判
    v8.6: 完整清除所有 CSS 選擇器、屬性、註解、@media 規則
    """
    if not content:
        return content

    # 1. 移除完整 CSS 區塊 (含跨行 { ... })
    content = re.sub(
        r'(?i)(h[1-6]|body|div|p|span|a|img|\.table-of-contents|\.\w+|@media)[^{]*\{[^}]*\}',
        '',
        content,
        flags=re.DOTALL
    )

    # 2. 移除裸露的 CSS 選擇器殘留 (行首)
    content = re.sub(
        r'(?m)^\s*(h[1-6]|body|div|p|span|a|img|\.[\w-]+|#[\w-]+|@media[^{]+)\s*\{\s*$',
        '',
        content
    )

    # 3. 移除裸露的 CSS 閉合大括號
    content = re.sub(r'(?m)^\s*\}\s*$', '', content)

    # 4. 移除常見 CSS 屬性行
    content = re.sub(
        r'(?m)^\s*(font|color|background|margin|padding|border|display|position|width|height|max-width|overflow|text-align|flex|grid|gap|font-size|font-weight|line-height|text-decoration|vertical-align|cursor|z-index|opacity|transform|transition|animation|box-shadow|justify-content|align-items)[^:\n]*:[^;\n]+;\s*$',
        '',
        content
    )

    # 5. 移除 CSS 註解
    content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)

    # 6. 清理多餘空行
    content = re.sub(r'\n\s*\n\s*\n', '\n\n', content)

    return content


# ============================================================
# 🆕 表格結構標準化函數
# ============================================================

def _normalize_tables(html_content):
    """
    修正 AI 輸出的無效表格結構
    將 <p><table>...</table></p> 轉換為標準 <table>...</table>
    """
    if not html_content:
        return html_content

    html_content = re.sub(r'<p>\s*<table', '<table', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'</table>\s*</p>', '</table>', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'</p>\s*<table', '<table', html_content, flags=re.IGNORECASE)
    html_content = re.sub(r'</table>\s*<p>', '</table>', html_content, flags=re.IGNORECASE)

    return html_content


# ============================================================
# 核心函數：將純文字轉換為完整 HTML (v8.6 徹底修復版)
# ============================================================

def text_to_html(content, keyword, category):
    """
    將 AI 生成的純文字內容轉換為完整的 HTML 結構
    v8.6: 徹底清除 CSS 殘留、修正 H2 計數邏輯、移除萬用模板
    """
    if not content:
        return None

    content = clean_raw_html(content)
    content = _clean_css_residue(content)

    lines = content.split('\n')

    # ============================================================
    # 二次防護：徹底過濾所有 CSS 相關行
    # ============================================================
    filtered_lines = []
    for line in lines:
        line_s = line.strip()

        # 跳過 CSS 選擇器行
        if re.search(r'^\s*(h[1-6]|body|div|p|span|a|img|\.[\w-]+|#[\w-]+|@media).*\{', line_s):
            continue
        # 跳過 CSS 屬性行
        if re.search(r'^\s*[\w-]+\s*:\s*[^;]+;', line_s):
            continue
        # 跳過 CSS 閉合大括號
        if re.search(r'^\s*\}\s*$', line_s):
            continue
        # 跳過 CSS 註解
        if re.search(r'^\s*/\*', line_s):
            continue

        filtered_lines.append(line)

    lines = filtered_lines

    # ============================================================
    # 偵測真正的內容起始位置
    # ============================================================
    start_idx = 0
    found_content_start = False

    for i, line in enumerate(lines):
        line_stripped = line.strip()
        if not line_stripped:
            continue

        if line_stripped.startswith('<!DOCTYPE') or line_stripped.startswith('<html'):
            continue
        if line_stripped.startswith('<head') or line_stripped.startswith('<body'):
            continue
        if line_stripped.startswith('<header') or line_stripped.startswith('<footer'):
            continue
        if line_stripped.startswith('<div') or line_stripped.startswith('<section'):
            continue

        content_indicators = [
            r'^[#*⃣]\s*',
            r'^[一二三四五六七八九十\d]+[、.．]\s*',
            r'^[A-Za-z\u4e00-\u9fa5]',
            r'^<h[1-6]',
            r'^<p>',
            r'^<ul>',
            r'^<ol>',
            r'^<blockquote',
        ]

        for indicator in content_indicators:
            if re.search(indicator, line_stripped):
                start_idx = i
                found_content_start = True
                break

        if found_content_start:
            break

    if not found_content_start:
        for i, line in enumerate(lines):
            if line.strip():
                start_idx = i
                break

    lines = lines[start_idx:] if start_idx < len(lines) else lines

    # ============================================================
    # 提取 H1 標題 (優先使用 AI 生成的標題)
    # ============================================================
    title = keyword
    description = f"{keyword} - 雅寶社區 · 頂客論壇"
    found_title = False

    for i, line in enumerate(lines[:30]):
        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)
        clean_line = re.sub(r'^>\s*', '', clean_line)

        if len(clean_line) > 3 and len(clean_line) < 80:
            # 跳過 CSS 選擇器
            if re.match(r'^[a-zA-Z\-_\.#]+\s*\{', clean_line):
                continue
            if re.match(r'^[\d\s\.]+$', clean_line):
                continue
            if ':' in clean_line and '{' not in clean_line:
                continue

            css_props_start = ['font', 'color', 'margin', 'padding', 'border', 'background',
                              'display', 'width', 'height', 'text', 'line', 'vertical']
            if any(clean_line.startswith(p) for p in css_props_start):
                continue

            if re.match(r'^h[1-6]\s*$', clean_line.lower()):
                continue

            title = clean_line
            lines[i] = ''
            found_title = True
            break

    if not found_title:
        title = keyword

    if title != keyword and keyword not in title:
        title = f"{keyword}｜{title}"

    # ============================================================
    # 構建 HTML (解析 Markdown 標題、段落、列表)
    # ============================================================
    html_parts = []
    html_parts.append(f'<h1>{title}</h1>')

    in_list = False
    in_ordered_list = False
    list_items = []
    ordered_items = []

    for i, line in enumerate(lines):
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

        # 跳過 HTML 標籤行
        html_tags_to_skip = ['<html', '</html>', '<head', '</head>', '<body', '</body>',
                             '<!DOCTYPE', '<meta', '<link', '<script', '<title', '</title>',
                             '<header', '</header>', '<footer', '</footer>', '<style', '</style>']
        if any(line.lower().startswith(tag.lower()) for tag in html_tags_to_skip):
            continue

        clean_line = re.sub(r'^[#*⃣\-\s]+', '', line).strip()
        clean_line = re.sub(r'^#{1,6}\s*', '', clean_line)

        # 判斷是否為標題
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
        elif (len(clean_line) < 60 and not clean_line.endswith(('。', '？', '！', '」', '：', ';', ',')) and len(clean_line) > 3):
            if not re.match(r'^[a-zA-Z\-_\.#]+\s*\{', clean_line):
                if not any(clean_line.startswith(p) for p in ['font', 'color', 'margin', 'padding', 'border', 'background', 'display', 'width', 'height', 'text', 'line']):
                    is_heading = True

        # 判斷清單
        is_unordered_item = line.startswith('- ') or line.startswith('* ') or line.startswith('• ')
        is_ordered_item = bool(re.match(r'^\d+[.、)）]\s', line))

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
            clean_line = re.sub(r'<[^>]+>', '', clean_line).strip()

            if not clean_line or len(clean_line) < 2:
                continue

            if clean_line.lower() in ['h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'body', 'div', 'p', 'span', 'a', 'img', 'table', 'tr', 'td', 'th']:
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

    if in_ordered_list and ordered_items:
        html_parts.append('<ol>')
        for item in ordered_items:
            html_parts.append(f'    <li>{item}</li>')
        html_parts.append('</ol>')

    body_content = '\n'.join(html_parts)

    # 移除空的 H2 標籤
    body_content = re.sub(r'<h2>\s*</h2>', '', body_content)
    body_content = re.sub(r'<h3>\s*</h3>', '', body_content)

    # ============================================================
    # 🆕 v8.6: 修正 H2 計數邏輯 — 在 HTML 轉換完成後才計算
    # ============================================================
    h2_count = body_content.count('<h2>')

    # 只有真正缺少 H2 時才記錄警告，不再強制插入萬用模板
    if h2_count < 2:
        logger.warning(f"⚠️ 文章 H2 數量偏低 ({h2_count})，建議檢查 AI 輸出內容")

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

    full_html = _normalize_tables(full_html)
    return full_html


# ============================================================
# 🖼️ 智慧配圖系統 v3.4 - 優化插入位置
# ============================================================

CATEGORY_VISUALS = {
    "📜 歷史腦洞": "ancient Chinese battlefield with dramatic lighting, epic historical scene, traditional ink painting style, cinematic atmosphere",
    "🌟 人生哲理": "a person meditating peacefully in a modern minimalist room, digital detox concept, laptop on desk, soft natural lighting, calm serene atmosphere",
    "💻 3C 科技教學": "modern workspace with laptop, smartphone, tablet, clean technology gadgets on wooden desk, minimal background",
    "📊 軟體評測": "computer screen showing data visualization dashboard, sleek software interface, modern office setup, blue and white color scheme",
    "🏠 生活小常識": "cozy home interior with organized spaces, warm lighting, comfortable living room, bright daylight",
    "🎮 遊戲攻略": "gaming setup with RGB keyboard, gaming monitor, headset, vibrant neon lighting, esports style",
    "🤖 AI 趨勢": "artificial intelligence concept, digital brain, futuristic tech network, glowing circuit board, cyan and blue lights",
    "🎵 音樂創作": "musical instruments, vinyl record, warm studio lighting, creative atmosphere, music production",
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
    """將圖片標籤轉為響應式"""
    return img_tag.replace(
        'width="800"',
        'style="width:100%;max-width:800px;height:auto;aspect-ratio:16/9;object-fit:cover;border-radius:12px;margin:20px 0;box-shadow:0 4px 12px rgba(0,0,0,0.08);"'
    )


def generate_and_embed_image(html_content, keyword, category, retry_count=1):
    """使用 Pollinations AI 生成配圖，並嵌入文章 (優化插入位置)"""
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

            # 🆕 v8.5: 優化插入位置 — 置於 H1 之後，而非段落之後
            h1_close_match = re.search(r'</h1>', html_content, re.IGNORECASE)
            if h1_close_match:
                pos = h1_close_match.end()
                html_content = html_content[:pos] + '\n' + responsive_img + '\n' + html_content[pos:]
                print(f"   ✅ 配圖已插入文章 H1 標題之後")
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
# 測試
# ============================================================

if __name__ == "__main__":
    print("\n" + "=" * 50)
    print("  🧪 article_generator.py v8.6 測試")
    print("=" * 50 + "\n")

    test_item = {
        "keyword": "三國普通農民視角：今天曹操來了，明天劉備又來了",
        "category": "📜 歷史腦洞",
        "filename": "history/three-kingdoms-peasant-perspective.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    }
    generate_article(test_item)
    print("\n✅ 測試完成")