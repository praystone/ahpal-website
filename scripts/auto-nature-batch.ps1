# ============================================================
# 🌳 動植物生態 100 篇 — SYSTEM 背景執行版
# ============================================================
# 用途：無人值守生成 100 篇動植物生態文章
# 執行方式：SYSTEM 帳戶 (背景執行，無視窗)
# 特色：
#   ✅ 100 篇完整文章清單 (動物/植物/生態)
#   ✅ 無人值守：自動完成 JSON 寫入 → 合併 → 生成 → 更新頁面 → 部署
#   ✅ 斷點續傳：已存在的文章自動跳過
#   ✅ 電源管理：執行期間防止睡眠
#   ✅ 錯誤通知：失敗時發送郵件
#   ✅ 雙重重試：生成失敗自動重試一次
# ============================================================

# ============================================================
# 🔧 電源管理
# ============================================================
$PowerCfgOriginal = (powercfg /getactivescheme) -replace '.*:\s+([a-f0-9-]+)\s+\(.*', '$1'
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
$env:PYTHONIOENCODING = "utf-8"

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# ============================================================
# 📝 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-nature-batch-100-$Timestamp.log"
$CheckpointFile = "$LogDir\nature-checkpoint.json"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

function Save-Checkpoint {
    param([string]$Stage, [string]$Detail = "")
    $checkpoint = @{
        stage = $Stage
        detail = $Detail
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    $checkpoint | ConvertTo-Json | Out-File $CheckpointFile -Encoding UTF8
}

function Send-ErrorNotification {
    param([string]$ErrorMsg)
    
    $EnvPath = "$ProjectRoot\.env"
    if (Test-Path $EnvPath) {
        Get-Content $EnvPath | ForEach-Object {
            if ($_ -match '^SMTP_USER=(.+)$') { $SmtpUser = $Matches[1] }
            if ($_ -match '^SMTP_PASS=(.+)$') { $SmtpPass = $Matches[1] }
            if ($_ -match '^SMTP_TO=(.+)$') { $ToEmail = $Matches[1] }
        }
    }
    
    if ($SmtpUser -and $SmtpPass -and $ToEmail) {
        try {
            $SmtpClient = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
            $SmtpClient.EnableSsl = $true
            $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPass)
            $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "❌ 動植物生態 100 篇批次生成失敗", $ErrorMsg)
            $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($MailMessage)
            Write-Log "📧 錯誤通知已發送"
        } catch {
            Write-Log "⚠️ 錯誤通知發送失敗: $($_.Exception.Message)"
        }
    }
}

Write-Log "============================================================"
Write-Log "🌳 動植物生態 100 篇 — SYSTEM 背景執行版"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 📋 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/4] 檢查 API Key..."
Save-Checkpoint -Stage "api_check"

$EnvPath = "$ProjectRoot\.env"
if (Test-Path $EnvPath) {
    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^DEEPSEEK_API_KEY=(.+)$') {
            [Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $Matches[1])
            Write-Log "✅ DEEPSEEK_API_KEY 已從 .env 載入"
        }
    }
}

$DeepSeekKey = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY")
if (-not $DeepSeekKey) {
    Write-Log "❌ 錯誤：無法載入 DEEPSEEK_API_KEY"
    Send-ErrorNotification -ErrorMsg "無法載入 DEEPSEEK_API_KEY，請檢查 .env"
    exit 1
}
Write-Log "✅ API Key 檢查通過"

# ============================================================
# 📝 步驟 2：★ 100 篇文章清單 ★
# ============================================================
Write-Log "[2/4] 準備 100 篇文章清單..."

