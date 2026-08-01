# ============================================================
# 📤 備份影片到 Google Drive (sax0936 精準實體穿透完全版)
# ============================================================

if ($Host.Name -eq "ConsoleHost") {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force
}

$SourceDir = "C:\Users\User\ahpal-AI-archive\videos"

# 🎯 終極鎖定：精準對應 sax0936@gmail.com 的官方實體核心同步入口
$DestDir = "C:\Users\User\AppData\Local\Google\DriveFS\104367035731133290085\root\AHPAL_影音備份"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📤 備份影片到 Google Drive (sax0936 專屬軌道)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   📂 來源：$SourceDir" -ForegroundColor Yellow
Write-Host "   📂 目標：$DestDir" -ForegroundColor Yellow
Write-Host "   📌 模式：精準快取穿透 (死鎖 sax0936 核心帳戶)" -ForegroundColor Gray
Write-Host ""

# 1. 建立實體目標資料夾
if (-not (Test-Path $DestDir)) {
    $null = New-Item -ItemType Directory -Path $DestDir -Force
}

# 2. 取得所有來源檔案
$files = Get-ChildItem -Path $SourceDir -Recurse -File
Write-Host "📊 找到 $($files.Count) 個檔案準備備份" -ForegroundColor Cyan
Write-Host "⏳ 正在寫入官方核心同步層..." -ForegroundColor Yellow
Write-Host ""

$copied = 0
$skipped = 0
$failed = 0

# 3. 進行穿透複製
foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($SourceDir.Length + 1)
    $targetFilePath = Join-Path $DestDir $relativePath
    $targetFileDir = Split-Path $targetFilePath -Parent
    
    if (-not (Test-Path $targetFileDir)) {
        $null = New-Item -ItemType Directory -Path $targetFileDir -Force
    }
    
    # 增量比對 (若檔案大小相同則跳過)
    if (Test-Path $targetFilePath) {
        $targetFile = Get-Item $targetFilePath
        if ($file.Length -eq $targetFile.Length) {
            Write-Host "   ⏭️ 跳過（已存在）：$relativePath" -ForegroundColor Gray
            $skipped++
            continue
        }
    }
    
    try {
        Copy-Item -Path $file.FullName -Destination $targetFilePath -Force -ErrorAction Stop
        Write-Host "   ✅ 備份成功：$relativePath" -ForegroundColor Green
        $copied++
    } catch {
        Write-Host "   ❌ 備份失敗：$relativePath (原因: $_)" -ForegroundColor Red
        $failed++
    }
}

# 4. 統計報告
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 備份程序執行完畢！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "📊 統計：成功 $copied 個，跳過 $skipped 個，失敗 $failed 個" -ForegroundColor Cyan
Write-Host "📌 檔案已精準灌入 sax0936 同步軌道，請重新整理網頁檢視！" -ForegroundColor Green
Write-Host ""

Read-Host "按 Enter 鍵結束"
