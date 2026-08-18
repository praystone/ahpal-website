# ============================================================
# check-seo-noindex.ps1 - 死命令 11：SEO 四大件嚴禁 noindex
# ============================================================
# 用途：獨立檢查 SEO 四大件是否含有 noindex
# 可被 ahpal-master.ps1 調用，也可單獨執行
# ============================================================

param(
    [switch]$Quiet,          # 安靜模式（僅輸出結果，不顯示詳細）
    [switch]$ReturnOnly      # 僅回傳結果，不輸出任何訊息（供腳本調用）
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$OutputDir = $ProjectRoot

$SeoPages = @("privacy-policy.html", "terms-of-service.html", "about.html", "contact.html")
$NoIndexViolations = @()
$HasError = $false

# 顏色函數（安靜模式跳過）
function Write-Info {
    if (-not $Quiet -and -not $ReturnOnly) { Write-Host $args -ForegroundColor Cyan }
}
function Write-Success {
    if (-not $Quiet -and -not $ReturnOnly) { Write-Host $args -ForegroundColor Green }
}
function Write-Warning {
    if (-not $Quiet -and -not $ReturnOnly) { Write-Host $args -ForegroundColor Yellow }
}
function Write-Error {
    if (-not $Quiet -and -not $ReturnOnly) { Write-Host $args -ForegroundColor Red }
}
function Write-Gray {
    if (-not $Quiet -and -not $ReturnOnly) { Write-Host $args -ForegroundColor Gray }
}

# 執行檢查
if (-not $ReturnOnly) {
    Write-Host ""
    Write-Host "📋 死命令 11 檢查：SEO 四大件嚴禁 noindex" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

foreach ($page in $SeoPages) {
    $pagePath = Join-Path $OutputDir $page
    if (Test-Path $pagePath) {
        $content = Get-Content $pagePath -Raw -ErrorAction SilentlyContinue
        if ($content -match 'noindex') {
            $NoIndexViolations += $page
            $HasError = $true
            if (-not $ReturnOnly) {
                Write-Error "   ❌ $page 含有 noindex"
            }
        } else {
            if (-not $ReturnOnly) {
                Write-Success "   ✅ $page 無 noindex"
            }
        }
    } else {
        # 檔案不存在視為警告（但不算違規）
        if (-not $ReturnOnly) {
            Write-Warning "   ⚠️ $page 不存在"
        }
    }
}

# 輸出結果（非 ReturnOnly 模式）
if (-not $ReturnOnly) {
    Write-Host ""
    if ($HasError) {
        Write-Error "   ❌ 違反死命令 11：以下頁面含有 noindex："
        foreach ($page in $NoIndexViolations) {
            Write-Error "      📄 $page"
        }
    } else {
        Write-Success "   ✅ 死命令 11 通過：四大件無 noindex"
    }
    Write-Host ""
}

# 回傳結果（供腳本調用）
if ($HasError) {
    exit 1   # 有違規
} else {
    exit 0   # 通過
}