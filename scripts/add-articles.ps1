# ============================================================
# add-articles.ps1 - 自動新增內容腳本 v3.3
# ============================================================
# 功能：從 JSON 檔案讀取內容，自動新增到 main.py
# 強化：
#   - 🆕 支援多個 JSON 檔案（articles / songs）
#   - 🆕 支援 content_type 欄位（article / song）
#   - 🆕 支援 video_id 欄位（音樂文章專用）
#   - 🆕 完整分類映射（含音樂創作）
#   - 🔧 UTF-8 無 BOM、特殊字元過濾、自動備份
#   - 🔧 完整欄位驗證
#   - 🔧 Python Fallback 讀取 JSON（ensure_ascii=True 徹底解決編碼問題）
#   - 🆕 支援 -DryRun 預覽模式
#   - 🆕 支援 -Force 跳過確認
#   - 🆕 統一的顏色輸出函數
# ============================================================

param(
    [switch]$DryRun,      # 預覽模式：僅顯示將要新增的內容
    [switch]$Force        # 強制模式：跳過確認步驟
)

# 設定執行原則（僅當前 Session）
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# 設定錯誤處理
$ErrorActionPreference = "Stop"

# ============================================================
# 🎨 顏色輸出函數
# ============================================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }
function Write-Gray { Write-ColorOutput $args[0] "Gray" }

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

# ============================================================
# 🆕 讀取 JSON（ensure_ascii=True 版本 — 徹底解決跨進程編碼問題）
# ============================================================
function Read-JsonFile {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    # 第一優先：Python 3 讀取 + ensure_ascii=True
    # 將所有 Unicode/Emoji 轉為 \uXXXX 格式，確保 PowerShell 接收 100% 純 ASCII
    try {
        $jsonAscii = python -c @"
import json
import sys
try:
    with open(r'$Path', 'r', encoding='utf-8') as f:
        data = json.load(f)
    # ensure_ascii=True 將所有非 ASCII 轉為 \uXXXX（純 ASCII 字串）
    print(json.dumps(data, ensure_ascii=True))
except Exception as e:
    print('ERROR:' + str(e), file=sys.stderr)
    sys.exit(1)
"@ 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $jsonAscii) {
            # PowerShell 接收純 ASCII，ConvertFrom-Json 會自動將 \uXXXX 還原
            return $jsonAscii | ConvertFrom-Json
        }
    } catch {
        Write-Warning "   ⚠️ Python 讀取失敗，嘗試 PowerShell 方法..."
    }
    
    # 第二優先：PowerShell 讀取（含 BOM 與 Null 字元處理）
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $content = [System.Text.Encoding]::UTF8.GetString($bytes)
        
        # 去除 BOM（如果存在）
        if ($content.StartsWith([char]0xFEFF)) {
            $content = $content.Substring(1)
            Write-Warning "   ⚠️ 偵測到 BOM，已自動去除"
        }
        
        # 清理 Null 字元與控制字元
        $content = $content -replace "`0", ""
        $content = $content -replace "`r`n", "`n"
        
        return $content | ConvertFrom-Json
    } catch {
        # 最後手段：嘗試將 Big5 轉為 UTF-8
        try {
            $content = Get-Content -Path $Path -Raw -Encoding Default -ErrorAction Stop
            $bytes = [System.Text.Encoding]::Default.GetBytes($content)
            $utf8Content = [System.Text.Encoding]::UTF8.GetString($bytes)
            return $utf8Content | ConvertFrom-Json
        } catch {
            throw "❌ JSON 解析失敗：$($_.Exception.Message)"
        }
    }
}

# ============================================================
# 🆕 完整分類映射（與 config.py 保持一致）
# ============================================================
function Get-CategoryMapping {
    return @{
        "💻 3C 科技教學" = "tech"
        "🎮 遊戲攻略" = "game"
        "🏠 生活小常識" = "life"
        "📊 軟體評測" = "review"
        "🌟 人生哲理" = "philosophy"
        "🤖 AI 趨勢" = "trend"
        "🎵 音樂創作" = "music"
        "🎵 台語音樂" = "music"   # 🆕 與 config.py 保持一致
    }
}

