# ============================================================
# launcher-test.ps1 - 測試用包裝腳本
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 龍蝦總工程師 - 測試喚醒執行" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "  測試模式: 單篇歷史腦洞生成" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Set-Location C:\Users\User\ahpal-static
& ".\scripts\auto-history-batch.ps1"

$ExitCode = $LASTEXITCODE
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 測試執行完成！" -ForegroundColor Green
Write-Host "  結束時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host "  退出碼: $ExitCode" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📌 測試完成！視窗將保持開啟，請檢視上方輸出。" -ForegroundColor Cyan
Write-Host "   按下任意鍵關閉此視窗..." -ForegroundColor Gray
Read-Host
