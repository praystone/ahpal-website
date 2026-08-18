# ============================================================
# 🌿 自然生態 — 無人值守 + 方便添加 v2.6
# ============================================================
# 用途：無人值守生成自然生態文章
# 特色：
#   ✅ 方便添加：直接在 $Articles 區塊增減文章
#   ✅ 無人值守：自動完成 JSON 寫入 → 合併 → 生成 → 更新頁面 → 部署
#   ✅ 斷點續傳：已存在的文章自動跳過
#   ✅ 電源管理：執行期間防止睡眠
#   ✅ 錯誤通知：失敗時發送郵件
#   ✅ 雙重重試：生成失敗自動重試一次
#   ✅ 即時進度：每篇顯示目前篇數 [N/M] 與詳細生成 Log
#   ✅ ETA 預估：每 10 篇顯示進度摘要與預估剩餘時間
#   ✅ 日誌路徑：統一使用 config.ps1 管理 (system-reports/)
#
# v2.6 變更 (2026-08-18)：
#   - 🆕 優化進度摘要顯示 (更精簡)
#   - 🆕 加入總跳過計數顯示
#   - 🆕 與 history/life v2.6 保持一致
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
# 📁 載入核心配置 (日誌路徑)
# ============================================================
. .\scripts\config.ps1

# ============================================================
# 📝 設定日誌 (使用 config.ps1 統一管理)
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = Get-LogPath -Type batch
$LogFile = "$LogDir\auto-nature-batch-v2-$Timestamp.log"
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
            $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "❌ 自然生態批次生成失敗", $ErrorMsg)
            $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($MailMessage)
            Write-Log "📧 錯誤通知已發送"
        } catch {
            Write-Log "⚠️ 錯誤通知發送失敗: $($_.Exception.Message)"
        }
    }
}

Write-Log "============================================================"
Write-Log "🌿 自然生態 — 無人值守 + 方便添加 v2.6"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📁 日誌位置: $LogDir"
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
# 📝 步驟 2：★ 方便添加區 ★ (80 篇文章，四大主題)
# ============================================================
Write-Log "[2/4] 準備文章清單..."

