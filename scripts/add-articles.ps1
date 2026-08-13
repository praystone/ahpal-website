# ============================================================
# add-articles.ps1 - 自動新增內容腳本 v4.0
# ============================================================
# 變更 (v4.0)：
#   - 🆕 將文章合併到 master-articles.json (主資料庫)
#   - 🆕 不再直接寫入 main.py
#   - 🆕 處理後清空 pending-articles.json
#   - 🆕 判斷邏輯：只在 pending-articles.json 有資料時才動作
# ============================================================

param(
    [switch]$DryRun,
    [switch]$Force
)

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# ============================================================
# 🎨 顏色輸出函數
# ============================================================

function Write-ColorOutput { param([string]$Message, [string]$Color = "White") Write-Host $Message -ForegroundColor $Color }
function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }
function Write-Gray { Write-ColorOutput $args[0] "Gray" }


# ============================================================
# 📁 路徑設定
# ============================================================

$ProjectRoot = "C:\Users\User\ahpal-static"
$PendingFile = "$ProjectRoot\data\pending-articles.json"
$MasterFile = "$ProjectRoot\data\master-articles.json"
$BackupDir = "$ProjectRoot\backups\master-json"


# ============================================================
# 🔍 主要邏輯
# ============================================================

Write-Info "============================================================"
Write-Info "  📝 自動新增內容工具 v4.0 (JSON 合併版)"
Write-Info "============================================================"
Write-Host ""

# ============================================================
# 步驟 1：檢查 pending-articles.json 是否存在且有資料
# ============================================================

Write-Info "[1/4] 檢查待新增文章..."

if (-not (Test-Path $PendingFile)) {
    Write-Warning "   ⚠️ 找不到 pending-articles.json"
    Write-Gray "   ℹ️ 請在 data/pending-articles.json 中新增文章"
    Write-Host ""
    Read-Host "按 Enter 鍵結束"
    exit 0
}

# 讀取 pending-articles.json
try {
    $pendingContent = Get-Content $PendingFile -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($pendingContent) -or $pendingContent -eq "[]") {
        Write-Success "   ✅ 待新增文章清單為空，無需動作"
        Write-Host ""
        Read-Host "按 Enter 鍵結束"
        exit 0
    }
    
    $pending = $pendingContent | ConvertFrom-Json
    if ($pending.Count -eq 0) {
        Write-Success "   ✅ 待新增文章清單為空，無需動作"
        Write-Host ""
        Read-Host "按 Enter 鍵結束"
        exit 0
    }
} catch {
    Write-Error "   ❌ 讀取 pending-articles.json 失敗：$_"
    Read-Host "按 Enter 鍵結束"
    exit 1
}

Write-Info "   📋 發現 $($pending.Count) 篇待新增文章"
Write-Host ""

# ============================================================
# 步驟 2：預覽模式
# ============================================================

if ($DryRun) {
    Write-Info "🔍 預覽模式：將合併以下文章到 master-articles.json"
    Write-Host ""
    foreach ($item in $pending) {
        Write-Gray "   📄 $($item.keyword) → $($item.category)"
    }
    Write-Host ""
    Write-Gray "   📊 共 $($pending.Count) 篇待新增"
    Write-Host ""
    Read-Host "按 Enter 鍵結束"
    exit 0
}

# ============================================================
# 步驟 3：備份 master-articles.json
# ============================================================

Write-Info "[2/4] 備份 master-articles.json..."

New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupFile = "$BackupDir\master-articles-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"

if (Test-Path $MasterFile) {
    Copy-Item $MasterFile $BackupFile -Force
    Write-Success "   ✅ 已備份到：$BackupFile"
} else {
    Write-Gray "   ℹ️ master-articles.json 不存在，將建立新檔案"
}


# ============================================================
# 步驟 4：讀取現有 master-articles.json 並合併
# ============================================================

Write-Info "[3/4] 合併到 master-articles.json..."

# 讀取現有 master 清單
$master = @()
if (Test-Path $MasterFile) {
    try {
        $masterContent = Get-Content $MasterFile -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($masterContent) -and $masterContent -ne "[]") {
            $master = $masterContent | ConvertFrom-Json
        }
    } catch {
        Write-Warning "   ⚠️ 讀取 master-articles.json 失敗，將建立新清單"
        $master = @()
    }
}

Write-Gray "   📊 現有文章：$($master.Count) 篇"

# 合併 (避免重複)
$existingKeywords = $master | ForEach-Object { $_.keyword }
$newCount = 0
$skipCount = 0

foreach ($item in $pending) {
    if ($item.keyword -notin $existingKeywords) {
        $master += $item
        $newCount++
        Write-Success "   ✅ 新增：$($item.keyword)"
    } else {
        $skipCount++
        Write-Gray "   ⏩ 跳過 (已存在)：$($item.keyword)"
    }
}

if ($newCount -eq 0) {
    Write-Warning "   ⚠️ 所有文章已存在，無需合併"
    Write-Gray "   📊 跳過 $skipCount 篇"
} else {
    Write-Success "   ✅ 新增 $newCount 篇文章 (跳過 $skipCount 篇)"
}

# ============================================================
# 步驟 5：寫回 master-articles.json
# ============================================================

Write-Info "[4/4] 儲存 master-articles.json..."

if ($newCount -gt 0) {
    # 確保目錄存在
    $MasterFileDir = Split-Path $MasterFile -Parent
    New-Item -ItemType Directory -Path $MasterFileDir -Force | Out-Null
    
    # 寫入 JSON (UTF-8 無 BOM)
    # 替換為 v4.1
$jsonContent = $master | ConvertTo-Json -Depth 10
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($MasterFile, $jsonContent, $utf8NoBom)

    Write-Success "   ✅ 已寫入 $($master.Count) 篇文章到 master-articles.json"
} else {
    Write-Gray "   ℹ️ 無變更，跳過寫入"
}

# ============================================================
# 步驟 6：清空 pending-articles.json
# ============================================================

Write-Info "🧹 清空 pending-articles.json..."
"[]" | Out-File $PendingFile -Encoding utf8
Write-Success "   ✅ 已清空 pending-articles.json"


# ============================================================
# 步驟 7：完成摘要
# ============================================================

Write-Host ""
Write-Info "============================================================"
Write-Success "✅ 合併完成！"
Write-Info "============================================================"
Write-Host ""
Write-Info "📊 摘要："
Write-Info "   ├─ 新增文章：$newCount 篇"
if ($skipCount -gt 0) {
    Write-Gray "   ├─ 跳過 (已存在)：$skipCount 篇"
}
Write-Info "   ├─ 主資料庫：$($master.Count) 篇文章"
Write-Info "   ├─ 備份位置：$BackupFile"
Write-Success "   └─ 編碼：UTF-8 無 BOM ✅"
Write-Host ""
Write-Info "📌 下一步："
Write-Gray "   python src\main.py --force deepseek"
Write-Gray "   .\scripts\ahpal-master.ps1 → 選擇 [6]"
Write-Host ""

Read-Host "按 Enter 鍵結束"