import json

# 讀取現有資料
with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f'📊 目前: {len(data)} 篇文章')

# 新增 2 篇文章
new_articles = [
    {
        "keyword": "2026 年 TypeScript 完整指南：從基礎到進階型別實戰",
        "category": "💻 3C 科技教學",
        "filename": "tech/typescript-complete-guide-2026.html"
    },
    {
        "keyword": "2026 年 Next.js 14 App Router 實戰：從入門到 Server Components",
        "category": "💻 3C 科技教學",
        "filename": "tech/nextjs14-app-router-guide-2026.html"
    }
]

# 檢查是否已存在，避免重複
existing_keywords = [item["keyword"] for item in data]
added = 0
for article in new_articles:
    if article["keyword"] not in existing_keywords:
        data.append(article)
        added += 1
        print(f'✅ 新增: {article["keyword"][:40]}...')

# 寫回
with open('data/master-articles.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f'📊 完成！共 {len(data)} 篇文章，新增 {added} 篇')

# 顯示最後 2 篇
print('')
print('📋 最後 2 篇文章:')
for item in data[-2:]:
    print(f'   - {item["keyword"][:50]}...')
    print(f'     檔案: {item["filename"]}')