$Articles = @(
    # ============================================================
    # 🌿 植物生態與演化 (20篇)
    # ============================================================
    @{ keyword = "大王花的寄生生活史：從種子到綻放的極端演化策略"; filename = "rafflesia-parasitic-lifecycle-evolution.html" },
    @{ keyword = "龍血樹的樹脂分泌機制與索科特拉島隔離演化奇蹟"; filename = "dragon-blood-tree-resin-socotra.html" },
    @{ keyword = "捕蠅草的瞬間閉合機制：動作電位與彈性不穩定性物理學"; filename = "venus-flytrap-action-potential-closure.html" },
    @{ keyword = "巨杉的耐火樹皮與北美森林火災生態適應"; filename = "giant-sequoia-fire-resistant-bark.html" },
    @{ keyword = "猴麵包樹的儲水組織與非洲稀樹草原乾旱適應"; filename = "baobab-water-storage-savanna.html" },
    @{ keyword = "紅杉的垂直水分輸送：根壓與蒸散作用的極限物理學"; filename = "redwood-water-transport-root-pressure.html" },
    @{ keyword = "曼陀羅的生物鹼防禦與昆蟲共演化軍備競賽"; filename = "datura-alkaloid-defense-coevolution.html" },
    @{ keyword = "跳舞草的葉片運動：膨壓變化與光週期調控機制"; filename = "dancing-plant-leaf-movement-photoperiod.html" },
    @{ keyword = "銀杏的古老基因組：恐龍時代至今的活化石演化停滯"; filename = "ginkgo-genome-living-fossil-stasis.html" },
    @{ keyword = "蕨類植物的孢子彈射力學與森林底層微氣候適應"; filename = "fern-spore-dispersal-mechanics.html" },
    @{ keyword = "蘭花的擬態欺騙：無報酬授粉與昆蟲行為操控演化"; filename = "orchid-mimicry-deceptive-pollination.html" },
    @{ keyword = "胡楊的鹽腺泌鹽機制與乾旱區土壤鹽漬化適應"; filename = "poplar-salt-glands-drought-adaptation.html" },
    @{ keyword = "藤蔓植物的向觸性生長與森林冠層競爭力學"; filename = "vine-thigmotropism-canopy-competition.html" },
    @{ keyword = "食蟲植物的消化酶演化：氮缺乏環境下的營養獲取策略"; filename = "carnivorous-plant-digestive-enzyme-evolution.html" },
    @{ keyword = "紅樹林的胎生種子萌發與潮間帶逆境適應"; filename = "mangrove-vivipary-intertidal-adaptation.html" },
    @{ keyword = "阿爾卑斯山植物的抗凍蛋白與高海拔紫外線防護"; filename = "alpine-plant-antifreeze-protein-uv-protection.html" },
    @{ keyword = "真菌與植物的菌根共生：磷營養交換與生態網絡結構"; filename = "mycorrhizal-symbiosis-phosphorus-exchange.html" },
    @{ keyword = "竹子的同步開花謎團：族群遺傳與演化時鐘假說"; filename = "bamboo-synchronous-flowering-evolution.html" },
    @{ keyword = "植物揮發性有機物的防禦信號與鄰居溝通網絡"; filename = "plant-volatile-defense-signaling-network.html" },
    @{ keyword = "風力傳粉的流體力學：裸子植物與被子植物的授粉效率比較"; filename = "wind-pollination-hydrodynamics-gymnosperm.html" },

    # ============================================================
    # 🦋 昆蟲與節肢動物 (20篇)
    # ============================================================
    @{ keyword = "帝王蝶的跨世代遷徙導航：太陽羅盤與地磁感應機制"; filename = "monarch-butterfly-navigation-sun-compass.html" },
    @{ keyword = "螞蟻的費洛蒙通訊網絡：群體智慧與最短路徑優化"; filename = "ant-pheromone-communication-swarm-intelligence.html" },
    @{ keyword = "蜘蛛絲的力學超能力：強度、彈性與生物材料工程"; filename = "spider-silk-mechanics-biomaterial-engineering.html" },
    @{ keyword = "螢火蟲的生物發光：螢光素酶反應與求偶信號演化"; filename = "firefly-bioluminescence-luciferase-mating.html" },
    @{ keyword = "蜜蜂的舞蹈語言：資訊編碼與群體決策機制"; filename = "honeybee-waggle-dance-information-coding.html" },
    @{ keyword = "糞金龜的星導航：銀河定位與糞球滾動力學"; filename = "dung-beetle-milky-way-navigation-mechanics.html" },
    @{ keyword = "蜻蜓的複眼視覺與空中捕獵飛行力學"; filename = "dragonfly-compound-eye-hunting-flight.html" },
    @{ keyword = "蟬的週期性出土：質數生命週期的演化優勢與生態時鐘"; filename = "cicada-periodical-emergence-prime-cycle.html" },
    @{ keyword = "竹節蟲的極致擬態：視覺欺騙與掠食者認知騙術"; filename = "stick-insect-mimicry-visual-deception.html" },
    @{ keyword = "螳螂的鐮刀前足：捕捉運動的彈性能釋放與衝擊力學"; filename = "mantis-raptorial-leg-elastic-recoil.html" },
    @{ keyword = "蝴蝶鱗片的結構色：光子晶體與奈米光學演化"; filename = "butterfly-scale-structural-color-photonic.html" },
    @{ keyword = "蜜蜂的熱防禦：集體扇風與巢溫調控生理機制"; filename = "honeybee-thermal-defense-collective-fanning.html" },
    @{ keyword = "跳蚤的彈跳力學：樹脂蛋白儲能與肌肉協同爆發"; filename = "flea-jumping-mechanics-resilin-energy.html" },
    @{ keyword = "白蟻的土木工程：巢穴通風與真菌培養共生生態"; filename = "termite-mound-ventilation-fungiculture.html" },
    @{ keyword = "豆娘的空中交配力學：連體飛行的流體動力學"; filename = "damselfly-mating-wheel-flight-hydrodynamics.html" },
    @{ keyword = "獨角仙的角鬥力學：繁殖競爭與角質結構強度"; filename = "rhinoceros-beetle-horn-mechanics-competition.html" },
    @{ keyword = "虎甲蟲的極速奔跑：視覺盲區與逃避掠食者的運動策略"; filename = "tiger-beetle-high-speed-vision-blindness.html" },
    @{ keyword = "螻蛄的挖穴力學：前足演化與土壤穿透物理"; filename = "mole-cricket-digging-foreleg-soil-penetration.html" },
    @{ keyword = "蠍子的螫針毒液：神經毒素演化與獵物癱瘓策略"; filename = "scorpion-venom-neurotoxin-evolution.html" },
    @{ keyword = "水黽的表面張力行走：疏水性腿毛與水面支撐力學"; filename = "water-strider-surface-tension-hydrophobic.html" },

    # ============================================================
    # 🐟 魚類與水生生物 (20篇)
    # ============================================================
    @{ keyword = "鮭魚的返鄉洄游：嗅覺印記與地磁導航機制"; filename = "salmon-homing-migration-olfactory-magnetoreception.html" },
    @{ keyword = "電鰻的放電器官：離子通道與高壓電擊獵捕物理學"; filename = "electric-eel-discharge-organ-ion-channel.html" },
    @{ keyword = "小丑魚的性別轉變：社會階級與賀爾蒙調控機制"; filename = "clownfish-sex-change-social-hierarchy.html" },
    @{ keyword = "深海琵琶魚的共生發光：費氏弧菌與誘餌演化"; filename = "anglerfish-bioluminescent-symbiosis-bacteria.html" },
    @{ keyword = "飛魚的滑翔力學：胸鰭升力與水面起飛動態"; filename = "flying-fish-gliding-lift-takeoff-dynamics.html" },
    @{ keyword = "彈塗魚的陸地適應：皮膚呼吸與鰭肢運動力學"; filename = "mudskipper-terrestrial-adaptation-skin-breathing.html" },
    @{ keyword = "河豚的膨脹防禦：彈性胃壁與四齒魨科演化策略"; filename = "pufferfish-inflation-defense-elastic-stomach.html" },
    @{ keyword = "鯊魚的皮膚齒狀鱗片：流體減阻與游泳效率物理學"; filename = "shark-skin-denticles-hydrodynamic-drag-reduction.html" },
    @{ keyword = "血鸚鵡的雜交畸形：觀賞魚產業下的基因組衝突"; filename = "blood-parrot-cichlid-hybrid-genome-conflict.html" },
    @{ keyword = "龍膽石斑的性轉變：順序雌雄同體與繁殖策略"; filename = "giant-grouper-sex-change-protogyny.html" },
    @{ keyword = "海馬的雄性懷孕：育兒袋生理與胚胎發育調控"; filename = "seahorse-male-pregnancy-brood-pouch.html" },
    @{ keyword = "比目魚的變態發育：眼睛遷移與扁平化適應演化"; filename = "flatfish-metamorphosis-eye-migration.html" },
    @{ keyword = "燈籠魚的垂直遷徙：深海晝夜移動物質能量流動"; filename = "lanternfish-vertical-migration-diel-cycle.html" },
    @{ keyword = "鯰魚的味覺觸鬚：化學感應與濁水環境覓食適應"; filename = "catfish-barbels-taste-chemoreception-feeding.html" },
    @{ keyword = "紅龍魚的嘴巴孵化：口孵行為與親代投資演化"; filename = "arowana-mouth-brooding-parental-investment.html" },
    @{ keyword = "海馬的尾巴力學：方形截面與抓握生物結構設計"; filename = "seahorse-tail-mechanics-square-section-grasping.html" },
    @{ keyword = "燈魚的發光器演化：共生生態系與視覺訊號同步"; filename = "lanternfish-photophore-evolution-symbiosis.html" },
    @{ keyword = "吻鱷的伏擊力學：下顎咬合力與流體感應神經網路"; filename = "gar-fish-ambush-jaw-bite-force-hydromechanics.html" },

    # ============================================================
    # 🐸 兩棲爬行動物 (20篇)
    # ============================================================
    @{ keyword = "箭毒蛙的皮膚生物鹼：毒素演化與警戒色共進化"; filename = "poison-dart-frog-alkaloid-evolution-aposematism.html" },
    @{ keyword = "變色龍的顏色變化：色素細胞與奈米晶體光學調控"; filename = "chameleon-color-change-chromatophores-photonics.html" },
    @{ keyword = "蛇類的下顎運動力學：頜骨脫臼與吞嚥生物力學"; filename = "snake-jaw-mechanics-kinetic-skull-swallowing.html" },
    @{ keyword = "壁虎的腳掌黏附力：凡德瓦爾力與微奈米結構設計"; filename = "gecko-foot-adhesion-van-der-waals-nanostructures.html" },
    @{ keyword = "蠑螈的肢體再生：芽基形成與基因組重啟機制"; filename = "salamander-limb-regeneration-blastema-genomics.html" },
    @{ keyword = "鬣蜥的海中覓食：滲透壓調節與鹽腺排鹽生理學"; filename = "marine-iguana-osmoregulation-salt-glands.html" },
    @{ keyword = "守宮的聲學通訊：叫聲結構與族群識別演化"; filename = "gecko-vocal-communication-call-structure.html" },
    @{ keyword = "蟒蛇的熱感應：頰窩器官與紅外線偵測物理學"; filename = "python-infrared-sensing-pit-organ-physics.html" },
    @{ keyword = "樹蛙的黏性腳墊：表面張力與樹棲環境適應力學"; filename = "tree-frog-adhesive-toe-pads-wettability.html" },
    @{ keyword = "刺尾鬣蜥的尾棘防禦：掠食者威懾與尾部自割演化"; filename = "spiny-tailed-iguana-tail-spines-defense.html" },
    @{ keyword = "玻璃蛙的透明皮膚：血細胞隱藏與背景融合機制"; filename = "glass-frog-translucent-skin-camouflage.html" },
    @{ keyword = "凱門鱷的母子溝通：呼喚聲與孵化同步化行為"; filename = "caiman-parent-offspring-communication-hatching.html" },
    @{ keyword = "避役的舌頭彈射：伸縮儲能與獵物捕獲超高速運動"; filename = "chameleon-tongue-projection-elastic-energy.html" },
    @{ keyword = "陸龜的龜甲演化：骨質防護與棲地適應多樣性"; filename = "tortoise-shell-evolution-bony-armor-habitat.html" },
    @{ keyword = "蠑螈的卵塊保護：季節性繁殖與親代照顧策略"; filename = "salamander-egg-mass-protection-reproductive.html" },

    # ============================================================
    # 🐦 鳥類生態 (20篇)
    # ============================================================
    @{ keyword = "極地燕鷗的極端遷徙：北極到南極的飛行生理學"; filename = "arctic-tern-extreme-migration-flight-physiology.html" },
    @{ keyword = "孔雀的尾羽演化：性選擇與訊號理論的經典案例"; filename = "peacock-tail-evolution-sexual-selection-signaling.html" },
    @{ keyword = "蜂鳥的懸停飛行：拍翅動力學與能量代謝極限"; filename = "hummingbird-hovering-flight-wing-kinematics.html" },
    @{ keyword = "渡鴉的認知能力：工具使用與元認知實驗證據"; filename = "raven-cognition-tool-use-metacognition.html" },
    @{ keyword = "鸚鵡的聲音模仿：鳴管控制與社會學習神經機制"; filename = "parrot-vocal-mimicry-syrinx-social-learning.html" },
    @{ keyword = "信天翁的動態滑翔：風場利用與長距離飛行最佳化"; filename = "albatross-dynamic-soaring-wind-optimization.html" },
    @{ keyword = "喜鵲的自我鏡像認知：動物意識與智能演化"; filename = "magpie-self-recognition-mirror-test-cognition.html" },
    @{ keyword = "遊隼的俯衝速度：空氣動力學與獵捕策略物理"; filename = "peregrine-falcon-dive-speed-aerodynamics.html" },
    @{ keyword = "鳥類的磁感應：隱花色素與量子糾纏導航機制"; filename = "bird-magnetoreception-cryptochrome-quantum.html" },
    @{ keyword = "啄木鳥的抗衝擊頭骨：減震結構與腦部保護力學"; filename = "woodpecker-shock-absorption-cranial-mechanics.html" },
    @{ keyword = "鳥巢的建築工程：材料選擇與結構力學多樣性"; filename = "bird-nest-architecture-material-structural.html" },
    @{ keyword = "杜鵑的巢寄生：卵色模仿與宿主反適應軍備競賽"; filename = "cuckoo-brood-parasitism-egg-mimicry.html" },
    @{ keyword = "猛禽的視覺超能力：紫外光辨識與遠距捕獵"; filename = "raptor-vision-ultraviolet-long-range-hunting.html" },
    @{ keyword = "企鵝的流線型身體：水下推進與極地游泳力學"; filename = "penguin-streamlined-body-aquatic-locomotion.html" },
    @{ keyword = "鳥鳴的方言演化：地理隔離與文化傳承機制"; filename = "bird-song-dialect-geographic-cultural-transmission.html" },
    @{ keyword = "蜂鳥的舌頭毛細作用：花蜜攝取的微流體物理學"; filename = "hummingbird-tongue-capillary-nectar-microfluidics.html" },
    @{ keyword = "貓頭鷹的靜音飛行：羽毛構造與聲學隱形力學"; filename = "owl-silent-flight-feather-acoustic-stealth.html" },
    @{ keyword = "群體鳥類的湧現行為：空中芭蕾與掠食者躲避策略"; filename = "starling-murmuration-emergent-behavior.html" },
    @{ keyword = "北極海鸚的銜魚紀錄：多條魚一次捕獲的嘴部力學"; filename = "puffin-fish-holding-mouth-mechanics.html" },
    @{ keyword = "太平鳥的果實消化與種子傳播共演化網絡"; filename = "waxwing-fruit-digestion-seed-dispersal.html" }
)

    # ── 🆕 新增文章請複製下面這一行，貼在上方 ──
    # @{ keyword = "你的新文章標題"; filename = "your-new-article.html" },

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
    "category": "🌿 自然生態",
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
# 🚀 步驟 4：執行文章生成 (即時 Log + 顯式進度 N/M + ETA)
# ============================================================
Write-Log "[4/4] 執行文章生成與部署..."
Save-Checkpoint -Stage "generation_start"