$Articles = @(
    # ============================================================
    # 🐾 動物類 (40篇) — 全新主題
    # ============================================================
    @{ keyword = "台灣狐蝠生態與保育現況"; filename = "taiwan-flying-fox-conservation.html" },
    @{ keyword = "台灣黃喉貂生態觀察"; filename = "taiwan-yellow-throated-marten.html" },
    @{ keyword = "台灣麝香貓生態與棲地"; filename = "taiwan-masked-palm-civet.html" },
    @{ keyword = "台灣水獺保育與復育計畫"; filename = "taiwan-otter-conservation.html" },
    @{ keyword = "台灣赤腹松鼠生態與都市適應"; filename = "taiwan-red-bellied-squirrel.html" },
    @{ keyword = "台灣刺鼠生態與農田關係"; filename = "taiwan-spiny-rat-ecology.html" },
    @{ keyword = "台灣鼴鼠生態與地下生活"; filename = "taiwan-mole-ecology.html" },
    @{ keyword = "台灣鯪鯉（穿山甲）習性深度解析"; filename = "taiwan-pangolin-behavior.html" },
    @{ keyword = "台灣八哥生態與都市棲地"; filename = "taiwan-crested-myna.html" },
    @{ keyword = "台灣藍腹鷴生態與繁殖"; filename = "taiwan-blue-pheasant.html" },
    @{ keyword = "台灣帝雉生態與保育"; filename = "taiwan-mikado-pheasant.html" },
    @{ keyword = "台灣環頸雉生態與農田棲息"; filename = "taiwan-ring-necked-pheasant.html" },
    @{ keyword = "台灣黑面琵鷺遷徙與棲地保護"; filename = "taiwan-black-faced-spoonbill.html" },
    @{ keyword = "台灣白鷺鷥生態與濕地"; filename = "taiwan-egret-ecology.html" },
    @{ keyword = "台灣夜鷺生態與都市河流"; filename = "taiwan-night-heron.html" },
    @{ keyword = "台灣小鷿鷉生態與湖泊"; filename = "taiwan-little-grebe.html" },
    @{ keyword = "台灣魚鷹生態與溪流狩獵"; filename = "taiwan-osprey-ecology.html" },
    @{ keyword = "台灣黑鳶生態與都市適應"; filename = "taiwan-black-kite.html" },
    @{ keyword = "台灣遊隼生態與懸崖棲地"; filename = "taiwan-peregrine-falcon.html" },
    @{ keyword = "台灣紅隼生態與農田狩獵"; filename = "taiwan-common-kestrel.html" },
    @{ keyword = "台灣領角鴞生態與都市夜間"; filename = "taiwan-collared-scops-owl.html" },
    @{ keyword = "台灣黃嘴角鴞生態與森林"; filename = "taiwan-mountain-scops-owl.html" },
    @{ keyword = "台灣褐鷹鴞生態與夜間狩獵"; filename = "taiwan-brown-hawk-owl.html" },
    @{ keyword = "台灣大冠鷲生態與森林棲地"; filename = "taiwan-crested-serpent-eagle.html" },
    @{ keyword = "台灣鳳頭蒼鷹生態與都市狩獵"; filename = "taiwan-crested-goshawk.html" },
    @{ keyword = "台灣松雀鷹生態與森林"; filename = "taiwan-besra-ecology.html" },
    @{ keyword = "台灣赤腹鷹遷徙與生態"; filename = "taiwan-chinese-goshawk.html" },
    @{ keyword = "台灣灰面鵟鷹遷徙生態"; filename = "taiwan-gray-faced-buzzard.html" },
    @{ keyword = "台灣蛇鵰生態與蛇類捕食"; filename = "taiwan-snake-eagle.html" },
    @{ keyword = "台灣熊鷹生態與原始森林"; filename = "taiwan-hawk-eagle.html" },
    @{ keyword = "台灣翡翠（翠鳥）生態與溪流"; filename = "taiwan-kingfisher-ecology.html" },
    @{ keyword = "台灣五色鳥繁殖生態"; filename = "taiwan-barbet-breeding.html" },
    @{ keyword = "台灣小啄木生態與森林"; filename = "taiwan-grey-capped-pygmy-woodpecker.html" },
    @{ keyword = "台灣綠鳩生態與果樹"; filename = "taiwan-green-pigeon.html" },
    @{ keyword = "台灣紅鳩生態與農田"; filename = "taiwan-red-turtle-dove.html" },
    @{ keyword = "台灣金背鳩生態與都市"; filename = "taiwan-oriental-turtle-dove.html" },
    @{ keyword = "台灣麻雀生態與都市適應"; filename = "taiwan-tree-sparrow-ecology.html" },
    @{ keyword = "台灣白頭翁生態與都市"; filename = "taiwan-light-vented-bulbul.html" },
    @{ keyword = "台灣紅嘴黑鵯生態與果園"; filename = "taiwan-black-bulbul.html" },
    @{ keyword = "台灣綠繡眼生態與都市花園"; filename = "taiwan-japanese-white-eye.html" },

    # ============================================================
    # 🌿 植物類 (30篇) — 全新主題
    # ============================================================
    @{ keyword = "台灣原生杜鵑種類與賞花指南"; filename = "taiwan-native-rhododendron-species.html" },
    @{ keyword = "台灣馬兜鈴生態與保育"; filename = "taiwan-aristolochia-ecology.html" },
    @{ keyword = "台灣牛樟生態與復育"; filename = "taiwan-stout-camphor-tree.html" },
    @{ keyword = "台灣相思樹生態與應用"; filename = "taiwan-acacia-ecology.html" },
    @{ keyword = "台灣苦楝樹生態與文化"; filename = "taiwan-chinaberry-tree.html" },
    @{ keyword = "台灣茄苳樹生態與古樹保護"; filename = "taiwan-bishop-wood.html" },
    @{ keyword = "台灣九芎生態與水土保持"; filename = "taiwan-crepe-myrtle-ecology.html" },
    @{ keyword = "台灣烏心石生態與木材應用"; filename = "taiwan-michelia-ecology.html" },
    @{ keyword = "台灣樟樹生態與精油應用"; filename = "taiwan-camphor-tree-ecology.html" },
    @{ keyword = "台灣檜木林生態與保育"; filename = "taiwan-cypress-forest-ecology.html" },
    @{ keyword = "台灣鐵杉生態與高山生態系"; filename = "taiwan-hemlock-ecology.html" },
    @{ keyword = "台灣雲杉生態與高山森林"; filename = "taiwan-spruce-forest-ecology.html" },
    @{ keyword = "台灣冷杉生態與高山苔原"; filename = "taiwan-fir-ecology.html" },
    @{ keyword = "台灣高山箭竹生態與動物棲地"; filename = "taiwan-alpine-bamboo-ecology.html" },
    @{ keyword = "台灣黃藤生態與原住民應用"; filename = "taiwan-rattan-ecology.html" },
    @{ keyword = "台灣山蘇花生態與附生"; filename = "taiwan-bird-nest-fern.html" },
    @{ keyword = "台灣筆筒樹生態與保育"; filename = "taiwan-tree-fern-ecology.html" },
    @{ keyword = "台灣觀音座蓮生態與保育"; filename = "taiwan-angiopteris-ecology.html" },
    @{ keyword = "台灣海金沙生態與海濱"; filename = "taiwan-climbing-fern.html" },
    @{ keyword = "台灣石松生態與低海拔森林"; filename = "taiwan-lycopodium-ecology.html" },
    @{ keyword = "台灣月桃生態與民俗植物"; filename = "taiwan-alpinia-ecology.html" },
    @{ keyword = "台灣野薑花生態與濕地"; filename = "taiwan-ginger-lily.html" },
    @{ keyword = "台灣金花石蒜生態與海濱"; filename = "taiwan-spider-lily.html" },
    @{ keyword = "台灣台灣杜鵑花季與賞花"; filename = "taiwan-rhododendron-season.html" },
    @{ keyword = "台灣玉山杜鵑生態與高山"; filename = "taiwan-yushan-rhododendron-ecology.html" },
    @{ keyword = "台灣台灣澤蘭生態與中海拔"; filename = "taiwan-taiwan-ageratum.html" },
    @{ keyword = "台灣台灣馬藍生態與溪谷"; filename = "taiwan-strobilanthes-ecology.html" },
    @{ keyword = "台灣台灣紅豆杉生態與保育"; filename = "taiwan-yew-ecology.html" },
    @{ keyword = "台灣台灣火刺木生態與都市綠化"; filename = "taiwan-firethorn-ecology.html" },
    @{ keyword = "台灣台灣桂花生態與文化"; filename = "taiwan-osmanthus-ecology.html" },

    # ============================================================
    # 🌍 生態/環境類 (30篇) — 全新主題
    # ============================================================
    @{ keyword = "台灣陸域生態系完整介紹"; filename = "taiwan-terrestrial-ecosystem.html" },
    @{ keyword = "台灣水域生態系完整介紹"; filename = "taiwan-aquatic-ecosystem.html" },
    @{ keyword = "台灣海岸生態系完整介紹"; filename = "taiwan-coastal-ecosystem.html" },
    @{ keyword = "台灣低海拔生態與生物多樣性"; filename = "taiwan-lowland-ecology.html" },
    @{ keyword = "台灣中海拔生態與霧林帶"; filename = "taiwan-mid-altitude-ecology.html" },
    @{ keyword = "台灣高海拔生態與寒原"; filename = "taiwan-high-altitude-ecology.html" },
    @{ keyword = "台灣溪流生態系與指標生物"; filename = "taiwan-stream-ecosystem-indicators.html" },
    @{ keyword = "台灣湖泊生態系與特有生物"; filename = "taiwan-lake-ecosystem.html" },
    @{ keyword = "台灣水庫生態與環境議題"; filename = "taiwan-reservoir-ecology.html" },
    @{ keyword = "台灣農田生態系與生物多樣性"; filename = "taiwan-farmland-ecosystem.html" },
    @{ keyword = "台灣都市生態系與綠色基礎設施"; filename = "taiwan-urban-ecosystem-infrastructure.html" },
    @{ keyword = "台灣生態廊道規劃與實踐"; filename = "taiwan-ecological-corridor-planning.html" },
    @{ keyword = "台灣生物多樣性保育策略"; filename = "taiwan-biodiversity-strategy.html" },
    @{ keyword = "台灣瀕危物種紅皮書與保育"; filename = "taiwan-red-list-conservation.html" },
    @{ keyword = "台灣外來種管理與移除策略"; filename = "taiwan-invasive-species-management.html" },
    @{ keyword = "台灣野生動物救援與醫療"; filename = "taiwan-wildlife-rescue-medical.html" },
    @{ keyword = "台灣野生動物路殺與生態廊道"; filename = "taiwan-roadkill-ecology.html" },
    @{ keyword = "台灣環境影響評估與生態檢核"; filename = "taiwan-eia-ecological-review.html" },
    @{ keyword = "台灣生態補償機制與實踐"; filename = "taiwan-ecological-compensation.html" },
    @{ keyword = "台灣森林認證與永續經營"; filename = "taiwan-forest-certification.html" },
    @{ keyword = "台灣海洋保護區與管理"; filename = "taiwan-marine-protected-areas.html" },
    @{ keyword = "台灣國家公園經營管理"; filename = "taiwan-national-park-management.html" },
    @{ keyword = "台灣自然保留區與生態保護"; filename = "taiwan-nature-reserve-ecology.html" },
    @{ keyword = "台灣生態旅遊永續發展"; filename = "taiwan-ecotourism-sustainability.html" },
    @{ keyword = "台灣環境教育與生態公民"; filename = "taiwan-environmental-education-citizen.html" },
    @{ keyword = "台灣原住民傳統生態知識"; filename = "taiwan-indigenous-ecological-knowledge.html" },
    @{ keyword = "台灣氣候變遷調適與生態"; filename = "taiwan-climate-adaptation-ecology.html" },
    @{ keyword = "台灣生態監測與公民科學"; filename = "taiwan-ecological-monitoring-citizen-science.html" },
    @{ keyword = "台灣里山倡議實踐案例"; filename = "taiwan-satoyama-practice.html" },
    @{ keyword = "台灣2050淨零與生態保育"; filename = "taiwan-net-zero-ecology.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 📂 步驟 3：檢查 nature/ 目錄 → 寫入 JSON → 合併
# ============================================================
Write-Log "[3/4] 檢查缺失文章並合併到 master-articles.json..."
Save-Checkpoint -Stage "merge"

$TargetDir = "$ProjectRoot\nature"
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Log "   📁 nature/ 目錄已建立"
}

# 建立子目錄
New-Item -ItemType Directory -Path "$TargetDir\animal" -Force | Out-Null
New-Item -ItemType Directory -Path "$TargetDir\plant" -Force | Out-Null
New-Item -ItemType Directory -Path "$TargetDir\ecology" -Force | Out-Null

$ExistingFiles = @()
if (Test-Path $TargetDir) {
    $ExistingFiles = Get-ChildItem "$TargetDir\*.html" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
}
Write-Log "   📄 已存在: $($ExistingFiles.Count) 篇"

$MissingArticles = @()
foreach ($article in $Articles) {
    if ($article.filename -notin $ExistingFiles) {
        $MissingArticles += $article
    }
}

if ($MissingArticles.Count -eq 0) {
    Write-Log "   ✅ 所有文章已存在，無需生成"
    Write-Log "============================================================"
    Write-Log "✅ 檢查完成！所有文章已存在"
    exit 0
}

Write-Log "   ⚠️ 缺失 $($MissingArticles.Count) 篇文章，準備生成..."
foreach ($article in $MissingArticles) {
    Write-Log "      📄 $($article.filename)"
}

# 寫入 pending-articles.json
$jsonContent = "[`n"
$first = $true
foreach ($article in $MissingArticles) {
    if (-not $first) { $jsonContent += "," }
    $first = $false
    $jsonContent += @"
  {
    "keyword": "$($article.keyword)",
    "category": "🌳 動植物生態",
    "filename": "nature/$($article.filename)",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  }
"@
}
$jsonContent += "`n]"

$PendingPath = "$ProjectRoot\data\pending-articles.json"
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($PendingPath, $jsonContent, $utf8NoBom)
Write-Log "   ✅ JSON 已寫入 ($($MissingArticles.Count) 篇，UTF-8 無 BOM)"

# 合併到 master-articles.json
$PyMergeScript = @'
import json, os, shutil
from datetime import datetime

project_root = r'C:\Users\User\ahpal-static'
pending_path = os.path.join(project_root, 'data', 'pending-articles.json')
master_path = os.path.join(project_root, 'data', 'master-articles.json')
backup_dir = os.path.join(project_root, 'backups', 'master-json')

os.makedirs(backup_dir, exist_ok=True)

if os.path.exists(master_path):
    ts = datetime.now().strftime('%Y%m%d-%H%M%S')
    shutil.copy(master_path, os.path.join(backup_dir, f'master-articles-{ts}.bak'))
    print('✅ 已備份 master-articles.json')

master = []
if os.path.exists(master_path):
    with open(master_path, 'r', encoding='utf-8') as f:
        master = json.load(f)
        print(f'📊 現有文章：{len(master)} 篇')

with open(pending_path, 'r', encoding='utf-8') as f:
    pending = json.load(f)
    print(f'📋 待合併文章：{len(pending)} 篇')

existing_keywords = [a.get('keyword', '') for a in master]
new_count = 0
for item in pending:
    kw = item.get('keyword', '')
    if kw not in existing_keywords:
        master.append(item)
        new_count += 1
        print(f'   ✅ 新增：{kw[:40]}...')

with open(master_path, 'w', encoding='utf-8') as f:
    json.dump(master, f, ensure_ascii=False, indent=2)

with open(pending_path, 'w', encoding='utf-8') as f:
    json.dump([], f)

print(f'📊 本次新增 {new_count} 篇文章，主資料庫共 {len(master)} 篇')
'@

python -c "$PyMergeScript"

if ($LASTEXITCODE -ne 0) {
    Write-Log "❌ 合併失敗，退出碼: $LASTEXITCODE"
    Write-Log "⚠️ 將在 30 秒後重試..."
    Start-Sleep -Seconds 30
    python -c "$PyMergeScript"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ 第二次重試仍失敗"
        Send-ErrorNotification -ErrorMsg "文章合併失敗，請檢查 master-articles.json"
        exit 1
    }
}
Write-Log "✅ 文章合併完成"

# ============================================================
# 🚀 步驟 4：執行文章生成 (直接呼叫 article_generator)
# ============================================================
Write-Log "[4/4] 執行 100 篇文章生成與部署..."
Save-Checkpoint -Stage "generation_start"

$CurrentCount = (Get-ChildItem "$TargetDir\*.html" -ErrorAction SilentlyContinue).Count
Write-Log "   📄 目前 nature/ 目錄有 $CurrentCount 篇文章"
Write-Log "   ⏳ 預計生成 $($MissingArticles.Count) 篇，耗時 60-90 分鐘"
Write-Log ""

Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  📡 文章生成即時輸出 (每篇文章完成時顯示)"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log ""

python -c "
import json
import sys
import os
sys.path.insert(0, '.')

from src.article_generator import generate_article

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    all_articles = json.load(f)

nature_articles = [a for a in all_articles if a.get('filename', '').startswith('nature/')]
total = len(nature_articles)
print(f'📊 從 master-articles.json 找到 {total} 篇 nature 文章')

success_count = 0
fail_count = 0
skip_count = 0

for idx, article in enumerate(nature_articles, 1):
    filename = article.get('filename', '')
    filepath = f'./{filename}'
    
    if os.path.exists(filepath):
        size = os.path.getsize(filepath)
        if size >= 5120:
            print(f'⏩ [{idx}/{total}] 已存在：{filename} ({size} bytes)')
            skip_count += 1
            continue
        else:
            print(f'⚠️ [{idx}/{total}] 檔案過小，重新生成：{filename} ({size} bytes)')
    
    print(f'--- 進度 {idx}/{total} ---')
    try:
        generate_article(article)
        success_count += 1
    except Exception as e:
        print(f'❌ 生成失敗：{e}')
        fail_count += 1

print(f'')
print(f'✅ 成功生成 {success_count} 篇')
print(f'⏩ 跳過 {skip_count} 篇')
print(f'❌ 失敗 {fail_count} 篇')
"

$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    Write-Log ""
    Write-Log "❌ 文章生成失敗，退出碼: $ExitCode"
    Write-Log "⚠️ 將在 60 秒後重試..."
    Start-Sleep -Seconds 60
    
    Write-Log ""
    Write-Log "🔄 第二次嘗試..."
    python -c "
import json
import sys
import os
sys.path.insert(0, '.')
from src.article_generator import generate_article

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    all_articles = json.load(f)

nature_articles = [a for a in all_articles if a.get('filename', '').startswith('nature/')]

success_count = 0
for idx, article in enumerate(nature_articles, 1):
    filename = article.get('filename', '')
    filepath = f'./{filename}'
    if os.path.exists(filepath) and os.path.getsize(filepath) >= 5120:
        continue
    try:
        generate_article(article)
        success_count += 1
    except Exception as e:
        print(f'❌ 失敗：{e}')
print(f'✅ 第二次嘗試成功生成 {success_count} 篇')
"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ 第二次重試仍失敗"
        Send-ErrorNotification -ErrorMsg "文章生成失敗，請檢查日誌: $LogFile"
        exit 1
    }
}

