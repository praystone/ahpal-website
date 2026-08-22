# ============================================================
# preflight-check.ps1 - 董事長死命令檢查 v2.5
# ============================================================

param(
    [switch]$Quiet,
    [switch]$Fix,
    [switch]$Report
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }

$ConfigPath = Join-Path $ScriptDir "config.ps1"
if (Test-Path $ConfigPath) { . $ConfigPath }

function Write-Info { if (-not $Quiet) { Write-Host $args -ForegroundColor Cyan } }
function Write-Success { if (-not $Quiet) { Write-Host $args -ForegroundColor Green } }
function Write-Warning { if (-not $Quiet) { Write-Host $args -ForegroundColor Yellow } }
function Write-Error { if (-not $Quiet) { Write-Host $args -ForegroundColor Red } }

Write-Info "============================================================"
Write-Info "  🔴 董事長死命令：變更後強制檢查 v2.5"
Write-Info "============================================================"
Write-Info ""
Write-Info "  執行時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info ""

$ErrorCount = 0
$WarningCount = 0

# 文章數量
Write-Info "   [1] 檢查文章數量..."
$ExcludeDirs = @("game", "docs", "scripts", "src", "backups", "logs", "images", "data", "test", "__pycache__")
$ArticleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.html" -File | Where-Object {
    $dir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $ExcludeDirs) {
        if ($dir -match "\\$ex\\?" -or $dir -match "/$ex/?") { $skip = $true; break }
    }
    -not $skip
}
$ArticleCount = $ArticleFiles.Count
Write-Info "   📄 文章總數：$ArticleCount 篇"

# 檢查待生成文章
$PendingFile = Join-Path $ProjectRoot "data\pending-articles.json"
if (Test-Path $PendingFile) {
    $PendingContent = Get-Content $PendingFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($PendingContent -and $PendingContent -ne "[]") {
        Write-Warning "   ⚠️ 發現待生成文章"
        $WarningCount++
    } else {
        Write-Success "   ✅ 無待生成文章"
    }
} else {
    Write-Success "   ✅ 無待生成文章"
}

# 首頁檢查
$IndexPath = Join-Path $ProjectRoot "index.html"
if (Test-Path $IndexPath) {
    Write-Success "   ✅ 首頁存在"
} else {
    Write-Error "   ❌ 首頁不存在"
    $ErrorCount++
}

# 品牌名稱檢查（精簡版）
Write-Info "   [2] 檢查品牌名稱..."
$BrandIssues = 0
$SampleFiles = $ArticleFiles | Select-Object -First 50
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '雅寶社區') {
        $BrandIssues++
    }
}
if ($BrandIssues -gt 0) {
    Write-Warning "   ⚠️ 有 $BrandIssues 個檔案缺少品牌名稱"
    $WarningCount++
} else {
    Write-Success "   ✅ 品牌名稱檢查通過"
}

# API錯誤檢查（精簡版）
Write-Info "   [3] 檢查 API 錯誤標記..."
$ApiErrorIssues = 0
$ErrorKeywords = @("API_ERROR", "RateLimit", "429")
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content) {
        foreach ($keyword in $ErrorKeywords) {
            if ($Content -match $keyword) {
                $ApiErrorIssues++
                break
            }
        }
    }
}
if ($ApiErrorIssues -gt 0) {
    Write-Warning "   ⚠️ 有 $ApiErrorIssues 個檔案含有 API 錯誤標記"
    $WarningCount++
} else {
    Write-Success "   ✅ 無 API 錯誤標記"
}

# Git狀態檢查
Write-Info "   [4] 檢查 Git 狀態..."
$GitStatus = git status --porcelain 2>$null
if ($GitStatus) {
    $ChangedCount = ($GitStatus | Measure-Object).Count
    Write-Warning "   ⚠️ 有 $ChangedCount 個未提交的變更"
    $WarningCount++
} else {
    Write-Success "   ✅ Git 工作目錄乾淨"
}

# 總結報告
Write-Info ""
Write-Info "============================================================"
Write-Info "  📊 檢查報告"
Write-Info "============================================================"
Write-Info ""
Write-Info "   ⚠️ 警告：$WarningCount 項"
Write-Info "   ❌ 錯誤：$ErrorCount 項"
Write-Info ""

if ($ErrorCount -eq 0) {
    Write-Success "   ✅ 檢查通過！"
    exit 0
} else {
    Write-Error "   ❌ 有錯誤需要修正！"
    exit 2
}
