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
    # 🍜 台灣美食 (25篇)
    # ============================================================
    @{ keyword = "台北寧夏夜市必吃 10 大經典小吃：從蚵仔煎到豬肝湯的深夜食堂"; filename = "ningxia-night-market-food-guide.html" },
    @{ keyword = "台南國華街美食地圖：在地人推薦的 8 家排隊老店"; filename = "tainan-guohua-street-food-guide.html" },
    @{ keyword = "台中逢甲夜市攻略：從惡魔雞排到明倫蛋餅的必吃清單"; filename = "fengjia-night-market-bites.html" },
    @{ keyword = "高雄瑞豐夜市美食巡禮：在地人帶路的 10 攤隱藏版美味"; filename = "ruifeng-night-market-food-guide.html" },
    @{ keyword = "花蓮東大門夜市必吃推薦：原住民烤山豬肉到炸彈蔥油餅"; filename = "hualien-dongdamen-night-market-guide.html" },
    @{ keyword = "嘉義雞肉飯王者對決：劉里長 vs 阿溪 vs 郭家評測"; filename = "chiayi-turkey-rice-comparison.html" },
    @{ keyword = "彰化肉圓大比拼：老擔 vs 阿璋 vs 北門口誰是正統"; filename = "changhua-bawan-food-comparison.html" },
    @{ keyword = "新竹城隍廟口美食：米粉、貢丸湯到潤餅的經典巡禮"; filename = "hsinchu-chenghuang-temple-food.html" },
    @{ keyword = "宜蘭羅東夜市攻略：一串心、龍鳳腿、包心粉圓必吃清單"; filename = "luodong-night-market-food-guide.html" },
    @{ keyword = "基隆廟口夜市必吃 12 攤：營養三明治、泡泡冰到咖哩炒麵"; filename = "keelung-miaokou-night-market-guide.html" },
    @{ keyword = "台灣牛肉麵地圖：台北 5 家得獎名店完整評測"; filename = "taiwan-beef-noodle-map-guide.html" },
    @{ keyword = "台中燒肉吃到飽推薦：屋馬、茶六、碳佐麻里評比"; filename = "taichung-yakiniku-buffet-comparison.html" },
    @{ keyword = "高雄海鮮熱炒店推薦：在地人帶路的 6 家新鮮實惠選擇"; filename = "kaohsiung-seafood-stir-fry-guide.html" },
    @{ keyword = "台北日式拉麵地圖：鷹流、一蘭、麵屋武藏等 8 家評測"; filename = "taipei-ramen-map-guide.html" },
    @{ keyword = "台南牛肉湯全攻略：從六千到阿裕的早起人限定美味"; filename = "tainan-beef-soup-guide.html" },
    @{ keyword = "台灣珍珠奶茶地圖：50 嵐、春水堂、可不可等品牌評比"; filename = "taiwan-bubble-tea-ranking.html" },
    @{ keyword = "台中早午餐推薦：勤美周邊 5 家網美級美味名單"; filename = "taichung-brunch-guide.html" },
    @{ keyword = "台北麻辣鍋推薦：詹記、太和殿、老四川等名店評測"; filename = "taipei-spicy-hotpot-guide.html" },
    @{ keyword = "高雄咖啡廳地圖：鹽埕區 5 家復古風與工業風咖啡館"; filename = "kaohsiung-cafe-guide-yancheng.html" },
    @{ keyword = "花蓮公正包子與周家蒸餃：觀光客 vs 在地人終極對決"; filename = "hualien-baozi-zhengjiao-comparison.html" },
    @{ keyword = "台灣夜市全攻略：從北到南 10 大夜市必吃總整理"; filename = "taiwan-night-market-ultimate-guide.html" },
    @{ keyword = "台北東區早午餐地圖：從扶旺號到 Gontran Cherrier 的晨食選擇"; filename = "taipei-dongqu-brunch-guide.html" },
    @{ keyword = "桃園機場美食推薦：出國前必吃的 6 家機場餐廳"; filename = "taoyuan-airport-food-guide.html" },
    @{ keyword = "台灣火鍋吃到飽排名：和牛、海鮮、麻辣鍋 CP 值大比拚"; filename = "taiwan-hotpot-buffet-ranking.html" },
    @{ keyword = "台灣傳統糕餅伴手禮：鳳梨酥、太陽餅、牛軋糖名店推薦"; filename = "taiwan-traditional-pastry-gift-guide.html" },

    # ============================================================
    # 🏨 住宿與旅館 (15篇)
    # ============================================================
    @{ keyword = "台北平價設計旅店推薦：5 家 3000 元內的高 CP 值選擇"; filename = "taipei-budget-design-hotel-guide.html" },
    @{ keyword = "台中逢甲住宿推薦：逢甲夜市周邊 5 家平價民宿評比"; filename = "taichung-fengjia-hostel-guide.html" },
    @{ keyword = "台南神農街民宿推薦：老屋改建風格的 4 家特色住宿"; filename = "tainan-shennong-street-homestay.html" },
    @{ keyword = "花蓮海景民宿推薦：太平洋第一排的 5 家絕美住宿"; filename = "hualien-seaview-homestay-guide.html" },
    @{ keyword = "日月潭住宿攻略：湖景飯店 vs 民宿的 6 家實測評比"; filename = "sun-moon-lake-hotel-guide.html" },
    @{ keyword = "阿里山住宿推薦：看日出最近的 4 家旅館與民宿"; filename = "alishan-homestay-guide.html" },
    @{ keyword = "墾丁大街住宿指南：步行到夜市只要 3 分鐘的 5 家選擇"; filename = "kenting-street-hotel-guide.html" },
    @{ keyword = "九份山城民宿推薦：看夜景與老街最近的 4 家特色旅宿"; filename = "jiufen-homestay-guide.html" },
    @{ keyword = "高雄愛河畔住宿推薦：夜景與交通便利的 5 家飯店"; filename = "kaohsiung-love-river-hotel-guide.html" },
    @{ keyword = "宜蘭礁溪溫泉住宿推薦：平價到奢華的 6 家泡湯選擇"; filename = "yilan-jiaoxi-hotspring-hotel-guide.html" },
    @{ keyword = "台東池上住宿推薦：稻田景觀與慢活風格的 4 家民宿"; filename = "taidong-chishang-homestay-guide.html" },
    @{ keyword = "澎湖民宿推薦：臨近馬公市區與沙灘的 5 家優質住宿"; filename = "penghu-homestay-guide.html" },
    @{ keyword = "小琉球住宿推薦：離島度假風的 4 家特色民宿"; filename = "xiaoliuqiu-homestay-guide.html" },
    @{ keyword = "台灣露營地推薦：從豪華露營到野營的 6 個推薦營地"; filename = "taiwan-camping-sites-guide.html" },
    @{ keyword = "背包客棧推薦：台北、台中、高雄 6 家高評價青旅評比"; filename = "taiwan-hostel-guide.html" },

    # ============================================================
    # 🚗 國內旅遊行程 (20篇)
    # ============================================================
    @{ keyword = "台北 2 天 1 夜輕旅行：文青必訪的 10 個台北景點"; filename = "taipei-2d1n-itinerary-guide.html" },
    @{ keyword = "台中彩虹眷村到高美濕地：台中一日遊必訪 8 大景點"; filename = "taichung-one-day-trip-guide.html" },
    @{ keyword = "台南 3 天 2 夜深度遊：從安平古堡到奇美博物館的慢活旅程"; filename = "tainan-3d2n-itinerary-guide.html" },
    @{ keyword = "花蓮太魯閣一日遊：燕子口、九曲洞到白楊步道全攻略"; filename = "taroko-one-day-trip-guide.html" },
    @{ keyword = "台東鹿野高台熱氣球嘉年華：2026 年最新攻略與秘境拍攝點"; filename = "taitung-hot-air-balloon-festival-guide.html" },
    @{ keyword = "阿里山森林遊樂區攻略：小火車、日出、神木步道全指南"; filename = "alishan-forest-guide.html" },
    @{ keyword = "日月潭環湖自行車道：全球最美單車路線的完整騎行攻略"; filename = "sun-moon-lake-bike-guide.html" },
    @{ keyword = "墾丁國家公園懶人包：白沙灣、鵝鑾鼻、龍磐草原一日遊"; filename = "kenting-national-park-guide.html" },
    @{ keyword = "宜蘭太平山國家森林遊樂區：蹦蹦車與翠峰湖全攻略"; filename = "yilan-taipingshan-guide.html" },
    @{ keyword = "高雄駁二藝術特區到西子灣：高雄一日文青路線"; filename = "kaohsiung-pier2-xiziwan-guide.html" },
    @{ keyword = "九份金瓜石一日遊：老街、黃金博物館、陰陽海秘境"; filename = "jiufen-jinguashi-one-day-trip.html" },
    @{ keyword = "南投清境農場與合歡山：2 天 1 夜高山度假攻略"; filename = "cingjing-farm-hehuan-guide.html" },
    @{ keyword = "桃園大溪老街與慈湖：一日文化輕旅行完整規劃"; filename = "daxi-old-street-guide.html" },
    @{ keyword = "新竹內灣老街與尖石溫泉：假日小旅行全攻略"; filename = "neiwan-old-street-guide.html" },
    @{ keyword = "嘉義阿里山公路沿線：奮起湖、石棹、隙頂秘境大公開"; filename = "alishan-highway-scenic-guide.html" },
    @{ keyword = "苗栗南庄老街與向天湖：客家文化與賽夏族部落之旅"; filename = "nanzhuang-xiangtian-lake-guide.html" },
    @{ keyword = "雲林古坑咖啡莊園：台灣咖啡故鄉的一日品嚐之旅"; filename = "yunlin-guukeng-coffee-farm-guide.html" },
    @{ keyword = "台東都蘭與金樽：東海岸最美衝浪小鎮的 2 日生活"; filename = "taitung-dulan-jinzun-guide.html" },
    @{ keyword = "澎湖菊島 3 天 2 夜：跨海大橋、七美、望安跳島全攻略"; filename = "penghu-3d2n-island-guide.html" },
    @{ keyword = "金門戰地風情 2 日遊：坑道、洋樓、高粱酒文化之旅"; filename = "kinmen-2d1n-war-heritage-guide.html" },

    # ============================================================
    # ✈️ 國際旅遊與文化 (20篇)
    # ============================================================
    @{ keyword = "日本東京 5 天 4 夜自由行：新宿、淺草、澀谷必訪景點攻略"; filename = "tokyo-5d4n-itinerary-guide.html" },
    @{ keyword = "日本大阪美食攻略：道頓堀、黑門市場、心齋橋必吃清單"; filename = "osaka-food-guide-dotonbori.html" },
    @{ keyword = "韓國首爾 4 天 3 夜自由行：明洞、弘大、東大門購物指南"; filename = "seoul-4d3n-shopping-guide.html" },
    @{ keyword = "泰國曼谷 3 天 2 夜懶人包：水上市場、夜市、按摩全攻略"; filename = "bangkok-3d2n-guide.html" },
    @{ keyword = "越南峴港與會安古城：5 天 4 夜中越文化之旅"; filename = "danang-hoian-5d4n-guide.html" },
    @{ keyword = "新加坡 4 天 3 夜自由行：濱海灣、聖淘沙、美食完整攻略"; filename = "singapore-4d3n-itinerary.html" },
    @{ keyword = "馬來西亞吉隆坡雙峰塔與麻六甲：3 天 2 夜多元文化之旅"; filename = "kuala-lumpur-malacca-guide.html" },
    @{ keyword = "香港 3 天 2 夜美食購物指南：茶餐廳、廟街、維港夜景"; filename = "hong-kong-3d2n-guide.html" },
    @{ keyword = "澳門 2 天 1 夜自由行：大三巴、威尼斯人、蛋塔全攻略"; filename = "macau-2d1n-itinerary.html" },
    @{ keyword = "法國巴黎 7 天行程：羅浮宮、凡爾賽、左岸咖啡文化之旅"; filename = "paris-7-day-itinerary-guide.html" },
    @{ keyword = "義大利羅馬與梵蒂岡 5 天：競技場、許願池、西斯廷教堂"; filename = "rome-vatican-5-day-guide.html" },
    @{ keyword = "英國倫敦 6 天自由行：大笨鐘、倫敦塔、西區音樂劇"; filename = "london-6-day-itinerary-guide.html" },
    @{ keyword = "西班牙巴塞隆納 4 天：聖家堂、奎爾公園、海鮮飯之旅"; filename = "barcelona-4-day-guide.html" },
    @{ keyword = "德國慕尼黑與新天鵝堡：3 天 2 夜南德童話之旅"; filename = "munich-neuschwanstein-guide.html" },
    @{ keyword = "荷蘭阿姆斯特丹 3 天：運河遊船、梵谷博物館、風車村"; filename = "amsterdam-3-day-guide.html" },
    @{ keyword = "瑞士少女峰與策馬特：5 天 4 夜阿爾卑斯山極致之旅"; filename = "switzerland-jungfrau-zermatt-guide.html" },
    @{ keyword = "奧地利維也納與哈爾施塔特：音樂之都與湖區小鎮 4 天"; filename = "vienna-hallstatt-4-day-guide.html" },
    @{ keyword = "土耳其伊斯坦堡 5 天：聖索菲亞、藍色清真寺、博斯普魯斯"; filename = "istanbul-5-day-guide.html" },
    @{ keyword = "杜拜 4 天奢華之旅：帆船飯店、哈里發塔、沙漠衝沙"; filename = "dubai-4-day-luxury-guide.html" },
    @{ keyword = "沖繩 4 天 3 夜自駕遊：美麗海水族館、美國村、首里城"; filename = "okinawa-4d3n-driving-guide.html" },

    # ============================================================
    # 🚲 戶外活動與秘境 (20篇)
    # ============================================================
    @{ keyword = "台灣登山入門推薦：5 座適合新手的百岳與郊山路線"; filename = "taiwan-hiking-beginner-guide.html" },
    @{ keyword = "台灣單車環島攻略：10 天 9 夜路線規劃與裝備清單"; filename = "taiwan-cycling-around-island-guide.html" },
    @{ keyword = "台灣溫泉秘境推薦：5 個隱藏版野溪溫泉與知名湯泉評比"; filename = "taiwan-hot-spring-secret-guide.html" },
    @{ keyword = "日月潭 SUP 立槳體驗：日出時分的最美水上活動攻略"; filename = "sun-moon-lake-sup-guide.html" },
    @{ keyword = "花蓮清水斷崖獨木舟：太平洋絕壁下的海上探險"; filename = "hualien-qingshui-cliff-kayak-guide.html" },
    @{ keyword = "台東栗松野溪溫泉：全台最美野溪溫泉的秘境路線"; filename = "taitung-lisong-hotspring-guide.html" },
    @{ keyword = "墾丁後壁湖浮潛：珊瑚礁生態與藍色大海的秘境體驗"; filename = "kenting-houbiliao-snorkeling-guide.html" },
    @{ keyword = "阿里山追日出行程：祝山觀日平台與小笠原山攻略"; filename = "alishan-sunrise-guide.html" },
    @{ keyword = "合歡山賞雪與登山：冬季台灣最美的雪景路線"; filename = "hehuanshan-snow-climbing-guide.html" },
    @{ keyword = "新竹司馬庫斯：上帝部落的千年巨木群與星空露營"; filename = "smangus-giant-tree-guide.html" },
    @{ keyword = "宜蘭龜山島賞鯨與登島：牛奶湖與火山島秘境一日遊"; filename = "guishan-island-whale-watching-guide.html" },
    @{ keyword = "澎湖七美雙心石滬與藍洞：南海跳島必訪的浪漫景點"; filename = "qimei-twins-heart-stone-guide.html" },
    @{ keyword = "金門建功嶼與軌條砦：夕陽時分的絕美海岸步道"; filename = "kinmen-jiangong-islet-guide.html" },
    @{ keyword = "台南鹽田夕陽與井仔腳：台灣最古老的瓦盤鹽田之旅"; filename = "tainan-jingzaijiao-salt-pans-guide.html" },
    @{ keyword = "苗栗三義木雕與舊山線：鐵道文化與木雕藝術小鎮"; filename = "sanyi-wood-sculpture-guide.html" },
    @{ keyword = "南投武界部落秘境：雲海、峽谷、曲冰遺址探索之旅"; filename = "wujie-tribe-guide.html" },
    @{ keyword = "花蓮慕谷慕魚與翡翠谷：花蓮最美峽谷與水簾瀑布秘境"; filename = "mukumugi-jade-valley-guide.html" },
    @{ keyword = "台東嘉明湖：天使的眼淚登山健行全攻略"; filename = "jiaming-lake-hiking-guide.html" },
    @{ keyword = "桃園東眼山森林浴：離台北最近的國家森林遊樂區"; filename = "dongyanshan-forest-guide.html" },
    @{ keyword = "宜蘭明池森林遊樂區：北橫最美高山湖泊與紅檜巨木"; filename = "mingchi-forest-guide.html" }
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