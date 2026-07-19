# ============================================================
# 雅寶社區 · 頂客論壇 - 全面文章檢查與修復腳本 v1.0
# ============================================================
# 功能：
#   1. 檢查文章數量與大小
#   2. 檢查品牌名稱完整性
#   3. 檢查 API 錯誤標記
#   4. 自動刪除異常文章
#   5. 產生檢查報告
# ============================================================
# 使用方法：
#   .\check-articles.ps1           # 只檢查，不刪除
#   .\check-articles.ps1 -Fix      # 檢查並刪除異常文章
#   .\check-articles.ps1 -Report   # 產生詳細報告
# ============================================================

param(
    [switch]$Fix,       # 自動刪除異常文章
    [switch]$Report     # 產生詳細報告
)

# ============================================================
# 設定
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

$OutputDir = "C:\Users\User\ahpal-static"
$ReportFile = "C:\Users\User\article-check-report.txt"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   📊 雅寶社區 · 頂客論壇 - 全面文章檢查工具 v1.0" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 輸出目錄：$OutputDir" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 掃描文章
# ============================================================
Write-Host "🔍 正在掃描文章..." -ForegroundColor Yellow
cd $OutputDir

$Dirs = @("tech", "life", "review", "philosophy", "trend")
$AllArticles = @()
$Total = 0

