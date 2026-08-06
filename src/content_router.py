# ============================================================
# content_router.py - 內容類型路由 v1.0
# ============================================================
# 功能：根據 content_type 分派到對應的生成器
# 位置：C:\Users\User\ahpal-static\src\content_router.py
# ============================================================

from src.article_generator import generate_article
from src.song_generator import generate_song


def generate_content(item):
    """
    統一內容生成入口
    
    參數：
        item: dict，必須包含 content_type 欄位
            - content_type: "article" 或 "song"
    
    回傳：
        bool: 生成成功與否
    """
    content_type = item.get("content_type", "article")
    
    print(f"📌 內容類型：{content_type}")
    
    try:
        if content_type == "song":
            generate_song(item)
        else:
            generate_article(item)
        return True
    except Exception as e:
        print(f"❌ 生成失敗：{e}")
        return False


# ============================================================
# 批次生成多篇內容
# ============================================================

def generate_batch(items):
    """
    批次生成多篇內容
    
    參數：
        items: list of dict，每篇文章的資料
    """
    success = 0
    failed = 0
    
    for item in items:
        if generate_content(item):
            success += 1
        else:
            failed += 1
    
    print(f"\n📊 批次生成完成：成功 {success} 篇，失敗 {failed} 篇")
    return success, failed


# ============================================================
# 直接執行測試
# ============================================================

if __name__ == "__main__":
    print("\n" + "="*50)
    print("  🧪 content_router.py v1.0 測試")
    print("="*50 + "\n")

    test_items = [
        {
            "keyword": "測試音樂文章",
            "category": "🎵 音樂創作",
            "filename": "music/test-router-song.html",
            "video_id": "A9Zw-QHEOqQ",
            "content_type": "song"
        },
        {
            "keyword": "測試一般文章",
            "category": "💻 3C 科技教學",
            "filename": "tech/test-router-article.html",
            "content_type": "article"
        }
    ]

    generate_batch(test_items)
    print("\n✅ 測試完成")