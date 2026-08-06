# ============================================================
# add-articles.ps1 - 自動新增內容腳本 v3.0
# ============================================================
# 功能：從 JSON 檔案讀取內容，自動新增到 main.py
# 強化：
#   - 🆕 支援多個 JSON 檔案（articles / songs）
#   - 🆕 支援 content_type 欄位（article / song）
#   - 🆕 支援 video_id 欄位（音樂文章專用）
#   - 🆕 完整分類映射（含音樂創作）
#   - 🔧 UTF-8 無 BOM、特殊字元過濾、自動備份
#   - 🔧 完整欄位驗證
# ============================================================

# 設定執行原則（僅當前 Session）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 設定錯誤處理
$ErrorActionPreference = "Stop"

# ============================================================
# 輔助函數
# ============================================================

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
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
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

# 🆕 完整分類映射（含音樂創作）
function Get-CategoryMapping {
    return @{
        "💻 3C 科技教學" = "tech"
        "🎮 遊戲攻略" = "game"
        "🏠 生活小常識" = "life"
        "📊 軟體評測" = "review"
        "🌟 人生哲理" = "philosophy"
        "🤖 AI 趨勢" = "trend"
        "🎵 音樂創作" = "music"  # 🆕
    }
}

# 🆕 產生安全的檔案名稱
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
            $catMap = Get-CategoryMapping
            $catDir = $catMap[$Category]
            if (-not $catDir) {
                $catDir = "other"
            }
            $CustomFilename = "$catDir/$CustomFilename"
        }
        return $CustomFilename
    }
    
    # 自動產生檔名
    $catMap = Get-CategoryMapping
    $catDir = $catMap[$Category]
    if (-not $catDir) {
        $catDir = "other"
    }
    
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
# 主程式開始
# ============================================================

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📝 自動新增內容工具 v3.0 (支援文章/音樂)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$ProjectRoot = "C:\Users\User\ahpal-static"
$MainPy = "$ProjectRoot\src\main.py"
$BackupDir = "$ProjectRoot\backups\main-py"
$Today = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

# ============================================================
# 1. 🆕 讀取多個 JSON 檔案
# ============================================================

$jsonFiles = @(
    @{ Path = "$ProjectRoot\data\pending-articles.json"; Type = "article"; Label = "一般文章" },
    @{ Path = "$ProjectRoot\data\pending-songs.json"; Type = "song"; Label = "音樂文章" }
)

$AllPending = @()
$TotalCount = 0

foreach ($file in $jsonFiles) {
    if (Test-Path $file.Path) {
        try {
            $items = Read-JsonFile -Path $file.Path
            if ($items -and $items.Count -gt 0) {
                Write-Host "📋 找到 $($items.Count) 篇待新增 $($file.Label)" -ForegroundColor Cyan
                foreach ($item in $items) {
                    # 🆕 加入 content_type（如果沒有）
                    if (-not ($item.PSObject.Properties.Name -contains "content_type")) {
                        $item | Add-Member -NotePropertyName "content_type" -NotePropertyValue $file.Type -Force
                    }
                    $AllPending += $item
                }
                $TotalCount += $items.Count
            }
        } catch {
            Write-Host "   ⚠️ 讀取 $($file.Path) 失敗：$_" -ForegroundColor Yellow
        }
    }
}

