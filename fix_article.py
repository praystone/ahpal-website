import re

file_path = 'music/seasonal-blossoms-edm-remix.html'
title = '四季紅 EDM 未來貝斯 改編 台羅拼音 解析'
brand = '雅寶社區 · 頂客論壇'

with open(file_path, 'rb') as f:
    raw = f.read()

try:
    content = raw.decode('utf-8')
except:
    content = raw.decode('big5', errors='ignore')

content = re.sub(r'<title>.*?</title>', f'<title>{title} - {brand}</title>', content, flags=re.DOTALL)
content = re.sub(r'<meta name="description" content=".*?">', f'<meta name="description" content="{title} - {brand}">', content, flags=re.DOTALL)
content = re.sub(r'<meta name="keywords" content=".*?">', f'<meta name="keywords" content="{title}">', content, flags=re.DOTALL)
content = re.sub(r'"name": ".*?"', f'"name": "{title}"', content)
content = re.sub(r'"url": "https://www.ahpal.com/music/.*?.html"', f'"url": "https://www.ahpal.com/music/seasonal-blossoms-edm-remix.html"', content)
content = re.sub(r'<h1>.*?</h1>', f'<h1>{title}</h1>', content, flags=re.DOTALL)
content = re.sub(r'<span class="post-category">.*?</span>', f'<span class="post-category">🎵 音樂創作</span>', content, flags=re.DOTALL)
content = re.sub(r'雅寶社區 · 頂客論壇', '雅寶社區 · 頂客論壇', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('✅ 文章修復完成！')