Write-Log "   [4a] 生成文章 (顯示目前進度 + ETA)..."
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  📡 文章生成即時輸出"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log ""

python -u -c "
import json
import sys
import os
import time
sys.path.insert(0, '.')

from src.article_generator import generate_article

with open('data/master-articles.json', 'r', encoding='utf-8') as f:
    all_articles = json.load(f)

nature_articles = [a for a in all_articles if a.get('filename', '').startswith('nature/')]
total = len(nature_articles)
print(f'📊 從 master-articles.json 找到 {total} 篇 nature 文章', flush=True)

start_time = time.time()
success_count = 0
fail_count = 0
skip_count = 0

for idx, article in enumerate(nature_articles, 1):
    filename = article.get('filename', '')
    filepath = f'./{filename}'
    keyword = article.get('keyword', '')
    progress = f'[{idx}/{total}]'

    # ✅ 進度摘要 (每 10 篇顯示)
    if idx == 1 or idx == total or idx % 10 == 0:
        elapsed = time.time() - start_time
        avg_time = elapsed / idx if idx > 0 else 0
        remaining = (total - idx) * avg_time
        print(f'📊 進度：{idx}/{total} ({idx/total*100:.1f}%) | 已耗：{elapsed:.0f}s | 預估剩餘：{remaining:.0f}s', flush=True)
        print(f'   └─ 累積跳過：{skip_count} 篇', flush=True)

    if os.path.exists(filepath):
        size = os.path.getsize(filepath)
        if size >= 5120:
            skip_count += 1
            print(f'⏩ {progress} 已存在跳過：{filename}', flush=True)
            continue
        else:
            print(f'⚠️ {progress} 檔案過小重新生成：{filename} ({size} bytes)', flush=True)
    
    print(f'\n============================================================', flush=True)
    print(f'🚀 {progress} 開始生成（第 {idx} 篇，共 {total} 篇）：{keyword} ({filename})', flush=True)
    print(f'============================================================', flush=True)
    
    try:
        generate_article(article)
        print(f'✅ {progress} 完成（第 {idx} 篇，共 {total} 篇）：{os.path.basename(filename)}', flush=True)
        success_count += 1
    except Exception as e:
        print(f'❌ {progress} 失敗（第 {idx} 篇，共 {total} 篇）：{str(e)}', flush=True)
        fail_count += 1