if ($TotalCount -eq 0) {
    Write-Host "✅ 沒有待新增內容" -ForegroundColor Green
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host ""
Write-Host "📊 總計：$TotalCount 篇待新增內容" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 2. 🆕 驗證 JSON 格式並顯示
# ============================================================

Write-Host "📝 待新增內容清單：" -ForegroundColor Yellow

$ValidItems = @()
$InvalidItems = @()

$i = 1
foreach ($item in $AllPending) {
    # 檢查必要欄位
    $hasError = $false
    $errorMsg = ""
    
    if (-not $item.keyword) {
        $hasError = $true
        $errorMsg = "缺少 keyword"
    }
    if (-not $item.category) {
        $hasError = $true
        $errorMsg = "缺少 category"
    }
    
    if ($hasError) {
        Write-Host "   ❌ 第 $i 筆 $errorMsg，已跳過" -ForegroundColor Red
        $InvalidItems += $item
        $i++
        continue
    }
    
    # 檢查 content_type
    $contentType = $item.content_type
    if (-not $contentType) {
        $contentType = "article"
    }
    
    # 檢查 video_id（音樂文章必須有）
    if ($contentType -eq "song") {
        if (-not ($item.PSObject.Properties.Name -contains "video_id") -or -not $item.video_id) {
            Write-Host "   ⚠️ 第 $i 筆 音樂文章缺少 video_id，已跳過" -ForegroundColor Yellow
            $InvalidItems += $item
            $i++
            continue
        }
    }
    
    # 檢查是否有 filename
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filenameDisplay = if ($hasFilename) { "📄 $($item.filename)" } else { "🔄 自動產生" }
    
    $typeLabel = if ($contentType -eq "song") { "🎵 音樂" } else { "📄 文章" }
    
    Write-Host "   $i. [$typeLabel] $($item.keyword) ($($item.category)) → $filenameDisplay" -ForegroundColor Gray
    
    # 🆕 顯示 video_id（如果有）
    if ($item.video_id) {
        Write-Host "      🎬 YouTube: $($item.video_id)" -ForegroundColor DarkGray
    }
    
    $ValidItems += $item
    $i++
}

if ($InvalidItems.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ 有 $($InvalidItems.Count) 筆資料格式錯誤，已跳過" -ForegroundColor Yellow
}

if ($ValidItems.Count -eq 0) {
    Write-Host "❌ 沒有有效的內容資料" -ForegroundColor Red
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
# 3. 備份 main.py
# ============================================================

Write-Host ""
Write-Host "📦 備份 main.py..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupPath = "$BackupDir\main.py.$Today.bak"
Copy-Item $MainPy $BackupPath -Force
Write-Host "   ✅ 已備份到：$BackupPath" -ForegroundColor Green

# ============================================================
# 4. 讀取現有 main.py
# ============================================================

Write-Host ""
Write-Host "📝 正在更新 main.py..." -ForegroundColor Yellow

$Content = Get-Content $MainPy -Raw -Encoding UTF8

# 🆕 檢查現有文章（更精確的比對）
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
    Write-Host "✅ 所有內容都已存在，無需新增" -ForegroundColor Green
    
    # 清空所有 JSON 檔案
    foreach ($file in $jsonFiles) {
        if (Test-Path $file.Path) {
            Write-UTF8NoBOM -Path $file.Path -Content "[]"
            Write-Host "   ✅ $($file.Path) 已清空" -ForegroundColor Green
        }
    }
    
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host "   將新增 $($NewItems.Count) 篇（$SkippedCount 篇已存在，已跳過）" -ForegroundColor Cyan

# ============================================================
# 5. 🆕 產生檔案名稱（支援 content_type）
# ============================================================

$NewEntries = @()
foreach ($item in $NewItems) {
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filename = Get-SafeFilename -Keyword $item.keyword -Category $item.category -CustomFilename $(if ($hasFilename) { $item.filename } else { $null })
    
    # 🆕 建構 JSON 條目（包含所有欄位）
    $entry = "    {`"keyword`": `"$($item.keyword)`", `"category`": `"$($item.category)`", `"filename`": `"$filename`""
    
    # 🆕 加入 content_type（如果不是預設的 article）
    $contentType = $item.content_type
    if ($contentType -and $contentType -ne "article") {
        $entry += ", `"content_type`": `"$contentType`""
    }
    
    # 🆕 加入 video_id（如果有）
    if ($item.video_id) {
        $entry += ", `"video_id`": `"$($item.video_id)`""
    }
    
    $entry += "},"
    $NewEntries += $entry
    
    $fileInfo = if ($hasFilename) { "📄 $filename" } else { "🔄 $filename (自動)" }
    $typeLabel = if ($contentType -eq "song") { "🎵" } else { "📄" }
    Write-Host "   ✅ $typeLabel $($item.keyword) → $fileInfo" -ForegroundColor Green
}

# ============================================================
# 6. 插入新關鍵字到 keywords_list
# ============================================================

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
# 7. 寫回 main.py（UTF-8 無 BOM）
# ============================================================

Write-UTF8NoBOM -Path $MainPy -Content $NewContent
Write-Host "   ✅ main.py 已更新（UTF-8 無 BOM）" -ForegroundColor Green

# ============================================================
# 8. 🆕 清空所有 JSON 檔案
# ============================================================

Write-Host ""
Write-Host "🧹 清空 JSON 檔案..." -ForegroundColor Yellow

foreach ($file in $jsonFiles) {
    if (Test-Path $file.Path) {
        Write-UTF8NoBOM -Path $file.Path -Content "[]"
        Write-Host "   ✅ $($file.Path) 已清空" -ForegroundColor Green
    }
}

# ============================================================
# 9. 完成摘要
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 新增完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

# 🆕 統計各類型數量
$articleCount = ($NewItems | Where-Object { $_.content_type -ne "song" }).Count
$songCount = ($NewItems | Where-Object { $_.content_type -eq "song" }).Count

Write-Host "📊 摘要：" -ForegroundColor Yellow
Write-Host "   ├─ 新增文章：$articleCount 篇" -ForegroundColor Cyan
Write-Host "   ├─ 新增音樂：$songCount 篇" -ForegroundColor Cyan
Write-Host "   ├─ 跳過（已存在）：$SkippedCount 篇" -ForegroundColor Gray
Write-Host "   ├─ 備份位置：$BackupPath" -ForegroundColor Gray
Write-Host "   └─ 編碼：UTF-8 無 BOM ✅" -ForegroundColor Green
Write-Host ""
Write-Host "📌 下一步：" -ForegroundColor Yellow
Write-Host "   python src\main.py --force deepseek" -ForegroundColor White
Write-Host "   .\scripts\ahpal-master.ps1 → 選擇 [6]" -ForegroundColor White
Write-Host ""

Read-Host "按 Enter 鍵結束"