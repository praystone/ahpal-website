# ============================================================
# check-seo-defense.ps1 - SEO 爬蟲防線與審查預警 v1.3
# ============================================================
# 🆕 v1.3 變更 (2026-08-19)：
#   - 🔧 只檢查核心爬蟲 (Mediapartners-Google, Googlebot, *)
#   - 🔧 不再把 AI 訓練爬蟲的 Disallow: / 當成錯誤
#   - 🔧 如果 robots.txt 沒有 Disallow: / 就給過
# ============================================================

param(
    [switch]$Quiet,
    [switch]$Fix
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$OutputDir = $ProjectRoot

$ErrorCount = 0
$WarningCount = 0
$FixCount = 0

function Write-Info {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Cyan }
}
function Write-Success {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Green }
}
function Write-Warning {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Yellow }
}
function Write-Error {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Red }
}

Write-Info "============================================================"
Write-Info "  🔍 SEO 爬蟲防線與審查預警 v1.3"
Write-Info "============================================================"
Write-Info ""

# ============================================================
# [1/5] 檢查 robots.txt (核心爬蟲)
# ============================================================
Write-Info "[1/5] 檢查 robots.txt..."

$RobotsPath = Join-Path $OutputDir "robots.txt"
if (Test-Path $RobotsPath) {
    $Content = Get-Content $RobotsPath -Raw -Encoding UTF8

    # 用空白行分割段落
    $Sections = $Content -split "`r`n`r`n|`n`n"
    
    $HasAdsenseAllow = $false
    $HasGooglebotAllow = $false
    $HasDisallowAll = $false

    foreach ($Section in $Sections) {
        # 檢查段落是否包含 User-agent: Mediapartners-Google
        if ($Section -match '(?m)^User-agent:\s*Mediapartners-Google') {
            if ($Section -match '(?m)^Allow:\s*/\s*$') {
                $HasAdsenseAllow = $true
            }
        }
        # 檢查段落是否包含 User-agent: Googlebot
        if ($Section -match '(?m)^User-agent:\s*Googlebot') {
            if ($Section -match '(?m)^Allow:\s*/\s*$') {
                $HasGooglebotAllow = $true
            }
        }
        # 檢查通用爬蟲是否有 Disallow: /
        if ($Section -match '(?m)^User-agent:\s*\*') {
            if ($Section -match '(?m)^Disallow:\s*/\s*$') {
                $HasDisallowAll = $true
            }
        }
    }

    if ($HasAdsenseAllow) {
        Write-Success "   ✅ Mediapartners-Google 已放行"
    } else {
        Write-Error "   ❌ Mediapartners-Google 未放行！"
        $ErrorCount++
    }
    if ($HasGooglebotAllow) {
        Write-Success "   ✅ Googlebot 已放行"
    } else {
        Write-Warning "   ⚠️ Googlebot 未明確放行"
        $WarningCount++
    }
    if ($HasDisallowAll) {
        Write-Error "   ❌ 通用爬蟲 (User-agent: *) 被 Disallow: / 阻擋！"
        $ErrorCount++
    } else {
        Write-Success "   ✅ 無 Disallow: / 阻擋所有爬蟲"
    }
} else {
    Write-Error "   ❌ robots.txt 不存在！"
    $ErrorCount++
}

# ============================================================
# [2/5] 檢查 SEO 四大件 noindex
# ============================================================
Write-Info "[2/5] 檢查 SEO 四大件 noindex..."
$SeoPages = @("privacy-policy.html", "terms-of-service.html", "about.html", "contact.html")
foreach ($page in $SeoPages) {
    $path = Join-Path $OutputDir $page
    if (Test-Path $path) {
        $Content = Get-Content $path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Content -and $Content -match 'noindex') {
            Write-Error "   ❌ $page 含有 noindex"
            $ErrorCount++
        } else {
            Write-Success "   ✅ $page 無 noindex"
        }
    } else {
        Write-Warning "   ⚠️ $page 不存在"
        $WarningCount++
    }
}

