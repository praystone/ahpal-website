# ============================================================
# 🔧 AHPAL 一鍵修復：nature master 同步 + lifestyle 合併
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🔧 AHPAL 一鍵修復工具 v1.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 步驟 1：修正 nature/ (刪除 master 中不存在的條目)
# ============================================================
Write-Host "[1/4] 修正 nature/ master 同步..." -ForegroundColor Yellow

python -c "
import json
import os

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)

filtered = []
removed = []
for a in articles:
    filename = a.get('filename', '')
    if filename.startswith('nature/'):
        if os.path.exists(filename):
            filtered.append(a)
        else:
            removed.append(a)
    else:
        filtered.append(a)

print(f'   ✅ 保留 {len(filtered)} 篇')
print(f'   🗑️ 刪除 {len(removed)} 篇 (不存在於目錄)')

with open('data/master-articles.json', 'w', encoding='utf-8') as f:
    json.dump(filtered, f, ensure_ascii=False, indent=2)
"

Write-Host "   ✅ nature/ master 同步完成" -ForegroundColor Green
Write-Host ""

# ============================================================
# 步驟 2：統一 lifestyle/ → life/
# ============================================================
Write-Host "[2/4] 統一 lifestyle/ → life/..." -ForegroundColor Yellow

if (Test-Path "lifestyle") {
    $count = (Get-ChildItem lifestyle/*.html -ErrorAction SilentlyContinue).Count
    if ($count -gt 0) {
        Move-Item lifestyle/*.html life/ -Force
        Write-Host "   ✅ 已搬移 $count 個檔案"
    }
    
    python -c "
import json

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    articles = json.load(f)

updated = 0
for a in articles:
    filename = a.get('filename', '')
    if filename.startswith('lifestyle/'):
        a['filename'] = filename.replace('lifestyle/', 'life/')
        updated += 1

with open('data/master-articles.json', 'w', encoding='utf-8') as f:
    json.dump(articles, f, ensure_ascii=False, indent=2)

print(f'   ✅ 更新 {updated} 條路徑')
"
    
    Remove-Item lifestyle -Force -ErrorAction SilentlyContinue
    Write-Host "   ✅ lifestyle/ 目錄已刪除" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ lifestyle/ 目錄不存在，跳過" -ForegroundColor Gray
}
Write-Host ""

# ============================================================
# 步驟 3：重新生成分類頁面
# ============================================================
Write-Host "[3/4] 重新生成分類頁面..." -ForegroundColor Yellow

python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()"

Write-Host "   ✅ 分類頁面已更新" -ForegroundColor Green
Write-Host ""

# ============================================================
# 步驟 4：更新 Sitemap
# ============================================================
Write-Host "[4/4] 更新 Sitemap..." -ForegroundColor Yellow

python -c "from src.sitemap_builder import update_sitemap; update_sitemap()"

Write-Host "   ✅ Sitemap 已更新" -ForegroundColor Green
Write-Host ""

# ============================================================
# 完成
# ============================================================
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 一鍵修復完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 下一步："
Write-Host "   .\scripts\ahpal-master.ps1 → [6] 部署"
Write-Host ""

Read-Host "按 Enter 結束"