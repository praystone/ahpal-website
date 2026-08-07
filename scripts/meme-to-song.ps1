# ============================================================
# meme-to-song.ps1 - 一鍵迷因轉歌曲文章 v1.0
# ============================================================
# 功能：將 PTT/Dcard/時事迷因自動轉為音樂文章 + Suno 歌曲
# 用法：
#   .\scripts\meme-to-song.ps1 -Meme "打工人心酸語錄" -Source "PTT"
#   .\scripts\meme-to-song.ps1 -Meme "颱風假廢文" -Source "Dcard" -GenerateAudio
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Meme,              # 迷因/時事主題
    [string]$Source = "網路迷因", # 來源（PTT / Dcard / 時事）
    [switch]$GenerateAudio,     # 是否自動生成 Suno 音訊（需 Suno API）
    [switch]$DryRun,            # 預覽模式
    [switch]$Force              # 強制模式（跳過確認）
)

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# ============================================================
# 🎨 顏色輸出函數
# ============================================================

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}
function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }

# ============================================================
# 顯示標題
# ============================================================

Write-Info "============================================================"
Write-Info "  🎵 迷因轉歌曲 — 一鍵自動化產線 v1.0"
Write-Info "============================================================"
Write-Host ""
Write-Info "📌 主題：$Meme"
Write-Info "📌 來源：$Source"
if ($GenerateAudio) { Write-Info "🎵 自動生成音訊：啟用" }
if ($DryRun) { Write-Warning "🔍 預覽模式：僅顯示將要執行的操作" }
Write-Host ""

# ============================================================
# 步驟 1：產生文章關鍵字與 JSON
# ============================================================

Write-Info "[1/5] 產生文章關鍵字..."

# 從迷因主題產生安全的檔案名稱
$safeName = $Meme -replace '[^a-zA-Z0-9\u4e00-\u9fa5]', '' -replace '\s+', '-' -replace '-+', '-'
$safeName = $safeName.Trim('-')
if ([string]::IsNullOrEmpty($safeName)) {
    $safeName = "meme-song-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$keyword = "$Meme 原創歌曲 迷因改編"
$filename = "music/$safeName.html"

Write-Success "   ✅ 關鍵字：$keyword"
Write-Success "   ✅ 檔案名稱：$filename"

# ============================================================
# 步驟 2：檢查現有文章（避免重複）
# ============================================================

Write-Info ""
Write-Info "[2/5] 檢查是否已存在..."

$ProjectRoot = "C:\Users\User\ahpal-static"
$filePath = Join-Path $ProjectRoot $filename

if (Test-Path $filePath) {
    $fileSize = (Get-Item $filePath).Length
    if ($fileSize -ge 5120) {
        Write-Warning "   ⚠️ 文章已存在：$filename（$([math]::Round($fileSize/1KB,2)) KB）"
        if (-not $Force) {
            $confirm = Read-Host "是否跳過？(y/n)"
            if ($confirm -eq "y") {
                Write-Warning "已跳過"
                exit 0
            }
        }
    }
}

# ============================================================
# 步驟 3：建立 JSON 檔案
# ============================================================

Write-Info ""
Write-Info "[3/5] 建立 JSON 待產清單..."

$jsonContent = @"
[
    {
        "keyword": "$keyword",
        "category": "🎵 音樂創作",
        "filename": "$filename",
        "meme_source": "$Source - $Meme",
        "use_responses_api": true,
        "enable_reasoning": true,
        "enable_search": false
    }
]
"@

$jsonPath = Join-Path $ProjectRoot "data\pending-articles.json"

# 讀取現有 JSON（如果存在）
if (Test-Path $jsonPath) {
    try {
        $existing = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $newItems = $jsonContent | ConvertFrom-Json
        $allItems = $existing + $newItems
        $jsonContent = $allItems | ConvertTo-Json -Depth 10
    } catch {
        # JSON 解析失敗，直接覆蓋
        Write-Warning "   ⚠️ 現有 JSON 解析失敗，將覆蓋"
    }
}

if ($DryRun) {
    Write-Info "   🔍 預覽 JSON 內容："
    Write-Host $jsonContent -ForegroundColor Gray
    Write-Host ""
    Write-Warning "🔍 預覽模式完成，請移除 -DryRun 實際執行"
    exit 0
}

# 寫入 JSON（UTF-8 無 BOM）
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($jsonPath, $jsonContent, $utf8)
Write-Success "   ✅ JSON 已寫入：$jsonPath"

# ============================================================
# 步驟 4：執行文章生成
# ============================================================

Write-Info ""
Write-Info "[4/5] 執行文章生成..."

$confirm = Read-Host "是否立即生成文章？(y/n)"
if ($confirm -ne "y") {
    Write-Warning "已跳過文章生成，請手動執行："
    Write-Gray "   python src/main.py --force deepseek"
    Write-Gray "   .\scripts\ahpal-master.ps1 → [6]"
    exit 0
}

# 執行 add-articles.ps1
Write-Info "   📝 執行 add-articles.ps1..."
& "$ProjectRoot\scripts\add-articles.ps1" -Force

# 執行文章生成
Write-Info "   🤖 生成文章..."
python -c @"
from src.article_generator import generate_article
import json

with open('$jsonPath', 'r', encoding='utf-8') as f:
    items = json.load(f)

for item in items:
    if '$keyword' in item['keyword']:
        generate_article(item)
        break
"@

if ($LASTEXITCODE -ne 0) {
    Write-Error "   ❌ 文章生成失敗"
    exit 1
}

Write-Success "   ✅ 文章生成完成"

# ============================================================
# 步驟 5：生成 Suno 音訊（選用）
# ============================================================

if ($GenerateAudio) {
    Write-Info ""
    Write-Info "[5/5] 生成 Suno 音訊..."
    
    # 檢查 Suno API 是否可用
    $SunoApiKey = $env:SUNO_API_KEY
    if (-not $SunoApiKey) {
        Write-Warning "   ⚠️ SUNO_API_KEY 未設定，跳過音訊生成"
        Write-Gray "   💡 請在 .env 中設定 SUNO_API_KEY"
    } else {
        Write-Info "   🎵 呼叫 Suno API 生成歌曲..."
        Write-Gray "   📌 主題：$Meme"
        
        # 此處需要實際 Suno API 整合
        # TODO: 整合 Suno API
        Write-Warning "   ⚠️ Suno API 整合功能開發中..."
        Write-Gray "   💡 請手動至 https://suno.com 生成音訊"
    }
}

# ============================================================
# 完成摘要
# ============================================================

Write-Info ""
Write-Info "============================================================"
Write-Success "✅ 迷因轉歌曲完成！"
Write-Info "============================================================"
Write-Host ""

Write-Info "📊 摘要："
Write-Info "   ├─ 主題：$Meme"
Write-Info "   ├─ 來源：$Source"
Write-Info "   ├─ 文章：$filename"
Write-Success "   └─ 狀態：✅ 已生成"

Write-Host ""
Write-Info "📌 下一步："
Write-Gray "   .\scripts\ahpal-master.ps1 → [6] 部署上線"
Write-Gray "   https://www.ahpal.com/$filename 查看文章"

Write-Host ""
Read-Host "按 Enter 鍵結束"