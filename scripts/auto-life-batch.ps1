# ============================================================
# 🏠 生活小常識 — 無人值守 + 方便添加 v2.6
# ============================================================
# 用途：無人值守生成生活小常識文章
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
#   - 🆕 加入 ETA 預估剩餘時間
#   - 🆕 加入進度摘要 (每 10 篇顯示)
#   - 🆕 加入跳過計數摘要
#   - 🆕 與 nature v2.6 保持一致
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
$LogFile = "$LogDir\auto-life-batch-v2-$Timestamp.log"
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
Write-Log "🏠 生活小常識 — 無人值守 + 方便添加 v2.6"
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
# 📝 步驟 2：★ 方便添加區 ★
# ============================================================
Write-Log "[2/4] 準備文章清單..."

$Articles = @(
    # ============================================================
    # 🍜 台灣美食進階 (20篇)
    # ============================================================
    @{ keyword = "台北南機場夜市美食攻略：在地人私藏的 10 家排隊攤位"; filename = "nanjichang-night-market-food-guide.html" },
    @{ keyword = "台中第二市場美食巡禮：從早餐吃到宵夜的 8 家老店"; filename = "taichung-second-market-food-guide.html" },
    @{ keyword = "台南花園夜市必吃清單：在地人推薦的 12 攤經典美味"; filename = "tainan-huayuan-night-market-guide.html" },
    @{ keyword = "高雄鹽埕區老味道：隱身巷弄的 8 家傳承半世紀小吃"; filename = "kaohsiung-yancheng-old-flavor-guide.html" },
    @{ keyword = "新竹東門市場美食重生：文青風老市場的 10 家必吃攤位"; filename = "hsinchu-dongmen-market-food-guide.html" },
    @{ keyword = "台北迪化街美食地圖：霞海城隍廟周邊的 7 家老字號"; filename = "dihua-street-food-guide.html" },
    @{ keyword = "台中中區老宅咖啡巡禮：12 間充滿故事的復古咖啡館"; filename = "taichung-central-district-cafe-guide.html" },
    @{ keyword = "台南中西區小吃全攻略：國華街到保安路的經典路線"; filename = "tainan-west-central-food-guide.html" },
    @{ keyword = "高雄左營眷村美食：10 家來自大江南北的眷村味"; filename = "kaohsiung-zuoying-military-village-food.html" },
    @{ keyword = "台北晴光市場美食：雙城街週邊的 8 家經典小吃"; filename = "qingguang-market-food-guide.html" },
    @{ keyword = "台灣蚵仔煎王者對決：5 家南北名店終極評比"; filename = "taiwan-oyster-omelet-ranking.html" },
    @{ keyword = "台灣滷肉飯地圖：從北到南 10 家必吃名店完整評測"; filename = "taiwan-braised-pork-rice-map.html" },
    @{ keyword = "台中公益路美食一條街：30 家餐廳精選推薦名單"; filename = "taichung-gongyi-road-food-guide.html" },
    @{ keyword = "台北市民大道熱炒一條街：8 家深夜食堂評比"; filename = "taipei-citizen-boulevard-stir-fry-guide.html" },
    @{ keyword = "台南善化牛墟美食：只在特定日子出現的流動夜市攻略"; filename = "tainan-shanhua-cattle-market-food.html" },
    @{ keyword = "高雄瑞豐夜市 vs 六合夜市：兩大夜市終極對決"; filename = "kaohsiung-ruifeng-vs-liuhe-night-market.html" },
    @{ keyword = "台灣擔仔麵全攻略：台南 vs 台北 6 家名店比較"; filename = "taiwan-danzai-noodle-comparison.html" },
    @{ keyword = "台北東區燒肉 vs 火鍋：10 家高 CP 值餐廳推薦"; filename = "taipei-dongqu-yakiniku-hotpot-guide.html" },
    @{ keyword = "台灣鹽酥雞名店巡禮：從北到南 8 家必吃炸物專賣"; filename = "taiwan-salt-chicken-guide.html" },
    @{ keyword = "台中逢甲 vs 一中夜市：兩大學生商圈美食對決"; filename = "taichung-fengjia-vs-yizhong-night-market.html" },

    # ============================================================
    # 🏨 住宿進階 (15篇)
    # ============================================================
    @{ keyword = "台北 10 家高 CP 值平價旅館推薦：每晚 1500 元有找"; filename = "taipei-budget-hotel-1500-guide.html" },
    @{ keyword = "台南特色民宿精選：5 家老屋改造的質感住宿"; filename = "tainan-old-house-homestay-guide.html" },
    @{ keyword = "台中勤美誠品周邊住宿推薦：走路就到草悟道的 6 家旅館"; filename = "taichung-qinmei-hotel-guide.html" },
    @{ keyword = "花蓮市區平價住宿：離東大門夜市最近的 5 家選擇"; filename = "hualien-city-budget-hotel-guide.html" },
    @{ keyword = "墾丁民宿 vs 飯店：8 家適合家庭與情侶的住宿評比"; filename = "kenting-homestay-vs-hotel-guide.html" },
    @{ keyword = "九份夜景住宿推薦：看山海景第一排的 4 家民宿"; filename = "jiufen-night-view-homestay-guide.html" },
    @{ keyword = "台東市區住宿指南：離鐵花村最近的 5 家高評價旅館"; filename = "taitung-city-hotel-guide.html" },
    @{ keyword = "澎湖馬公住宿推薦：海景第一排的 5 家特色民宿"; filename = "penghu-magong-seaview-homestay.html" },
    @{ keyword = "宜蘭羅東住宿：離夜市最近的 6 家平價選擇"; filename = "yilan-luodong-hotel-guide.html" },
    @{ keyword = "桃園機場周邊住宿：4 家適合紅眼班機的過境旅館"; filename = "taoyuan-airport-hotel-guide.html" },
    @{ keyword = "阿里山住宿推薦：看日出最近的 3 家旅館與民宿"; filename = "alishan-sunrise-hotel-guide.html" },
    @{ keyword = "綠島住宿推薦：離港口最近的 5 家潛水友善民宿"; filename = "green-island-homestay-guide.html" },
    @{ keyword = "日月潭伊達邵住宿：湖景第一排的 4 家精選旅館"; filename = "sun-moon-lake-itashao-hotel-guide.html" },
    @{ keyword = "台南民宿包棟推薦：5 家適合家族旅遊的獨棟住宿"; filename = "tainan-whole-house-homestay-guide.html" },
    @{ keyword = "台灣豪華露營推薦：5 家免裝備奢華營地評比"; filename = "taiwan-glamping-guide.html" },

    # ============================================================
    # 🚗 國內旅遊進階 (20篇)
    # ============================================================
    @{ keyword = "苗栗三義勝興車站與龍騰斷橋：鐵道文化一日遊"; filename = "miaoli-sanyi-railway-guide.html" },
    @{ keyword = "南投埔里日月潭東岸：自行車環湖與秘境景點攻略"; filename = "nantou-puli-sun-moon-lake-east-guide.html" },
    @{ keyword = "嘉義市區 2 天 1 夜：檜意森活村與嘉義公園深度遊"; filename = "chiayi-2d1n-guide.html" },
    @{ keyword = "台東池上關山小鎮漫遊：稻田與米鄉文化之旅"; filename = "taitung-chishang-guanshan-guide.html" },
    @{ keyword = "基隆正濱漁港與和平島：彩色屋與海蝕地質秘境"; filename = "keelung-zhengbin-fishing-port-guide.html" },
    @{ keyword = "桃園大溪與復興：兩蔣文化與部落輕旅行"; filename = "taoyuan-daxi-fuxing-guide.html" },
    @{ keyword = "新北深坑石碇老街：豆腐與茶香的文化之旅"; filename = "new-taipei-shenkeng-shiding-guide.html" },
    @{ keyword = "新竹竹東與北埔：客家山城 2 日深度文化遊"; filename = "hsinchu-zhudong-beipu-guide.html" },
    @{ keyword = "苗栗通霄與苑裡：山海之間的小鎮漫遊"; filename = "miaoli-tongxiao-yuanli-guide.html" },
    @{ keyword = "雲林北港與新港：媽祖文化與傳統工藝之旅"; filename = "yunlin-beigang-xingang-guide.html" },
    @{ keyword = "嘉義東石與布袋：蚵田與溼地生態之旅"; filename = "chiayi-dongshi-budai-guide.html" },
    @{ keyword = "台南鹽水與新營：月津港燈節與糖廠文化"; filename = "tainan-yanshui-xinying-guide.html" },
    @{ keyword = "高雄美濃與旗山：客家文化與香蕉王國之旅"; filename = "kaohsiung-meinong-qishan-guide.html" },
    @{ keyword = "屏東潮州與萬巒：豬腳與燒冷冰的美食之旅"; filename = "pingtung-chaozhou-wanluan-guide.html" },
    @{ keyword = "花蓮光復與鳳林：糖廠與客家小鎮慢活之旅"; filename = "hualien-guangfu-fenglin-guide.html" },
    @{ keyword = "台東金峰與太麻里：金崙溫泉與釋迦故鄉之旅"; filename = "taitung-jinfeng-taimali-guide.html" },
    @{ keyword = "澎湖北環一日遊：跨海大橋到西嶼燈塔的經典路線"; filename = "penghu-north-ring-guide.html" },
    @{ keyword = "金門戰地文化 3 日深度遊：坑道與洋樓的歷史之旅"; filename = "kinmen-3d2n-war-culture-guide.html" },
    @{ keyword = "馬祖南竿與北竿：藍眼淚與閩東文化之旅"; filename = "matsu-nangan-beigan-guide.html" },
    @{ keyword = "台灣小鎮漫遊 10 選：觀光局推薦的經典小鎮攻略"; filename = "taiwan-small-town-10-guide.html" },

    # ============================================================
    # 🍽️ 美食文化與深度 (15篇)
    # ============================================================
    @{ keyword = "台灣夜市文化解析：從攤車到米其林的庶民美食演進"; filename = "taiwan-night-market-culture-guide.html" },
    @{ keyword = "台灣茶文化之旅：從坪林到阿里山的品茶路線"; filename = "taiwan-tea-culture-guide.html" },
    @{ keyword = "台灣傳統糕餅巡禮：鳳梨酥、太陽餅、綠豆椪名店推薦"; filename = "taiwan-traditional-cake-guide.html" },
    @{ keyword = "台灣精釀啤酒地圖：10 家在地酒廠與酒吧推薦"; filename = "taiwan-craft-beer-guide.html" },
    @{ keyword = "台灣咖啡莊園巡禮：從古坑到東山的精品咖啡之路"; filename = "taiwan-coffee-farm-guide.html" },
    @{ keyword = "台灣巧克力工坊推薦：5 家 bean-to-bar 精品巧克力"; filename = "taiwan-chocolate-factory-guide.html" },
    @{ keyword = "台灣小籠包名店評比：鼎泰豐 vs 點水樓 vs 杭州小籠包"; filename = "taiwan-xiaolongbao-comparison.html" },
    @{ keyword = "台灣牛肉麵文化：從老兵家鄉味到國際名店的演變"; filename = "taiwan-beef-noodle-culture-guide.html" },
    @{ keyword = "台灣古早味飲料巡禮：青草茶、蓮藕茶、冬瓜茶名店"; filename = "taiwan-traditional-drinks-guide.html" },
    @{ keyword = "台灣市場美食文化：從傳統早市到深夜夜市的味覺記憶"; filename = "taiwan-market-food-culture-guide.html" },
    @{ keyword = "台灣辦桌文化與總舖師：南部宴席料理的經典菜色"; filename = "taiwan-banquet-culture-guide.html" },
    @{ keyword = "台灣客家美食地圖：從粄條到梅干扣肉的經典客家味"; filename = "taiwan-hakka-food-guide.html" },
    @{ keyword = "台灣原住民料理巡禮：馬告、山豬肉到小米酒的部落美食"; filename = "taiwan-indigenous-food-guide.html" },
    @{ keyword = "台灣素食文化與蔬食餐廳推薦：10 家蔬食者必訪名店"; filename = "taiwan-vegetarian-restaurant-guide.html" },
    @{ keyword = "台灣甜湯文化：燒仙草、紅豆湯、薑母茶到花生湯的冬日溫暖"; filename = "taiwan-sweet-soup-culture-guide.html" },

    # ============================================================
    # 🌿 生態與自然旅遊 (15篇)
    # ============================================================
    @{ keyword = "台灣賞鳥秘境：10 個候鳥過境與留鳥觀察熱點"; filename = "taiwan-bird-watching-hotspots.html" },
    @{ keyword = "台灣賞螢火蟲季節：5 月到 6 月的 8 個最佳觀賞點"; filename = "taiwan-firefly-watching-guide.html" },
    @{ keyword = "台灣賞楓祕境：秋季限定的 10 個紅葉景點"; filename = "taiwan-autumn-maple-guide.html" },
    @{ keyword = "台灣賞櫻景點全攻略：從陽明山到武陵農場的粉色路線"; filename = "taiwan-cherry-blossom-guide.html" },
    @{ keyword = "台灣濕地生態旅遊：5 大國家級濕地推薦"; filename = "taiwan-wetland-ecotourism-guide.html" },
    @{ keyword = "台灣瀑布秘境：從十分瀑布到白楊瀑布的 10 條步道"; filename = "taiwan-waterfall-hiking-guide.html" },
    @{ keyword = "台灣森林遊樂區全攻略：從太平山到知本的 8 處森呼吸路線"; filename = "taiwan-forest-recreation-guide.html" },
    @{ keyword = "台灣星空觀測點推薦：從合歡山到墾丁的 8 處無光害景點"; filename = "taiwan-stargazing-guide.html" },
    @{ keyword = "台灣金針花季：花蓮六十石山與台東太麻里賞花攻略"; filename = "taiwan-daylily-season-guide.html" },
    @{ keyword = "台灣桐花季攻略：4 月到 5 月的 10 條賞桐步道"; filename = "taiwan-tung-flower-guide.html" },
    @{ keyword = "台灣賞梅秘境：1 月到 2 月的 6 個梅花景點"; filename = "taiwan-plum-blossom-guide.html" },
    @{ keyword = "台灣海芋季：陽明山竹子湖的浪漫白色海芋花海"; filename = "taiwan-calla-lily-guide.html" },
    @{ keyword = "台灣繡球花季：陽明山與杉林溪的紫色花海攻略"; filename = "taiwan-hydrangea-guide.html" },
    @{ keyword = "台灣台灣欒樹季節：10 月的城市金色樹海與觀賞路線"; filename = "taiwan-golden-rain-tree-guide.html" },
    @{ keyword = "台灣生態觀察入門：從蛙類、蝴蝶到蜻蜓的自然筆記"; filename = "taiwan-nature-observation-guide.html" },

    # ============================================================
    # 🏖️ 海島與離島旅遊 (15篇)
    # ============================================================
    @{ keyword = "澎湖花火節 2026 攻略：最佳觀賞點與行程推薦"; filename = "penghu-fireworks-festival-2026-guide.html" },
    @{ keyword = "金門海灘秘境：5 個隱藏版沙灘與軌條砦夕陽景點"; filename = "kinmen-beach-secret-guide.html" },
    @{ keyword = "馬祖東引與莒光：藍眼淚與軍事遺跡之旅"; filename = "matsu-dongyin-juguang-guide.html" },
    @{ keyword = "小琉球 2 天 1 夜：浮潛、海龜與潮間帶生態之旅"; filename = "xiaoliuqiu-2d1n-guide.html" },
    @{ keyword = "綠島 3 天 2 夜：潛水、溫泉與監獄文化之旅"; filename = "green-island-3d2n-guide.html" },
    @{ keyword = "蘭嶼旅遊攻略：達悟族文化與飛魚季深度體驗"; filename = "lanyu-travel-guide.html" },
    @{ keyword = "澎湖南海跳島：七美、望安、虎井嶼一日遊"; filename = "penghu-south-island-hopping-guide.html" },
    @{ keyword = "金門戰地坑道之旅：翟山坑道、瓊林坑道與民防遺跡"; filename = "kinmen-tunnel-war-guide.html" },
    @{ keyword = "馬祖芹壁村與北竿：閩東聚落與石頭屋之美"; filename = "matsu-qinbi-beigan-guide.html" },
    @{ keyword = "澎湖東海一日遊：鳥嶼、員貝嶼與澎澎灘水上活動"; filename = "penghu-east-island-guide.html" },
    @{ keyword = "金門高粱酒文化之旅：酒廠參觀與品酒體驗"; filename = "kinmen-kaoliang-liquor-guide.html" },
    @{ keyword = "馬祖宗教文化之旅：媽祖巨神像與宗教慶典"; filename = "matsu-religious-culture-guide.html" },
    @{ keyword = "澎湖海洋牧場體驗：釣魚、烤牡蠣與海上平台活動"; filename = "penghu-ocean-ranch-guide.html" },
    @{ keyword = "金門迎城隍文化：一年一度的宗教盛事與遶境體驗"; filename = "kinmen-chenghuang-festival-guide.html" },
    @{ keyword = "台灣離島 5 選：澎湖、金門、馬祖、綠島、小琉球比較"; filename = "taiwan-outlying-islands-comparison.html" }
)
Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 📂 步驟 3：檢查 life/ 目錄 → 寫入 JSON → 合併
# ============================================================
Write-Log "[3/4] 檢查缺失文章並合併到 master-articles.json..."
Save-Checkpoint -Stage "merge"

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

life_articles = [a for a in all_articles if a.get('filename', '').startswith('life/')]
total = len(life_articles)
print(f'📊 從 master-articles.json 找到 {total} 篇 life 文章', flush=True)

start_time = time.time()
success_count = 0
fail_count = 0
skip_count = 0

for idx, article in enumerate(life_articles, 1):
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

life_articles = [a for a in all_articles if a.get('filename', '').startswith('life/')]
total = len(life_articles)

success_count = 0
for idx, article in enumerate(life_articles, 1):
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
Write-Log "✅ 生活小常識 — 無人值守 + 方便添加 v2.6 執行完畢！"
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
    $Subject = "🏠 生活小常識批次生成 v2.6 完成通知"
    $Body = @"
生活小常識批次生成 v2.6 已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
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