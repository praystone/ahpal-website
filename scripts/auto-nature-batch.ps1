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
    # 🐾 動物類 (40篇)
    # ============================================================
    @{ keyword = "台灣藍鵲生態觀察：都市中的藍色精靈"; filename = "taiwan-blue-magpie-ecology.html" },
    @{ keyword = "台灣黑熊保育現況與挑戰"; filename = "taiwan-black-bear-conservation.html" },
    @{ keyword = "石虎生存危機：台灣最後的野生貓科動物"; filename = "leopard-cat-taiwan.html" },
    @{ keyword = "台灣獼猴社會行為觀察"; filename = "taiwan-macaque-behavior.html" },
    @{ keyword = "中華白海豚台灣海域生態紀錄"; filename = "taiwan-pink-dolphin.html" },
    @{ keyword = "綠蠵龜台灣產卵棲地保護"; filename = "green-sea-turtle-taiwan.html" },
    @{ keyword = "台灣特有種鳥類完整指南"; filename = "taiwan-endemic-birds-guide.html" },
    @{ keyword = "台灣蝴蝶王國：紫斑蝶遷徙奇觀"; filename = "taiwan-butterfly-migration.html" },
    @{ keyword = "螢火蟲生態與台灣賞螢景點"; filename = "firefly-ecology-taiwan.html" },
    @{ keyword = "台灣蜻蛉目昆蟲多樣性"; filename = "taiwan-dragonfly-guide.html" },
    @{ keyword = "獨角仙飼養與生態觀察"; filename = "rhinoceros-beetle-guide.html" },
    @{ keyword = "台灣鍬形蟲圖鑑與棲地"; filename = "taiwan-stag-beetle-guide.html" },
    @{ keyword = "台灣蛇類圖鑑：無毒與有毒蛇辨識"; filename = "taiwan-snake-guide.html" },
    @{ keyword = "台灣蜥蜴多樣性與生態"; filename = "taiwan-lizard-guide.html" },
    @{ keyword = "台灣蛙類生態與叫聲辨識"; filename = "taiwan-frog-guide.html" },
    @{ keyword = "台灣山椒魚：冰河孑遺物種"; filename = "taiwan-salamander-guide.html" },
    @{ keyword = "台灣櫻花鉤吻鮭保育之路"; filename = "taiwan-salmon-conservation.html" },
    @{ keyword = "台灣溪流魚類生態"; filename = "taiwan-freshwater-fish-ecology.html" },
    @{ keyword = "台灣珊瑚礁生態系"; filename = "taiwan-coral-reef-ecology.html" },
    @{ keyword = "台灣海龜種類與保育"; filename = "taiwan-sea-turtle-guide.html" },
    @{ keyword = "台灣鯨豚觀察指南"; filename = "taiwan-whale-dolphin-guide.html" },
    @{ keyword = "台灣候鳥遷徙路線與賞鳥景點"; filename = "taiwan-migratory-birds-spots.html" },
    @{ keyword = "台灣猛禽生態：老鷹、鳳頭蒼鷹、大冠鷲"; filename = "taiwan-raptors-guide.html" },
    @{ keyword = "台灣貓頭鷹種類與夜間觀察"; filename = "taiwan-owl-guide.html" },
    @{ keyword = "台灣五色鳥生態觀察"; filename = "taiwan-barbet-guide.html" },
    @{ keyword = "台灣翠鳥生態與釣魚技巧"; filename = "taiwan-kingfisher-guide.html" },
    @{ keyword = "台灣蝙蝠生態與棲息地保護"; filename = "taiwan-bat-ecology.html" },
    @{ keyword = "台灣飛鼠生態與夜間觀察"; filename = "taiwan-flying-squirrel-guide.html" },
    @{ keyword = "台灣穿山甲生態與保育"; filename = "taiwan-pangolin-guide.html" },
    @{ keyword = "台灣水鹿高山生態"; filename = "taiwan-sambar-deer-guide.html" },
    @{ keyword = "台灣山羊生態與棲地"; filename = "taiwan-serow-guide.html" },
    @{ keyword = "台灣野豬生態與族群管理"; filename = "taiwan-wild-boar-guide.html" },
    @{ keyword = "台灣白鼻心生態觀察"; filename = "taiwan-palm-civet-guide.html" },
    @{ keyword = "台灣鼬獾生態與習性"; filename = "taiwan-ferret-badger-guide.html" },
    @{ keyword = "台灣食蛇龜保育與非法貿易"; filename = "taiwan-box-turtle-conservation.html" },
    @{ keyword = "台灣斑龜生態與飼養"; filename = "taiwan-stripe-necked-turtle.html" },
    @{ keyword = "台灣溪蟹生態與棲地"; filename = "taiwan-freshwater-crab-guide.html" },
    @{ keyword = "台灣寄居蟹生態與保育"; filename = "taiwan-hermit-crab-guide.html" },
    @{ keyword = "台灣海蛞蝓多樣性"; filename = "taiwan-sea-slug-guide.html" },
    @{ keyword = "台灣小丑魚與海葵共生"; filename = "taiwan-clownfish-anemone.html" },

    # ============================================================
    # 🌿 植物類 (30篇)
    # ============================================================
    @{ keyword = "多肉植物養護大全：從選盆到澆水完整教學"; filename = "succulent-care-guide.html" },
    @{ keyword = "台灣原生蘭花圖鑑與保育"; filename = "taiwan-native-orchids-guide.html" },
    @{ keyword = "台灣紅檜與扁柏：千年神木的秘密"; filename = "taiwan-cypress-guide.html" },
    @{ keyword = "台灣高山杜鵑花季與賞花景點"; filename = "taiwan-rhododendron-guide.html" },
    @{ keyword = "台灣蕨類植物多樣性與辨識"; filename = "taiwan-fern-guide.html" },
    @{ keyword = "台灣竹林生態與經濟價值"; filename = "taiwan-bamboo-ecology.html" },
    @{ keyword = "台灣原生種茶樹與茶文化"; filename = "taiwan-native-tea-guide.html" },
    @{ keyword = "台灣特有種植物完整名錄"; filename = "taiwan-endemic-plants-list.html" },
    @{ keyword = "室內觀葉植物照顧指南"; filename = "indoor-foliage-plant-care.html" },
    @{ keyword = "香草植物種植與料理應用"; filename = "herb-planting-culinary-guide.html" },
    @{ keyword = "台灣野花圖鑑：春季賞花指南"; filename = "taiwan-wildflowers-spring.html" },
    @{ keyword = "台灣野花圖鑑：秋季賞花指南"; filename = "taiwan-wildflowers-autumn.html" },
    @{ keyword = "台灣海岸植物生態與防風林"; filename = "taiwan-coastal-plants-guide.html" },
    @{ keyword = "台灣溼地植物圖鑑"; filename = "taiwan-wetland-plants-guide.html" },
    @{ keyword = "台灣水生植物與水質淨化"; filename = "taiwan-aquatic-plants-guide.html" },
    @{ keyword = "台灣藥用植物圖鑑與應用"; filename = "taiwan-medicinal-plants-guide.html" },
    @{ keyword = "台灣民俗植物與傳統智慧"; filename = "taiwan-folk-plants-guide.html" },
    @{ keyword = "空氣鳳梨養護與品種介紹"; filename = "air-plant-care-guide.html" },
    @{ keyword = "鹿角蕨上板種植教學"; filename = "staghorn-fern-mounting.html" },
    @{ keyword = "觀音座蓮蕨種植指南"; filename = "angiopteris-fern-guide.html" },
    @{ keyword = "台灣杉：台灣特有針葉樹種"; filename = "taiwania-guide.html" },
    @{ keyword = "台灣肖楠生態與木材應用"; filename = "taiwan-incense-cedar-guide.html" },
    @{ keyword = "台灣油杉保育與復育"; filename = "taiwan-spruce-guide.html" },
    @{ keyword = "台灣玉山杜鵑生態"; filename = "taiwan-yushan-rhododendron.html" },
    @{ keyword = "台灣百合復育與種植"; filename = "taiwan-lily-guide.html" },
    @{ keyword = "台灣金線蓮種植與保健"; filename = "taiwan-anoectochilus-guide.html" },
    @{ keyword = "台灣石斛蘭種類與種植"; filename = "taiwan-dendrobium-guide.html" },
    @{ keyword = "台灣蝴蝶蘭原生種保育"; filename = "taiwan-phalaenopsis-guide.html" },
    @{ keyword = "台灣一葉蘭生態與觀賞"; filename = "taiwan-pleione-guide.html" },
    @{ keyword = "台灣原生蕨類植物圖鑑與應用"; filename = "taiwan-native-ferns-application.html" },

    # ============================================================
    # 🌍 生態/環境類 (30篇)
    # ============================================================
    @{ keyword = "台灣森林生態系完整介紹"; filename = "taiwan-forest-ecosystem.html" },
    @{ keyword = "台灣高山生態與氣候變遷"; filename = "taiwan-alpine-ecology-climate.html" },
    @{ keyword = "台灣溪流生態與指標物種"; filename = "taiwan-stream-ecology.html" },
    @{ keyword = "台灣濕地生態與候鳥棲地"; filename = "taiwan-wetland-ecology.html" },
    @{ keyword = "台灣海洋生態與保育區"; filename = "taiwan-marine-ecology.html" },
    @{ keyword = "台灣國家公園生物多樣性"; filename = "taiwan-national-park-biodiversity.html" },
    @{ keyword = "台灣自然生態保育政策與法規"; filename = "taiwan-conservation-policy.html" },
    @{ keyword = "台灣生態旅遊景點推薦"; filename = "taiwan-ecotourism-spots.html" },
    @{ keyword = "台灣外來種入侵生態危機"; filename = "taiwan-invasive-species.html" },
    @{ keyword = "台灣氣候變遷對生態的影響"; filename = "taiwan-climate-change-ecology.html" },
    @{ keyword = "台灣環境教育與生態體驗"; filename = "taiwan-environmental-education.html" },
    @{ keyword = "台灣生態攝影技巧與器材推薦"; filename = "nature-photography-taiwan.html" },
    @{ keyword = "台灣自然觀察日誌撰寫教學"; filename = "nature-journal-guide.html" },
    @{ keyword = "台灣生態保育志工招募與參與"; filename = "taiwan-conservation-volunteer.html" },
    @{ keyword = "台灣環境信託與棲地保護"; filename = "taiwan-environmental-trust.html" },
    @{ keyword = "台灣生態檢核與開發評估"; filename = "taiwan-ecological-assessment.html" },
    @{ keyword = "台灣城市生態學：都市中的自然"; filename = "urban-ecology-taiwan.html" },
    @{ keyword = "台灣夜間生態觀察與安全須知"; filename = "taiwan-night-ecology-guide.html" },
    @{ keyword = "台灣生態步道推薦與導覽"; filename = "taiwan-ecology-trails.html" },
    @{ keyword = "台灣社區生態營造案例分享"; filename = "taiwan-community-ecology.html" },
    @{ keyword = "台灣原住民傳統生態智慧"; filename = "taiwan-indigenous-ecology.html" },
    @{ keyword = "台灣生態文學與自然書寫"; filename = "taiwan-nature-writing.html" },
    @{ keyword = "台灣生態紀錄片推薦與導讀"; filename = "taiwan-ecology-documentary.html" },
    @{ keyword = "台灣自然生態繪畫與藝術"; filename = "taiwan-nature-art-guide.html" },
    @{ keyword = "台灣生態教育教材與繪本推薦"; filename = "taiwan-ecology-education-guide.html" },
    @{ keyword = "台灣生態保護區與管制區介紹"; filename = "taiwan-protected-areas-guide.html" },
    @{ keyword = "台灣生物多樣性熱點分析"; filename = "taiwan-biodiversity-hotspots.html" },
    @{ keyword = "台灣生態廊道與動物通道"; filename = "taiwan-ecological-corridor.html" },
    @{ keyword = "台灣里山倡議與環境永續"; filename = "taiwan-satoyama-initiative.html" },
    @{ keyword = "台灣生態未來展望與青年行動"; filename = "taiwan-ecology-future.html" }
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