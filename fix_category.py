import json

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

for item in data:
    if 'Home Assistant 2026 智慧家庭自動化' in item.get('keyword', ''):
        item['category'] = '🏠 生活小常識'
        print(f'✅ 修正: {item["keyword"][:40]}... → {item["category"]}')

with open('data/master-articles.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'📊 完成！共 {len(data)} 篇文章')
