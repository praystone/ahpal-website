# ============================================================
# quality_checker.py - 文章品質檢查模組
# ============================================================
# 功能：檢查文章品質（字數、H2、表格、FAQ）
# ============================================================

import re
from src.config import MIN_WORDS, MIN_HEADINGS

def check_article_quality(html_content, keyword):
    """檢查文章品質，回傳分數與詳細報告"""
    print(f"🔍 正在檢查文章品質：{keyword}")

    text_only = re.sub(r'<[^>]+>', ' ', html_content)
    text_only = re.sub(r'\s+', ' ', text_only).strip()
    word_count = len(text_only)

    h2_count = len(re.findall(r'<h2[^>]*>.*?</h2>', html_content, re.IGNORECASE | re.DOTALL))
    h3_count = len(re.findall(r'<h3[^>]*>.*?</h3>', html_content, re.IGNORECASE | re.DOTALL))

    has_table = bool(re.search(r'<table[^>]*>.*?</table>', html_content, re.IGNORECASE | re.DOTALL))
    has_faq = bool(re.search(r'(FAQ|常見問題|Q：|問：|Q&A)', html_content, re.IGNORECASE))
    has_list = bool(re.search(r'<(ul|ol)[^>]*>.*?</(ul|ol)>', html_content, re.IGNORECASE | re.DOTALL))

    score = 0
    details = []

    if word_count >= MIN_WORDS:
        score += 35
        details.append(f"✅ 字數 {word_count} 字（達標）")
    elif word_count >= MIN_WORDS * 0.7:
        score += 20
        details.append(f"⚠️ 字數 {word_count} 字（略低）")
    else:
        details.append(f"❌ 字數 {word_count} 字（嚴重不足）")

    if h2_count >= MIN_HEADINGS:
        score += 25
        details.append(f"✅ H2 標題 {h2_count} 個（達標）")
    elif h2_count >= 2:
        score += 12
        details.append(f"⚠️ H2 標題 {h2_count} 個（建議至少 {MIN_HEADINGS} 個）")
    else:
        details.append(f"❌ H2 標題 {h2_count} 個（嚴重不足）")

    if has_table:
        score += 15
        details.append("✅ 包含表格")
    else:
        details.append("⚠️ 未包含表格（建議加入對比表格）")

    if has_faq:
        score += 15
        details.append("✅ 包含 FAQ")
    else:
        details.append("⚠️ 未包含 FAQ（建議加入常見問題）")

    if has_list:
        score += 10
        details.append("✅ 包含清單")
    else:
        details.append("ℹ️ 未包含清單（加分項）")

    passed = score >= 60

    return {
        "passed": passed,
        "score": score,
        "word_count": word_count,
        "h2_count": h2_count,
        "h3_count": h3_count,
        "has_table": has_table,
        "has_faq": has_faq,
        "has_list": has_list,
        "details": "\n".join(details)
    }
