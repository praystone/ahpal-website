# ============================================================
# 雅寶社區 · 頂客論壇 - 備用設定檔 v3.5 (完善版)
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
# 3. 補上 Global 變數（讓 check-all.ps1 / backup-system.ps1 能正確讀取）
# ============================================================
$Global:ProjectRoot = $OUTPUT_DIR
$Global:OutputDir = $OUTPUT_DIR

# 分類目錄映射（含 9 大分類）
$Global:CategoryDirs = @{
    "history"    = "📜 歷史腦洞"
    "tech"       = "💻 3C 科技教學"
    "game"       = "🎮 遊戲攻略"
    "life"       = "🏠 生活小常識"
    "review"     = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend"      = "🤖 AI 趨勢"
    "music"      = "🎵 音樂創作"
    "nature"     = "🌳 動植物生態"
}

# 分類頁面清單（自動產生）
$Global:CategoryPages = $Global:CategoryDirs.Keys | ForEach-Object { "category-$_.html" }

# 品質門檻
$Global:MinFileSize = 5120        # 5KB 以下視為異常
$Global:MinWords = 1200           # 最少字數
$Global:QualityThreshold = 60     # 品質及格分數

# 備份保留數量
$Global:BackupKeepCount = 5
$Global:GoldenBackupKeepCount = 3

# ============================================================
# 4. 顯示載入狀態
# ============================================================
Write-Host "✅ 載入備用設定 (config.ps1 v3.5)" -ForegroundColor Green

if ($env:GEMINI_API_KEY -and $env:GEMINI_API_KEY -ne "YOUR_GEMINI_API_KEY") {
    $masked = $env:GEMINI_API_KEY.Substring(0, 6) + "..." + $env:GEMINI_API_KEY.Substring($env:GEMINI_API_KEY.Length - 4)
    Write-Host "   🔑 Gemini API Key 已設定：$masked" -ForegroundColor Cyan
} else {
    Write-Host "   ⚠️ Gemini API Key 未設定（請填入實際金鑰）" -ForegroundColor Yellow
}

Write-Host "   📁 輸出目錄：$OUTPUT_DIR" -ForegroundColor Cyan
Write-Host "   📁 專案名稱：$PROJECT_NAME" -ForegroundColor Cyan
Write-Host "   📂 分類數量：$($Global:CategoryDirs.Count) 類" -ForegroundColor Cyan
Write-Host ""