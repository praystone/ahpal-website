import json
with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)
print(f'✅ 成功載入 {len(data)} 篇文章')
print('')
print('📋 最後 2 篇文章:')
for item in data[-2:]:
    print(f'   - {item["keyword"][:50]}...')
    print(f'     檔案: {item.get("filename", "未指定")}')
