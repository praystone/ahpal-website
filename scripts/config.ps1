# ============================================================
# config.ps1 - AHPAL 核心統一配置 v1.2
# ============================================================
# 功能：
#   - 所有腳本的統一配置來源 (分類、路徑、門檻值)
#   - 符合 DRY 原則 (Don't Repeat Yourself)
#   - 所有腳本應從此檔案讀取定義
#
# 使用方式：
#   在其他腳本中呼叫：. .\scripts\config.ps1
#   或：Import-Module .\scripts\config.ps1 -Force
#
# v1.2 變更 (2026-08-18)：
#   - 🆕 日誌路徑遷移至 system-reports/ (批次/系統分離)
#   - 🆕 新增 $Global:LogDirBatch (批次生成日誌)
#   - 🆕 新增 $Global:LogDirSystem (系統執行日誌)
#   - 🆕 保持 $Global:LogDir 向後相容 (指向舊 logs/)
#   - 🆕 新增 Get-LogPath 函數統一取得日誌路徑
# ============================================================

# ============================================================
# 📂 9 大分類定義 (統一來源)
# ============================================================
$Global:CategoryDirs = @{
    "history"    = "📜 歷史腦洞"
    "tech"       = "💻 3C 科技教學"
    "game"       = "🎮 遊戲攻略"
    "life"       = "🏠 生活小常識"
    "review"     = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend"      = "🤖 AI 趨勢"
    "music"      = "🎵 音樂創作"
    "nature"     = "🌳 動植物生態"
}

# ============================================================
# 📄 分類頁面清單 (自動生成)
# ============================================================
$Global:CategoryPages = $Global:CategoryDirs.Keys | ForEach-Object { "category-$_.html" }

# ============================================================
# 📁 路徑設定 (v1.2 更新)
# ============================================================
$Global:ProjectRoot = if ($env:AHPAL_OUTPUT_DIR) { $env:AHPAL_OUTPUT_DIR } else { "C:\Users\User\ahpal-static" }
$Global:ScriptsDir = Join-Path $Global:ProjectRoot "scripts"
$Global:BackupRoot = "C:\Users\User\ahpal-backup"
$Global:ArchiveRoot = "C:\Users\User\ahpal-AI-archive"

# 🆕 v1.2: 日誌路徑遷移至 system-reports/
$Global:SystemReportsRoot = Join-Path $Global:ArchiveRoot "system-tools\system-reports"
$Global:LogDirBatch = Join-Path $Global:SystemReportsRoot "01-批次生成日誌"
$Global:LogDirSystem = Join-Path $Global:SystemReportsRoot "02-系統執行日誌"

# 向後相容：保留舊 logs/ 路徑 (避免現有腳本錯誤)
$Global:LogDir = Join-Path $Global:ProjectRoot "logs"

# 確保目錄存在
New-Item -ItemType Directory -Path $Global:LogDirBatch -Force | Out-Null
New-Item -ItemType Directory -Path $Global:LogDirSystem -Force | Out-Null

# ============================================================
# 📊 品質門檻設定
# ============================================================
$Global:QualityThreshold = 60           # 品質通過分數 (滿分 100)
$Global:MinFileSize = 5120              # 最小有效檔案大小 (bytes)
$Global:MinWords = 1200                 # 最低文章字數
$Global:MinH2Count = 3                  # 最低 H2 數量

# ============================================================
# 💾 備份設定
# ============================================================
$Global:BackupKeepCount = 5             # 保留最近 N 個備份
$Global:GoldenBackupKeepCount = 3       # 黃金備份保留數量

# ============================================================
# 🎯 API 設定
# ============================================================
$Global:DeepSeekModel = "deepseek-v4-flash"
$Global:GeminiModel = "gemini-3.1-flash-image"
$Global:BalanceThreshold = 1.0          # 餘額告警門檻 (USD)

# ============================================================
# 🆕 v1.2: 統一取得日誌路徑
# ============================================================
function Get-LogPath {
    param(
        [ValidateSet("batch", "system", "legacy", "all")]
        [string]$Type = "batch"
    )
    switch ($Type) {
        "batch"   { return $Global:LogDirBatch }
        "system"  { return $Global:LogDirSystem }
        "legacy"  { return $Global:LogDir }
        "all"     { return @{
                        Batch = $Global:LogDirBatch
                        System = $Global:LogDirSystem
                        Legacy = $Global:LogDir
                    }
        }
        default   { return $Global:LogDirBatch }
    }
}

# ============================================================
# 🆕 v1.2: 取得日誌檔案 (支援類型過濾)
# ============================================================
function Get-LogFiles {
    param(
        [ValidateSet("batch", "system", "legacy", "all")]
        [string]$Type = "batch",
        [string]$Pattern = "*.log",
        [int]$MaxCount = 0
    )
    
    $targetDir = Get-LogPath -Type $Type
    if ($Type -eq "all") {
        $dirs = @($Global:LogDirBatch, $Global:LogDirSystem, $Global:LogDir)
    } else {
        $dirs = @($targetDir)
    }
    
    $files = @()
    foreach ($dir in $dirs) {
        if (Test-Path $dir) {
            $files += Get-ChildItem -Path $dir -Filter $Pattern -File -ErrorAction SilentlyContinue
        }
    }
    
    $files = $files | Sort-Object LastWriteTime -Descending
    if ($MaxCount -gt 0) {
        $files = $files | Select-Object -First $MaxCount
    }
    return $files
}