# ============================================================
# 🆕 產生安全的檔案名稱
# ============================================================
function Get-SafeFilename {
    param(
        [string]$Keyword,
        [string]$Category,
        [string]$CustomFilename = $null
    )
    
    # 如果有自訂 filename，直接使用
    if ($CustomFilename) {
        if ($CustomFilename -notmatch '\.html$') {
            $CustomFilename = "$CustomFilename.html"
        }
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

Write-Info "============================================================"
Write-Info "  📝 自動新增內容工具 v3.3 (ensure_ascii=True 最終版)"
Write-Info "============================================================"
Write-Host ""

if ($DryRun) {
    Write-Warning "🔍 預覽模式：僅顯示將要新增的內容，不實際修改"
    Write-Host ""
}

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
                Write-Info "📋 找到 $($items.Count) 篇待新增 $($file.Label)"
                foreach ($item in $items) {
                    if (-not ($item.PSObject.Properties.Name -contains "content_type")) {
                        $item | Add-Member -NotePropertyName "content_type" -NotePropertyValue $file.Type -Force
                    }
                    $AllPending += $item
                }
                $TotalCount += $items.Count
            }
        } catch {
            Write-Warning "   ⚠️ 讀取 $($file.Path) 失敗：$_"
        }
    }
}

if ($TotalCount -eq 0) {
    Write-Success "✅ 沒有待新增內容"
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Host ""
Write-Info "📊 總計：$TotalCount 篇待新增內容"
Write-Host ""

# ============================================================
# 2. 🆕 驗證 JSON 格式並顯示
# ============================================================

Write-Info "📝 待新增內容清單："

$ValidItems = @()
$InvalidItems = @()

$i = 1
foreach ($item in $AllPending) {
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
        Write-Error "   ❌ 第 $i 筆 $errorMsg，已跳過"
        $InvalidItems += $item
        $i++
        continue
    }
    
    $contentType = $item.content_type
    if (-not $contentType) {
        $contentType = "article"
    }
    
    if ($contentType -eq "song") {
        if (-not ($item.PSObject.Properties.Name -contains "video_id") -or -not $item.video_id) {
            Write-Warning "   ⚠️ 第 $i 筆 音樂文章缺少 video_id，已跳過"
            $InvalidItems += $item
            $i++
            continue
        }
    }
    
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filenameDisplay = if ($hasFilename) { "📄 $($item.filename)" } else { "🔄 自動產生" }
    
    $typeLabel = if ($contentType -eq "song") { "🎵 音樂" } else { "📄 文章" }
    
    Write-Gray "   $i. [$typeLabel] $($item.keyword) ($($item.category)) → $filenameDisplay"
    
    if ($item.video_id) {
        Write-Gray "      🎬 YouTube: $($item.video_id)"
    }
    
    $ValidItems += $item
    $i++
}

if ($InvalidItems.Count -gt 0) {
    Write-Host ""
    Write-Warning "⚠️ 有 $($InvalidItems.Count) 筆資料格式錯誤，已跳過"
}

if ($ValidItems.Count -eq 0) {
    Write-Error "❌ 沒有有效的內容資料"
    Read-Host "按 Enter 鍵結束"
    exit 1
}

# ============================================================
# 3. 🆕 預覽模式或確認
# ============================================================

Write-Host ""

if ($DryRun) {
    Write-Info "🔍 預覽模式完成，將新增 $($ValidItems.Count) 篇內容"
    Write-Gray "   若要實際執行，請移除 -DryRun 參數"
    Read-Host "按 Enter 鍵結束"
    exit 0
}

if (-not $Force) {
    $confirm = Read-Host "是否繼續新增？(y/n)"
    if ($confirm -ne "y") {
        Write-Warning "已取消操作"
        Read-Host "按 Enter 鍵結束"
        exit 0
    }
} else {
    Write-Gray "   ⚡ 強制模式：跳過確認步驟"
}

# ============================================================
# 4. 備份 main.py
# ============================================================

Write-Host ""
Write-Info "📦 備份 main.py..."
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupPath = "$BackupDir\main.py.$Today.bak"
Copy-Item $MainPy $BackupPath -Force
Write-Success "   ✅ 已備份到：$BackupPath"

