# ============================================================
# AHPAL 流量管制批次上傳 (每日上限 85 支)
# 版本：v1.0
# 功能：自動掃描 videos/output/ 中的 Shorts 影片，
#       每日最多上傳 85 支至 YouTube
# ============================================================

cd C:\Users\User\ahpal-static

Write-Host "🦞 流量管制批次上傳啟動" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray

# 1. 載入 Refresh Token
$envContent = Get-Content .env -Raw
if ($envContent -match "YOUTUBE_REFRESH_TOKEN=(.+)") {
    [Environment]::SetEnvironmentVariable("YOUTUBE_REFRESH_TOKEN", $Matches[1].Trim(), "Process")
    Write-Host "✅ Refresh Token 已載入" -ForegroundColor Green
} else {
    Write-Host "❌ Refresh Token 載入失敗" -ForegroundColor Red
    exit 1
}

# 2. 設定每日上限 (安全緩衝區)
$DailyLimit = 85
$UploadedToday = 0
$SkippedCount = 0

# 3. 掃描所有 Shorts 影片 (依名稱排序)
$VideoFiles = Get-ChildItem "videos\output\*-shorts.mp4" -ErrorAction SilentlyContinue | Sort-Object Name

if ($VideoFiles.Count -eq 0) {
    Write-Host "⚠️ 未找到任何 Shorts 影片" -ForegroundColor Yellow
    exit 0
}

Write-Host "📁 找到 $($VideoFiles.Count) 支 Shorts 影片" -ForegroundColor Yellow
Write-Host "📌 本日上限：$DailyLimit 支" -ForegroundColor Yellow
Write-Host ""

# 4. 開始上傳
foreach ($video in $VideoFiles) {
    # 檢查是否已達上限
    if ($UploadedToday -ge $DailyLimit) {
        $SkippedCount = $VideoFiles.Count - $UploadedToday
        Write-Host ""
        Write-Host "⚠️ 已達每日上限 ($DailyLimit 支)，剩餘 $SkippedCount 支待明日上傳" -ForegroundColor Yellow
        break
    }
    
    # 準備上傳
    $Title = $video.BaseName -replace "-shorts$", "" -replace "-", " "
    Write-Host "📤 [$($UploadedToday + 1)/$DailyLimit] 上傳：$Title" -ForegroundColor Gray
    
    # 執行上傳
    & ".\scripts\youtube-upload-realtime.ps1" `
        -VideoFile $video.FullName `
        -Title "【AHPAL 精選】$Title" `
        -Description "AHPAL 雅寶社區 · 頂客論壇 - 更多內容請至 https://www.ahpal.com" `
        -Tags @("AHPAL", "科技", "生活", "評測", "Shorts")
    
    # 檢查上傳結果
    if ($LASTEXITCODE -eq 0) {
        $UploadedToday++
        Write-Host "   ✅ 上傳成功" -ForegroundColor Green
    } else {
        Write-Host "   ❌ 上傳失敗，跳過此影片" -ForegroundColor Red
    }
    
    # 避免 API 速率限制
    Start-Sleep -Seconds 3
}

# 5. 總結報告
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "📊 上傳完成報告" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   ✅ 本日上傳：$UploadedToday 支" -ForegroundColor Green
Write-Host "   ⏳ 待上傳：$SkippedCount 支" -ForegroundColor Gray
Write-Host "   📌 上限設定：$DailyLimit 支/日" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan
