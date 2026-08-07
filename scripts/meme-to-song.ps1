# ============================================================
# meme-to-song.ps1 - 一鍵迷因轉歌曲文章 v1.2
# ============================================================
# 功能：將 PTT/Dcard/時事迷因自動轉為音樂文章 + Suno 歌曲
# 修復：
#   - 🔧 強制英文檔名（符合董事長死命令）
#   - 🔧 加入錯誤處理與退出碼
#   - 🆕 加入執行日誌
#   - 🆕 -GenerateAudio 整合 Suno API（預留）
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Meme,              # 迷因/時事主題
    [string]$Source = "網路迷因", # 來源（PTT / Dcard / 時事）
    [switch]$GenerateAudio,     # 是否自動生成 Suno 音訊
    [switch]$DryRun,            # 預覽模式
    [switch]$Force              # 強制模式（跳過確認）
)

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

# ============================================================
# 顏色輸出函數
# ============================================================

function Write-ColorOutput { param([string]$Message, [string]$Color = "White") Write-Host $Message -ForegroundColor $Color }
function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }

# ============================================================
# 開始執行
# ============================================================

Write-Info "============================================================"
Write-Info "  🎵 迷因轉歌曲 — 一鍵自動化產線 v1.2"
Write-Info "============================================================"
Write-Host ""
Write-Info "📌 主題：$Meme"
Write-Info "📌 來源：$Source"
if ($GenerateAudio) { Write-Info "🎵 自動生成音訊：啟用" }
if ($DryRun) { Write-Warning "🔍 預覽模式：僅顯示將要執行的操作" }
Write-Host ""

# ============================================================
# [1/5] 產生關鍵字與檔名（強制英文）
# ============================================================

Write-Info "[1/5] 產生文章關鍵字..."

# 強制轉為英文檔名（移除所有中文與特殊字元）
$safeName = $Meme -replace '[^a-zA-Z0-9\s]', '' -replace '\s+', '-'
$safeName = $safeName.Trim('-')
if ([string]::IsNullOrEmpty($safeName) -or $safeName -match '[^a-zA-Z0-9-]') {
    $safeName = "meme-song-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}
$safeName = $safeName.ToLower()

$keyword = "$Meme 原創歌曲 迷因改編"
$filename = "music/$safeName.html"

Write-Success "   ✅ 關鍵字：$keyword"
Write-Success "   ✅ 檔案名稱：$filename (英文)"

# ============================================================
# [2/5] 檢查重複
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
# [3/5] 寫入 JSON（UTF-8 無 BOM）
# ============================================================

Write-Info ""
Write-Info "[3/5] 寫入 JSON 待產清單..."
$jsonPath = Join-Path $ProjectRoot "data\pending-articles.json"

if ($DryRun) {
    Write-Info "   🔍 預覽模式：準備將 [$keyword] 寫入 $jsonPath"
    exit 0
}

python -c "
import json, os

json_path = r'$jsonPath'
new_item = {
    'keyword': '''$keyword''',
    'category': '🎵 音樂創作',
    'filename': '''$filename''',
    'meme_source': '''$Source - $Meme''',
    'use_responses_api': True,
    'enable_reasoning': True,
    'enable_search': False
}

items = []
if os.path.exists(json_path):
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            items = json.load(f)
    except Exception:
        items = []

items.append(new_item)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(items, f, ensure_ascii=False, indent=4)

print('   ✅ JSON 已安全追加 (UTF-8 無 BOM)')
"

if ($LASTEXITCODE -ne 0) {
    Write-Error "   ❌ JSON 寫入失敗"
    exit 1
}

# ============================================================
# [4/5] 執行文章生成
# ============================================================

Write-Info ""
Write-Info "[4/5] 執行文章生成..."

if (-not $Force) {
    $confirm = Read-Host "是否立即生成文章？(y/n)"
    if ($confirm -ne "y") {
        Write-Warning "已手動跳過，請後續執行：.\scripts\add-articles.ps1 -Force 且 python src/main.py --force deepseek"
        exit 0
    }
}

Write-Info "   🤖 正在生成文章：《$keyword》..."
python -c "
from src.article_generator import generate_article

item = {
    'keyword': '''$keyword''',
    'category': '🎵 音樂創作',
    'filename': '''$filename''',
    'use_responses_api': True,
    'enable_reasoning': True,
    'enable_search': False
}
generate_article(item)
"

if ($LASTEXITCODE -ne 0) {
    Write-Error "   ❌ 文章生成失敗"
    exit 1
}

# ============================================================
# 更新 main.py 與清空 JSON
# ============================================================

Write-Info "   📝 更新 main.py 與清空待產清單..."
& "$ProjectRoot\scripts\add-articles.ps1" -Force

if ($LASTEXITCODE -ne 0) {
    Write-Error "   ❌ add-articles.ps1 執行失敗"
    exit 1
}

Write-Success "   ✅ 文章生成與 main.py 更新完成！"

# ============================================================
# [5/5] Suno 音訊生成（預留整合）
# ============================================================

if ($GenerateAudio) {
    Write-Info ""
    Write-Info "[5/5] Suno 音訊生成..."
    
    $SunoApiKey = $env:SUNO_API_KEY
    if (-not $SunoApiKey) {
        Write-Warning "   ⚠️ SUNO_API_KEY 未設定，跳過音訊生成"
        Write-Info "   💡 請在 .env 中設定 SUNO_API_KEY"
    } else {
        Write-Info "   🎵 呼叫 Suno API 生成歌曲..."
        Write-Warning "   ⚠️ Suno API 整合功能開發中..."
        Write-Info "   💡 請手動至 https://suno.com 將《$Meme》改編歌詞輸入生成歌曲"
    }
}

# ============================================================
# 完成摘要
# ============================================================

Write-Host ""
Write-Info "============================================================"
Write-Success "✅ 迷因轉歌曲自動化流程完工！"
Write-Info "============================================================"
Write-Info "📊 摘要："
Write-Info "   ├─ 主題：$Meme"
Write-Info "   ├─ 來源：$Source"
Write-Info "   ├─ 文章：$filename"
Write-Info "   └─ 狀態：✅ 已生成"
Write-Host ""
Write-Info "📌 下一步："
Write-Gray "   .\scripts\ahpal-master.ps1 → 選擇 [6] 部署上線"
Write-Gray "   https://www.ahpal.com/$filename 查看文章"
Write-Host ""

exit 0# ============================================================
# meme-to-song.ps1 - 一鍵迷因轉歌曲文章 v1.1 (穩定修復版)
# ============================================================
# 功能：將 PTT/Dcard/時事迷因自動轉為音樂文章 + Suno 歌曲
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$Meme,              # 迷因/時事主題
    [string]$Source = "網路迷因", # 來源（PTT / Dcard / 時事）
    [switch]$GenerateAudio,     # 是否自動生成 Suno 音訊
    [switch]$DryRun,            # 預覽模式
    [switch]$Force              # 強制模式（跳過確認）
)

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "Stop"

