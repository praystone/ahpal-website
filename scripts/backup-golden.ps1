# ============================================================
# backup-golden.ps1 - AHPAL 整站優良備份腳本 v1.0
# ============================================================
# 功能：建立整站完整備份（黃金基準版本）
# 輸出：ahpal-整站優良備份-YYYYMMDD_HHMMSS.zip
# 位置：C:\Users\User\ahpal-AI-archive\優良備份\
# ============================================================

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ArchiveRoot = "C:\Users\User\ahpal-AI-archive\優良備份"
$SourceRoot = "C:\Users\User\ahpal-static"
$BackupName = "ahpal-整站優良備份-$Timestamp"

$BackupPath = Join-Path $ArchiveRoot $BackupName
$ZipPath = "$BackupPath.zip"

# 建立備份目錄
New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📦 AHPAL 整站優良備份" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   📂 來源：$SourceRoot"
Write-Host "   📂 目標：$BackupPath"
Write-Host ""

# 1. 複製網站檔案（排除暫存）
Write-Host "   [1/6] 複製網站檔案..." -ForegroundColor Yellow
$Exclude = @("*.tmp", "*.log", "__pycache__", ".wrangler", "node_modules", "logs")
Get-ChildItem -Path $SourceRoot -Exclude $Exclude | ForEach-Object {
    $dest = Join-Path $BackupPath $_.Name
    Copy-Item -Path $_.FullName -Destination $dest -Recurse -Force
}
Write-Host "   ✅ 網站檔案已複製" -ForegroundColor Green

# 2. 複製原始碼
Write-Host "   [2/6] 複製原始碼..." -ForegroundColor Yellow
Copy-Item -Path "$SourceRoot\src" -Destination "$BackupPath\src" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "$SourceRoot\scripts" -Destination "$BackupPath\scripts" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "   ✅ 原始碼已複製" -ForegroundColor Green

# 3. 複製設定檔
Write-Host "   [3/6] 複製設定檔..." -ForegroundColor Yellow
$ConfigFiles = @(".env", ".env.template", ".gitignore", "README.md", "package.json")
foreach ($f in $ConfigFiles) {
    $src = Join-Path $SourceRoot $f
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination "$BackupPath\$f" -Force
        Write-Host "      ✅ $f" -ForegroundColor Gray
    }
}
Write-Host "   ✅ 設定檔已複製" -ForegroundColor Green

# 4. 複製資料檔案
Write-Host "   [4/6] 複製資料檔案..." -ForegroundColor Yellow
if (Test-Path "$SourceRoot\data") {
    Copy-Item -Path "$SourceRoot\data" -Destination "$BackupPath\data" -Recurse -Force
    Write-Host "      ✅ data/" -ForegroundColor Gray
}
if (Test-Path "$SourceRoot\docs") {
    Copy-Item -Path "$SourceRoot\docs" -Destination "$BackupPath\docs" -Recurse -Force
    Write-Host "      ✅ docs/" -ForegroundColor Gray
}
Write-Host "   ✅ 資料檔案已複製" -ForegroundColor Green

# 5. 複製影音檔案
Write-Host "   [5/6] 複製影音檔案..." -ForegroundColor Yellow
if (Test-Path "$SourceRoot\videos") {
    Copy-Item -Path "$SourceRoot\videos" -Destination "$BackupPath\videos" -Recurse -Force
    Write-Host "      ✅ videos/" -ForegroundColor Gray
}
Write-Host "   ✅ 影音檔案已複製" -ForegroundColor Green

# 6. 建立備份清單
Write-Host "   [6/6] 建立備份清單..." -ForegroundColor Yellow
$Manifest = @"
============================================================
AHPAL 整站優良備份清單
============================================================
備份時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
備份版本：v9.0
備份位置：$BackupPath

檔案統計：
"@
$TotalFiles = (Get-ChildItem -Path $BackupPath -Recurse -File).Count
$TotalSize = [math]::Round((Get-ChildItem -Path $BackupPath -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
$Manifest += "`n總檔案數：$TotalFiles 個"
$Manifest += "`n總大小：$TotalSize MB"
$Manifest += "`n`n目錄結構："
$Manifest | Out-File -FilePath "$BackupPath\MANIFEST.txt" -Encoding UTF8

Get-ChildItem -Path $BackupPath -Directory | ForEach-Object {
    $count = (Get-ChildItem -Path $_.FullName -Recurse -File).Count
    $size = [math]::Round((Get-ChildItem -Path $_.FullName -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1KB, 2)
    Add-Content -Path "$BackupPath\MANIFEST.txt" -Value "   📁 $($_.Name)/ - $count 個檔案 ($size KB)" -Encoding UTF8
}
Write-Host "   ✅ 備份清單已建立" -ForegroundColor Green

# 壓縮備份
Write-Host ""
Write-Host "   📦 壓縮備份..." -ForegroundColor Yellow
Compress-Archive -Path $BackupPath -DestinationPath $ZipPath -Force
$ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
Write-Host "   ✅ 壓縮完成：$BackupName.zip ($ZipSize MB)" -ForegroundColor Green

# 顯示摘要
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ✅ 整站優良備份完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   📂 備份位置：$BackupPath"
Write-Host "   📦 壓縮檔案：$ZipPath ($ZipSize MB)"
Write-Host "   📄 檔案總數：$TotalFiles 個"
Write-Host ""
Write-Host "   📌 此為 AHPAL 黃金基準版本" -ForegroundColor Yellow
Write-Host "   📌 還原時請先停止服務，解壓縮覆蓋" -ForegroundColor Yellow
Write-Host ""
