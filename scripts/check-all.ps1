# ============================================================
# 雅寶社區 · 頂客論壇 - 全面系統檢查腳本 v2.0
# ============================================================
# 功能：
#   1. 檢查所有文章檔案（大小、品牌、品質）
#   2. 檢查所有遊戲檔案
#   3. 檢查分類頁面
#   4. 檢查 Sitemap
#   5. 檢查首頁
#   6. 產生完整檢查報告
#   7. 🆕 刪除品質未達標文章（<60分）
# ============================================================
# 使用方法：
#   .\check-all.ps1              # 執行全面檢查
#   .\check-all.ps1 -Fix         # 刪除品質未達標文章（<60分）
#   .\check-all.ps1 -Report      # 產生詳細報告
#   .\check-all.ps1 -Fix -Report # 刪除 + 報告
#   .\check-all.ps1 -DryRun      # 預覽要刪除的文章（不實際刪除）
# ============================================================

param(
    [switch]$Fix,       # 刪除品質未達標文章（<60分）
    [switch]$Report,    # 產生詳細報告
    [switch]$DryRun     # 預覽模式（不實際刪除）
)

# ============================================================
# 1. 設定
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

$OutputDir = "C:\Users\User\ahpal-static"
$ReportFile = "C:\Users\User\ahpal-full-check-report.txt"
$DateStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   📊 雅寶社區 · 頂客論壇 - 全面系統檢查工具 v2.0" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 輸出目錄：$OutputDir" -ForegroundColor Cyan
Write-Host "📅 檢查時間：$DateStr" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🔍 預覽模式：只顯示要刪除的文章，不實際刪除" -ForegroundColor Yellow
}
Write-Host ""

# ============================================================
# 2. 檢查目錄是否存在
# ============================================================
if (-not (Test-Path $OutputDir)) {
    Write-Host "❌ 錯誤：找不到輸出目錄！" -ForegroundColor Red
    Write-Host "   請確認路徑：$OutputDir" -ForegroundColor Yellow
    exit 1
}

# ============================================================
# 3. 掃描所有文章
# ============================================================
Write-Host "🔍 正在掃描所有文章..." -ForegroundColor Yellow
Write-Host ""

$AllArticles = @()
$AbnormalFiles = @()
$MissingBrand = @()
$HasApiError = @()
$LowQualityFiles = @()
$TotalSize = 0
$TotalArticles = 0

$CategoryDirs = @{
    "tech" = "💻 3C 科技教學"
    "life" = "🏠 生活小常識"
    "review" = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend" = "🤖 AI 趨勢"
    "game" = "🎮 遊戲攻略"
}

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
        $hasApiError = $false
        
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
        }
        
        # 嘗試估算字數和品質
        if (-not $isAbnormal) {
            try {
                $content = Get-Content -Path $f.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
                $textOnly = $content -replace '<[^>]+>', ' ' -replace '\s+', ' '
                $article.WordCount = $textOnly.Length
                
                # 簡單品質檢查
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
            } catch {
                # 無法解析
            }
        }
        
        $AllArticles += $article
        
        if ($isAbnormal) { $AbnormalFiles += $article }
        if (-not $hasBrand) { $MissingBrand += $article }
        if ($hasApiError) { $HasApiError += $article }
        if ($article.IsLowQuality) { $LowQualityFiles += $article }
    }
}

# ============================================================
# 4. 檢查遊戲
# ============================================================
Write-Host ""
Write-Host "🎮 檢查遊戲..." -ForegroundColor Yellow

$GameDir = Join-Path $OutputDir "game"
$GameFiles = @()
$GameIndexPath = Join-Path $GameDir "index.html"

