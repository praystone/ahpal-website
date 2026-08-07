from src.article_generator import generate_article

# 刪除錯誤檔案
import os
if os.path.exists('music/打工人心酸語錄.html'):
    os.remove('music/打工人心酸語錄.html')
    print('🗑️ 已刪除舊檔案')

# 重新生成
item = {
    'keyword': '打工人心酸語錄 原創歌曲 迷因改編',
    'category': '🎵 音樂創作',
    'filename': 'music/打工人心酸語錄.html',
    'content_type': 'song',
    'use_responses_api': True,
    'enable_reasoning': True,
    'enable_search': False
}
generate_article(item)
print('✅ 打工人心酸語錄 重新生成完成！')
