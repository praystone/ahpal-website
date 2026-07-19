# ============================================================
# 雅寶社區 · 頂客論壇 - 備用設定檔
# ============================================================
# 功能：提供備用的環境設定（當 ahpal-static.ps1 無法使用時）
# 注意：此檔案為備用方案，主要設定請使用 ahpal-static.ps1
# ============================================================

# ============================================================
# 1. Gemini API Key（尖峰時段使用）
# ============================================================
# 請至 https://aistudio.google.com/apikey 取得
# 格式必須是 AIzaSy 開頭
$env:GEMINI_API_KEY = "YOUR_GEMINI_API_KEY"

# ============================================================
# 2. 輸出目錄設定
# ============================================================
$OUTPUT_DIR = "C:\Users\User\ahpal-static"
$PROJECT_NAME = "ahpal-pages"

# ============================================================
# 3. 顯示載入狀態
# ============================================================
Write-Host "✅ 載入備用設定 (config.ps1)" -ForegroundColor Green

if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY -ne "YOUR_GEMINI_API_KEY") {
    $masked = $env:GEMINI_API_KEY.Substring(0, 6) + "..." + $env:GEMINI_API_KEY.Substring($env:GEMINI_API_KEY.Length - 4)
    Write-Host "   🔑 Gemini API Key 已設定：$masked" -ForegroundColor Cyan
} else {
    Write-Host "   ⚠️ Gemini API Key 未設定（請填入實際金鑰）" -ForegroundColor Yellow
}

Write-Host "   📁 輸出目錄：$OUTPUT_DIR" -ForegroundColor Cyan
Write-Host "   📁 專案名稱：$PROJECT_NAME" -ForegroundColor Cyan
Write-Host ""