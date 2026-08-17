# ============================================================
# config.ps1 - AHPAL 核心統一配置 v1.0
# ============================================================
# 功能：
#   - 所有腳本的統一配置來源 (分類、路徑、門檻值)
#   - 符合 DRY 原則 (Don't Repeat Yourself)
#   - 所有腳本應從此檔案讀取定義
#
# 使用方式：
#   在其他腳本中呼叫：. .\scripts\config.ps1
#   或：Import-Module .\scripts\config.ps1 -Force
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
# 📁 路徑設定
# ============================================================
$Global:ProjectRoot = if ($env:AHPAL_OUTPUT_DIR) { $env:AHPAL_OUTPUT_DIR } else { "C:\Users\User\ahpal-static" }
$Global:ScriptsDir = Join-Path $Global:ProjectRoot "scripts"
$Global:BackupRoot = "C:\Users\User\ahpal-backup"
$Global:ArchiveRoot = "C:\Users\User\ahpal-AI-archive"
$Global:LogDir = Join-Path $Global:ProjectRoot "logs"

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
# 📌 顯示載入狀態
# ============================================================
if ($MyInvocation.InvocationName -ne ".") {
    Write-Host "✅ 已載入核心配置 v1.0" -ForegroundColor Green
    Write-Host "   📂 分類數量：$($Global:CategoryDirs.Count) 個" -ForegroundColor Cyan
    Write-Host "   📄 分類頁面：$($Global:CategoryPages.Count) 個" -ForegroundColor Cyan
    Write-Host "   📁 專案路徑：$Global:ProjectRoot" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# 匯出變數與函數 (供其他腳本使用)
# ============================================================
Export-ModuleMember -Variable "CategoryDirs", "CategoryPages", "ProjectRoot", "ScriptsDir", "BackupRoot", "ArchiveRoot", "LogDir", "QualityThreshold", "MinFileSize", "MinWords", "MinH2Count", "BackupKeepCount", "GoldenBackupKeepCount", "DeepSeekModel", "GeminiModel", "BalanceThreshold"
Export-ModuleMember -Function "Get-CategoryName", "Get-CategoryKey", "Get-AllCategoryKeys", "Get-AllCategoryNames", "Get-CategoryArticleCount", "Get-AllCategoryStats"