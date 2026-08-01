# scripts\backup-to-archive.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📦 AHPAL 備份到 AI 檔案館" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$date = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupName = "ahpal-static-stable-$date"
$archivePath = "C:\Users\User\ahpal-AI-archive"

Set-Location C:\Users\User\ahpal-static

$count = (Get-ChildItem -Recurse -Filter "*.html" | Measure-Object).Count
Write-Host "📊 文章數：$count 篇" -ForegroundColor Yellow

Write-Host "`n📦 壓縮備份中..." -ForegroundColor Cyan
Compress-Archive -Path .\* -DestinationPath "$archivePath\$backupName.zip" -Force

$size = [math]::Round((Get-Item "$archivePath\$backupName.zip").Length / 1MB, 2)
Write-Host "✅ 備份完成！" -ForegroundColor Green
Write-Host "📍 $archivePath\$backupName.zip ($size MB)" -ForegroundColor Yellow

# 建立記錄
@"
AHPAL 穩定版備份
日期：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
文章數：$count 篇
版本：v4.4
"@ | Out-File "$archivePath\$backupName-README.txt"

# 顯示最近 5 個備份
Write-Host "`n📁 最近備份：" -ForegroundColor Cyan
Get-ChildItem $archivePath -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 5 Name, LastWriteTime