Save-Checkpoint -Stage "generation_done"
Write-Log ""
Write-Log "✅ 文章生成完成"

$AfterCount = (Get-ChildItem "$TargetDir\*.html" -ErrorAction SilentlyContinue).Count
Write-Log "   📄 生成後 nature/ 目錄有 $AfterCount 篇文章 (新增 $($AfterCount - $CurrentCount) 篇)"

# ============================================================
# 📂 更新分類頁面與 Sitemap
# ============================================================
Write-Log "   [4a] 更新分類頁面與 Sitemap..."
python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ 分類頁面更新失敗，嘗試重試..."
    Start-Sleep -Seconds 10
    python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log
}
Write-Log "✅ 分類頁面與首頁已更新"

# ============================================================
# ☁️ 部署到 Cloudflare
# ============================================================
Write-Log "   [4b] 部署到 Cloudflare Pages..."
$DeployResult = & npx wrangler pages deploy . --project-name=ahpal-pages 2>&1
Write-Log $DeployResult

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ 部署失敗，10 分鐘後重試..."
    Start-Sleep -Seconds 600
    $DeployResult = & npx wrangler pages deploy . --project-name=ahpal-pages 2>&1
    Write-Log $DeployResult
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ 第二次部署仍失敗，請手動檢查"
        Send-ErrorNotification -ErrorMsg "Cloudflare 部署失敗，請手動檢查"
        exit 1
    }
}
Write-Log "✅ 部署完成"

