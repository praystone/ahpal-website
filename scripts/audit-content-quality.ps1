# ============================================================
# audit-content-quality.ps1 - 內容品質自動審查 v1.2
# ============================================================
# 🆕 v1.2 修復 (2026-08-19)：
#   - 🔧 移除 PowerShell 不支援的 ?? 運算子
#   - 🔧 改用標準 if/else 寫法
# ============================================================

param(
    [int]$SampleSize = 50,
    [string]$Category = "life",
    [switch]$Quiet
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$OutputDir = $ProjectRoot
$ReportDir = "C:\Users\User\ahpal-AI-archive\system-tools\system-reports\04-品質報告"

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

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
Write-Info "  📝 內容品質自動審查 v1.2"
Write-Info "  目標分類：$Category | 抽樣數量：$SampleSize"
Write-Info "============================================================"
Write-Info ""

$TargetDir = Join-Path $OutputDir $Category
if (-not (Test-Path $TargetDir)) {
    Write-Error "❌ 目錄不存在：$TargetDir"
    exit 1
}

$AllFiles = Get-ChildItem -Path $TargetDir -Filter "*.html" | Sort-Object Name
$TotalFiles = $AllFiles.Count
$SampleFiles = $AllFiles | Select-Object -First $SampleSize

Write-Info "📁 總文章數：$TotalFiles | 抽樣：$($SampleFiles.Count) 篇"
Write-Info ""

$Results = @()
$PassCount = 0
$FailCount = 0

foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $Content) { continue }

    $Score = 0
    $Issues = @()
    $Details = @{}

    if ($Content -match '<h1[^>]*>') { $Score += 15 } else { $Issues += "缺少 H1" }

    $h2Count = ([regex]::Matches($Content, '<h2[^>]*>')).Count
    if ($h2Count -ge 2) { $Score += 15 } else { $Issues += "H2 不足（$h2Count 個）" }
    $Details["H2"] = $h2Count

    if ($Content -match '<table[^>]*>') { $Score += 10 } else { $Issues += "缺少表格" }
    if ($Content -match '(FAQ|常見問題|Q：|問：|Q&A)') { $Score += 10 } else { $Issues += "缺少 FAQ" }
    if ($Content -match '本文目錄|目錄|Table of Contents|TOC') { $Score += 10 } else { $Issues += "缺少目錄" }

    $CleanContent = $Content -replace '<script[^>]*>.*?</script>', '' -replace '<style[^>]*>.*?</style>', ''
    $TextOnly = $CleanContent -replace '<[^>]+>', ' ' -replace '\s+', ' '
    $WordCount = $TextOnly.Length
    if ($WordCount -ge 5000) { $Score += 20 }
    elseif ($WordCount -ge 3000) { $Score += 10 }
    else { $Issues += "字數不足（$WordCount 字）" }
    $Details["字數"] = $WordCount

    if ($Content -match '<img[^>]*>') { $Score += 10 } else { $Issues += "缺少圖片" }
    if ($Content -match '文／|作者|編輯') { $Score += 10 } else { $Issues += "缺少作者署名" }

    if ($Content -match '發表時間：(\d{4})[年\-/](\d{2})') {
        $Year = $Matches[1]
        if ($Year -lt 2026) { $Score += 10 }
        $Details["年份"] = $Year
    }

    if ($Content -match '<title>(.+?)</title>') {
        $Title = $Matches[1]
        if ($Title.Length -gt 10 -and $Title.Length -lt 60) { $Score += 10 }
        else { $Issues += "標題長度異常（$($Title.Length) 字）" }
        $Details["標題"] = $Title
    }

    $Passed = $Score -ge 80
    if ($Passed) { $PassCount++ } else { $FailCount++ }

    # 🆕 v1.2: 用 if/else 替代 ?? 運算子
    $YearValue = if ($Details.ContainsKey("年份")) { $Details["年份"] } else { "未知" }
    $TitleValue = if ($Details.ContainsKey("標題")) { $Details["標題"] } else { "" }

    $Results += [PSCustomObject]@{
        FileName = $f.Name
        Score = $Score
        Passed = $Passed
        Issues = if ($Issues) { $Issues -join "；" } else { "無" }
        H2 = $Details["H2"]
        WordCount = $Details["字數"]
        Year = $YearValue
        Title = $TitleValue
    }
}

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportFile = Join-Path $ReportDir "quality-audit-$Category-$Timestamp.csv"
$Results | Export-Csv -Path $ReportFile -NoTypeInformation -Encoding UTF8

Write-Info "📊 審查摘要："
Write-Info "   ✅ 通過（≥80分）：$PassCount / $($SampleFiles.Count)"
Write-Info "   ❌ 未達標：$FailCount / $($SampleFiles.Count)"
Write-Info "   📊 平均分數：$([math]::Round(($Results | Measure-Object -Property Score -Average).Average, 1))"
Write-Info "   📊 平均字數：$([math]::Round(($Results | Measure-Object -Property WordCount -Average).Average, 0)) 字"
Write-Info "   📊 平均 H2：$([math]::Round(($Results | Measure-Object -Property H2 -Average).Average, 1)) 個"
Write-Info ""
Write-Info "📁 報告已儲存：$ReportFile"

if ($FailCount -gt 0) {
    Write-Warning "⚠️ 未達標文章清單："
    $Results | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Warning "   - $($_.FileName)（分數：$($_.Score)）→ $($_.Issues)"
    }
} else {
    Write-Success "✅ 所有抽樣文章品質達標！"
}

Write-Info ""
Write-Info "✅ 內容品質審查完成！"