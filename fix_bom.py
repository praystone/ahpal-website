import json

file_path = 'data/master-articles.json'

# 讀取 (支援 BOM)
with open(file_path, 'r', encoding='utf-8-sig') as f:
    data = json.load(f)

print(f'✅ 讀取成功，共 {len(data)} 篇文章')

# 寫入 (無 BOM)
with open(file_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('✅ BOM 已移除，檔案已修復')
print('')
print('📋 最後 3 篇文章:')
for item in data[-3:]:
    print(f'   - {item["keyword"][:40]}...')