# ============================================================
# 📊 完成報告
# ============================================================
Save-Checkpoint -Stage "complete"
Write-Log "============================================================"
Write-Log "✅ 動植物生態 100 篇 — SYSTEM 背景執行版 執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📊 nature/ 目錄文章總數: $AfterCount 篇"
Write-Log "📁 日誌位置: $LogFile"
Write-Log "============================================================"

# ============================================================
# 📧 寄送完成通知
# ============================================================
Write-Log "📧 寄送完成通知..."

if (Test-Path $EnvPath) {
    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^SMTP_USER=(.+)$') { $SmtpUser = $Matches[1] }
        if ($_ -match '^SMTP_PASS=(.+)$') { $SmtpPass = $Matches[1] }
        if ($_ -match '^SMTP_TO=(.+)$') { $ToEmail = $Matches[1] }
    }
}

if ($SmtpUser -and $SmtpPass -and $ToEmail) {
    $Subject = "🌳 動植物生態 100 篇 — SYSTEM 背景執行版 完成通知"
    $Body = @"
動植物生態 100 篇 SYSTEM 背景執行版已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 文章總數：$AfterCount 篇
   - 日誌位置：$LogFile
   - 部署狀態：✅ 已完成

請至 https://www.ahpal.com/category-nature.html 查看最新文章。

🦞 龍蝦總工程師
"@

    try {
        $SmtpClient = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
        $SmtpClient.EnableSsl = $true
        $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPass)
        $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, $Subject, $Body)
        $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
        $SmtpClient.Send($MailMessage)
        Write-Log "✅ 通知郵件已發送"
    } catch {
        Write-Log "⚠️ 郵件發送失敗: $($_.Exception.Message)"
    }
} else {
    Write-Log "⚠️ SMTP 設定不完整，跳過郵件通知"
}

# ============================================================
# 🔧 恢復電源計劃
# ============================================================
Write-Log "🔄 恢復原始電源計劃..."
powercfg -setactive $PowerCfgOriginal 2>$null

Write-Log "============================================================"
exit 0