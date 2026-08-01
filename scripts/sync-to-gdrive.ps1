# ============================================================
# 📤 AHPAL 雲端同步黃金標準 v2.1 (完整繁體版)
# ============================================================
# 功能：統一管理 AHPAL 所有雲端同步任務
# 用法：.\scripts\sync-to-gdrive.ps1
#       .\scripts\sync-to-gdrive.ps1 -Task articles  # 僅同步文章
#       .\scripts\sync-to-gdrive.ps1 -Task videos    # 僅同步影音
#       .\scripts\sync-to-gdrive.ps1 -Task scripts   # 僅同步腳本
# ============================================================

param(
    [ValidateSet("all", "articles", "videos", "scripts", "backup")]
    [string]$Task = "all",
    [switch]$DryRun,
    [switch]$Force
)

# ---- 1. 環境設定 ----
if ($Host.Name -eq "ConsoleHost") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}

$ErrorActionPreference = "Continue"

$ProjectRoot = "C:\Users\User\ahpal-static"
$ArchiveRoot = "C:\Users\User\ahpal-AI-archive"
$RclonePath = "C:\MyCloudBackup\rclone.exe"

# ---- 2. 檢查 Rclone ----
if (-not (Test-Path $RclonePath)) {
    Write-Host "⚠️ Rclone 不存在，正在下載..." -ForegroundColor Yellow
    $BackupDir = "C:\MyCloudBackup"
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    $RcloneZip = "$env:TEMP\rclone.zip"
    $RcloneExtract = "$env:TEMP\rclone_tmp"
    
    try {
        Invoke-WebRequest -Uri "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -OutFile $RcloneZip -UseBasicParsing
        if (Test-Path $RcloneExtract) { Remove-Item -Recurse -Force $RcloneExtract }
        Expand-Archive -Path $RcloneZip -DestinationPath $RcloneExtract -Force
        Copy-Item "$RcloneExtract\*\rclone.exe" -Destination $RclonePath -Force
        Write-Host "✅ Rclone 安裝完成" -ForegroundColor Green
    } catch {
        Write-Host "❌ Rclone 安裝失敗：$_" -ForegroundColor Red
        exit 1
    }
}

# ---- 3. 檢查 Rclone 配置 ----
$ConfigCheck = & $RclonePath config show 2>&1
if ($ConfigCheck -notmatch "ahpalke_drive" -and $Force) {
    Write-Host "⚠️ ahpalke_drive 配置不存在，請先執行配置" -ForegroundColor Yellow
    & $RclonePath config
}

# ---- 4. 定義同步任務 ----
$RemoteTarget = "ahpalke_drive"

# 顯示標題
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📤 AHPAL 雲端同步黃金標準 v2.1" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   📌 遠端目標：$RemoteTarget (ahpalke@gmail.com)" -ForegroundColor Green
Write-Host "   🔧 模式：$(if ($DryRun) { '預覽模式' } else { '執行模式' })" -ForegroundColor Yellow
Write-Host ""

# ---- 5. 執行同步任務 ----
$SyncResults = @()

function Invoke-SyncTask {
    param(
        [string]$LocalPath,
        [string]$RemotePath,
        [string]$TaskName
    )
    
    Write-Host "📂 [$TaskName] 同步中..." -ForegroundColor Yellow
    Write-Host "   來源：$LocalPath" -ForegroundColor Gray
    Write-Host "   目標：$RemoteTarget`:$RemotePath" -ForegroundColor Gray
    
    if (-not (Test-Path $LocalPath)) {
        Write-Host "   ⚠️ 來源路徑不存在，跳過" -ForegroundColor Red
        return $false
    }
    
    $Args = @(
        "sync", "`"$LocalPath`"", "`"$RemoteTarget`:$RemotePath`"",
        "--progress",
        "--transfers", "4",
        "--verbose"
    )
    
    if ($DryRun) {
        $Args += "--dry-run"
        Write-Host "   🔍 預覽模式：僅顯示將要同步的檔案" -ForegroundColor Cyan
    }
    
    $CmdLine = $RclonePath + " " + ($Args -join " ")
    Write-Host "   🖥️ 執行中..." -ForegroundColor Gray
    
    if ($DryRun) {
        # 預覽模式：僅列出檔案
        $ListArgs = @("ls", "`"$LocalPath`"")
        & $RclonePath $ListArgs | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
        Write-Host "   ✅ 預覽完成" -ForegroundColor Green
    } else {
        & $RclonePath sync $LocalPath "$RemoteTarget`:$RemotePath" --progress --transfers 4 --verbose
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ 同步完成" -ForegroundColor Green
            return $true
        } else {
            Write-Host "   ⚠️ 同步可能不完全，請檢查" -ForegroundColor Yellow
            return $false
        }
    }
    return $true
}

# ---- 6. 根據任務類型執行 ----
switch ($Task) {
    "all" {
        Write-Host "📋 執行全部同步任務：" -ForegroundColor Cyan
        Write-Host ""
        
        # 6.1 同步文章 (優良備份)
        Invoke-SyncTask -LocalPath "$ArchiveRoot\優良備份" -RemotePath "AHPAL_文章_優良備份" -TaskName "文章備份"
        
        # 6.2 同步腳本
        Invoke-SyncTask -LocalPath "$ProjectRoot\scripts" -RemotePath "AHPAL_腳本" -TaskName "腳本備份"
        
        # 6.3 同步影音
        Invoke-SyncTask -LocalPath "$ArchiveRoot\videos" -RemotePath "AHPAL_影音備份" -TaskName "影音備份"
    }
    
    "articles" {
        Invoke-SyncTask -LocalPath "$ArchiveRoot\優良備份" -RemotePath "AHPAL_文章_優良備份" -TaskName "文章備份"
    }
    
    "videos" {
        Invoke-SyncTask -LocalPath "$ArchiveRoot\videos" -RemotePath "AHPAL_影音備份" -TaskName "影音備份"
    }
    
    "scripts" {
        Invoke-SyncTask -LocalPath "$ProjectRoot\scripts" -RemotePath "AHPAL_腳本" -TaskName "腳本備份"
    }
    
    "backup" {
        # 僅備份優良備份 + 腳本
        Invoke-SyncTask -LocalPath "$ArchiveRoot\優良備份" -RemotePath "AHPAL_文章_優良備份" -TaskName "文章備份"
        Invoke-SyncTask -LocalPath "$ProjectRoot\scripts" -RemotePath "AHPAL_腳本" -TaskName "腳本備份"
    }
}

# ---- 7. 完成報告 ----
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 同步任務完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📌 同步摘要：" -ForegroundColor Yellow
Write-Host "   任務類型：$Task" -ForegroundColor Cyan
Write-Host "   遠端目標：$RemoteTarget (ahpalke@gmail.com)" -ForegroundColor Green
if (-not $DryRun) {
    Write-Host "   📁 請到 https://drive.google.com 登入 ahpalke@gmail.com 驗證" -ForegroundColor Cyan
}
Write-Host ""

Read-Host "按 Enter 鍵結束"