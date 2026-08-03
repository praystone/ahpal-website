# ============================================================
# quality_checker.py - 文章品質檢查模組 v4.0
# ============================================================
# 功能：
#   1. 文章品質檢查（字數、H1、H2、表格、FAQ、品牌連結）
#   2. 🆕 遊戲頁面智慧辨識（自動跳過，給予 100 分）
#   3. 🆕 品質報告寫入日誌
# ============================================================

import os
import re
from pathlib import Path
from src.config import MIN_WORDS, MIN_HEADINGS
from src.logger import get_logger

logger = get_logger("quality_checker")

# ============================================================
# 🆕 遊戲頁面辨識設定
# ============================================================

GAME_FILENAMES = {
    '2048', 'snake', 'tetris', 'minesweeper', 'sudoku',
    'pong', 'breakout', 'flappy-bird', 'doodle-jump',
    'tic-tac-toe', 'memory', 'hangman', 'wordsearch',
    'bubble-shooter', 'colormatch', 'shooting-range',
    'archery', 'jigsaw-puzzle', 'simon-says', 'math-quiz',
    'clicker', 'color-memory', 'solitaire', 'index'
}

GAME_INDICATORS = {
    'canvas', 'game-container', 'game-board', 'game-wrapper',
    'game-over', 'restart-game', 'new-game', 'start-game',
    'score-board', 'high-score', 'game-title',
    'requestAnimationFrame', 'gameLoop', 'initGame'
}


def is_game_page(filepath, html_content=None):
    """檢測是否為遊戲頁面"""
    filepath = Path(filepath)
    path_parts = filepath.parts
    
    # 條件 1：在 game/ 目錄下且檔名在遊戲清單中
    if 'game' in path_parts:
        if filepath.stem in GAME_FILENAMES:
            return True
        # 如果在 game/ 目錄下但檔名不在清單中，檢查內容
        if html_content and _content_has_game_indicators(html_content):
            return True
        # 預設為遊戲（因為在 game/ 目錄下）
        return True
    
    # 條件 2：檔名在遊戲清單中
    if filepath.stem in GAME_FILENAMES:
        return True
    
    # 條件 3：內容包含遊戲特徵
    if html_content and _content_has_game_indicators(html_content):
        return True
    
    return False


def _content_has_game_indicators(html_content):
    """檢查 HTML 內容是否包含遊戲特徵"""
    if not html_content:
        return False
    
    content_lower = html_content.lower()
    
    # 檢查遊戲關鍵字
    for indicator in GAME_INDICATORS:
        if indicator.lower() in content_lower:
            return True
    
    # 檢查遊戲常見模式
    game_patterns = [
        r'<canvas[^>]*>.*?</canvas>',
        r'game\s*[=:]\s*\{',
        r'const\s+game\s*=',
        r'function\s+gameLoop',
        r'function\s+initGame',
        r'class\s+\w*Game\w*',
        r'game\.init',
        r'game\.start',
        r'game\.reset',
        r'game\.update',
        r'game\.render',
        r'gameOver',
        r'restartGame',
        r'newGame',
        r'startGame',
        r'highScore'
    ]
    
    for pattern in game_patterns:
        if re.search(pattern, html_content, re.IGNORECASE):
            return True
    
    return False


