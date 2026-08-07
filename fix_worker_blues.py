import re

file_path = 'music/打工人心酸語錄.html'
title = '打工人心酸語錄 原創歌曲 迷因改編'
brand = '雅寶社區 · 頂客論壇'

with open(file_path, 'rb') as f:
    raw = f.read()

try:
    content = raw.decode('utf-8')
except:
    content = raw.decode('big5', errors='ignore')

# 修正標題
content = re.sub(r'<title>.*?</title>', f'<title>{title} - {brand}</title>', content, flags=re.DOTALL)
content = re.sub(r'<meta name="description" content=".*?">', f'<meta name="description" content="{title} - {brand}">', content, flags=re.DOTALL)
content = re.sub(r'<meta name="keywords" content=".*?">', f'<meta name="keywords" content="{title}">', content, flags=re.DOTALL)

# 修正 H1 標題
content = re.sub(r'<h1>.*?</h1>', f'<h1>{title}</h1>', content, flags=re.DOTALL)

# 修正分類
content = re.sub(r'<span class="post-category">.*?</span>', f'<span class="post-category">🎵 音樂創作</span>', content, flags=re.DOTALL)

# 修正品牌名稱
content = re.sub(r'雅寶社區 · 頂客論壇', '雅寶社區 · 頂客論壇', content)

# 移除錯誤的 DOCTYPE 殘留
content = re.sub(r'\|<!DOCTYPE html>', '', content)

# 寫回檔案（UTF-8 無 BOM）
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('✅ 打工人心酸語錄.html 修復完成！')
