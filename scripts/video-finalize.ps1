# ============================================================
# AHPAL 自動化影音後製管線 v1.2
# 功能：合軌、浮水印、轉檔、TTS 旁白
# 作者：龍蝦總工程師（DeepSeek）
# 修正：移除 trim 裁切（避免 FFmpeg 報錯）
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$InputVideo,
    [string]$OutputName = "ahpal-api-compliance.mp4",
    [string]$AudioFile = "C:\Users\User\ahpal-static\audio\podcast.wav",
    [string]$WatermarkText = "AHPAL.COM | 18年權威網域",
    [switch]$TTS,
    [string]$TTSText = ""
)

Write-Host ""
Write-Host "🦞 AHPAL 自動化影音後製管線啟動" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray

# ============================================================
# 1. 檢查 FFmpeg
# ============================================================
Write-Host "🔍 [1/6] 檢查 FFmpeg..." -ForegroundColor Yellow

$FFmpegPath = (Get-Command ffmpeg -ErrorAction SilentlyContinue).Source
if (-not $FFmpegPath) {
    Write-Host "   ❌ FFmpeg 未安裝！" -ForegroundColor Red
    Write-Host "   📌 請安裝 FFmpeg：winget install ffmpeg" -ForegroundColor Yellow
    exit 1
}
Write-Host "   ✅ FFmpeg 已就位：$FFmpegPath" -ForegroundColor Green

# ============================================================
# 2. 檢查輸入檔案
# ============================================================
Write-Host "📁 [2/6] 檢查輸入檔案..." -ForegroundColor Yellow

if (-not (Test-Path $InputVideo)) {
    Write-Host "   ❌ 找不到影片：$InputVideo" -ForegroundColor Red
    exit 1
}
Write-Host "   ✅ 影片：$InputVideo" -ForegroundColor Green

$UseOriginalAudio = $true
if (-not (Test-Path $AudioFile) -and -not $TTS) {
    Write-Host "   ⚠️ 找不到音訊：$AudioFile，使用影片原始音軌" -ForegroundColor Yellow
    $UseOriginalAudio = $true
}

# ============================================================
# 3. TTS 生成（可選）
# ============================================================
if ($TTS -and $TTSText) {
    Write-Host "🗣️ [3/6] 生成 TTS 旁白..." -ForegroundColor Yellow
    $TTSFile = "C:\Users\User\ahpal-static\audio\tts_temp.wav"
    try {
        Add-Type -AssemblyName System.Speech
        $Speech = New-Object System.Speech.Synthesis.SpeechSynthesizer
        $Speech.Rate = 1
        $Speech.Volume = 100
        $Speech.SetOutputToWaveFile($TTSFile)
        $Speech.Speak($TTSText)
        $Speech.Dispose()
        $AudioFile = $TTSFile
        Write-Host "   ✅ TTS 旁白已生成：$TTSFile" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ TTS 生成失敗：$($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# 4. 準備 FFmpeg 參數
# ============================================================
Write-Host "🎬 [4/6] 建構 FFmpeg 管線..." -ForegroundColor Yellow

$OutputDir = "C:\Users\User\ahpal-static\videos\final"
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$OutputPath = Join-Path $OutputDir $OutputName

# === 浮水印參數（使用 Windows 內建字型）===
$WatermarkFilter = "drawtext=text='$WatermarkText':fontcolor=white:fontsize=24:fontfile='C\:/Windows/Fonts/msyh.ttc':box=1:boxcolor=black@0.6:boxborderw=5:x=w-tw-20:y=20"

# === 完整過濾器鏈（無 trim）===
$FullFilter = $WatermarkFilter

# ============================================================
# 5. 執行 FFmpeg
# ============================================================
Write-Host "⚙️ [5/6] 執行 FFmpeg 轉檔..." -ForegroundColor Yellow
Write-Host "   📌 這可能需要數分鐘，請稍候..." -ForegroundColor Gray

if ($UseOriginalAudio) {
    $FFmpegCmd = "ffmpeg -i `"$InputVideo`" -vf `"$FullFilter`" -c:v libx264 -preset fast -crf 23 -c:a copy `"$OutputPath`" -y"
} else {
    $FFmpegCmd = "ffmpeg -i `"$InputVideo`" -i `"$AudioFile`" -vf `"$FullFilter`" -map 0:v -map 1:a -shortest -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k `"$OutputPath`" -y"
}

Write-Host "   🖥️ 執行中..." -ForegroundColor Gray
Invoke-Expression $FFmpegCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ FFmpeg 執行失敗！" -ForegroundColor Red
    exit 1
}

Write-Host "   ✅ 影片已輸出：$OutputPath" -ForegroundColor Green

# ============================================================
# 6. 複製至桌面
# ============================================================
Write-Host "📊 [6/6] 複製至桌面..." -ForegroundColor Yellow

if (Test-Path $OutputPath) {
    $FileInfo = Get-Item $OutputPath
    $FileSizeMB = [math]::Round($FileInfo.Length / 1MB, 2)
    Write-Host "   ✅ 檔案大小：$FileSizeMB MB" -ForegroundColor Green
} else {
    Write-Host "   ❌ 找不到輸出檔案！" -ForegroundColor Red
    exit 1
}

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$DesktopCopy = Join-Path $DesktopPath $OutputName
Copy-Item $OutputPath $DesktopCopy -Force
Write-Host "   ✅ 已複製至桌面：$DesktopCopy" -ForegroundColor Green

# ============================================================
# 完成報告
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ 影音後製管線執行完畢！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "📌 成品位置：$OutputPath" -ForegroundColor Gray
Write-Host "📌 桌面備份：$DesktopCopy" -ForegroundColor Gray
Write-Host ""
Write-Host "📋 下一步：" -ForegroundColor Yellow
Write-Host "   1. 開啟桌面上的 $OutputName 確認影片內容" -ForegroundColor Gray
Write-Host "   2. 上傳至 Google Drive（設定為『知道連結者均可觀看』）" -ForegroundColor Gray
Write-Host "   3. 回覆 Google 審核團隊郵件，附上連結" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan