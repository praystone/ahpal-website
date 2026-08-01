# ============================================================
# 雅寶社區 · 頂客論壇 - 環境設定檔 v3.1
# ============================================================
# 功能：設定所有環境變數（API Key、SMTP、路徑等）
# 用法：.\scripts\ahpal-static.ps1
# ============================================================

Write-Host "🔧 載入環境設定..." -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 從 .env 讀取所有環境變數
# ============================================================

# 取得腳本所在目錄
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$EnvPath = Join-Path $ScriptDir "..\.env"

if (Test-Path $EnvPath) {
    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            $Key = $Matches[1].Trim()
            $Value = $Matches[2].Trim()
            Set-Item -Path "env:$Key" -Value $Value
        }
    }
    Write-Host "   ✅ 已從 .env 載入環境變數" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ .env 檔案不存在，使用預設值" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# 2. 設定輸出目錄
# ============================================================

$env:AHPAL_OUTPUT_DIR = "C:\Users\User\ahpal-static"
if (-not (Test-Path $env:AHPAL_OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $env:AHPAL_OUTPUT_DIR -Force | Out-Null
}
Write-Host "   📁 輸出目錄：$($env:AHPAL_OUTPUT_DIR)" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 3. 顯示環境狀態摘要
# ============================================================

Write-Host "📊 環境狀態摘要：" -ForegroundColor Yellow
Write-Host ""

# Gemini API Key
if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY -ne "YOUR_GEMINI_API_KEY") {
    $masked = $env:GEMINI_API_KEY.Substring(0, 4) + "..." + $env:GEMINI_API_KEY.Substring($env:GEMINI_API_KEY.Length - 4)
    Write-Host "   ✅ Gemini API Key：$masked" -ForegroundColor Green
} else {
    Write-Host "   ❌ Gemini API Key：未設定" -ForegroundColor Red
}

# DeepSeek API Key
if ($env:DEEPSEEK_API_KEY -and $env:DEEPSEEK_API_KEY -ne "YOUR_DEEPSEEK_API_KEY") {
    $masked = $env:DEEPSEEK_API_KEY.Substring(0, 4) + "..." + $env:DEEPSEEK_API_KEY.Substring($env:DEEPSEEK_API_KEY.Length - 4)
    Write-Host "   ✅ DeepSeek API Key：$masked" -ForegroundColor Green
} else {
    Write-Host "   ❌ DeepSeek API Key：未設定" -ForegroundColor Red
}

# SMTP 設定
if ($env:SMTP_USER -and $env:SMTP_USER -ne "你的Gmail帳號@gmail.com") {
    Write-Host "   ✅ SMTP 郵件設定：$($env:SMTP_USER)" -ForegroundColor Green
    Write-Host "   📌 寄件者：$($env:SMTP_FROM)" -ForegroundColor Gray
    Write-Host "   📌 收件者：$($env:SMTP_TO)" -ForegroundColor Gray
} else {
    Write-Host "   ⚠️ SMTP 郵件設定：未完整設定" -ForegroundColor Yellow
}

# 餘額門檻
$Threshold = if ($env:DEEPSEEK_BALANCE_THRESHOLD) { $env:DEEPSEEK_BALANCE_THRESHOLD } else { "1.0" }
Write-Host "   📌 餘額告警門檻：¥$Threshold" -ForegroundColor Gray

Write-Host ""

# ============================================================
# 4. 檢查必要檔案
# ============================================================

Write-Host "📂 檢查必要檔案：" -ForegroundColor Yellow

$RequiredFiles = @(
    "ahpal-master.ps1",
    "backup-system.ps1",
    "check-articles.ps1",
    "check-all.ps1",
    "generate-games.ps1"
)

foreach ($file in $RequiredFiles) {
    $filePath = Join-Path $ScriptDir $file
    if (Test-Path $filePath) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file（找不到）" -ForegroundColor Red
    }
}

Write-Host ""

# ============================================================
# 5. 時段判斷
# ============================================================

$currentHour = (Get-Date).Hour
if ($currentHour -ge 9 -and $currentHour -lt 18) {
    Write-Host "⏰ 當前為尖峰時段（09:00-18:00）" -ForegroundColor Yellow
    if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY -ne "YOUR_GEMINI_API_KEY") {
        Write-Host "   ✅ 建議使用 Gemini 生成文章" -ForegroundColor Green
    }
} else {
    Write-Host "⏰ 當前為離峰時段（18:00-09:00）" -ForegroundColor Green
    if ($env:DEEPSEEK_API_KEY -and $env:DEEPSEEK_API_KEY -ne "YOUR_DEEPSEEK_API_KEY") {
        Write-Host "   ✅ 建議使用 DeepSeek 生成文章（成本低、速度快）" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "✅ 環境設定完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📌 下一步：執行 .\ahpal-master.ps1 開始生成文章" -ForegroundColor Yellow
Write-Host ""
