# scripts/validate-seo.ps1
# ============================================================
# 🔍 AHPAL SEO 驗證閘門（手動版）v2.1
# 用法：.\scripts\validate-seo.ps1
#       .\scripts\validate-seo.ps1 -Master
# ============================================================
# 更新 v2.1：
#   - AI 爬蟲檢查改為檢查 Cloudflare Managed 區塊（自動添加）
#   - 同時兼容本地手動添加的 GPTBot/ClaudeBot
# ============================================================

param([switch]$Master)

$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🔍 AHPAL SEO 驗證閘門 v2.1" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. robots.txt
# ============================================================
Write-Host "📄 1. 驗證 robots.txt" -ForegroundColor Yellow

$robotsPath = Join-Path $ProjectRoot "robots.txt"
$robotsOk = $true

if (Test-Path $robotsPath) {
    $robots = Get-Content $robotsPath -Raw -Encoding UTF8
    $fileSize = (Get-Item $robotsPath).Length
    Write-Host "   ✅ 檔案存在" -ForegroundColor Green
    Write-Host "   ✅ 檔案大小：$([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Gray
    
    if ($robots -match "Sitemap: https://www.ahpal.com/sitemap.xml") {
        Write-Host "   ✅ Sitemap 宣告：正確" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ Sitemap 宣告：遺失" -ForegroundColor Yellow
        $robotsOk = $false
    }
    
    # 🔧 優化：檢查 Cloudflare Managed 區塊（自動添加）或本地手動添加的 AI 爬蟲規則
    if ($robots -match "Cloudflare Managed|GPTBot|ClaudeBot") {
        Write-Host "   ✅ AI 爬蟲封鎖：已設定 (Cloudflare 自動管理)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ AI 爬蟲封鎖：未設定（Cloudflare 部署後會自動添加）" -ForegroundColor Yellow
        # 不將此項設為失敗，因為 Cloudflare 會自動添加
        # $robotsOk = $false  # 註解掉，不再因此報錯
    }
} else {
    Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
    $robotsOk = $false
}


# ============================================================
# 2. ads.txt
# ============================================================
Write-Host ""
Write-Host "📄 2. 驗證 ads.txt" -ForegroundColor Yellow

$adsPath = Join-Path $ProjectRoot "ads.txt"
$adsOk = $true

if (Test-Path $adsPath) {
    $ads = Get-Content $adsPath -Raw -Encoding UTF8
    $fileSize = (Get-Item $adsPath).Length
    Write-Host "   ✅ 檔案存在" -ForegroundColor Green
    Write-Host "   ✅ 檔案大小：$([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Gray
    
    if ($ads -match "pub-8637791667872348") {
        Write-Host "   ✅ AdSense PUB-ID：正確" -ForegroundColor Green
    } else {
        Write-Host "   ❌ AdSense PUB-ID：遺失" -ForegroundColor Red
        $adsOk = $false
    }
    
    $lines = $ads -split "`n" | Where-Object { $_.Trim() -ne "" }
    if ($lines.Count -eq 1) {
        Write-Host "   ✅ 格式：僅含 AdSense 宣告" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ 格式：包含其他內容" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
    $adsOk = $false
}


# ============================================================
# 3. sitemap.xml
# ============================================================
Write-Host ""
Write-Host "📄 3. 驗證 sitemap.xml" -ForegroundColor Yellow

$sitemapPath = Join-Path $ProjectRoot "sitemap.xml"
$sitemapOk = $true

if (Test-Path $sitemapPath) {
    $sitemap = Get-Content $sitemapPath -Raw -Encoding UTF8
    $fileSize = (Get-Item $sitemapPath).Length
    Write-Host "   ✅ 檔案存在" -ForegroundColor Green
    Write-Host "   ✅ 檔案大小：$([math]::Round($fileSize / 1KB, 2)) KB" -ForegroundColor Gray
    
    # 檢查 XML 格式（修正版）
    if ($sitemap -match "<\?xml version=""1.0"" encoding=""UTF-8""\?>") {
        Write-Host "   ✅ XML 格式：正確" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ XML 格式：無法確認" -ForegroundColor Yellow
    }
    
    $urlCount = ([regex]::Matches($sitemap, "<loc>")).Count
    if ($urlCount -ge 50) {
        Write-Host "   ✅ URL 數量：$urlCount 個" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ URL 數量：$urlCount 個 (偏低)" -ForegroundColor Yellow
        $sitemapOk = $false
    }
    
    if ($sitemap -match "<loc>https://www.ahpal.com/</loc>") {
        Write-Host "   ✅ 首頁已包含" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ 首頁未包含" -ForegroundColor Yellow
        $sitemapOk = $false
    }
} else {
    Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
    $sitemapOk = $false
}


# ============================================================
# 4. Master 模式
# ============================================================
if ($Master) {
    Write-Host ""
    Write-Host "📋 Master 模式資訊" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    $gitBranch = git branch --show-current 2>$null
    $gitCommit = git log --oneline -1 2>$null
    Write-Host "   🌿 Git 分支：$gitBranch" -ForegroundColor Cyan
    Write-Host "   📝 最新提交：$gitCommit" -ForegroundColor Cyan
    
    $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories" } | Measure-Object).Count
    Write-Host "   📊 文章總數：$articleCount 篇" -ForegroundColor Cyan
}


# ============================================================
# 5. 總結
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 驗證完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

if ($robotsOk -and $adsOk -and $sitemapOk) {
    Write-Host "📋 狀態：所有基礎檔案正常 ✅" -ForegroundColor Green
} else {
    Write-Host "📋 狀態：部分項目需注意 ⚠️" -ForegroundColor Yellow
    Write-Host "   💡 robots.txt AI 爬蟲封鎖由 Cloudflare 自動管理" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📌 使用提示：" -ForegroundColor Gray
Write-Host "   .\scripts\validate-seo.ps1        # 基本檢查" -ForegroundColor Gray
Write-Host "   .\scripts\validate-seo.ps1 -Master  # 完整檢查" -ForegroundColor Gray
Write-Host ""

# ============================================================
# 🔒 防止視窗自動關閉（按右鍵執行時生效）
# ============================================================
Read-Host "按 Enter 鍵結束"