if (Test-Path $GameDir) {
    $GameFiles = Get-ChildItem -Path $GameDir -Filter "*.html" -ErrorAction SilentlyContinue
    $GameCount = $GameFiles.Count
    $GameIndexExists = Test-Path $GameIndexPath
    
    Write-Host "   🎮 遊戲總數：$GameCount 款" -ForegroundColor Cyan
    Write-Host "   📄 遊戲索引：$(if ($GameIndexExists) {'✅ 存在'} else {'❌ 不存在'})" -ForegroundColor $(if ($GameIndexExists) {'Green'} else {'Red'})
    
    $SmallGames = $GameFiles | Where-Object { $_.Length -lt 2048 }
    if ($SmallGames.Count -gt 0) {
        Write-Host "   ⚠️ 發現 $($SmallGames.Count) 個異常小遊戲檔案：" -ForegroundColor Yellow
        foreach ($g in $SmallGames) {
            Write-Host "      ❌ $($g.Name) ($([math]::Round($g.Length/1KB,2)) KB)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   ❌ 找不到遊戲目錄！" -ForegroundColor Red
}

# ============================================================
# 5. 檢查關鍵頁面
# ============================================================
Write-Host ""
Write-Host "📄 檢查關鍵頁面..." -ForegroundColor Yellow

$KeyPages = @(
    "index.html",
    "categories.html",
    "sitemap.xml",
    "404.html",
    "memorial.html",
    "royal_dragon_karma.html"
)

$CategoryPages = @(
    "category-tech.html",
    "category-game.html",
    "category-life.html",
    "category-review.html",
    "category-philosophy.html",
    "category-trend.html"
)

$AllKeyPages = $KeyPages + $CategoryPages
$MissingPages = @()

foreach ($page in $AllKeyPages) {
    $pagePath = Join-Path $OutputDir $page
    if (Test-Path $pagePath) {
        $size = (Get-Item $pagePath).Length
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "   ✅ $page ($sizeKB KB)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $page (不存在)" -ForegroundColor Red
        $MissingPages += $page
    }
}

# ============================================================
# 6. 顯示統計摘要
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
Write-Host "   ├─ 含 API 錯誤：$($HasApiError.Count) 篇" -ForegroundColor $(if ($HasApiError.Count -gt 0) {'Yellow'} else {'Green'})
Write-Host "   └─ 品質未達標：$($LowQualityFiles.Count) 篇" -ForegroundColor $(if ($LowQualityFiles.Count -gt 0) {'Red'} else {'Green'})

if ($TotalSize) {
    $TotalSizeMB = [math]::Round($TotalSize / 1MB, 2)
    Write-Host "   💾 文章總大小：$TotalSizeMB MB" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📂 各目錄統計：" -ForegroundColor Cyan
foreach ($dirName in $CategoryDirs.Keys) {
    $stat = $DirStats[$dirName]
    if ($stat) {
        $status = if ($stat.Count -gt 0) { "✅" } else { "⚠️" }
        Write-Host "   $status $dirName : $($stat.Count) 篇, $($stat.SizeKB) KB" -ForegroundColor $(if ($stat.Count -gt 0) {'White'} else {'Yellow'})
    } else {
        Write-Host "   ❌ $dirName : (空)" -ForegroundColor Red
    }
}

# ============================================================
# 7. 顯示品質未達標清單
# ============================================================
if ($LowQualityFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 品質未達標文章清單 (<60分)：" -ForegroundColor Red
    $LowQualityFiles | Sort-Object Score | ForEach-Object {
        Write-Host "   📄 $($_.RelativePath) (分數：$($_.Score)/100)" -ForegroundColor Red
    }
}

if ($AbnormalFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 異常檔案清單 (< 5KB)：" -ForegroundColor Red
    foreach ($f in $AbnormalFiles) {
        Write-Host "   📄 $($f.RelativePath) ($($f.SizeKB) KB)" -ForegroundColor Red
    }
}

if ($MissingBrand.Count -gt 0) {
    Write-Host ""
    Write-Host "⚠️ 缺少品牌名稱的文章：" -ForegroundColor Yellow
    foreach ($f in $MissingBrand) {
        Write-Host "   📄 $($f.RelativePath)" -ForegroundColor Yellow
    }
}

if ($MissingPages.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ 缺少的關鍵頁面：" -ForegroundColor Red
    foreach ($p in $MissingPages) {
        Write-Host "   📄 $p" -ForegroundColor Red
    }
}

# ============================================================
# 8. 品質分數統計
# ============================================================
$ScoredArticles = $AllArticles | Where-Object { $_.Score -gt 0 }
if ($ScoredArticles.Count -gt 0) {
    Write-Host ""
    Write-Host "⭐ 品質分數統計：" -ForegroundColor Cyan
    $PassedCount = ($ScoredArticles | Where-Object { $_.Passed }).Count
    $FailedCount = $ScoredArticles.Count - $PassedCount
    Write-Host "   ├─ 通過 (≥60分)：$PassedCount 篇" -ForegroundColor Green
    Write-Host "   └─ 未達標 (<60分)：$FailedCount 篇" -ForegroundColor $(if ($FailedCount -gt 0) {'Red'} else {'Green'})
    
    # 顯示平均分數
    $AvgScore = [math]::Round(($ScoredArticles | Measure-Object -Property Score -Average).Average, 1)
    Write-Host "   📊 平均品質分數：$AvgScore 分" -ForegroundColor Cyan
}

# ============================================================
# 9. 刪除品質未達標文章（🆕 新功能）
# ============================================================
if ($Fix -and $LowQualityFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "🔧 正在刪除品質未達標文章..." -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "   🔍 預覽模式：以下文章將被刪除（但不實際刪除）" -ForegroundColor Yellow
        foreach ($f in $LowQualityFiles) {
            Write-Host "      📄 $($f.RelativePath) (分數：$($f.Score)/100)" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "   📊 將刪除 $($LowQualityFiles.Count) 篇品質未達標文章" -ForegroundColor Yellow
    } else {
        $DeletedCount = 0
        foreach ($f in $LowQualityFiles) {
            try {
                Remove-Item -Path $f.Path -Force
                Write-Host "   🗑️ 已刪除：$($f.RelativePath) (分數：$($f.Score)/100)" -ForegroundColor Red
                $DeletedCount++
            } catch {
                Write-Host "   ❌ 刪除失敗：$($f.RelativePath)" -ForegroundColor Red
            }
        }
        Write-Host ""
        Write-Host "✅ 已刪除 $DeletedCount 篇品質未達標文章" -ForegroundColor Green
        Write-Host ""
        Write-Host "📌 請重新執行 .\ahpal-master.ps1 生成文章" -ForegroundColor Yellow
    }
} elseif ($Fix -and $LowQualityFiles.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ 沒有品質未達標的文章需要刪除！" -ForegroundColor Green
}

# ============================================================
# 10. 刪除異常檔案（原有功能）
# ============================================================
if ($Fix -and $AbnormalFiles.Count -gt 0 -and -not $DryRun) {
    Write-Host ""
    Write-Host "🔧 正在刪除異常文章 (<5KB)..." -ForegroundColor Yellow
    foreach ($f in $AbnormalFiles) {
        try {
            Remove-Item -Path $f.Path -Force
            Write-Host "   🗑️ 已刪除：$($f.RelativePath)" -ForegroundColor Red
        } catch {
            Write-Host "   ❌ 刪除失敗：$($f.RelativePath)" -ForegroundColor Red
        }
    }
    Write-Host ""
    Write-Host "✅ 已刪除 $($AbnormalFiles.Count) 篇異常文章" -ForegroundColor Green
}

# ============================================================
# 11. 產生報告
# ============================================================
if ($Report) {
    Write-Host ""
    Write-Host "📄 正在產生詳細報告..." -ForegroundColor Yellow
    
    $ReportContent = @"
============================================================
雅寶社區 · 頂客論壇 - 全面系統檢查報告
============================================================
檢查時間：$DateStr
輸出目錄：$OutputDir
============================================================

📊 統計摘要：
   總文章數: $TotalArticles 篇
   正常檔案: $($TotalArticles - $AbnormalFiles.Count) 篇
   異常檔案: $($AbnormalFiles.Count) 篇
   缺少品牌: $($MissingBrand.Count) 篇
   含 API 錯誤: $($HasApiError.Count) 篇
   品質未達標: $($LowQualityFiles.Count) 篇
   文章總大小: $([math]::Round($TotalSize / 1MB, 2)) MB
   品質通過: $PassedCount 篇
   品質未達標: $FailedCount 篇
   平均品質分數: $AvgScore 分

📂 各目錄統計：
"@
    foreach ($dirName in $CategoryDirs.Keys) {
        $stat = $DirStats[$dirName]
        if ($stat) {
            $ReportContent += "   $dirName : $($stat.Count) 篇, $($stat.SizeKB) KB`n"
        } else {
            $ReportContent += "   $dirName : (空)`n"
        }
    }

    if ($LowQualityFiles.Count -gt 0) {
        $ReportContent += "`n❌ 品質未達標文章清單 (<60分)：`n"
        foreach ($f in $LowQualityFiles | Sort-Object Score) {
            $ReportContent += "   - $($f.RelativePath) (分數：$($f.Score)/100)`n"
        }
    }

    if ($AbnormalFiles.Count -gt 0) {
        $ReportContent += "`n❌ 異常檔案清單：`n"
        foreach ($f in $AbnormalFiles) {
            $ReportContent += "   - $($f.RelativePath) ($($f.SizeKB) KB)`n"
        }
    }

    if ($MissingBrand.Count -gt 0) {
        $ReportContent += "`n⚠️ 缺少品牌名稱的文章：`n"
        foreach ($f in $MissingBrand) {
            $ReportContent += "   - $($f.RelativePath)`n"
        }
    }

    if ($MissingPages.Count -gt 0) {
        $ReportContent += "`n❌ 缺少的關鍵頁面：`n"
        foreach ($p in $MissingPages) {
            $ReportContent += "   - $p`n"
        }
    }

    $ReportContent += "`n============================================================`n"
    $ReportContent += "報告產生時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    Set-Content -Path $ReportFile -Value $ReportContent -Encoding UTF8
    Write-Host "   ✅ 報告已儲存：$ReportFile" -ForegroundColor Green
}

# ============================================================
# 12. 完成
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 檢查完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

if (-not $Fix -and -not $Report) {
    Write-Host "💡 若要刪除品質未達標文章，請執行：.\check-all.ps1 -Fix" -ForegroundColor Yellow
    Write-Host "💡 若要預覽要刪除的文章：.\check-all.ps1 -Fix -DryRun" -ForegroundColor Yellow
    Write-Host "💡 若要產生詳細報告，請執行：.\check-all.ps1 -Report" -ForegroundColor Yellow
    Write-Host "💡 若要同時執行：.\check-all.ps1 -Fix -Report" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "按 Enter 鍵結束"