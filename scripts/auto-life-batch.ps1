# ============================================================
# 生活小常識 100 篇 — 即時顯示 + 排程優化版 v1.0
# ============================================================
# 用途：無人值守一次性生成 全新生活小常識文章
# 
# v1.0 初始版本 (2026-08-16)：
#   - 基於 auto-history-batch.ps1 v10.2 改造
#   - 分類改為 🏠 生活小常識
#   - 目錄改為 life/
#   - 100 篇居家生活主題
#   - 繼承所有功能 (斷點續傳、郵件通知、電源管理)
# ============================================================

# ============================================================
# 🔧 電源管理：擷取當前電源計劃並防止睡眠
# ============================================================
$PowerCfgOriginal = (powercfg /getactivescheme) -replace '.*:\s+([a-f0-9-]+)\s+\(.*', '$1'
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

# ⭐ 強制 UTF-8 編碼
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
$env:PYTHONIOENCODING = "utf-8"

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-life-batch-v1-$Timestamp.log"
$CheckpointFile = "$LogDir\life-checkpoint.json"

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
        article_count = $MissingArticles.Count
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
            $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "❌ 生活小常識批次生成失敗", $ErrorMsg)
            $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($MailMessage)
            Write-Log "📧 錯誤通知已發送"
        } catch {
            Write-Log "⚠️ 錯誤通知發送失敗: $($_.Exception.Message)"
        }
    }
}

Write-Log "============================================================"
Write-Log "🏠 生活小常識 100 篇 — 即時顯示 + 排程優化版 v1.0"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/6] 檢查 API Key..."
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
# 步驟 2：定義 100 篇生活小常識文章
# ============================================================
Write-Log "[2/6] 定義 100 篇文章清單..."
Save-Checkpoint -Stage "article_definition"

