import re

files = [
    'about.html',
    'privacy-policy.html',
    'terms-of-service.html'
]

for file_path in files:
    print(f'🔧 處理: {file_path}')
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # 移除精確的 noindex 標記
        content = content.replace('<meta name="robots" content="noindex, follow">', '')
        content = content.replace('<meta name="robots" content="noindex">', '')
        
        # 移除任何其他格式的 noindex
        content = re.sub(r'<meta\s+name="robots"\s+content="noindex[^"]*">', '', content, flags=re.IGNORECASE)

        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'   ✅ {file_path} 已修復')
    except Exception as e:
        print(f'   ❌ {file_path} 處理失敗: {e}')

print('\n✅ 所有檔案處理完成！')
