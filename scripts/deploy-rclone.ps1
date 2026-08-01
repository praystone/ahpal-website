# ============================================================
# 📤 Rclone 一鍵部署 — Google Drive 雲端同步方案
# ============================================================
# 策略：使用 Rclone 將影片備份至 Google Drive (sax0936@gmail.com)
# 模式：單向同步 (本機 → 雲端)
# ============================================================

if ($Host.Name -eq "ConsoleHost") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📤 Rclone 一鍵部署 — Google Drive 雲端備份" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# --- 1. 設定路徑 ---
$BackupDir = "C:\MyCloudBackup"
$RcloneZip = "$env:TEMP\rclone.zip"
$RcloneExtract = "$env:TEMP\rclone_tmp"

# --- 2. 建立本地備份目錄 ---
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "✅ 本地備份目錄已建立：$BackupDir" -ForegroundColor Green
} else {
    Write-Host "✅ 本地備份目錄已存在：$BackupDir" -ForegroundColor Green
}
Write-Host ""

# --- 3. 下載 Rclone ---
Write-Host "⏳ 正在下載 Rclone..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $RcloneZip -UseBasicParsing
    Write-Host "✅ Rclone 下載完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 下載失敗：$_" -ForegroundColor Red
    Read-Host "按 Enter 鍵結束"
    exit 1
}

# --- 4. 解壓縮 Rclone ---
Write-Host "⏳ 正在解壓縮 Rclone..." -ForegroundColor Yellow
try {
    if (Test-Path $RcloneExtract) { Remove-Item -Recurse -Force $RcloneExtract }
    Expand-Archive -Path $RcloneZip -DestinationPath $RcloneExtract -Force
    Copy-Item "$RcloneExtract\*\rclone.exe" -Destination "$BackupDir\rclone.exe" -Force
    Write-Host "✅ Rclone 安裝完成" -ForegroundColor Green
} catch {
    Write-Host "❌ 解壓縮失敗：$_" -ForegroundColor Red
    Read-Host "按 Enter 鍵結束"
    exit 1
}

# --- 5. 設定執行路徑 ---
$env:Path += ";$BackupDir"
Set-Location $BackupDir

# --- 6. 檢查 Rclone 配置 ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🔑 Rclone 帳戶配置" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$configCheck = & .\rclone.exe config show 2>&1
if ($configCheck -match "my_drive") {
    Write-Host "✅ 已偵測到現有配置：my_drive" -ForegroundColor Green
    $reconfigure = Read-Host "是否重新配置？(Y/N)"
    if ($reconfigure -ne "Y" -and $reconfigure -ne "y") {
        Write-Host "⏭️ 跳過配置步驟" -ForegroundColor Gray
    } else {
        Write-Host "⏳ 請依照指示完成 Google 帳號授權..." -ForegroundColor Yellow
        & .\rclone.exe config
    }
} else {
    Write-Host "⏳ 請依照指示完成 Google 帳號授權..." -ForegroundColor Yellow
    Write-Host "   (選擇：n) 新建配置 → 名稱：my_drive → 類型：drive → 依照提示完成授權)" -ForegroundColor Gray
    & .\rclone.exe config
}

# --- 7. 執行同步 (本機 → 雲端) ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📤 開始同步至 Google Drive (sax0936@gmail.com)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📂 來源：$BackupDir" -ForegroundColor Yellow
Write-Host "☁️ 目標：my_drive:/AHPAL_影音備份" -ForegroundColor Yellow
Write-Host ""

# 先將 AHPAL 影片複製到本地備份目錄
$SourceVideoDir = "C:\Users\User\ahpal-AI-archive\videos"
if (Test-Path $SourceVideoDir) {
    Write-Host "⏳ 正在複製 AHPAL 影片到本地備份目錄..." -ForegroundColor Yellow
    Copy-Item -Path "$SourceVideoDir\*" -Destination "$BackupDir\AHPAL_影音備份" -Recurse -Force
    Write-Host "✅ 影片已複製到本地備份目錄" -ForegroundColor Green
}

Write-Host ""
Write-Host "⏳ 正在同步至 Google Drive (這可能需要幾分鐘)..." -ForegroundColor Yellow
Write-Host ""

# 執行 Rclone 同步
& .\rclone.exe sync "$BackupDir\AHPAL_影音備份" "my_drive:/AHPAL_影音備份" --progress --transfers 4 --verbose

# --- 8. 完成 ---
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 同步完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📊 同步摘要：" -ForegroundColor Yellow
Write-Host "   📂 本地備份：$BackupDir\AHPAL_影音備份" -ForegroundColor Cyan
Write-Host "   ☁️ 雲端路徑：my_drive:/AHPAL_影音備份" -ForegroundColor Cyan
Write-Host "   👤 目標帳戶：sax0936@gmail.com" -ForegroundColor Green
Write-Host ""

Read-Host "按 Enter 鍵結束"