$Articles = @(
    # ============================================================
    # 🏠 居家裝潢與空間改造 (10篇)
    # ============================================================
    @{ keyword = "北歐風居家布置：5 個關鍵元素打造質感空間"; filename = "nordic-home-decor.html" },
    @{ keyword = "無印良品風收納：極簡美學的實作指南"; filename = "muji-style-storage.html" },
    @{ keyword = "小陽台改造計畫：1 坪也能變成療癒花園"; filename = "small-balcony-makeover.html" },
    @{ keyword = "租屋族裝飾技巧：不破壞牆面的 10 種方法"; filename = "renter-decor-tips.html" },
    @{ keyword = "家中動線規劃：讓生活更順暢的空間設計"; filename = "home-flow-design.html" },
    @{ keyword = "採光改善技巧：讓陰暗房間瞬間明亮"; filename = "brighten-dark-room.html" },
    @{ keyword = "牆面裝飾靈感：照片牆、掛畫、層板搭配術"; filename = "wall-decor-ideas.html" },
    @{ keyword = "地板材質選擇：木地板、磁磚、地毯優缺點比較"; filename = "flooring-material-guide.html" },
    @{ keyword = "窗戶窗簾搭配：遮光、通風、美觀一次搞定"; filename = "curtain-window-treatment.html" },
    @{ keyword = "家具擺放風水：科學觀點與實用建議"; filename = "feng-shui-furniture.html" },

    # ============================================================
    # 🛒 聰明消費與理財 (10篇)
    # ============================================================
    @{ keyword = "網購省錢密技：折扣碼、現金回饋、比價全攻略"; filename = "online-shopping-tips.html" },
    @{ keyword = "好市多必買清單：2026 年 CP 值最高商品推薦"; filename = "costco-shopping-list.html" },
    @{ keyword = "全聯省錢攻略：週六折扣日這樣買最划算"; filename = "pxmart-saving-guide.html" },
    @{ keyword = "家樂福隱藏優惠：會員價、折價券、點數兌換技巧"; filename = "carrefour-shopping-tips.html" },
    @{ keyword = "電商大促銷攻略：618、雙11、黑五這樣買最省"; filename = "ecommerce-sale-guide.html" },
    @{ keyword = "零錢理財法：每天存 50 元，一年存 18000 元"; filename = "coin-saving-method.html" },
    @{ keyword = "家庭記帳 APP 推薦：2026 年 5 款最好用工具"; filename = "budget-apps-2026.html" },
    @{ keyword = "年終獎金分配術：投資、還債、消費的最佳比例"; filename = "year-end-bonus-plan.html" },
    @{ keyword = "親子理財教育：讓孩子從小學會管錢"; filename = "kids-financial-education.html" },
    @{ keyword = "退休金試算：現在開始每月存多少才夠"; filename = "retirement-savings-calc.html" },

    # ============================================================
    # 🍽️ 飲食與營養知識 (10篇)
    # ============================================================
    @{ keyword = "168 斷食法完整攻略：適合台灣人的執行指南"; filename = "intermittent-fasting-guide.html" },
    @{ keyword = "減醣飲食入門：新手第一週菜單規劃"; filename = "low-carb-diet-guide.html" },
    @{ keyword = "植物肉 vs 真肉：營養比較與選購建議"; filename = "plant-based-meat-guide.html" },
    @{ keyword = "超級食物清單：2026 年必吃的 10 種健康食材"; filename = "superfoods-list-2026.html" },
    @{ keyword = "台灣傳統市場採買指南：挑選新鮮食材的秘訣"; filename = "traditional-market-guide.html" },
    @{ keyword = "外食族健康吃：自助餐、便當、便利商店這樣選"; filename = "healthy-eating-out.html" },
    @{ keyword = "益生菌這樣吃：挑選、食用時機與注意事項"; filename = "probiotics-guide.html" },
    @{ keyword = "保健食品選購指南：維生素、礦物質、魚油怎麼挑"; filename = "supplement-buying-guide.html" },
    @{ keyword = "兒童營養午餐：學校便當健康搭配秘訣"; filename = "kids-lunchbox-guide.html" },
    @{ keyword = "銀髮族營養：高齡長輩的飲食照護重點"; filename = "elderly-nutrition-guide.html" },

    # ============================================================
    # 🧘 心靈成長與情緒管理 (10篇)
    # ============================================================
    @{ keyword = "正念冥想入門：每天 5 分鐘減輕焦慮"; filename = "mindfulness-basics.html" },
    @{ keyword = "情緒日記寫法：透過書寫療癒內心"; filename = "emotion-journal-guide.html" },
    @{ keyword = "職場壓力管理：上班族必學的 5 個放鬆技巧"; filename = "workplace-stress-relief.html" },
    @{ keyword = "失眠自救手冊：不需藥物的助眠方法"; filename = "insomnia-self-help.html" },
    @{ keyword = "高敏感人生活指南：把敏感變成優勢"; filename = "hsp-life-guide.html" },
    @{ keyword = "自我肯定練習：建立自信的 7 個日常習慣"; filename = "self-affirmation-practice.html" },
    @{ keyword = "人際關係界線：學會說不的藝術"; filename = "boundary-setting-guide.html" },
    @{ keyword = "數位排毒計畫：減少手機依賴的實戰步驟"; filename = "digital-detox-plan.html" },
    @{ keyword = "面對失敗的勇氣：從挫折中成長的方法"; filename = "dealing-with-failure.html" },
    @{ keyword = "感恩練習：每天記錄 3 件好事改變人生"; filename = "gratitude-practice.html" },

    # ============================================================
    # 💡 生活科技與數位應用 (10篇)
    # ============================================================
    @{ keyword = "長輩手機教學：Line、Facebook 簡單上手"; filename = "senior-phone-guide.html" },
    @{ keyword = "免費雲端空間整理：Google、iCloud、OneDrive 比較"; filename = "cloud-storage-guide.html" },
    @{ keyword = "家庭 WiFi 優化：讓網路速度提升 50% 的方法"; filename = "wifi-optimization-guide.html" },
    @{ keyword = "手機資安檢查：5 步驟確認個資不外洩"; filename = "phone-security-check.html" },
    @{ keyword = "AI 工具入門：用 ChatGPT 提升生活效率"; filename = "ai-tools-daily-life.html" },
    @{ keyword = "智慧家庭設備推薦：2026 年 CP 值最高選擇"; filename = "smart-home-devices-2026.html" },
    @{ keyword = "電子發票 APP 推薦：對獎、記帳一次搞定"; filename = "e-invoice-app-guide.html" },
    @{ keyword = "數位筆記術：Notion、Evernote 新手入門"; filename = "digital-note-taking.html" },
    @{ keyword = "免費圖片編輯工具：Canva、美圖秀秀實戰教學"; filename = "free-image-editing-tools.html" },
    @{ keyword = "線上學習平台推薦：Coursera、Hahow、Udemy 怎麼選"; filename = "online-learning-platforms.html" },

    # ============================================================
    # 🚗 交通與移動生活 (10篇)
    # ============================================================
    @{ keyword = "電動車購買指南：2026 年台灣市場完整分析"; filename = "ev-buying-guide-2026.html" },
    @{ keyword = "機車保養 DIY：換機油、煞車皮自己來"; filename = "scooter-maintenance-diy.html" },
    @{ keyword = "汽車保險怎麼買：強制險、第三責任險、超額險解析"; filename = "car-insurance-guide.html" },
    @{ keyword = "台北捷運攻略：隱藏版省錢技巧與時間優化"; filename = "taipei-mrt-guide.html" },
    @{ keyword = "共享單車使用教學：YouBike、GoShare 完整攻略"; filename = "bike-sharing-guide.html" },
    @{ keyword = "長途開車必備清單：安全、舒適、娛樂一次準備"; filename = "road-trip-checklist.html" },
    @{ keyword = "機場接送比價：Uber、計程車、機場快線哪個划算"; filename = "airport-transfer-guide.html" },
    @{ keyword = "出國行李打包術：10 天旅行一個登機箱搞定"; filename = "packing-light-guide.html" },
    @{ keyword = "旅行平安險比較：國內外旅遊保障怎麼選"; filename = "travel-insurance-guide.html" },
    @{ keyword = "自駕遊路線規劃：台灣 10 條最美公路推薦"; filename = "road-trip-routes-taiwan.html" },

    # ============================================================
    # 🏥 居家健康與安全 (10篇)
    # ============================================================
    @{ keyword = "家庭用藥管理：過期藥品處理與常備藥清單"; filename = "home-medicine-guide.html" },
    @{ keyword = "血壓計選購與使用：正確測量的 6 個步驟"; filename = "blood-pressure-monitor-guide.html" },
    @{ keyword = "居家防疫消毒：正確使用漂白水、酒精的方法"; filename = "home-disinfection-guide.html" },
    @{ keyword = "異物梗塞急救法：哈姆立克術圖解教學"; filename = "choking-first-aid.html" },
    @{ keyword = "燒燙傷處理：沖脫泡蓋送正確步驟"; filename = "burn-first-aid.html" },
    @{ keyword = "中暑預防與處理：熱衰竭、熱中暑辨別指南"; filename = "heat-stroke-guide.html" },
    @{ keyword = "過敏季節對策：花粉、塵蟎、黴菌防護方法"; filename = "allergy-season-guide.html" },
    @{ keyword = "肩頸痠痛舒緩：辦公室 5 分鐘伸展操"; filename = "neck-shoulder-stretch.html" },
    @{ keyword = "正確搬重物姿勢：預防腰傷的關鍵技巧"; filename = "lifting-heavy-objects.html" },
    @{ keyword = "居家視力保健：長時間用眼的護眼對策"; filename = "eye-health-home-guide.html" },

    # ============================================================
    # 📚 親子教育與家庭生活 (10篇)
    # ============================================================
    @{ keyword = "新手爸媽生存指南：嬰兒照顧的第一個月"; filename = "new-parent-survival-guide.html" },
    @{ keyword = "幼兒如廁訓練：戒尿布的 7 個成功步驟"; filename = "potty-training-guide.html" },
    @{ keyword = "親子共讀技巧：讓孩子愛上閱讀的方法"; filename = "parent-child-reading.html" },
    @{ keyword = "兒童情緒教育：教孩子認識與表達情緒"; filename = "kids-emotional-education.html" },
    @{ keyword = "家事分工表：讓全家一起參與家務的系統"; filename = "family-chore-system.html" },
    @{ keyword = "家庭會議制度：建立良好親子溝通的橋樑"; filename = "family-meeting-guide.html" },
    @{ keyword = "品格教育實踐：日常生活中培養孩子好品格"; filename = "character-education-guide.html" },
    @{ keyword = "兒童理財教育：零用錢給法與儲蓄習慣養成"; filename = "kids-money-management.html" },
    @{ keyword = "親子旅遊規劃：帶小孩出遊的實用技巧"; filename = "family-travel-guide.html" },
    @{ keyword = "孩子手機管理：螢幕時間設定的實戰策略"; filename = "kids-screen-time-guide.html" },

    # ============================================================
    # 🌿 環境與永續生活 (10篇)
    # ============================================================
    @{ keyword = "零廢棄生活入門：新手也能做到的 5 件事"; filename = "zero-waste-basics.html" },
    @{ keyword = "自備餐具攻略：環保杯、便當盒、吸管推薦"; filename = "reusable-tableware-guide.html" },
    @{ keyword = "塑膠減量生活：10 個替代方案一次學會"; filename = "plastic-reduction-guide.html" },
    @{ keyword = "二手衣物再利用：改造、交換、捐贈全攻略"; filename = "secondhand-clothing-guide.html" },
    @{ keyword = "食物不浪費計畫：剩食再利用的創意方法"; filename = "food-waste-reduction.html" },
    @{ keyword = "環保清潔劑 DIY：無化學成分的居家清潔"; filename = "eco-friendly-cleaners.html" },
    @{ keyword = "綠色消費指南：認識環保標章與永續品牌"; filename = "green-consumption-guide.html" },
    @{ keyword = "自種香草廚房：在家種植料理必備香料"; filename = "kitchen-herb-garden.html" },
    @{ keyword = "社區環保行動：從鄰里開始的永續生活"; filename = "community-environmental-action.html" },
    @{ keyword = "氣候變遷因應：個人可以做的減碳行動"; filename = "climate-change-action.html" },

    # ============================================================
    # 🎨 興趣與生活美學 (10篇)
    # ============================================================
    @{ keyword = "手寫字練習：從零開始學硬筆書法"; filename = "handwriting-practice.html" },
    @{ keyword = "水彩畫入門：新手必備的工具與基礎技巧"; filename = "watercolor-basics.html" },
    @{ keyword = "攝影新手教學：用手機拍出專業級照片"; filename = "mobile-photography-guide.html" },
    @{ keyword = "居家咖啡沖煮：手沖、愛樂壓、摩卡壺教學"; filename = "home-brew-coffee.html" },
    @{ keyword = "品茶入門：台灣烏龍茶、紅茶、綠茶認識"; filename = "tea-tasting-basics.html" },
    @{ keyword = "居家調酒指南：10 款經典雞尾酒 DIY"; filename = "home-cocktail-guide.html" },
    @{ keyword = "陶藝入門：手捏、拉坯初學者教學"; filename = "pottery-basics.html" },
    @{ keyword = "編織教學：鉤針、棒針新手第一件作品"; filename = "knitting-crochet-basics.html" },
    @{ keyword = "園藝治療：透過種植療癒身心的實證方法"; filename = "horticultural-therapy.html" },
    @{ keyword = "閱讀習慣養成：一年讀 50 本書的實踐計畫"; filename = "reading-habit-guide.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇生活小常識文章"

# ============================================================
# 步驟 3：檢查 life/ 目錄
# ============================================================
Write-Log "[3/6] 檢查 life/ 目錄..."
Save-Checkpoint -Stage "directory_check"

$TargetDir = "$ProjectRoot\life"
if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    Write-Log "   📁 life/ 目錄已建立"
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
    Write-Log "   ✅ 所有 100 篇文章已存在，無需生成"
    Write-Log "============================================================"
    Write-Log "✅ 檢查完成！所有文章已存在"
    exit 0
}

Write-Log "   ⚠️ 缺失 $($MissingArticles.Count) 篇文章，開始生成..."
foreach ($article in $MissingArticles) {
    Write-Log "      📄 $($article.filename)"
}

# ============================================================
# 步驟 4：寫入 pending-articles.json
# ============================================================
Write-Log "[4/6] 寫入缺失文章 JSON..."
Save-Checkpoint -Stage "json_write" -Detail "Missing: $($MissingArticles.Count) articles"

$jsonContent = "[`n"
$first = $true
foreach ($article in $MissingArticles) {
    if (-not $first) { $jsonContent += "," }
    $first = $false
    $jsonContent += @"
  {
    "keyword": "$($article.keyword)",
    "category": "🏠 生活小常識",
    "filename": "life/$($article.filename)",
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
Write-Log "✅ JSON 已寫入 ($($MissingArticles.Count) 篇，UTF-8 無 BOM)"

# ============================================================
# 步驟 5：合併文章
# ============================================================
Write-Log "[5/6] 直接合併文章到 master-articles.json..."
Save-Checkpoint -Stage "merge"

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
# 步驟 6：執行文章生成 — 即時顯示模式
# ============================================================
Write-Log "[6/6] 執行文章生成與部署..."
Save-Checkpoint -Stage "generation_start"

Write-Log "   [6a] 生成文章 (python src/main.py --force deepseek)..."
Write-Log "   ⏳ 預計耗時 60-90 分鐘"
Write-Log ""
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  📡 文章生成即時輸出 (每篇文章完成時顯示)"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log ""

$MainOutputPath = "$LogDir\main-output.txt"

python src/main.py --force deepseek 2>&1 | Tee-Object -FilePath $MainOutputPath

$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    Write-Log ""
    Write-Log "❌ 文章生成失敗，退出碼: $ExitCode"
    Write-Log "⚠️ 將在 60 秒後重試..."
    Start-Sleep -Seconds 60
    
    Write-Log ""
    Write-Log "🔄 第二次嘗試..."
    python src/main.py --force deepseek 2>&1 | Tee-Object -FilePath "$LogDir\main-output-retry.txt"
    
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
# 步驟 7：更新分類頁面與 Sitemap
# ============================================================
Write-Log "   [6b] 更新分類頁面與 Sitemap..."
Save-Checkpoint -Stage "category_update"

python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ 分類頁面更新失敗，嘗試重試..."
    Start-Sleep -Seconds 10
    python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log
}
Write-Log "✅ 分類頁面與首頁已更新"

# ============================================================
# 步驟 8：部署到 Cloudflare
# ============================================================
Write-Log "   [6c] 部署到 Cloudflare Pages..."
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
# 完成報告
# ============================================================
Save-Checkpoint -Stage "complete"
Write-Log "============================================================"
Write-Log "✅ 生活小常識 100 篇 — 即時顯示 + 排程優化版 v1.0 執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📊 本次新增: $($MissingArticles.Count) 篇"
Write-Log "📁 日誌位置: $LogFile"
Write-Log "============================================================"

# ============================================================
# 寄送完成通知
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
    $Subject = "🏠 生活小常識 100 篇 — 即時顯示 + 排程優化版完成通知"
    $Body = @"
生活小常識 100 篇即時顯示 + 排程優化版已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 本次新增：$($MissingArticles.Count) 篇
   - 日誌位置：$LogFile
   - 部署狀態：✅ 已完成

請至 https://www.ahpal.com/category-life.html 查看最新文章。

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