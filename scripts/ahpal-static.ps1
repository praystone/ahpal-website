# ============================================================
# 雅寶社區 · 頂客論壇 - 環境設定檔 v3.0
# ============================================================
# 功能：設定所有環境變數（API Key、路徑等）
# 用法：.\ahpal-static.ps1
# ============================================================

Write-Host "🔧 載入環境設定..." -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1. 設定 API Key（尖峰時段使用 Gemini，離峰使用 DeepSeek）
# ============================================================

# Google Gemini API Key（尖峰時段使用）
# 格式必須是 AIzaSy 開頭，請至 https://aistudio.google.com/apikey 取得
if (-not $env:GEMINI_API_KEY) {
    # ⚠️ 請將下方金鑰替換為你的 Gemini API Key（AIzaSy 開頭）
    $env:GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"
    Write-Host "   🔑 Gemini API Key 已設定" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ Gemini API Key 已存在" -ForegroundColor Gray
}

# DeepSeek API Key（離峰時段使用）
# 格式必須是 sk- 開頭，請至 https://platform.deepseek.com/ 取得
if (-not $env:DEEPSEEK_API_KEY) {
    # ⚠️ 請將下方金鑰替換為你的 DeepSeek API Key（sk- 開頭）
    $env:DEEPSEEK_API_KEY = "YOUR_DEEPSEEK_API_KEY"
    Write-Host "   🔑 DeepSeek API Key 已設定" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ DeepSeek API Key 已存在" -ForegroundColor Gray
}

Write-Host ""

# ============================================================
# 2. 設定輸出目錄
# ============================================================

# 使用腳本所在目錄下的 ahpal-static 資料夾
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

$env:AHPAL_OUTPUT_DIR = Join-Path $ScriptDir "ahpal-static"

# 確保目錄存在
if (-not (Test-Path $env:AHPAL_OUTPUT_DIR)) {
    New-Item -ItemType Directory -Path $env:AHPAL_OUTPUT_DIR -Force | Out-Null
    Write-Host "   📁 已建立輸出目錄" -ForegroundColor Green
}

Write-Host "   📁 輸出目錄：$($env:AHPAL_OUTPUT_DIR)" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 3. 顯示環境狀態摘要
# ============================================================

Write-Host "📊 環境狀態摘要：" -ForegroundColor Yellow
Write-Host ""

# Gemini API Key 狀態
if ($env:GEMINI_API_KEY) {
    if ($env:GEMINI_API_KEY -match "^AIzaSy") {
        $masked = $env:GEMINI_API_KEY.Substring(0, 6) + "..." + $env:GEMINI_API_KEY.Substring($env:GEMINI_API_KEY.Length - 4)
        Write-Host "   ✅ Gemini API Key：$masked" -ForegroundColor Green
        Write-Host "   📌 用途：尖峰時段（09:00-18:00）" -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️ Gemini API Key 格式錯誤！應以 AIzaSy 開頭" -ForegroundColor Yellow
        Write-Host "   📌 請至 https://aistudio.google.com/apikey 重新取得" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ Gemini API Key：未設定" -ForegroundColor Red
}

# DeepSeek API Key 狀態
if ($env:DEEPSEEK_API_KEY) {
    if ($env:DEEPSEEK_API_KEY -match "^sk-") {
        $masked = $env:DEEPSEEK_API_KEY.Substring(0, 6) + "..." + $env:DEEPSEEK_API_KEY.Substring($env:DEEPSEEK_API_KEY.Length - 4)
        Write-Host "   ✅ DeepSeek API Key：$masked" -ForegroundColor Green
        Write-Host "   📌 用途：離峰時段（18:00-09:00）" -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️ DeepSeek API Key 格式錯誤！應以 sk- 開頭" -ForegroundColor Yellow
        Write-Host "   📌 請至 https://platform.deepseek.com/ 重新取得" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ DeepSeek API Key：未設定" -ForegroundColor Red
}

# 輸出目錄狀態
Write-Host "   📁 輸出目錄：$($env:AHPAL_OUTPUT_DIR)" -ForegroundColor Cyan

# 檢查輸出目錄是否存在
if (Test-Path $env:AHPAL_OUTPUT_DIR) {
    $fileCount = (Get-ChildItem -Path $env:AHPAL_OUTPUT_DIR -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-Host "   📄 目錄中檔案數量：$fileCount 個" -ForegroundColor Gray
} else {
    Write-Host "   ⚠️ 輸出目錄尚不存在，將在執行時自動建立" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# 4. 檢查必要檔案是否存在
# ============================================================

Write-Host "📂 檢查必要檔案：" -ForegroundColor Yellow

$RequiredFiles = @(
    "ahpal-master.ps1",
    "ahpal_generator.py",
    "add_articles.ps1",
    "backup-system.ps1",
    "check-articles.ps1"
)

$MissingFiles = @()
foreach ($file in $RequiredFiles) {
    $filePath = Join-Path $ScriptDir $file
    if (Test-Path $filePath) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file（找不到）" -ForegroundColor Red
        $MissingFiles += $file
    }
}

if ($MissingFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "   ⚠️ 下列檔案缺失，可能影響系統運作：" -ForegroundColor Yellow
    foreach ($file in $MissingFiles) {
        Write-Host "      - $file" -ForegroundColor Gray
    }
}

Write-Host ""

# ============================================================
# 5. 顯示時段與 API 使用建議
# ============================================================

$currentHour = (Get-Date).Hour
if ($currentHour -ge 9 -and $currentHour -lt 18) {
    Write-Host "⏰ 當前為尖峰時段（09:00-18:00）" -ForegroundColor Yellow
    if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY -match "^AIzaSy") {
        Write-Host "   ✅ Gemini API Key 已設定，可使用 Gemini" -ForegroundColor Green
        Write-Host "   💡 建議使用 Gemini 生成文章（速度穩定）" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️ Gemini API Key 未設定或格式錯誤" -ForegroundColor Yellow
        Write-Host "   💡 建議等待 18:00 後使用 DeepSeek（離峰時段）" -ForegroundColor Cyan
    }
} else {
    Write-Host "⏰ 當前為離峰時段（18:00-09:00）" -ForegroundColor Green
    if ($env:DEEPSEEK_API_KEY -and $env:DEEPSEEK_API_KEY -match "^sk-") {
        Write-Host "   ✅ DeepSeek API Key 已設定，可使用 DeepSeek" -ForegroundColor Green
        Write-Host "   💡 建議使用 DeepSeek 生成文章（成本低、速度快）" -ForegroundColor Cyan
    } else {
        Write-Host "   ⚠️ DeepSeek API Key 未設定或格式錯誤" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "✅ 環境設定完成！" -ForegroundColor Green
Write-Host ""

# ============================================================
# 6. 返回主選單提示
# ============================================================
Write-Host "📌 下一步：執行 .\ahpal-master.ps1 開始生成文章" -ForegroundColor Yellow
Write-Host ""