# ============================================================
# [3/5] 檢查 Cloudflare Managed Content 汙染
# ============================================================
Write-Info "[3/5] 檢查 Cloudflare Managed Content 汙染..."
if (Test-Path $RobotsPath) {
    $Content = Get-Content $RobotsPath -Raw -Encoding UTF8
    if ($Content -match "BEGIN Cloudflare Managed content" -or $Content -match "Content-Signal") {
        Write-Error "   ❌ robots.txt 被 Cloudflare Managed Content 汙染！"
        $ErrorCount++
        if ($Fix) {
            Write-Info "   🔧 嘗試修復..."
            $CleanContent = $Content -replace '(?s)# BEGIN Cloudflare Managed content.*?# END Cloudflare Managed Content', ''
            $CleanContent = $CleanContent -replace '(?m)^Content-Signal:.*$', ''
            $CleanContent | Out-File -FilePath $RobotsPath -Encoding UTF8
            $FixCount++
            Write-Success "   ✅ 已清理 robots.txt"
        }
    } else {
        Write-Success "   ✅ robots.txt 乾淨"
    }
}

# ============================================================
# [4/5] 檢查文章發布日期分散度
# ============================================================
Write-Info "[4/5] 檢查文章發布日期分散度..."
$SampleDir = Join-Path $OutputDir "life"
$Dates = @()
if (Test-Path $SampleDir) {
    $Files = Get-ChildItem -Path $SampleDir -Filter "*.html" | Select-Object -First 30
    foreach ($f in $Files) {
        $Content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($Content -match '發表時間：(\d{4})[年\-/](\d{2})[月\-/](\d{2})') {
            $Dates += "$($Matches[1])-$($Matches[2])-$($Matches[3])"
        }
    }
    if ($Dates.Count -gt 0) {
        $UniqueDates = $Dates | Sort-Object -Unique
        if ($UniqueDates.Count -gt 5) {
            Write-Success "   ✅ 日期分散度良好（$($UniqueDates.Count) 個不同日期）"
        } else {
            Write-Warning "   ⚠️ 日期可能過度集中（僅 $($UniqueDates.Count) 個不同日期）"
            $WarningCount++
        }
    }
} else {
    Write-Warning "   ⚠️ life/ 目錄不存在，跳過日期檢查"
    $WarningCount++
}

# ============================================================
# [5/5] 檢查 Sitemap 可訪問性
# ============================================================
Write-Info "[5/5] 檢查 Sitemap 可訪問性..."
$SitemapPath = Join-Path $OutputDir "sitemap.xml"
if (Test-Path $SitemapPath) {
    $Content = Get-Content $SitemapPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($Content -match '<urlset' -or $Content -match '<sitemapindex') {
        Write-Success "   ✅ sitemap.xml 格式正確"
        $urlCount = ([regex]::Matches($Content, "<loc>")).Count
        Write-Info "      📊 URL 數量：$urlCount 個"
    } else {
        Write-Warning "   ⚠️ sitemap.xml 格式異常"
        $WarningCount++
    }
} else {
    Write-Warning "   ⚠️ sitemap.xml 不存在"
    $WarningCount++
}

# ============================================================
# 總結
# ============================================================
Write-Info ""
Write-Info "============================================================"
Write-Info "📊 檢查摘要"
Write-Info "============================================================"
Write-Info "   ❌ 錯誤：$ErrorCount"
Write-Info "   ⚠️ 警告：$WarningCount"
if ($Fix) {
    Write-Info "   🔧 自動修復：$FixCount 項"
}
Write-Info ""
if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Success "   ✅ 所有防線正常，無審查風險"
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Warning "   ⚠️ 有警告，建議關注"
    exit 1
} else {
    Write-Error "   ❌ 有錯誤，請立即修正！"
    exit 2
}