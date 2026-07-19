# ============================================================
# article_generator.py - 文章生成核心模組
# ============================================================
# 功能：生成單一文章、過濾待生成清單
# ============================================================

import os
import time
from datetime import datetime
from src.config import OUTPUT_DIR, CURRENT_DATE_STR
from src.api_client import call_api, get_current_api_info
from src.html_builder import build_article_html, clean_ai_header
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

    system_prompt = (
        "你是一位擁有 20 年經驗的資深網路編輯與 SEO 專家。\n"
        f"當前時間是 {CURRENT_DATE_STR}。\n"
        "請針對關鍵字撰寫一篇高質量的繁體中文文章。\n\n"
        "【內容要求】\n"
        "1. 包含實操步驟、對比表格、常見問題（FAQ）。\n"
        "2. 使用 H2、H3 小標題分段。\n"
        "3. 字數至少 1500 字。\n\n"
        "【強制品牌與導航要求】\n"
        "1. 文章標題必須包含『雅寶社區 · 頂客論壇』。\n"
        "2. 開頭必須有『雅寶社區 · 頂客論壇 (AHPAL.COM)』。\n"
        "3. 結尾必須加入返回首頁連結。\n"
        "4. 加入返回頂部按鈕。\n\n"
        "【輸出格式】\n"
        "直接輸出完整 HTML，不要包含 Markdown 標記。"
    )

    user_prompt = f"關鍵字：{keyword}\n分類：{category}\n網站：雅寶社區 · 頂客論壇 (AHPAL.COM)"

    raw_html = call_api(user_prompt, system_prompt, max_tokens=16384)

    if not raw_html:
        print(f"❌ 生成失敗：{keyword}")
        return

    # 清理 Markdown 標記
    if raw_html.startswith("```html"):
        raw_html = raw_html.replace("```html", "").replace("```", "").strip()
    elif raw_html.startswith("```"):
        raw_html = raw_html.replace("```", "").strip()

    # 建構完整 HTML
    html_content = build_article_html(keyword, category, raw_html)

    # 品質檢查
    quality_report = check_article_quality(html_content, keyword)

    print(f"📊 品質報告：{keyword}")
    print(f"   └─ 分數：{quality_report['score']}/100")
    print(f"   └─ 字數：{quality_report['word_count']} 字")
    print(f"   └─ 結果：{'✅ 通過' if quality_report['passed'] else '⚠️ 未達標'}")

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
