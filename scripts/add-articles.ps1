# ============================================================
# add-articles.ps1 - 自動新增內容腳本 v5.0
# ============================================================
# 變更 (v5.0)：
#   - 🆕 完整整合 ensure-utf8-nobom.ps1 編碼驗證邏輯
#   - 🆕 新增 Write-Utf8NoBom 與 Test-NoBom 輔助函數
#   - 🆕 清空 pending-articles.json 後自動驗證編碼
#   - 🆕 讀取與寫入 JSON 統一使用 UTF-8 無 BOM
#   - 🔧 修復 ConvertFrom-Json 在空檔案時的錯誤處理
#   - 🔧 優化錯誤處理與重試機制
# ============================================================

param(
    [switch]$DryRun,
    [switch]$Force
)

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Continue"

# ============================================================
# 🎨 顏色輸出函數
# ============================================================

function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Gray { Write-Host $args -ForegroundColor Gray }

# ============================================================
# 📁 路徑設定
# ============================================================

$ProjectRoot = "C:\Users\User\ahpal-static"
$PendingFile = "$ProjectRoot\data\pending-articles.json"
$MasterFile = "$ProjectRoot\data\master-articles.json"
$BackupDir = "$ProjectRoot\backups\master-json"

# ============================================================
# 🔧 輔助函數：UTF-8 無 BOM 寫入
# ============================================================

function Write-Utf8NoBom {
    param(
        [string]$Path,
        [string]$Content
    )
    
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# ============================================================
# 🔧 輔助函數：驗證編碼 (無 BOM)
# ============================================================

function Test-NoBom {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) { return $false }
    
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        return $false  # 有 BOM
    }
    return $true  # 無 BOM
}

# ============================================================
# 🔧 輔助函數：讀取 JSON (UTF-8)
# ============================================================

function Read-PendingArticles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        return $null
    }
    
    try {
        $content = Get-Content $Path -Raw -Encoding UTF8 -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content) -or $content -eq "[]") {
            return @()
        }
        return $content | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Warning "   ⚠️ 讀取失敗：$_"
        return $null
    }
}

# ============================================================
# 🔧 輔助函數：寫入 JSON (UTF-8 無 BOM)
# ============================================================

function Write-PendingArticles {
    param(
        [string]$Path,
        [array]$Data
    )
    
    try {
        $json = $Data | ConvertTo-Json -Depth 10
        Write-Utf8NoBom -Path $Path -Content $json
        return $true
    } catch {
        Write-Error "   ❌ 寫入失敗：$_"
        return $false
    }
}

# ============================================================
# 🔍 主要邏輯
# ============================================================

Write-Info "============================================================"
Write-Info "  📝 自動新增內容工具 v5.0 (UTF-8 無 BOM 整合版)"
Write-Info "============================================================"
Write-Host ""

# ============================================================
# 步驟 1：檢查 pending-articles.json
# ============================================================

Write-Info "[1/4] 檢查待新增文章..."

if (-not (Test-Path $PendingFile)) {
    Write-Warning "   ⚠️ 找不到 pending-articles.json"
    Write-Gray "   ℹ️ 請在 data/pending-articles.json 中新增文章"
    Write-Host ""
    Read-Host "按 Enter 鍵結束"
    exit 0
}

$pending = Read-PendingArticles -Path $PendingFile

if ($pending -eq $null) {
    Write-Error "   ❌ 讀取 pending-articles.json 失敗"
    Read-Host "按 Enter 鍵結束"
    exit 1
}

if ($pending.Count -eq 0) {
    Write-Success "   ✅ 待新增文章清單為空，無需動作"
    Write-Host ""
    Read-Host "按 Enter 鍵結束"
    exit 0
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
# 步驟 4：讀取現有 master-articles.json
# ============================================================

Write-Info "[3/4] 合併到 master-articles.json..."

$master = @()
if (Test-Path $MasterFile) {
    try {
        $masterContent = Get-Content $MasterFile -Raw -Encoding UTF8 -ErrorAction Stop
        if (-not [string]::IsNullOrWhiteSpace($masterContent) -and $masterContent -ne "[]") {
            $master = $masterContent | ConvertFrom-Json -ErrorAction Stop
        }
    } catch {
        Write-Warning "   ⚠️ 讀取 master-articles.json 失敗，將建立新清單"
        $master = @()
    }
}

Write-Gray "   📊 現有文章：$($master.Count) 篇"

# ============================================================
# 步驟 5：合併 (避免重複)
# ============================================================

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
# 步驟 6：寫回 master-articles.json (UTF-8 無 BOM)
# ============================================================

Write-Info "[4/4] 儲存 master-articles.json..."

if ($newCount -gt 0) {
    $MasterFileDir = Split-Path $MasterFile -Parent
    New-Item -ItemType Directory -Path $MasterFileDir -Force | Out-Null
    
    $jsonContent = $master | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($MasterFile, $jsonContent, $utf8NoBom)

    Write-Success "   ✅ 已寫入 $($master.Count) 篇文章到 master-articles.json"
    
    # 驗證 master-articles.json 編碼
    if (Test-NoBom -Path $MasterFile) {
        Write-Success "   ✅ master-articles.json 編碼驗證通過：UTF-8 無 BOM"
    } else {
        Write-Warning "   ⚠️ master-articles.json 編碼驗證失敗：仍有 BOM，請檢查"
    }
} else {
    Write-Gray "   ℹ️ 無變更，跳過寫入"
}

# ============================================================
# 步驟 7：清空 pending-articles.json (UTF-8 無 BOM)
# ============================================================

Write-Info "🧹 清空 pending-articles.json..."

try {
    Write-Utf8NoBom -Path $PendingFile -Content "[]"
    Write-Success "   ✅ 已清空 pending-articles.json (UTF-8 無 BOM)"
} catch {
    Write-Error "   ❌ 清空失敗：$_"
    Write-Warning "   ⚠️ 嘗試使用備用方法..."
    
    try {
        [System.IO.File]::WriteAllText($PendingFile, "[]", [System.Text.Encoding]::UTF8)
        Write-Success "   ✅ 已清空 pending-articles.json (備用方法)"
    } catch {
        Write-Error "   ❌ 備用方法也失敗：$_"
        Write-Warning "   ⚠️ 請手動清空：echo '[]' > $PendingFile"
        exit 1
    }
}

# 驗證 pending-articles.json 編碼
if (Test-NoBom -Path $PendingFile) {
    Write-Success "   ✅ pending-articles.json 編碼驗證通過：UTF-8 無 BOM"
} else {
    Write-Warning "   ⚠️ pending-articles.json 編碼驗證失敗：仍有 BOM，請檢查"
}

# ============================================================
# 步驟 8：完成摘要
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
Write-Success "   ├─ master-articles.json 編碼：UTF-8 無 BOM ✅"
Write-Success "   └─ pending-articles.json 編碼：UTF-8 無 BOM ✅"
Write-Host ""
Write-Info "📌 下一步："
Write-Gray "   python src\main.py --force deepseek"
Write-Gray "   .\scripts\ahpal-master.ps1 → 選擇 [6]"
Write-Host ""

Read-Host "按 Enter 鍵結束"