foreach ($dir in $Dirs) {
    $files = Get-ChildItem -Path $dir -Filter "*.html" -ErrorAction SilentlyContinue
    $count = $files.Count
    $Total += $count
    foreach ($f in $files) {
        $AllArticles += [PSCustomObject]@{
            Name = $f.Name
            Path = $f.FullName
            RelativePath = $f.FullName.Replace("$OutputDir\", "")
            Size = $f.Length
            SizeKB = [math]::Round($f.Length / 1KB, 2)
            Directory = $dir
            IsAbnormal = $f.Length -lt 5120
        }
    }
    Write-Host "   📁 $dir : $count 篇" -ForegroundColor Cyan
}
Write-Host "   ─────────────" -ForegroundColor Gray
Write-Host "   📝 總文章數: $Total 篇" -ForegroundColor Green
Write-Host ""

# ============================================================
# 2. 檢查異常檔案
# ============================================================
$AbnormalFiles = $AllArticles | Where-Object { $_.IsAbnormal }
$AbnormalCount = $AbnormalFiles.Count

Write-Host "📄 異常檔案檢查 (< 5KB)：" -ForegroundColor Yellow
if ($AbnormalCount -gt 0) {
    Write-Host "   ⚠️ 發現 $AbnormalCount 個異常小檔案：" -ForegroundColor Red
    foreach ($f in $AbnormalFiles) {
        Write-Host "      ❌ $($f.RelativePath) ($($f.SizeKB) KB)" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ 所有文章檔案大小正常 (≥ 5KB)" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 3. 檢查品牌名稱
# ============================================================
Write-Host "📋 品牌名稱檢查 (雅寶社區 · 頂客論壇)：" -ForegroundColor Yellow
$MissingBrand = @()
foreach ($f in $AllArticles) {
    try {
        $content = Get-Content -Path $f.Path -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
        if ($content -notmatch "雅寶社區") {
            $MissingBrand += $f
        }
    } catch {
        $MissingBrand += $f
    }
}
if ($MissingBrand.Count -gt 0) {
    Write-Host "   ⚠️ 以下文章缺少品牌名稱：" -ForegroundColor Red
    foreach ($f in $MissingBrand) {
        Write-Host "      ❌ $($f.RelativePath)" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ 所有文章品牌名稱完整" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 4. 檢查 API 錯誤標記
# ============================================================
Write-Host "🔍 檢查 API 錯誤標記 (429/503)：" -ForegroundColor Yellow
$HasError = @()
foreach ($f in $AllArticles) {
    try {
        $content = Get-Content -Path $f.Path -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
        if ($content -match "429" -or $content -match "503" -or $content -match "RESOURCE_EXHAUSTED" -or $content -match "unavailable" -or $content -match "暫時無法") {
            $HasError += $f
        }
    } catch {
        $HasError += $f
    }
}
if ($HasError.Count -gt 0) {
    Write-Host "   ⚠️ 以下文章可能包含 API 錯誤內容：" -ForegroundColor Red
    foreach ($f in $HasError) {
        Write-Host "      ❌ $($f.RelativePath)" -ForegroundColor Red
    }
} else {
    Write-Host "   ✅ 未發現 API 錯誤標記" -ForegroundColor Green
}
Write-Host ""

# ============================================================
# 5. 各目錄大小統計
# ============================================================
Write-Host "📊 各目錄統計：" -ForegroundColor Yellow
foreach ($dir in $Dirs) {
    $files = $AllArticles | Where-Object { $_.Directory -eq $dir }
    $count = $files.Count
    $size = ($files | Measure-Object -Property Size -Sum).Sum
    if ($size -gt 0) {
        $sizeKB = [math]::Round($size / 1KB, 2)
        Write-Host "   $dir : $count 篇, $sizeKB KB" -ForegroundColor Cyan
    } else {
        Write-Host "   $dir : (空)" -ForegroundColor Red
    }
}
Write-Host ""

# ============================================================
# 6. 總結
# ============================================================
$NormalCount = $AllArticles | Where-Object { -not $_.IsAbnormal } | Measure-Object | Select-Object -ExpandProperty Count

Write-Host "============================================================" -ForegroundColor Green
Write-Host "📊 診斷總結" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "   📝 總文章數: $Total 篇" -ForegroundColor Cyan
Write-Host "   ✅ 正常檔案: $NormalCount 篇" -ForegroundColor Green
Write-Host "   ❌ 異常檔案: $AbnormalCount 篇" -ForegroundColor $(if ($AbnormalCount -gt 0) {'Red'} else {'Green'})
Write-Host "   ⚠️ 缺少品牌: $($MissingBrand.Count) 篇" -ForegroundColor $(if ($MissingBrand.Count -gt 0) {'Yellow'} else {'Green'})
Write-Host "   ⚠️ 含錯誤標記: $($HasError.Count) 篇" -ForegroundColor $(if ($HasError.Count -gt 0) {'Yellow'} else {'Green'})
$TotalSize = ($AllArticles | Measure-Object -Property Size -Sum).Sum
if ($TotalSize) {
    $TotalSizeMB = [math]::Round($TotalSize / 1MB, 2)
    Write-Host "   💾 文章總大小: $TotalSizeMB MB" -ForegroundColor Cyan
}
Write-Host ""

# ============================================================
# 7. 自動修復 (如果啟用)
# ============================================================
if ($Fix -and $AbnormalCount -gt 0) {
    Write-Host "🔧 正在刪除異常文章..." -ForegroundColor Yellow
    foreach ($f in $AbnormalFiles) {
        Remove-Item -Path $f.Path -Force
        Write-Host "   🗑️ 已刪除: $($f.RelativePath)" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "✅ 已刪除 $AbnormalCount 篇異常文章" -ForegroundColor Green
    Write-Host ""
    Write-Host "📌 請重新執行 .\ahpal-master.ps1 生成文章" -ForegroundColor Yellow
}

# ============================================================
# 8. 產生報告 (如果啟用)
# ============================================================
if ($Report) {
    Write-Host "📄 正在產生詳細報告..." -ForegroundColor Yellow
    
    $ReportContent = @"
============================================================
雅寶社區 · 頂客論壇 - 文章檢查報告
============================================================
檢查時間：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
輸出目錄：$OutputDir
============================================================

📊 統計摘要：
   總文章數: $Total 篇
   正常檔案: $NormalCount 篇
   異常檔案: $AbnormalCount 篇
   缺少品牌: $($MissingBrand.Count) 篇
   含錯誤標記: $($HasError.Count) 篇
   文章總大小: $([math]::Round($TotalSize / 1MB, 2)) MB

📁 各目錄統計：
"@
    foreach ($dir in $Dirs) {
        $files = $AllArticles | Where-Object { $_.Directory -eq $dir }
        $count = $files.Count
        $size = ($files | Measure-Object -Property Size -Sum).Sum
        if ($size -gt 0) {
            $sizeKB = [math]::Round($size / 1KB, 2)
            $ReportContent += "   $dir : $count 篇, $sizeKB KB`n"
        } else {
            $ReportContent += "   $dir : (空)`n"
        }
    }

    if ($AbnormalCount -gt 0) {
        $ReportContent += "`n❌ 異常文章清單：`n"
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

    if ($HasError.Count -gt 0) {
        $ReportContent += "`n⚠️ 含 API 錯誤標記的文章：`n"
        foreach ($f in $HasError) {
            $ReportContent += "   - $($f.RelativePath)`n"
        }
    }

    $ReportContent += "`n============================================================`n"
    $ReportContent += "報告產生時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

    Set-Content -Path $ReportFile -Value $ReportContent -Encoding UTF8
    Write-Host "   ✅ 報告已儲存：$ReportFile" -ForegroundColor Green
}

# ============================================================
# 完成
# ============================================================
Write-Host ""
if (-not $Fix -and -not $Report) {
    Write-Host "💡 若要自動刪除異常文章，請執行：.\check-articles.ps1 -Fix" -ForegroundColor Yellow
    Write-Host "💡 若要產生詳細報告，請執行：.\check-articles.ps1 -Report" -ForegroundColor Yellow
}
Write-Host ""
Read-Host "按 Enter 鍵結束"