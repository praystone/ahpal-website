# ============================================================
# AHPAL 配額監控腳本
# 使用：.\scripts\check-quota.ps1
# ============================================================

$LogDir = "C:\Users\User\ahpal-static\logs"
$LogFile = Join-Path $LogDir "upload-history.txt"
$Today = Get-Date -Format "yyyy-MM-dd"
$DailyLimit = 80

Write-Host "📊 YouTube API 配額監控" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray

if (Test-Path $LogFile) {
    $TodayUploads = (Get-Content $LogFile | Where-Object {$_ -match "^$Today.*✅"}).Count
    $TotalUploads = (Get-Content $LogFile | Where-Object {$_ -match "✅"}).Count
    $Remaining = $DailyLimit - $TodayUploads
    
    Write-Host "📌 今日已上傳：$TodayUploads 支" -ForegroundColor Yellow
    Write-Host "📌 歷史總上傳：$TotalUploads 支" -ForegroundColor Gray
    Write-Host "📌 剩餘配額：$Remaining 支" -ForegroundColor Green
    
    if ($TodayUploads -ge $DailyLimit) {
        Write-Host "⚠️ 警告：今日配額已達上限！" -ForegroundColor Red
    } elseif ($TodayUploads -ge ($DailyLimit * 0.85)) {
        Write-Host "⚠️ 注意：配額使用超過 85%" -ForegroundColor Yellow
    } else {
        Write-Host "✅ 配額狀態正常" -ForegroundColor Green
    }
} else {
    Write-Host "📌 尚無上傳記錄" -ForegroundColor Yellow
}

Write-Host "========================================" -ForegroundColor Gray