# ============================================================
# 🆕 v1.2: 清理舊日誌 (保留 N 個)
# ============================================================
function Clear-OldLogs {
    param(
        [ValidateSet("batch", "system", "legacy", "all")]
        [string]$Type = "batch",
        [int]$KeepCount = 10
    )
    
    $files = Get-LogFiles -Type $Type -MaxCount 0
    if ($files.Count -le $KeepCount) {
        Write-Host "  ℹ️ 日誌數量 ($($files.Count)) 未超過保留數 ($KeepCount)，無需清理" -ForegroundColor Gray
        return 0
    }
    
    $toDelete = $files | Select-Object -Skip $KeepCount
    $deletedCount = 0
    foreach ($f in $toDelete) {
        Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
        $deletedCount++
    }
    Write-Host "  🗑️ 已刪除 $deletedCount 個舊日誌 (保留 $KeepCount 個)" -ForegroundColor Green
    return $deletedCount
}

# ============================================================
# 🔧 匯出函數：取得分類名稱 (依 key)
# ============================================================
function Get-CategoryName {
    param([string]$Key)
    if ($Global:CategoryDirs.ContainsKey($Key)) {
        return $Global:CategoryDirs[$Key]
    }
    return $null
}

# ============================================================
# 🔧 匯出函數：取得分類 Key (依名稱)
# ============================================================
function Get-CategoryKey {
    param([string]$Name)
    foreach ($key in $Global:CategoryDirs.Keys) {
        if ($Global:CategoryDirs[$key] -eq $Name) {
            return $key
        }
    }
    return $null
}

# ============================================================
# 🔧 匯出函數：取得所有分類 Key
# ============================================================
function Get-AllCategoryKeys {
    return $Global:CategoryDirs.Keys
}

# ============================================================
# 🔧 匯出函數：取得所有分類名稱
# ============================================================
function Get-AllCategoryNames {
    return $Global:CategoryDirs.Values
}

# ============================================================
# 🔧 匯出函數：取得指定分類的文章數量
# ============================================================
function Get-CategoryArticleCount {
    param([string]$Key)
    $dir = Join-Path $Global:ProjectRoot $Key
    if (Test-Path $dir) {
        return (Get-ChildItem -Path $dir -Filter "*.html" -ErrorAction SilentlyContinue).Count
    }
    return 0
}

# ============================================================
# 🔧 匯出函數：取得所有分類的文章統計
# ============================================================
function Get-AllCategoryStats {
    $stats = @{}
    foreach ($key in $Global:CategoryDirs.Keys) {
        $stats[$key] = @{
            Name = $Global:CategoryDirs[$key]
            Count = Get-CategoryArticleCount -Key $key
        }
    }
    return $stats
}

# ============================================================
# 🔧 統一配置存取函數
# ============================================================
function Get-Config {
    param([string]$Key)
    switch ($Key) {
        "CategoryDirs" { return $Global:CategoryDirs }
        "CategoryPages" { return $Global:CategoryPages }
        "ProjectRoot" { return $Global:ProjectRoot }
        "ScriptsDir" { return $Global:ScriptsDir }
        "BackupRoot" { return $Global:BackupRoot }
        "ArchiveRoot" { return $Global:ArchiveRoot }
        "SystemReportsRoot" { return $Global:SystemReportsRoot }
        "LogDir" { return $Global:LogDir }
        "LogDirBatch" { return $Global:LogDirBatch }
        "LogDirSystem" { return $Global:LogDirSystem }
        "QualityThreshold" { return $Global:QualityThreshold }
        "MinFileSize" { return $Global:MinFileSize }
        "MinWords" { return $Global:MinWords }
        "MinH2Count" { return $Global:MinH2Count }
        "BackupKeepCount" { return $Global:BackupKeepCount }
        "DeepSeekModel" { return $Global:DeepSeekModel }
        "GeminiModel" { return $Global:GeminiModel }
        default { return $null }
    }
}

# ============================================================
# 📌 顯示載入狀態 (只在直接執行時顯示)
# ============================================================
if ($MyInvocation.InvocationName -eq ".") {
    $null = 1  # 靜默載入
} elseif ($MyInvocation.InvocationName -eq $null -or $MyInvocation.InvocationName -eq "") {
    Write-Host "✅ 已載入核心配置 v1.2" -ForegroundColor Green
    Write-Host "   📂 分類數量：$($Global:CategoryDirs.Count) 個" -ForegroundColor Cyan
    Write-Host "   📄 分類頁面：$($Global:CategoryPages.Count) 個" -ForegroundColor Cyan
    Write-Host "   📁 專案路徑：$Global:ProjectRoot" -ForegroundColor Cyan
    Write-Host "   📁 批次日誌：$Global:LogDirBatch" -ForegroundColor Cyan
    Write-Host "   📁 系統日誌：$Global:LogDirSystem" -ForegroundColor Cyan
    Write-Host ""
} else {
    $null = 1  # 從其他腳本載入時靜默
}

# ============================================================
# 僅在作為模組載入時匯出
# ============================================================
if ($MyInvocation.MyCommand.CommandType -eq "Script" -and $MyInvocation.MyCommand.Path -match "\.psm1$") {
    Export-ModuleMember -Variable "CategoryDirs", "CategoryPages", "ProjectRoot", "ScriptsDir", "BackupRoot", "ArchiveRoot", "LogDir", "LogDirBatch", "LogDirSystem", "SystemReportsRoot", "QualityThreshold", "MinFileSize", "MinWords", "MinH2Count", "BackupKeepCount", "GoldenBackupKeepCount", "DeepSeekModel", "GeminiModel", "BalanceThreshold"
    Export-ModuleMember -Function "Get-CategoryName", "Get-CategoryKey", "Get-AllCategoryKeys", "Get-AllCategoryNames", "Get-CategoryArticleCount", "Get-AllCategoryStats", "Get-Config", "Get-LogPath", "Get-LogFiles", "Clear-OldLogs"
}