# ============================================================
# 5. 讀取現有 main.py
# ============================================================

Write-Host ""
Write-Info "📝 正在更新 main.py..."

$Content = Get-Content $MainPy -Raw -Encoding UTF8

$ExistingKeywords = [regex]::Matches($Content, '"keyword": "([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
$NewItems = @()
$SkippedCount = 0

foreach ($item in $ValidItems) {
    if ($item.keyword -in $ExistingKeywords) {
        Write-Gray "   ⏩ 跳過（已存在）：$($item.keyword)"
        $SkippedCount++
        continue
    }
    $NewItems += $item
}

if ($NewItems.Count -eq 0) {
    Write-Success "✅ 所有內容都已存在，無需新增"
    
    foreach ($file in $jsonFiles) {
        if (Test-Path $file.Path) {
            Write-UTF8NoBOM -Path $file.Path -Content "[]"
            Write-Success "   ✅ $($file.Path) 已清空"
        }
    }
    
    Read-Host "按 Enter 鍵結束"
    exit 0
}

Write-Info "   將新增 $($NewItems.Count) 篇（$SkippedCount 篇已存在，已跳過）"

# ============================================================
# 6. 🆕 產生檔案名稱
# ============================================================

$NewEntries = @()
foreach ($item in $NewItems) {
    $hasFilename = ($item.PSObject.Properties.Name -contains "filename") -and $item.filename
    $filename = Get-SafeFilename -Keyword $item.keyword -Category $item.category -CustomFilename $(if ($hasFilename) { $item.filename } else { $null })
    
    $entry = "    {`"keyword`": `"$($item.keyword)`", `"category`": `"$($item.category)`", `"filename`": `"$filename`""
    
    $contentType = $item.content_type
    if ($contentType -and $contentType -ne "article") {
        $entry += ", `"content_type`": `"$contentType`""
    }
    
    if ($item.video_id) {
        $entry += ", `"video_id`": `"$($item.video_id)`""
    }
    
    $entry += "},"
    $NewEntries += $entry
    
    $fileInfo = if ($hasFilename) { "📄 $filename" } else { "🔄 $filename (自動)" }
    $typeLabel = if ($contentType -eq "song") { "🎵" } else { "📄" }
    Write-Success "   ✅ $typeLabel $($item.keyword) → $fileInfo"
}

# ============================================================
# 7. 插入新關鍵字到 keywords_list
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
# 8. 寫回 main.py（UTF-8 無 BOM）
# ============================================================

Write-UTF8NoBOM -Path $MainPy -Content $NewContent
Write-Success "   ✅ main.py 已更新（UTF-8 無 BOM）"

# ============================================================
# 9. 清空所有 JSON 檔案（UTF-8 無 BOM）
# ============================================================

Write-Host ""
Write-Info "🧹 清空 JSON 檔案..."

foreach ($file in $jsonFiles) {
    if (Test-Path $file.Path) {
        Write-UTF8NoBOM -Path $file.Path -Content "[]"
        Write-Success "   ✅ $($file.Path) 已清空 (UTF-8 無 BOM)"
    }
}

# ============================================================
# 10. 完成摘要
# ============================================================

Write-Host ""
Write-Info "============================================================"
Write-Success "✅ 新增完成！"
Write-Info "============================================================"
Write-Host ""

$articleCount = ($NewItems | Where-Object { $_.content_type -ne "song" }).Count
$songCount = ($NewItems | Where-Object { $_.content_type -eq "song" }).Count

Write-Info "📊 摘要："
Write-Info "   ├─ 新增文章：$articleCount 篇"
Write-Info "   ├─ 新增音樂：$songCount 篇"
Write-Gray "   ├─ 跳過（已存在）：$SkippedCount 篇"
Write-Gray "   ├─ 備份位置：$BackupPath"
Write-Success "   └─ 編碼：UTF-8 無 BOM ✅"
Write-Host ""
Write-Info "📌 下一步："
Write-Gray "   python src\main.py --force deepseek"
Write-Gray "   .\scripts\ahpal-master.ps1 → 選擇 [6]"
Write-Host ""

Read-Host "按 Enter 鍵結束"