function Write-ColorOutput { param([string]$Message, [string]$Color = "White") Write-Host $Message -ForegroundColor $Color }
function Write-Success { Write-ColorOutput $args[0] "Green" }
function Write-Info { Write-ColorOutput $args[0] "Cyan" }
function Write-Warning { Write-ColorOutput $args[0] "Yellow" }
function Write-Error { Write-ColorOutput $args[0] "Red" }

Write-Info "============================================================"
Write-Info "  🎵 迷因轉歌曲 — 一鍵自動化產線 v1.1"
Write-Info "============================================================"
Write-Host ""
Write-Info "📌 主題：$Meme"
Write-Info "📌 來源：$Source"
if ($GenerateAudio) { Write-Info "🎵 自動生成音訊：啟用" }
if ($DryRun) { Write-Warning "🔍 預覽模式：僅顯示將要執行的操作" }
Write-Host ""

# [1/5] 產生關鍵字與檔名
Write-Info "[1/5] 產生文章關鍵字..."
$safeName = $Meme -replace '[^a-zA-Z0-9\u4e00-\u9fa5]', '' -replace '\s+', '-' -replace '-+', '-'
$safeName = $safeName.Trim('-')
if ([string]::IsNullOrEmpty($safeName)) {
    $safeName = "meme-song-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

$keyword = "$Meme 原創歌曲 迷因改編"
$filename = "music/$safeName.html"

Write-Success "   ✅ 關鍵字：$keyword"
Write-Success "   ✅ 檔案名稱：$filename"

# [2/5] 檢查重複
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
            if ($confirm -eq "y") { exit 0 }
        }
    }
}

# [3/5] 使用 Python 寫入 JSON（100% Unicode / Emoji 安全追加）
Write-Info ""
Write-Info "[3/5] 寫入 JSON 待產清單..."
$jsonPath = Join-Path $ProjectRoot "data\pending-articles.json"

if ($DryRun) {
    Write-Info "   🔍 預覽模式：準備將 [$keyword] 寫入 $jsonPath"
    exit 0
}

python -c "
import json, os

json_path = r'$jsonPath'
new_item = {
    'keyword': '''$keyword''',
    'category': '🎵 音樂創作',
    'filename': '''$filename''',
    'meme_source': '''$Source - $Meme''',
    'use_responses_api': True,
    'enable_reasoning': True,
    'enable_search': False
}

items = []
if os.path.exists(json_path):
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            items = json.load(f)
    except Exception:
        items = []

items.append(new_item)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(items, f, ensure_ascii=False, indent=4)

print('   ✅ JSON 已安全追加 (UTF-8 無 BOM)')
"

# [4/5] 執行文章生成
Write-Info ""
Write-Info "[4/5] 執行文章生成..."

if (-not $Force) {
    $confirm = Read-Host "是否立即生成文章？(y/n)"
    if ($confirm -ne "y") {
        Write-Warning "已手動跳過，請後續執行：.\scripts\add-articles.ps1 -Force 且 python src/main.py --force deepseek"
        exit 0
    }
}

Write-Info "   🤖 正在生成文章：《$keyword》..."
python -c "
from src.article_generator import generate_article

item = {
    'keyword': '''$keyword''',
    'category': '🎵 音樂創作',
    'filename': '''$filename''',
    'use_responses_api': True,
    'enable_reasoning': True,
    'enable_search': False
}
generate_article(item)
"

if ($LASTEXITCODE -ne 0) {
    Write-Error "   ❌ 文章生成失敗"
    exit 1
}

Write-Info "   📝 更新 main.py 與清空待產清單..."
& "$ProjectRoot\scripts\add-articles.ps1" -Force

Write-Success "   ✅ 文章生成與 main.py 更新完成！"

# [5/5] Suno 音訊提示
if ($GenerateAudio) {
    Write-Info ""
    Write-Info "[5/5] Suno 音訊生成..."
    Write-Warning "   💡 請前往 https://suno.com 將《$Meme》改編歌詞輸入生成歌曲"
}

Write-Host ""
Write-Info "============================================================"
Write-Success "✅ 迷因轉歌曲自動化流程完工！"
Write-Info "============================================================"
Write-Info "📌 部署上線指令：.\scripts\ahpal-master.ps1 → 選擇 [6]"
Write-Host ""