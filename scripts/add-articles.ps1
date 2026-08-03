# ============================================================
# add-articles.ps1 - 自動新增文章腳本 v2.3 (支援 filename)
# ============================================================
# 功能：從 JSON 檔案讀取關鍵字，自動新增到 main.py
# 強化：UTF-8 無 BOM、特殊字元過濾、自動備份
# 新增：支援 filename 欄位（可自訂檔名）
# 新增：自動偵測 JSON 格式（有/無 filename）
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

# 讀取 JSON（自動偵測編碼）
function Read-JsonFile {
    param([string]$Path)
    
    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8 -ErrorAction Stop
        return $content | ConvertFrom-Json
    } catch {
        try {
            $content = Get-Content -Path $Path -Raw -Encoding Default -ErrorAction Stop
            return $content | ConvertFrom-Json
        } catch {
            try {
                $bytes = [System.IO.File]::ReadAllBytes($Path)
                $content = [System.Text.Encoding]::UTF8.GetString($bytes)
                return $content | ConvertFrom-Json
            } catch {
                throw "無法讀取 JSON 檔案，請確認編碼是否為 UTF-8"
            }
        }
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📝 自動新增文章工具 v2.3 (支援 filename)" -ForegroundColor Green
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
    $Pending = Read-JsonFile -Path $PendingFile
} catch {
    Write-Host "❌ JSON 讀取失敗：$($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   請確認 pending-articles.json 為 UTF-8 編碼" -ForegroundColor Yellow
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
# 3. 驗證 JSON 格式並顯示
# ============================================================
Write-Host ""
Write-Host "📝 待新增文章清單：" -ForegroundColor Yellow

$ValidItems = @()
$InvalidItems = @()

$i = 1
foreach ($item in $Pending) {
    # 檢查必要欄位
    if (-not $item.keyword -or -not $item.category) {
        Write-Host "   ❌ 第 $i 筆缺少 keyword 或 category，已跳過" -ForegroundColor Red
        $InvalidItems += $item
        $i++
        continue
    }
    
    # 檢查是否有 filename
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filenameDisplay = if ($hasFilename) { "📄 $($item.filename)" } else { "🔄 自動產生" }
    
    Write-Host "   $i. $($item.keyword) ($($item.category)) → $filenameDisplay" -ForegroundColor Gray
    $ValidItems += $item
    $i++
}

if ($InvalidItems.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ 有 $($InvalidItems.Count) 筆資料格式錯誤，已跳過" -ForegroundColor Yellow
}

if ($ValidItems.Count -eq 0) {
    Write-Host "❌ 沒有有效的文章資料" -ForegroundColor Red
    Read-Host "按 Enter 鍵結束"
    exit 1
}

Write-Host ""
$confirm = Read-Host "是否繼續新增？(y/n)"
if ($confirm -ne "y") {
    Write-Host "已取消操作" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 0
}

# ============================================================
# 4. 備份 main.py
# ============================================================
Write-Host ""
Write-Host "📦 備份 main.py..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupPath = "$BackupDir\main.py.$Today.bak"
Copy-Item $MainPy $BackupPath -Force
Write-Host "   ✅ 已備份到：$BackupPath" -ForegroundColor Green

# ============================================================
# 5. 讀取現有 main.py
# ============================================================
Write-Host ""
Write-Host "📝 正在更新 main.py..." -ForegroundColor Yellow

$Content = Get-Content $MainPy -Raw -Encoding UTF8

# 檢查是否已經有這些關鍵字
$ExistingKeywords = [regex]::Matches($Content, '"keyword": "([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$NewItems = @()
$SkippedCount = 0

foreach ($item in $ValidItems) {
    if ($item.keyword -in $ExistingKeywords) {
        Write-Host "   ⏩ 跳過（已存在）：$($item.keyword)" -ForegroundColor Yellow
        $SkippedCount++
        continue
    }
    $NewItems += $item
}

if ($NewItems.Count -eq 0) {
    Write-Host "✅ 所有文章都已存在，無需新增" -ForegroundColor Green
    Write-UTF8NoBOM -Path $PendingFile -Content "[]"
    Write-Host "   ✅ pending-articles.json 已清空" -ForegroundColor Green
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host "   將新增 $($NewItems.Count) 篇（$SkippedCount 篇已存在，已跳過）" -ForegroundColor Cyan

# ============================================================
# 6. 產生檔案名稱（支援自訂 filename）
# ============================================================
function Get-SafeFilename {
    param(
        [string]$Keyword,
        [string]$Category,
        [string]$CustomFilename = $null
    )
    
    # 如果有自訂 filename，直接使用
    if ($CustomFilename) {
        # 確保有 .html 副檔名
        if ($CustomFilename -notmatch '\.html$') {
            $CustomFilename = "$CustomFilename.html"
        }
        # 確保路徑正確（如果有目錄前綴）
        if ($CustomFilename -notmatch '^[a-zA-Z0-9_-]+/') {
            $catMap = @{
                "💻 3C 科技教學" = "tech"
                "🎮 遊戲攻略" = "game"
                "🏠 生活小常識" = "life"
                "📊 軟體評測" = "review"
                "🌟 人生哲理" = "philosophy"
                "🤖 AI 趨勢" = "trend"
            }
            $catDir = $catMap[$Category]
            $CustomFilename = "$catDir/$CustomFilename"
        }
        return $CustomFilename
    }
    
    # 自動產生檔名
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
    $safeName = $safeName -replace '\s+', '-'
    $safeName = $safeName -replace '-+', '-'
    $safeName = $safeName.Trim('-')
    
    if ([string]::IsNullOrEmpty($safeName)) {
        $safeName = "article-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    }
    
    return "$catDir/$safeName.html"
}

# ============================================================
# 7. 檢查檔案名稱是否已存在
# ============================================================
$FilesToCheck = @()
$FileMap = @{}
foreach ($item in $NewItems) {
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filename = Get-SafeFilename -Keyword $item.keyword -Category $item.category -CustomFilename $(if ($hasFilename) { $item.filename } else { $null })
    $FilesToCheck += $filename
    $FileMap[$filename] = $item
}

$ExistingFiles = @()
foreach ($f in $FilesToCheck) {
    $fullPath = Join-Path $ProjectRoot $f
    if (Test-Path $fullPath) {
        $ExistingFiles += $f
    }
}

if ($ExistingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "   ⚠️ 以下檔案已存在，將被覆蓋：" -ForegroundColor Yellow
    foreach ($f in $ExistingFiles) {
        Write-Host "      - $f" -ForegroundColor Gray
    }
    $overwriteConfirm = Read-Host "是否繼續？(y/n)"
    if ($overwriteConfirm -ne "y") {
        Write-Host "已取消操作" -ForegroundColor Yellow
        Read-Host "按 Enter 鍵結束"
        exit 0
    }
}

# ============================================================
# 8. 插入新關鍵字到 keywords_list
# ============================================================
$NewEntries = @()
foreach ($item in $NewItems) {
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filename = Get-SafeFilename -Keyword $item.keyword -Category $item.category -CustomFilename $(if ($hasFilename) { $item.filename } else { $null })
    $NewEntries += "    {`"keyword`": `"$($item.keyword)`", `"category`": `"$($item.category)`", `"filename`": `"$filename`"},"
    $fileInfo = if ($hasFilename) { "📄 $filename" } else { "🔄 $filename (自動)" }
    Write-Host "   ✅ $($item.keyword) → $fileInfo" -ForegroundColor Green
}

$KeywordListStart = $Content.IndexOf("keywords_list = [")
if ($KeywordListStart -lt 0) {
    throw "找不到 keywords_list，已停止寫入以保護 main.py"
}

$InsertPoint = $Content.IndexOf("`n]", $KeywordListStart)
if ($InsertPoint -lt 0) {
    throw "找不到 keywords_list 的結尾，已停止寫入以保護 main.py"
}

$NewContent = $Content.Insert($InsertPoint, "`n" + ($NewEntries -join "`n") + "`n")

# ============================================================
# 9. 寫回 main.py（UTF-8 無 BOM）
# ============================================================
Write-UTF8NoBOM -Path $MainPy -Content $NewContent
Write-Host "   ✅ main.py 已更新（UTF-8 無 BOM）" -ForegroundColor Green

# ============================================================
# 10. 清空 pending-articles.json（UTF-8 無 BOM）
# ============================================================
Write-UTF8NoBOM -Path $PendingFile -Content "[]"
Write-Host "   ✅ pending-articles.json 已清空（UTF-8 無 BOM）" -ForegroundColor Green

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
Write-Host "   ├─ 備份位置：$BackupPath" -ForegroundColor Gray
Write-Host "   └─ 編碼：UTF-8 無 BOM ✅" -ForegroundColor Green
Write-Host ""
Write-Host "📌 下一步：" -ForegroundColor Yellow
Write-Host "   python src\main.py --force deepseek" -ForegroundColor White
Write-Host "   .\scripts\ahpal-master.ps1 → 選擇 [6]" -ForegroundColor White
Write-Host ""

Read-Host "按 Enter 鍵結束"