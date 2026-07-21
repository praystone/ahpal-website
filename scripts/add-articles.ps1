# ============================================================
# add-articles.ps1 - 自動新增文章腳本 v2.1
# ============================================================
# 功能：從 JSON 檔案讀取關鍵字，自動新增到 main.py
# 強化：UTF-8 無 BOM、特殊字元過濾、自動備份
# 修正：PowerShell 5.1 相容性（.Trim() 取代 -trim）
# 使用方法：.\add-articles.ps1
# ============================================================

# 設定執行原則（僅當前 Session）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 設定錯誤處理
$ErrorActionPreference = "Stop"

# 確保 UTF-8 無 BOM 的寫入函數
function Write-UTF8NoBOM {
    param(
        [string]$Path,
        [string]$Content
    )
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8)
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📝 自動新增文章工具 v2.1 (龍蝦總工程師強化版)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = "C:\Users\User\ahpal-static"
$PendingFile = "$ProjectRoot\data\pending-articles.json"
$MainPy = "$ProjectRoot\src\main.py"
$BackupDir = "$ProjectRoot\backups\main-py"
$Today = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# ============================================================
# 1. 檢查待新增檔案
# ============================================================
if (-not (Test-Path $PendingFile)) {
    Write-Host "❌ 找不到 pending-articles.json" -ForegroundColor Red
    Write-Host "   請先在 data/pending-articles.json 中定義新文章" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 1
}

# ============================================================
# 2. 讀取並驗證 JSON
# ============================================================
try {
    $PendingRaw = Get-Content $PendingFile -Raw -Encoding UTF8
    $Pending = $PendingRaw | ConvertFrom-Json
} catch {
    Write-Host "❌ JSON 格式錯誤！請檢查 pending-articles.json" -ForegroundColor Red
    Write-Host "   錯誤訊息：$($_.Exception.Message)" -ForegroundColor Red
    Read-Host "按 Enter 鍵結束"
    exit 1
}

$Total = $Pending.Count
Write-Host "📋 找到 $Total 篇待新增文章" -ForegroundColor Cyan

if ($Total -eq 0) {
    Write-Host "✅ 沒有待新增文章" -ForegroundColor Green
    Read-Host "按 Enter 鍵結束"
    exit 0
}

# ============================================================
# 3. 檢查是否有重複關鍵字
# ============================================================
$Keywords = $Pending | ForEach-Object { $_.keyword }
$Duplicates = $Keywords | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
if ($Duplicates) {
    Write-Host "❌ 發現重複的關鍵字：" -ForegroundColor Red
    foreach ($dup in $Duplicates) {
        Write-Host "   - $dup" -ForegroundColor Red
    }
    Read-Host "請修正後重新執行，按 Enter 鍵結束"
    exit 1
}

# ============================================================
# 4. 顯示待新增清單
# ============================================================
Write-Host ""
Write-Host "📝 待新增文章清單：" -ForegroundColor Yellow
$i = 1
foreach ($item in $Pending) {
    Write-Host "   $i. $($item.keyword) ($($item.category))" -ForegroundColor Gray
    $i++
}
Write-Host ""

$confirm = Read-Host "是否繼續新增？(y/n)"
if ($confirm -ne "y") {
    Write-Host "已取消操作" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 0
}

# ============================================================
# 5. 備份 main.py
# ============================================================
Write-Host ""
Write-Host "📦 備份 main.py..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupPath = "$BackupDir\main.py.$Today.bak"
Copy-Item $MainPy $BackupPath -Force
Write-Host "   ✅ 已備份到：$BackupPath" -ForegroundColor Green

# ============================================================
# 6. 讀取現有 main.py 並準備插入
# ============================================================
Write-Host ""
Write-Host "📝 正在更新 main.py..." -ForegroundColor Yellow

$Content = Get-Content $MainPy -Raw -Encoding UTF8

# 檢查是否已經有這些關鍵字（避免重複新增）
$ExistingKeywords = [regex]::Matches($Content, '"keyword": "([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$NewItems = @()
$SkippedCount = 0

foreach ($item in $Pending) {
    if ($item.keyword -in $ExistingKeywords) {
        Write-Host "   ⏩ 跳過（已存在）：$($item.keyword)" -ForegroundColor Yellow
        $SkippedCount++
        continue
    }
    $NewItems += $item
}

if ($NewItems.Count -eq 0) {
    Write-Host "✅ 所有文章都已存在，無需新增" -ForegroundColor Green
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host "   將新增 $($NewItems.Count) 篇（$SkippedCount 篇已存在，已跳過）" -ForegroundColor Cyan

# ============================================================
# 7. 產生檔案名稱（去除特殊字元）
# ============================================================
function Get-SafeFilename {
    param([string]$Keyword, [string]$Category)
    
    $catMap = @{
        "💻 3C 科技教學" = "tech"
        "🎮 遊戲攻略" = "game"
        "🏠 生活小常識" = "life"
        "📊 軟體評測" = "review"
        "🌟 人生哲理" = "philosophy"
        "🤖 AI 趨勢" = "trend"
    }
    $catDir = $catMap[$Category]
    
    # 去除特殊字元，只保留中文、英文、數字、中線
    $safeName = $Keyword -replace '[^a-zA-Z0-9\u4e00-\u9fa5-]', ''
    # 將空白換成中線
    $safeName = $safeName -replace '\s+', '-'
    # 去掉連續的中線
    $safeName = $safeName -replace '-+', '-'
    # 去掉前後中線（修正：使用 .Trim() 方法）
    $safeName = $safeName.Trim('-')
    
    return "$catDir/$safeName.html"
}

# ============================================================
# 8. 插入新關鍵字到 keywords_list
# ============================================================
$NewEntries = @()
foreach ($item in $NewItems) {
    $filename = Get-SafeFilename -Keyword $item.keyword -Category $item.category
    $NewEntries += "    {`"keyword`": `"$($item.keyword)`", `"category`": `"$($item.category)`", `"filename`": `"$filename`"},"
    Write-Host "   ✅ $($item.keyword) → $filename" -ForegroundColor Green
}

$InsertPoint = $Content.LastIndexOf("]")
$NewContent = $Content.Insert($InsertPoint, "`n" + ($NewEntries -join "`n") + "`n")

# ============================================================
# 9. 寫回 main.py（UTF-8 無 BOM）
# ============================================================
Write-UTF8NoBOM -Path $MainPy -Content $NewContent
Write-Host "   ✅ main.py 已更新（UTF-8 無 BOM）" -ForegroundColor Green

# ============================================================
# 10. 清空 pending-articles.json（UTF-8 無 BOM）
# ============================================================
$Empty = @()
$EmptyJson = $Empty | ConvertTo-Json -Depth 10
Write-UTF8NoBOM -Path $PendingFile -Content $EmptyJson
Write-Host "   ✅ pending-articles.json 已清空" -ForegroundColor Green

# ============================================================
# 11. 完成摘要
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 新增完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 摘要：" -ForegroundColor Yellow
Write-Host "   ├─ 新增文章：$($NewItems.Count) 篇" -ForegroundColor Cyan
Write-Host "   ├─ 跳過（已存在）：$SkippedCount 篇" -ForegroundColor Gray
Write-Host "   └─ 備份位置：$BackupPath" -ForegroundColor Gray
Write-Host ""
Write-Host "📌 下一步：" -ForegroundColor Yellow
Write-Host "   python src\main.py --force deepseek" -ForegroundColor White
Write-Host "   .\scripts\ahpal-master.ps1 → 選擇 [6]" -ForegroundColor White
Write-Host ""

Read-Host "按 Enter 鍵結束"