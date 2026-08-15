# ============================================================
# 雅寶社區 · 頂客論壇 - 全面系統檢查腳本 v3.3
# ============================================================
# v3.3 變更：
#   - 🆕 加入 history/ 與 music/ 目錄掃描
#   - 🆕 加入 category-history.html 與 category-music.html 檢查
#   - 🔧 修復 $HasApiError 型別問題
#   - 🔧 優化變數命名，避免混淆
#   - 📊 完整統計所有 8 大分類
# ============================================================

param(
    [switch]$Fix,
    [switch]$Report,
    [switch]$DryRun
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$OutputDir = "C:\Users\User\ahpal-static"
$ReportFile = "C:\Users\User\ahpal-full-check-report.txt"
$DateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   📊 雅寶社區 · 頂客論壇 - 全面系統檢查工具 v3.3" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 輸出目錄：$OutputDir" -ForegroundColor Cyan
Write-Host "📅 檢查時間：$DateStr" -ForegroundColor Cyan
if ($DryRun) { Write-Host "🔍 預覽模式" -ForegroundColor Yellow }
Write-Host ""

if (-not (Test-Path $OutputDir)) {
    Write-Host "❌ 錯誤：找不到輸出目錄！" -ForegroundColor Red
    exit 1
}

# ============================================================
# 🆕 v3.3: 完整 8 大分類
# ============================================================
$CategoryDirs = @{
    "tech" = "💻 3C 科技教學"
    "life" = "🏠 生活小常識"
    "review" = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend" = "🤖 AI 趨勢"
    "game" = "🎮 遊戲攻略"
    "history" = "📜 歷史腦洞"      # 🆕 新增
    "music" = "🎵 音樂創作"        # 🆕 新增
}

# ============================================================
# 🆕 v3.3: 完整分類頁面清單
# ============================================================
$CategoryPages = @(
    "category-tech.html",
    "category-game.html",
    "category-life.html",
    "category-review.html",
    "category-philosophy.html",
    "category-trend.html",
    "category-history.html",    # 🆕 新增
    "category-music.html"       # 🆕 新增
)

# ============================================================
# 掃描所有文章
# ============================================================
Write-Host "🔍 正在掃描所有文章..." -ForegroundColor Yellow
Write-Host ""

$AllArticles = New-Object System.Collections.ArrayList
$AbnormalFiles = New-Object System.Collections.ArrayList
$MissingBrand = New-Object System.Collections.ArrayList
$ApiErrorFiles = New-Object System.Collections.ArrayList   # 🆕 改名，避免混淆
$LowQualityFiles = New-Object System.Collections.ArrayList
$TotalSize = 0
$TotalArticles = 0

$DirStats = @{}

foreach ($dirName in $CategoryDirs.Keys) {
    $dirPath = Join-Path $OutputDir $dirName
    if (-not (Test-Path $dirPath)) {
        Write-Host "   ⚠️ 目錄不存在：$dirName" -ForegroundColor Yellow
        continue
    }
    
    $files = Get-ChildItem -Path $dirPath -Filter "*.html" -ErrorAction SilentlyContinue
    $count = $files.Count
    $TotalArticles += $count
    $dirSize = ($files | Measure-Object -Property Length -Sum).Sum
    $TotalSize += $dirSize
    
    $DirStats[$dirName] = @{
        Count = $count
        Size = $dirSize
        SizeKB = if ($dirSize) { [math]::Round($dirSize / 1KB, 2) } else { 0 }
    }
    
    Write-Host "   📁 $dirName : $count 篇" -ForegroundColor Cyan
    
    foreach ($f in $files) {
        $relPath = $f.FullName.Replace("$OutputDir\", "")
        $sizeKB = [math]::Round($f.Length / 1KB, 2)
        $isAbnormal = $f.Length -lt 5120
        $hasBrand = $false
        $hasApiError = $false   # 🆕 改用布林值
        
        try {
            $content = Get-Content -Path $f.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
            if ($content -match "雅寶社區") { $hasBrand = $true }
            if ($content -match "429|503|RESOURCE_EXHAUSTED|unavailable|暫時無法") { $hasApiError = $true }
        } catch {
            $hasBrand = $false
        }
        
        $article = [PSCustomObject]@{
            Name = $f.Name
            Path = $f.FullName
            RelativePath = $relPath
            Directory = $dirName
            Category = $CategoryDirs[$dirName]
            Size = $f.Length
            SizeKB = $sizeKB
            IsAbnormal = $isAbnormal
            HasBrand = $hasBrand
            HasApiError = $hasApiError
            WordCount = 0
            Score = 0
            Passed = $false
            IsLowQuality = $false
            IsGame = ($dirName -eq "game")
        }
        
        # 非遊戲目錄才做品質檢查
        if (-not $article.IsGame -and -not $isAbnormal) {
            try {
                $content = Get-Content -Path $f.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
                $textOnly = $content -replace '<[^>]+>', ' ' -replace '\s+', ' '
                $article.WordCount = $textOnly.Length
                
                $hasTable = $content -match '<table[^>]*>.*?</table>'
                $hasFaq = $content -match '(FAQ|常見問題|Q：|問：|Q&A)'
                $hasH2 = $content -match '<h2[^>]*>'
                $hasH3 = $content -match '<h3[^>]*>'
                $hasList = $content -match '<(ul|ol)[^>]*>'
                $hasImage = $content -match '<img[^>]*>'
                
                $score = 0
                if ($article.WordCount -ge 1200) { $score += 35 }
                elseif ($article.WordCount -ge 800) { $score += 20 }
                else { $score += 10 }
                
                if ($hasH2) { $score += 20 }
                if ($hasTable) { $score += 15 }
                if ($hasFaq) { $score += 15 }
                if ($hasH3) { $score += 10 }
                if ($hasList) { $score += 5 }
                if ($hasImage) { $score += 5 }
                
                $article.Score = $score
                $article.Passed = $score -ge 60
                $article.IsLowQuality = (-not $article.Passed)
            } catch {}
        } elseif ($article.IsGame) {
            $article.Score = 100
            $article.Passed = $true
            $article.IsLowQuality = $false
        }
        
        [void]$AllArticles.Add($article)
        
        if ($isAbnormal) { [void]$AbnormalFiles.Add($article) }
        if (-not $hasBrand) { [void]$MissingBrand.Add($article) }
        if ($hasApiError) { [void]$ApiErrorFiles.Add($article) }
        if ($article.IsLowQuality) { [void]$LowQualityFiles.Add($article) }
    }
}

# ============================================================
# 檢查遊戲
# ============================================================
Write-Host ""
Write-Host "🎮 檢查遊戲..." -ForegroundColor Yellow

$GameDir = Join-Path $OutputDir "game"
if (Test-Path $GameDir) {
    $GameFiles = Get-ChildItem -Path $GameDir -Filter "*.html" -ErrorAction SilentlyContinue
    $GameCount = $GameFiles.Count
    $GameIndexExists = Test-Path (Join-Path $GameDir "index.html")
    
    Write-Host "   🎮 遊戲總數：$GameCount 款" -ForegroundColor Cyan
    Write-Host "   📄 遊戲索引：$(if ($GameIndexExists) {'✅ 存在'} else {'❌ 不存在'})" -ForegroundColor $(if ($GameIndexExists) {'Green'} else {'Red'})
} else {
    Write-Host "   ❌ 找不到遊戲目錄！" -ForegroundColor Red
}

# ============================================================
# 檢查關鍵頁面
# ============================================================
Write-Host ""
Write-Host "📄 檢查關鍵頁面..." -ForegroundColor Yellow

$KeyPages = @(
    "index.html", "categories.html", "sitemap.xml", "404.html",
    "memorial.html", "royal_dragon_karma.html"
)
$AllKeyPages = $KeyPages + $CategoryPages
$MissingPages = @()

foreach ($page in $AllKeyPages) {
    $pagePath = Join-Path $OutputDir $page
    if (Test-Path $pagePath) {
        $size = (Get-Item $pagePath).Length
        Write-Host "   ✅ $page ($([math]::Round($size/1KB,2)) KB)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $page (不存在)" -ForegroundColor Red
        $MissingPages += $page
    }
}

# ============================================================
# 顯示統計摘要
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "📊 檢查摘要" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📝 文章統計：" -ForegroundColor Cyan
Write-Host "   ├─ 總文章數：$TotalArticles 篇" -ForegroundColor White
Write-Host "   ├─ 正常檔案：$($TotalArticles - $AbnormalFiles.Count) 篇" -ForegroundColor Green
Write-Host "   ├─ 異常檔案：$($AbnormalFiles.Count) 篇" -ForegroundColor $(if ($AbnormalFiles.Count -gt 0) {'Red'} else {'Green'})
Write-Host "   ├─ 缺少品牌：$($MissingBrand.Count) 篇" -ForegroundColor $(if ($MissingBrand.Count -gt 0) {'Yellow'} else {'Green'})
Write-Host "   ├─ 含 API 錯誤：$($ApiErrorFiles.Count) 篇" -ForegroundColor $(if ($ApiErrorFiles.Count -gt 0) {'Yellow'} else {'Green'})
Write-Host "   └─ 品質未達標：$($LowQualityFiles.Count) 篇" -ForegroundColor $(if ($LowQualityFiles.Count -gt 0) {'Red'} else {'Green'})

if ($TotalSize) {
    Write-Host "   💾 文章總大小：$([math]::Round($TotalSize / 1MB, 2)) MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📂 各目錄統計：" -ForegroundColor Cyan
foreach ($dirName in $CategoryDirs.Keys) {
    $stat = $DirStats[$dirName]
    if ($stat) {
        Write-Host "   ✅ $dirName : $($stat.Count) 篇, $($stat.SizeKB) KB" -ForegroundColor White
    }
}

if ($LowQualityFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 品質未達標文章清單 (<60分)：" -ForegroundColor Red
    foreach ($item in $LowQualityFiles) {
        Write-Host "   📄 $($item.RelativePath) (分數：$($item.Score)/100)" -ForegroundColor Red
    }
}

# ============================================================
# 品質分數統計
# ============================================================
$ScoredArticles = $AllArticles | Where-Object { $_.Score -gt 0 -and -not $_.IsGame }
if ($ScoredArticles.Count -gt 0) {
    Write-Host ""
    Write-Host "⭐ 品質分數統計：" -ForegroundColor Cyan
    $PassedCount = ($ScoredArticles | Where-Object { $_.Passed }).Count
    $FailedCount = $ScoredArticles.Count - $PassedCount
    Write-Host "   ├─ 通過 (≥60分)：$PassedCount 篇" -ForegroundColor Green
    Write-Host "   └─ 未達標 (<60分)：$FailedCount 篇" -ForegroundColor $(if ($FailedCount -gt 0) {'Red'} else {'Green'})
    
    $AvgScore = [math]::Round(($ScoredArticles | Measure-Object -Property Score -Average).Average, 1)
    Write-Host "   📊 平均品質分數：$AvgScore 分" -ForegroundColor Cyan
}

# ============================================================
# 刪除功能
# ============================================================
if ($Fix -and $LowQualityFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "🔧 正在刪除品質未達標文章..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "   🔍 預覽模式：以下文章將被刪除" -ForegroundColor Yellow
        foreach ($f in $LowQualityFiles) {
            Write-Host "      📄 $($f.RelativePath) (分數：$($f.Score)/100)" -ForegroundColor Yellow
        }
        Write-Host "   📊 將刪除 $($LowQualityFiles.Count) 篇" -ForegroundColor Yellow
    } else {
        $DeletedCount = 0
        foreach ($f in $LowQualityFiles) {
            try {
                Remove-Item -Path $f.Path -Force
                Write-Host "   🗑️ 已刪除：$($f.RelativePath)" -ForegroundColor Red
                $DeletedCount++
            } catch {
                Write-Host "   ❌ 刪除失敗：$($f.RelativePath)" -ForegroundColor Red
            }
        }
        Write-Host "✅ 已刪除 $DeletedCount 篇" -ForegroundColor Green
    }
}

# ============================================================
# 產生報告
# ============================================================
if ($Report) {
    Write-Host ""
    Write-Host "📄 正在產生詳細報告..." -ForegroundColor Yellow
    
    $ReportContent = @"
============================================================
雅寶社區 · 頂客論壇 - 全面系統檢查報告 v3.3
============================================================
檢查時間：$DateStr
輸出目錄：$OutputDir
============================================================

📊 統計摘要：
   總文章數: $TotalArticles 篇
   正常檔案: $($TotalArticles - $AbnormalFiles.Count) 篇
   異常檔案: $($AbnormalFiles.Count) 篇
   缺少品牌: $($MissingBrand.Count) 篇
   含 API 錯誤: $($ApiErrorFiles.Count) 篇
   品質未達標: $($LowQualityFiles.Count) 篇
   文章總大小: $([math]::Round($TotalSize / 1MB, 2)) MB
   平均品質分數: $AvgScore 分

📂 各目錄統計：
$(foreach ($dirName in $CategoryDirs.Keys) {
    $stat = $DirStats[$dirName]
    if ($stat) { "   $dirName : $($stat.Count) 篇, $($stat.SizeKB) KB`n" }
})

$(if ($LowQualityFiles.Count -gt 0) {
    "`n❌ 品質未達標文章清單：`n" + ($LowQualityFiles | ForEach-Object { "   - $($_.RelativePath) (分數：$($_.Score)/100)" }) + "`n"
})

============================================================
報告產生時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
============================================================
"@
    Set-Content -Path $ReportFile -Value $ReportContent -Encoding UTF8
    Write-Host "   ✅ 報告已儲存：$ReportFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 檢查完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "按 Enter 鍵結束"