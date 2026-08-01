# ============================================================
# AHPAL 待生成文章處理腳本 v2.0 (編碼與語法修正版)
# 功能：讀取 pending-articles.json，精確寫入 main.py 的 keywords_list
# ============================================================

Write-Host "🦞 待生成文章處理腳本啟動 v2.0" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray

# 切換至專案根目錄
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# 1. 檢查 pending-articles.json
$PendingFile = Join-Path $ProjectRoot "pending-articles.json"
if (-not (Test-Path $PendingFile)) {
    Write-Host "❌ 找不到 pending-articles.json" -ForegroundColor Red
    Write-Host "📌 請先從面板匯出待生成清單" -ForegroundColor Yellow
    exit 1
}

# 2. 讀取 JSON (使用 UTF8 編碼)
$PendingData = Get-Content $PendingFile -Raw -Encoding UTF8 | ConvertFrom-Json
$Articles = $PendingData.articles

if ($Articles.Count -eq 0) {
    Write-Host "⚠️ 待生成清單為空" -ForegroundColor Yellow
    exit 0
}

Write-Host "📋 找到 $($Articles.Count) 篇待生成文章" -ForegroundColor Yellow

# 3. 轉換為 keywords_list 格式
$KeywordList = @()
foreach ($item in $Articles) {
    # 安全處理檔案名稱
    $safeFilename = $item.title -replace '[^a-zA-Z0-9\u4e00-\u9fa5]', '-' -replace '-+', '-'
    # 確保 category 正確編碼
    $category = $item.categoryLabel
    $KeywordList += @{
        keyword = $item.title
        category = $category
        filename = "$($item.category)/$safeFilename.html"
    }
}

# 4. 備份現有 main.py
$MainPyPath = Join-Path $ProjectRoot "src\main.py"
$MainPyBakPath = Join-Path $ProjectRoot "src\main.py.bak"
Copy-Item $MainPyPath $MainPyBakPath -Force -ErrorAction SilentlyContinue

# 5. 讀取現有 main.py
$MainPyContent = Get-Content $MainPyPath -Raw -Encoding UTF8

# 6. 找到 keywords_list 的起始和結束位置
$StartMarker = "keywords_list = ["
$StartIndex = $MainPyContent.IndexOf($StartMarker)
if ($StartIndex -eq -1) {
    Write-Host "❌ 找不到 keywords_list" -ForegroundColor Red
    exit 1
}

# 從 keywords_list 開始處往後找第一個匹配的 ']'
$StartPos = $StartIndex + $StartMarker.Length
$BracketCount = 0
$EndPos = -1
for ($i = $StartPos; $i -lt $MainPyContent.Length; $i++) {
    $char = $MainPyContent[$i]
    if ($char -eq '[') { $BracketCount++ }
    if ($char -eq ']') {
        if ($BracketCount -eq 0) {
            $EndPos = $i
            break
        } else {
            $BracketCount--
        }
    }
}

if ($EndPos -eq -1) {
    Write-Host "❌ 找不到 keywords_list 的結束位置" -ForegroundColor Red
    exit 1
}

Write-Host "📍 找到 keywords_list，插入位置：$EndPos" -ForegroundColor Gray

# 7. 生成新的 keywords_list 區塊 (確保正確的 JSON 格式)
$NewKeywords = ""
foreach ($item in $KeywordList) {
    $escapedKeyword = $item.keyword -replace '"', '\"'
    $escapedCategory = $item.category -replace '"', '\"'
    $NewKeywords += "    {`"keyword`": `"$escapedKeyword`", `"category`": `"$escapedCategory`", `"filename`": `"$($item.filename)`"},\n"
}

# 8. 在結束位置之前插入新文章 (移除多餘的換行)
$MainPyContent = $MainPyContent.Insert($EndPos, "`n$NewKeywords")

# 9. 清理可能出現的語法錯誤：移除多餘的換行符號
$MainPyContent = $MainPyContent -replace ',\\n\]', ', ]'

# 10. 寫回 main.py（UTF-8 with BOM）
$Utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($MainPyPath, $MainPyContent, $Utf8Bom)

Write-Host "✅ 已將 $($Articles.Count) 篇文章加入 keywords_list" -ForegroundColor Green

# 11. 執行文章生成
Write-Host "🚀 執行文章生成..." -ForegroundColor Yellow
python $MainPyPath

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ 文章生成完成！" -ForegroundColor Green
    Remove-Item $PendingFile -Force
    Write-Host "📌 已清理 pending-articles.json" -ForegroundColor Gray
} else {
    Write-Host "❌ 文章生成失敗！請檢查錯誤訊息" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 處理完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