print(f'\n📊 執行總結：成功 {success_count} 篇 | 跳過 {skip_count} 篇 | 失敗 {fail_count} 篇', flush=True)
" 2>&1

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
total = len(nature_articles)

success_count = 0
for idx, article in enumerate(nature_articles, 1):
    filename = article.get('filename', '')
    filepath = f'./{filename}'
    keyword = article.get('keyword', '')
    progress = f'[{idx}/{total}]'
    if os.path.exists(filepath) and os.path.getsize(filepath) >= 5120:
        continue
    try:
        print(f'🚀 {progress} 重試生成：{keyword[:30]}... ({filename})')
        generate_article(article)
        print(f'✅ {progress} 重試成功：{filename}')
        success_count += 1
    except Exception as e:
        print(f'❌ {progress} 重試失敗：{e}')
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

# ============================================================
# 📂 更新分類頁面與 Sitemap
# ============================================================
Write-Log "   [4b] 更新分類頁面與 Sitemap..."
Save-Checkpoint -Stage "category_update"

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
Write-Log "   [4c] 部署到 Cloudflare Pages..."
Save-Checkpoint -Stage "deploy"

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
Write-Log "✅ 自然生態 — 無人值守 + 方便添加 v2.6 執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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
    $Subject = "🌿 自然生態批次生成 v2.6 完成通知"
    $Body = @"
自然生態批次生成 v2.6 已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
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