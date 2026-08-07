import re

file_path = 'src/html_builder.py'
with open(file_path, 'r', encoding='utf-8') as f:
    code = f.read()

# 替換標題提取邏輯
old_title = "title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.IGNORECASE | re.DOTALL)"
new_title = "if keyword and len(keyword.strip()) > 0:\n        title = keyword.strip()\n    else:\n        title_match = re.search(r'<h1[^>]*>(.*?)</h1>', html_content, re.IGNORECASE | re.DOTALL)"

# 替換分類提取邏輯
old_category = "category = extract_category_from_content(html_content)"
new_category = "if category:\n        final_category = category\n    else:\n        final_category = extract_category_from_content(html_content)"

# 替換 Header 變數引用
old_header = "GOLDEN_HEADER_TEMPLATE.replace('{title}', title).replace('{category}', category)"
new_header = "GOLDEN_HEADER_TEMPLATE.replace('{title}', title).replace('{category}', final_category)"

if old_title in code:
    code = code.replace(old_title, new_title)
    code = code.replace(old_category, new_category)
    code = code.replace(old_header, new_header)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(code)
    print('✅ html_builder.py 微調完成！')
else:
    print('⚠️ 請手動檢查 src/html_builder.py')