def check_article_quality(html_content, keyword, filepath=None):
    """檢查文章品質，回傳分數與詳細報告"""
    
    # ============================================================
    # 🆕 遊戲頁面檢測（優先執行）
    # ============================================================
    if filepath and is_game_page(filepath, html_content):
        logger.info(f"🎮 偵測到遊戲頁面：{filepath}，自動給予 100 分")
        return {
            "passed": True,
            "score": 100,
            "is_game": True,
            "word_count": 0,
            "h1_count": 0,
            "h2_count": 0,
            "h3_count": 0,
            "has_h1": False,
            "has_table": False,
            "has_faq": False,
            "has_list": False,
            "has_brand_link": False,
            "has_home_link": False,
            "details": "🎮 遊戲頁面（自動跳過文章品質檢查）",
            "game_detected": True
        }

    print(f"🔍 正在檢查文章品質：{keyword}")

    # 移除 HTML 標籤計算純文字
    text_only = re.sub(r'<[^>]+>', ' ', html_content)
    text_only = re.sub(r'\s+', ' ', text_only).strip()
    word_count = len(text_only)

    # 檢查標題
    h1_count = len(re.findall(r'<h1[^>]*>.*?</h1>', html_content, re.IGNORECASE | re.DOTALL))
    h2_count = len(re.findall(r'<h2[^>]*>.*?</h2>', html_content, re.IGNORECASE | re.DOTALL))
    h3_count = len(re.findall(r'<h3[^>]*>.*?</h3>', html_content, re.IGNORECASE | re.DOTALL))
    
    # 檢查其他元素
    has_table = bool(re.search(r'<table[^>]*>.*?</table>', html_content, re.IGNORECASE | re.DOTALL))
    has_faq = bool(re.search(r'(FAQ|常見問題|Q：|問：|Q&A|問答)', html_content, re.IGNORECASE))
    has_list = bool(re.search(r'<(ul|ol)[^>]*>.*?</(ul|ol)>', html_content, re.IGNORECASE | re.DOTALL))
    has_brand_link = bool(re.search(
        r'<a[^>]*href=["\']/?["\'][^>]*>.*?雅寶社區.*?</a>', 
        html_content, re.IGNORECASE | re.DOTALL
    ))
    has_home_link = bool(re.search(
        r'<a[^>]*href=["\']/["\'][^>]*>.*?返回首頁.*?</a>',
        html_content, re.IGNORECASE | re.DOTALL
    ))

    # ============================================================
    # 評分計算（總分 100）
    # ============================================================
    score = 0
    details = []

    # 1. H1 標題（20 分）
    if h1_count >= 1:
        score += 20
        details.append(f"✅ H1 標題：{h1_count} 個（達標）")
    else:
        details.append(f"❌ H1 標題：{h1_count} 個（嚴重不足）")

    # 2. H2 標題（25 分）
    if h2_count >= MIN_HEADINGS:
        score += 25
        details.append(f"✅ H2 標題：{h2_count} 個（達標）")
    elif h2_count >= 2:
        score += 15
        details.append(f"⚠️ H2 標題：{h2_count} 個（建議至少 {MIN_HEADINGS} 個）")
    else:
        details.append(f"❌ H2 標題：{h2_count} 個（嚴重不足）")

    # 3. 字數（25 分）
    if word_count >= MIN_WORDS:
        score += 25
        details.append(f"✅ 字數：{word_count} 字（達標）")
    elif word_count >= MIN_WORDS * 0.7:
        score += 15
        details.append(f"⚠️ 字數：{word_count} 字（略低，建議至少 {MIN_WORDS} 字）")
    else:
        details.append(f"❌ 字數：{word_count} 字（嚴重不足）")

    # 4. 表格（10 分）
    if has_table:
        score += 10
        details.append("✅ 包含表格（加分）")
    else:
        details.append("ℹ️ 未包含表格（可選加分項）")

    # 5. FAQ（10 分）
    if has_faq:
        score += 10
        details.append("✅ 包含 FAQ（加分）")
    else:
        details.append("ℹ️ 未包含 FAQ（可選加分項）")

    # 6. 清單（5 分）
    if has_list:
        score += 5
        details.append("✅ 包含清單（加分）")
    else:
        details.append("ℹ️ 未包含清單（可選加分項）")

    # 7. 品牌連結（5 分）
    if has_brand_link:
        score += 5
        details.append("✅ 包含品牌連結")
    else:
        details.append("ℹ️ 品牌連結由系統自動加入")

    passed = score >= 60

    # 寫入日誌
    logger.info(f"\n📊 品質報告：{keyword}\n   └─ 分數：{score}/100\n   └─ 結果：{'✅ 通過' if passed else '⚠️ 待改善'}")

    return {
        "passed": passed,
        "score": score,
        "is_game": False,
        "game_detected": False,
        "word_count": word_count,
        "h1_count": h1_count,
        "h2_count": h2_count,
        "h3_count": h3_count,
        "has_h1": h1_count >= 1,
        "has_table": has_table,
        "has_faq": has_faq,
        "has_list": has_list,
        "has_brand_link": has_brand_link,
        "has_home_link": has_home_link,
        "details": "\n".join(details)
    }


# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    test_article = '''
    <!DOCTYPE html>
    <html>
    <head><title>測試文章</title></head>
    <body>
        <h1>測試標題</h1>
        <h2>第一章</h2><p>內容</p>
        <h2>第二章</h2><p>內容</p>
        <h2>第三章</h2><p>內容</p>
        <p>更多內容...</p>
        <ul><li>項目1</li><li>項目2</li></ul>
        <a href="/">雅寶社區</a>
    </body>
    </html>
    '''
    
    result = check_article_quality(test_article, "測試文章", "test.html")
    print(f"\n📊 測試結果：分數 {result['score']}/100，通過：{result['passed']}")
    print(f"遊戲頁面：{result.get('game_detected', False)}")