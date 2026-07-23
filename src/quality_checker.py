# ============================================================
# quality_checker.py - 文章品質檢查模組 v2.0
# ============================================================
# 功能：檢查文章品質（字數、H1、H2、表格、FAQ、品牌連結）
# 修正：加入 H1 標題檢查，確保 SEO 完整性
# 修正：評分標準優化，總分 100 分
# ============================================================

import re
from src.config import MIN_WORDS, MIN_HEADINGS

def check_article_quality(html_content, keyword):
    """
    檢查文章品質，回傳分數與詳細報告
    
    評分項目：
    - H1 標題：20 分（必須）
    - H2 標題：25 分（必須至少 3 個）
    - 字數：25 分（至少 1200 字）
    - 表格：10 分（加分項）
    - FAQ：10 分（加分項）
    - 清單：5 分（加分項）
    - 品牌連結：5 分（加分項）
    
    總分：100 分，60 分以上通過
    """
    print(f"🔍 正在檢查文章品質：{keyword}")

    # 移除 HTML 標籤計算純文字
    text_only = re.sub(r'<[^>]+>', ' ', html_content)
    text_only = re.sub(r'\s+', ' ', text_only).strip()
    word_count = len(text_only)

    # 檢查標題（使用正則表達式匹配）
    h1_count = len(re.findall(r'<h1[^>]*>.*?</h1>', html_content, re.IGNORECASE | re.DOTALL))
    h2_count = len(re.findall(r'<h2[^>]*>.*?</h2>', html_content, re.IGNORECASE | re.DOTALL))
    h3_count = len(re.findall(r'<h3[^>]*>.*?</h3>', html_content, re.IGNORECASE | re.DOTALL))
    
    # 檢查其他元素
    has_table = bool(re.search(r'<table[^>]*>.*?</table>', html_content, re.IGNORECASE | re.DOTALL))
    has_faq = bool(re.search(r'(FAQ|常見問題|Q：|問：|Q&A|問答)', html_content, re.IGNORECASE))
    has_list = bool(re.search(r'<(ul|ol)[^>]*>.*?</(ul|ol)>', html_content, re.IGNORECASE | re.DOTALL))
    
    # 檢查是否有品牌連結（雅寶社區可點擊連結）
    has_brand_link = bool(re.search(
        r'<a[^>]*href=["\']/?["\'][^>]*>.*?雅寶社區.*?</a>', 
        html_content, 
        re.IGNORECASE | re.DOTALL
    ))
    
    # 檢查是否有返回首頁連結
    has_home_link = bool(re.search(
        r'<a[^>]*href=["\']/["\'][^>]*>.*?返回首頁.*?</a>',
        html_content,
        re.IGNORECASE | re.DOTALL
    ))

    # ============================================================
    # 評分計算（總分 100）
    # ============================================================
    score = 0
    details = []

    # 1. H1 標題檢查（20 分）- 必須有
    if h1_count >= 1:
        score += 20
        details.append(f"✅ H1 標題：{h1_count} 個（達標）")
    else:
        details.append(f"❌ H1 標題：{h1_count} 個（嚴重不足，請加入 H1 標題）")

    # 2. H2 標題檢查（25 分）- 至少 3 個
    if h2_count >= MIN_HEADINGS:
        score += 25
        details.append(f"✅ H2 標題：{h2_count} 個（達標）")
    elif h2_count >= 2:
        score += 15
        details.append(f"⚠️ H2 標題：{h2_count} 個（建議至少 {MIN_HEADINGS} 個）")
    else:
        details.append(f"❌ H2 標題：{h2_count} 個（嚴重不足）")

    # 3. 字數檢查（25 分）
    if word_count >= MIN_WORDS:
        score += 25
        details.append(f"✅ 字數：{word_count} 字（達標）")
    elif word_count >= MIN_WORDS * 0.7:
        score += 15
        details.append(f"⚠️ 字數：{word_count} 字（略低，建議至少 {MIN_WORDS} 字）")
    else:
        details.append(f"❌ 字數：{word_count} 字（嚴重不足）")

    # 4. 表格檢查（10 分）- 加分項
    if has_table:
        score += 10
        details.append("✅ 包含表格（加分）")
    else:
        details.append("ℹ️ 未包含表格（可選加分項）")

    # 5. FAQ 檢查（10 分）- 加分項
    if has_faq:
        score += 10
        details.append("✅ 包含 FAQ（加分）")
    else:
        details.append("ℹ️ 未包含 FAQ（可選加分項）")

    # 6. 清單檢查（5 分）- 加分項
    if has_list:
        score += 5
        details.append("✅ 包含清單（加分）")
    else:
        details.append("ℹ️ 未包含清單（可選加分項）")

    # 7. 品牌連結檢查（5 分）- 加分項
    if has_brand_link:
        score += 5
        details.append("✅ 包含品牌連結")
    else:
        details.append("ℹ️ 品牌連結由系統自動加入")

    # 是否通過（60 分以上通過）
    passed = score >= 60

    return {
        "passed": passed,
        "score": score,
        "word_count": word_count,
        "h1_count": h1_count,
        "h2_count": h2_count,
        "h3_count": h3_count,
        "has_h1": h1_count >= 1,      # 供外部快速判斷
        "has_table": has_table,
        "has_faq": has_faq,
        "has_list": has_list,
        "has_brand_link": has_brand_link,
        "has_home_link": has_home_link,
        "details": "\n".join(details)
    }


def check_article_quality_simple(html_content):
    """
    簡化版品質檢查（快速檢查）
    只回傳基本的品質指標
    """
    # 移除 HTML 標籤計算純文字
    text_only = re.sub(r'<[^>]+>', ' ', html_content)
    text_only = re.sub(r'\s+', ' ', text_only).strip()
    word_count = len(text_only)

    h1_count = len(re.findall(r'<h1[^>]*>.*?</h1>', html_content, re.IGNORECASE | re.DOTALL))
    h2_count = len(re.findall(r'<h2[^>]*>.*?</h2>', html_content, re.IGNORECASE | re.DOTALL))
    
    # 檢查是否包含必要元素
    has_body = '<body' in html_content
    has_head = '<head' in html_content
    has_title = '<title' in html_content
    
    return {
        "word_count": word_count,
        "h1_count": h1_count,
        "h2_count": h2_count,
        "has_body": has_body,
        "has_head": has_head,
        "has_title": has_title,
        "is_complete": has_body and has_head and has_title and h1_count >= 1
    }


# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    # 測試範例
    test_html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>測試文章</title>
    </head>
    <body>
        <h1>測試標題</h1>
        <h2>第一章</h2>
        <p>內容</p>
        <h2>第二章</h2>
        <p>內容</p>
        <h2>第三章</h2>
        <p>內容</p>
        <p>更多內容...</p>
        <ul>
            <li>項目1</li>
            <li>項目2</li>
        </ul>
        <a href="/">雅寶社區</a>
    </body>
    </html>
    '''
    
    result = check_article_quality(test_html, "測試")
    print("\n📊 測試結果：")
    print(f"   └─ 分數：{result['score']}/100")
    print(f"   └─ 通過：{result['passed']}")
    print(f"   └─ H1 標題：{result['h1_count']} 個")
    print(f"   └─ H2 標題：{result['h2_count']} 個")
    print(f"   └─ 字數：{result['word_count']} 字")
    print("\n詳細報告：")
    print(result['details'])