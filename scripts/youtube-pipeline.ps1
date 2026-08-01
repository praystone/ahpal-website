# ============================================================
# AHPAL 影音自動化管線 (youtube-pipeline.ps1) v1.0
# ============================================================
param (
    [string]$NotebookId = "9844f371-19ba-4f10-aa33-8dc7b40a41f8",
    [string]$ArticlePath = "",
    [string]$OutputDir = "C:\Users\User\ahpal-static\audio",
    [string]$OutputFilename = "podcast.wav"
)

# 檢查必要參數
if (-not $ArticlePath) {
    Write-Host "❌ 錯誤：請指定 -ArticlePath 參數" -ForegroundColor Red
    Write-Host "📌 範例：.\scripts\youtube-pipeline.ps1 -ArticlePath 'tech\3d-printer-guide-2026.html'" -ForegroundColor Yellow
    exit 1
}

Write-Host "🦞 AHPAL 影音自動化管線啟動" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Gray
Write-Host "📌 文章路徑：$ArticlePath" -ForegroundColor Gray
Write-Host ""

# 1. 設定 Notebook 上下文
Write-Host "🤖 [1/5] 設定 Notebook 上下文..."
notebooklm use $NotebookId
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 設定 Notebook 失敗" -ForegroundColor Red
    exit 1
}

# 2. 讀取文章內容並新增來源
Write-Host "📄 [2/5] 讀取文章內容..."
if (-not (Test-Path $ArticlePath)) {
    Write-Host "❌ 找不到文章檔案：$ArticlePath" -ForegroundColor Red
    exit 1
}

$fileName = [System.IO.Path]::GetFileNameWithoutExtension($ArticlePath)
$title = $fileName -replace "-", " "

Write-Host "📤 新增來源至 Notebook：$title"
Get-Content $ArticlePath -Raw -Encoding UTF8 | notebooklm source add --type text --title $title
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 新增來源失敗" -ForegroundColor Red
    exit 1
}

# 3. 觸發音訊生成
Write-Host "🎧 [3/5] 觸發音訊生成..."
$jobOutput = notebooklm generate audio
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 觸發音訊生成失敗 (可能配額已用盡)" -ForegroundColor Red
    exit 1
}
$jobId = ($jobOutput -split ": ")[1].Trim()
Write-Host "📌 任務 ID：$jobId"

# 4. 等待生成完成
Write-Host "⏳ [4/5] 等待生成完成..."
notebooklm artifact wait $jobId
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 等待任務完成失敗" -ForegroundColor Red
    exit 1
}

# 5. 確認任務狀態
Write-Host "📊 確認任務狀態..."
$status = notebooklm artifact get $jobId --json
Write-Host $status

# 6. 下載音訊檔案
Write-Host "📥 [5/5] 下載音訊檔案..."
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$outputFile = Join-Path $OutputDir $OutputFilename
notebooklm download audio -a $jobId $outputFile
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 下載音訊檔案失敗" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ 影音自動化管線執行完畢！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "📌 音訊檔案：$outputFile" -ForegroundColor Gray
Write-Host "📌 下一步：執行 .\scripts\ahpal-master.ps1 選擇 [6] 部署" -ForegroundColor Yellow
