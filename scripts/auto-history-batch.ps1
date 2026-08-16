# ============================================================
# 歷史腦洞20篇 — 即時顯示 + 排程優化版 v10.2 (移除 Emoji 破壞修復)
# ============================================================
# 用途：無人值守一次性生成 全新歷史腦洞文章
# 
# v10.2 變更 (2026-08-16)：
#   - 🗑️ 移除自動修復 html_builder.py 區塊 (避免破壞 Emoji)
#   - ✅ 繼承 v10.1 所有功能 (斷點續傳、郵件通知、電源管理)
# ============================================================

# ============================================================
# 🔧 電源管理：擷取當前電源計劃並防止睡眠
# ============================================================
# 擷取目前的電源計劃 GUID
$PowerCfgOriginal = (powercfg /getactivescheme) -replace '.*:\s+([a-f0-9-]+)\s+\(.*', '$1'

# 切換為高效能 / 卓越效能（若無則維持現狀）
# 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 為 Windows 內建「高效能」GUID
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
# 🔧 預載 .NET Assembly (SMTP 郵件) - 已註解，改用 .env 讀取
# ============================================================
# Add-Type -AssemblyName System.Net.Mail -ErrorAction SilentlyContinue

# ============================================================
# ✅ 已移除「自動修復 html_builder.py」區塊
# 原因：該修復會將 Emoji (🎮📊🤖📚等) 替換為 [[[[[[[[[[[[🎮]]]]]]]]]]]]
# 導致網站頁面顯示異常。
# ============================================================

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-history-batch-v10-$Timestamp.log"

# 🆕 Checkpoint 檔案 (斷點續傳)
$CheckpointFile = "$LogDir\v10-checkpoint.json"

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
            $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "❌ V10 執行失敗", $ErrorMsg)
            $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($MailMessage)
            Write-Log "📧 錯誤通知已發送"
        } catch {
            Write-Log "⚠️ 錯誤通知發送失敗: $($_.Exception.Message)"
        }
    }
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 20 篇 — 即時顯示 + 排程優化版 v10.2"
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
# 步驟 2：定義 20 篇文章 -- 現代人穿越中國古代
# ============================================================
Write-Log "[2/6] 定義 20 篇文章清單..."
Save-Checkpoint -Stage "article_definition"

# ============================================================
# 步驟 2：定義 100 篇文章 -- 現代人穿越中國古代 (100篇完整版)
# ============================================================
Write-Log "[2/6] 定義 100 篇文章清單..."
Save-Checkpoint -Stage "article_definition"

$Articles = @(
    @{ keyword = "如果現代神經外科醫生穿越到唐朝：幫唐玄宗治療頭痛，用開顱手術根治千年頑疾，皇帝封他為「天醫」"; filename = "neurosurgeon-tang-xuanzong.html" },
    @{ keyword = "如果現代釀酒師穿越到宋朝：幫蘇軾研發古代精釀啤酒，東坡醉變成東坡生啤，汴京酒館大排長龍"; filename = "brewer-song-sushi-beer.html" },
    @{ keyword = "如果現代園藝治療師穿越到明朝：幫朱元璋設計療癒花園，皇帝暴躁脾氣變溫和，大臣不再怕上朝"; filename = "horticultural-therapist-ming-zhu.html" },
    @{ keyword = "如果現代機械手臂工程師穿越到三國：幫關羽安裝義肢，青龍偃月刀揮得更快，成為古代生化戰士"; filename = "cyborg-engineer-guan-yu.html" },
    @{ keyword = "如果現代品水師穿越到唐朝：幫楊貴妃找長安最好的溫泉水源，華清池變成古代第一溫泉會館"; filename = "water-sommelier-tang-yangguifei.html" },
    @{ keyword = "如果現代無人車工程師穿越到秦朝：幫秦始皇設計自動駕駛戰車，六國聯軍看到嚇到投降"; filename = "autonomous-vehicle-qin-shihuang.html" },
    @{ keyword = "如果現代聲音治療師穿越到宋朝：幫柳永治療失聲，用聲波療法讓歌聲更美，婉約詞變成天籟之音"; filename = "sound-therapist-song-liuyong.html" },
    @{ keyword = "如果現代太空食物科學家穿越到明朝：幫鄭和研發航海乾糧，船員不再得壞血病，艦隊航向更遠"; filename = "space-food-scientist-ming-zhenghe.html" },
    @{ keyword = "如果現代寵物行為學家穿越到宋朝：幫宋徽宗馴服御貓，原來皇帝是古代第一貓奴，還寫了貓咪心理學"; filename = "pet-behaviorist-song-huizong.html" },
    @{ keyword = "如果現代立體書藝術家穿越到唐朝：幫敦煌壁畫做成3D立體書，飛天仙女跳出牆面震撼長安"; filename = "pop-up-book-artist-tang-dunhuang.html" },
    @{ keyword = "如果現代奈米材料科學家穿越到宋朝：發明古代防彈衣，岳家軍變成刀槍不入的終極戰士"; filename = "nanomaterials-scientist-song-armor.html" },
    @{ keyword = "如果現代中藥科學家穿越到漢朝：幫張仲景用現代藥理學改良傷寒論，寫出《傷寒論2.0》"; filename = "pharmacologist-han-zhangzhongjing.html" },
    @{ keyword = "如果現代高空彈跳教練穿越到唐朝：幫唐玄宗設計皇家高空彈跳，皇帝壓力大時跳下去紓壓"; filename = "bungee-instructor-tang-xuanzong.html" },
    @{ keyword = "如果現代染布藝術家穿越到明朝：幫朱元璋設計皇袍新色，大明時尚圈直接起飛"; filename = "textile-artist-ming-zhu.html" },
    @{ keyword = "如果現代加密貨幣工程師穿越到宋朝：幫蘇軾發行古代比特幣，文人雅士開始投資數字貨幣"; filename = "crypto-engineer-song-sushi.html" },
    @{ keyword = "如果現代極地探險家穿越到元朝：幫成吉思汗探索北極，蒙古鐵騎變成雪地機動部隊"; filename = "explorer-yuan-genghis-arctic.html" },
    @{ keyword = "如果現代輕小說作家穿越到唐朝：幫李白把詩集改成輕小說，成為大唐第一暢銷作家"; filename = "light-novel-writer-tang-libo.html" },
    @{ keyword = "如果現代太陽能工程師穿越到秦朝：幫秦始皇設計古代太陽能板，長城變成萬里發電牆"; filename = "solar-engineer-qin-greatwall.html" },
    @{ keyword = "如果現代紙雕藝術家穿越到漢朝：幫蔡倫改良造紙術，紙張變成藝術品，漢朝文化輸出大爆發"; filename = "paper-artist-han-cailun.html" },
    @{ keyword = "如果現代寶石鑑定師穿越到明朝：幫鄭和鑑定南洋寶石，大明珠寶市場變成世界奢侈品中心"; filename = "gemologist-ming-zhenghe.html" },
    @{ keyword = "如果現代卡丁車賽車手穿越到唐朝：幫唐玄宗設計賽車場，古代F1比馬車還快，皇帝親自飆車"; filename = "kart-racer-tang-xuanzong.html" },
    @{ keyword = "如果現代拼布藝術家穿越到宋朝：幫宋徽宗設計幾何圖案壁毯，皇宮變成現代藝術館"; filename = "quilt-artist-song-huizong.html" },
    @{ keyword = "如果現代復健治療師穿越到三國：幫關羽設計膝蓋復健計畫，讓他不再被刮骨療傷困擾"; filename = "rehab-therapist-guan-yu.html" },
    @{ keyword = "如果現代光學藝術家穿越到唐朝：幫敦煌壁畫製作光影裝置藝術，飛天仙女在光影中飛舞"; filename = "light-artist-tang-dunhuang.html" },
    @{ keyword = "如果現代地熱能工程師穿越到隋朝：幫隋煬帝設計溫泉發電，大運河變成永續能源運河"; filename = "geothermal-engineer-sui-grandcanal.html" },
    @{ keyword = "如果現代漫畫家穿越到宋朝：幫宋徽宗畫漫畫版《清明上河圖》，汴京百姓排隊購買"; filename = "manga-artist-song-qingming.html" },
    @{ keyword = "如果現代骨科復健師穿越到明朝：幫朱元璋治療風濕，皇帝不再腰酸背痛，上朝更有精神"; filename = "orthopedic-rehab-ming-zhu.html" },
    @{ keyword = "如果現代環境藝術家穿越到唐朝：幫長安城設計城市綠化，大唐首都變成森林城市"; filename = "environmental-artist-tang-changan.html" },
    @{ keyword = "如果現代印刷廠老闆穿越到漢朝：幫司馬遷大量印刷《史記》，書籍普及化，漢朝文化全民運動"; filename = "printer-han-simaqian.html" },
    @{ keyword = "如果現代電子音樂製作人穿越到宋朝：幫柳永製作古代電音專輯，婉約詞變身派對神曲"; filename = "edm-producer-song-liuyong.html" },
    @{ keyword = "如果現代虛擬實境工程師穿越到唐朝：幫李白打造詩詞VR世界，讀者可進入詩中遊歷"; filename = "vr-engineer-tang-libo.html" },
    @{ keyword = "如果現代生物燃料科學家穿越到明朝：幫鄭和研發生質燃料，寶船不再靠風力，全球航行更快速"; filename = "biofuel-scientist-ming-zhenghe.html" },
    @{ keyword = "如果現代紋身藝術家穿越到宋朝：幫岳飛設計現代圖騰刺青，精忠報國變身潮流時尚"; filename = "tattoo-artist-song-yuefei.html" },
    @{ keyword = "如果現代風力發電工程師穿越到隋朝：幫隋煬帝設計風車發電，大運河沿岸成為綠色能源走廊"; filename = "wind-engineer-sui-grandcanal.html" },
    @{ keyword = "如果現代行為藝術家穿越到唐朝：幫楊貴妃設計現代舞表演，長安城掀起當代藝術風潮"; filename = "performance-artist-tang-yangguifei.html" },
    @{ keyword = "如果現代分子料理廚師穿越到宋朝：幫蘇軾改良東坡肉，用科學方法讓肉質更嫩，美食家都驚呆"; filename = "molecular-chef-song-sushi.html" },
    @{ keyword = "如果現代環境毒理學家穿越到唐朝：幫長安城解決空氣汙染，百姓不再燒煤，天空恢復湛藍"; filename = "toxicologist-tang-changan.html" },
    @{ keyword = "如果現代催眠治療師穿越到三國：幫曹操治療偏頭痛，用催眠療法找出病因，曹操不再暴躁"; filename = "hypnotherapist-cao-cao.html" },
    @{ keyword = "如果現代口技表演者穿越到唐朝：幫長安城寺廟設計聲音裝置，鐘聲變成超現實音景"; filename = "beatboxer-tang-bells.html" },
    @{ keyword = "如果現代波浪能工程師穿越到明朝：幫鄭和設計海洋能發電，寶船變成海上發電站"; filename = "wave-energy-engineer-ming-zhenghe.html" },
    @{ keyword = "如果現代沙畫藝術家穿越到宋朝：幫蘇軾在西湖邊表演沙畫，圍觀百姓擠爆湖畔"; filename = "sand-artist-song-sushi.html" },
    @{ keyword = "如果現代寄生蟲學家穿越到唐朝：幫長安城消滅瘧疾，建立古代第一支公衛部隊"; filename = "parasitologist-tang-changan.html" },
    @{ keyword = "如果現代數位修復師穿越到漢朝：幫司馬遷數位化《史記》，古籍變成互動式歷史資料庫"; filename = "digital-restorer-han-simaqian.html" },
    @{ keyword = "如果現代飛輪教練穿越到宋朝：幫宋徽宗設計皇家飛輪課程，皇帝瘦身成功，大臣跟風健身"; filename = "spin-instructor-song-huizong.html" },
    @{ keyword = "如果現代影像藝術家穿越到唐朝：幫敦煌壁畫製作動態影像，飛天仙女在螢幕上飛舞"; filename = "video-artist-tang-dunhuang.html" },
    @{ keyword = "如果現代水力發電工程師穿越到隋朝：幫隋煬帝改良大運河水利系統，運河變成水力發電廠"; filename = "hydro-engineer-sui-grandcanal.html" },
    @{ keyword = "如果現代隨機數生成器專家穿越到秦朝：幫秦始皇設計命運演算法，預測未來當作決策依據"; filename = "rng-expert-qin-shihuang.html" },
    @{ keyword = "如果現代金繼藝術家穿越到宋朝：幫宋徽宗修復瓷器，金繼工藝變成皇家御用技術"; filename = "kintsugi-artist-song-huizong.html" },
    @{ keyword = "如果現代野生動物保育專家穿越到唐朝：幫唐玄宗建立皇家自然保護區，珍禽異獸不再被濫捕"; filename = "conservationist-tang-xuanzong.html" },
    @{ keyword = "如果現代賽車技師穿越到明朝：幫朱棣設計古代超跑，北京城變成賽車之城，皇帝開車巡視天下"; filename = "racing-mechanic-ming-zhudi.html" },
    @{ keyword = "如果現代植栽設計師穿越到宋朝：幫蘇軾設計文人盆景，東坡書房變成古代綠植時尚空間"; filename = "planter-song-sushi.html" },
    @{ keyword = "如果現代食品安全專家穿越到唐朝：幫長安城建立古代食安標準，餐廳標示衛生等級，百姓安心吃飯"; filename = "food-safety-tang-changan.html" },
    @{ keyword = "如果現代VR藝術家穿越到漢朝：幫司馬遷打造《史記》虛擬博物館，讀者沉浸式體驗歷史"; filename = "vr-artist-han-simaqian.html" },
    @{ keyword = "如果現代運動科學家穿越到唐朝：幫唐玄宗設計皇家健身數據庫，皇帝體能數據每天更新"; filename = "sports-scientist-tang-xuanzong.html" },
    @{ keyword = "如果現代光影藝術家穿越到明朝：幫朱元璋設計紫禁城光雕秀，皇帝天天看夜景"; filename = "lighting-artist-ming-forbidden-city.html" },
    @{ keyword = "如果現代垃圾回收工程師穿越到宋朝：幫汴京建立古代回收系統，廢物變黃金，城市變乾淨"; filename = "recycling-engineer-song-kaifeng.html" },
    @{ keyword = "如果現代聲音雕塑家穿越到唐朝：幫長安城設計聲音景觀，城市變成巨大音樂廳"; filename = "sound-sculptor-tang-changan.html" },
    @{ keyword = "如果現代大數據分析師穿越到秦朝：幫秦始皇分析六國數據，用數據預測叛亂，秦朝統一更加穩固"; filename = "big-data-analyst-qin-shihuang.html" },
    @{ keyword = "如果現代街頭藝人穿越到宋朝：幫汴京夜市設計街頭表演秀，百姓晚上不再無聊"; filename = "busker-song-kaifeng.html" },
    @{ keyword = "如果現代木偶戲師穿越到唐朝：幫長安城設計機器人木偶秀，百姓擠爆廣場觀看"; filename = "puppeteer-tang-changan.html" },
    @{ keyword = "如果現代氣候科學家穿越到明朝：幫朱元璋分析小冰河期數據，提前預防饑荒，大明更加強盛"; filename = "climate-scientist-ming-zhu.html" },
    @{ keyword = "如果現代行動藝術家穿越到唐朝：幫楊貴妃設計街頭表演，長安城變成巨大藝術舞台"; filename = "flash-mob-artist-tang-yangguifei.html" },
    @{ keyword = "如果現代工業設計師穿越到宋朝：幫宋徽宗設計現代家具，皇宮變成北歐風極簡空間"; filename = "industrial-designer-song-huizong.html" },
    @{ keyword = "如果現代食品造型師穿越到唐朝：幫楊貴妃設計荔枝擺盤，水果變成藝術品，唐玄宗驚呆"; filename = "food-stylist-tang-yangguifei.html" },
    @{ keyword = "如果現代深海潛水員穿越到明朝：幫鄭和探索海底世界，發現古代沉船秘密，改寫航海史"; filename = "deep-sea-diver-ming-zhenghe.html" },
    @{ keyword = "如果現代無重力模擬專家穿越到唐朝：幫李白體驗太空無重力，詩仙寫出超現實詩篇"; filename = "zero-gravity-expert-tang-libo.html" },
    @{ keyword = "如果現代寶石切割師穿越到明朝：幫鄭和切割超大鑽石，大明皇室珠寶震驚世界"; filename = "gem-cutter-ming-zhenghe.html" },
    @{ keyword = "如果現代攀岩教練穿越到宋朝：幫宋徽宗設計攀岩牆，皇帝愛上極限運動，大臣不敢爬"; filename = "rock-climbing-instructor-song-huizong.html" },
    @{ keyword = "如果現代人工珊瑚礁工程師穿越到明朝：幫鄭和建立海底生態系統，海洋資源永續發展"; filename = "coral-engineer-ming-zhenghe.html" },
    @{ keyword = "如果現代意念控制工程師穿越到三國：幫諸葛亮設計意念控制木牛流馬，運輸更有效率"; filename = "bci-engineer-zhuge-liang.html" },
    @{ keyword = "如果現代馬賽克藝術家穿越到唐朝：幫長安城設計馬賽克壁畫，城市變成巨大藝術畫布"; filename = "mosaic-artist-tang-changan.html" },
    @{ keyword = "如果現代物聯網工程師穿越到宋朝：幫汴京設計智慧城市系統，全城監控管理，治安超好"; filename = "iot-engineer-song-kaifeng.html" },
    @{ keyword = "如果現代花式調酒師穿越到唐朝：幫李白設計火焰調酒表演，詩仙喝酒變成視覺饗宴"; filename = "flair-bartender-tang-libo.html" },
    @{ keyword = "如果現代竹編藝術家穿越到宋朝：幫蘇軾設計竹編家具，文人雅士爭相收藏"; filename = "bamboo-artist-song-sushi.html" },
    @{ keyword = "如果現代量子計算工程師穿越到秦朝：幫秦始皇設計量子計算機，預測六國動向百分百準確"; filename = "quantum-computing-qin-shihuang.html" },
    @{ keyword = "如果現代玻璃藝術家穿越到唐朝：幫長安城製作彩色玻璃窗，陽光灑落變成彩虹"; filename = "glass-artist-tang-changan.html" },
    @{ keyword = "如果現代海上風電工程師穿越到明朝：幫鄭和設計海上風力發電，艦隊永續航行"; filename = "offshore-wind-ming-zhenghe.html" },
    @{ keyword = "如果現代皮革藝術家穿越到元朝：幫成吉思汗設計時尚皮衣，蒙古戰士變身古代型男"; filename = "leather-artist-yuan-genghis.html" },
    @{ keyword = "如果現代數據可視化專家穿越到漢朝：幫司馬遷將《史記》做成互動圖表，一目了然讀歷史"; filename = "data-viz-han-simaqian.html" },
    @{ keyword = "如果現代自動化工程師穿越到宋朝：幫宋徽宗設計自動化書法機，皇帝每天產出百幅墨寶"; filename = "automation-engineer-song-huizong.html" },
    @{ keyword = "如果現代金屬工藝家穿越到唐朝：幫長安城設計現代金屬雕塑，城市美學大升級"; filename = "metal-artist-tang-changan.html" },
    @{ keyword = "如果現代3D列印工程師穿越到明朝：幫朱元璋3D列印皇冠，量產宮廷用品"; filename = "3d-printer-ming-zhu.html" },
    @{ keyword = "如果現代太空農業專家穿越到唐朝：幫長安城設計垂直農場，糧食產量翻倍，百姓不再餓肚子"; filename = "space-farmer-tang-changan.html" },
    @{ keyword = "如果現代紙藝工程師穿越到漢朝：幫蔡倫設計自動化造紙機，紙張產量暴增，文化傳播加速"; filename = "paper-engineer-han-cailun.html" },
    @{ keyword = "如果現代節能建築師穿越到宋朝：幫汴京設計被動式節能建築，冬暖夏涼，百姓省燃料費"; filename = "green-architect-song-kaifeng.html" },
    @{ keyword = "如果現代玻璃纖維工程師穿越到明朝：幫鄭和設計玻璃纖維船體，寶船更輕更快更堅固"; filename = "fiberglass-engineer-ming-zhenghe.html" },
    @{ keyword = "如果現代動態雕塑家穿越到唐朝：幫楊貴妃設計動態雕塑，風吹就動，后宮驚豔"; filename = "kinetic-sculptor-tang-yangguifei.html" },
    @{ keyword = "如果現代數位貨幣礦工穿越到宋朝：幫蘇軾挖礦比特幣，成為古代第一礦工，富可敵國"; filename = "crypto-miner-song-sushi.html" },
    @{ keyword = "如果現代聲納工程師穿越到明朝：幫鄭和設計聲納系統，水下探測更精準，航海更安全"; filename = "sonar-engineer-ming-zhenghe.html" },
    @{ keyword = "如果現代摺紙工程師穿越到宋朝：幫宋徽宗設計大型摺紙裝置，皇宮變成紙藝博物館"; filename = "origami-engineer-song-huizong.html" },
    @{ keyword = "如果現代機器學習工程師穿越到秦朝：幫秦始皇設計AI預測系統，六國叛亂提前知道"; filename = "ml-engineer-qin-shihuang.html" },
    @{ keyword = "如果現代微型模型藝術家穿越到唐朝：幫長安城製作一比一百微型模型，城市規劃一目了然"; filename = "miniature-artist-tang-changan.html" },
    @{ keyword = "如果現代生物發光工程師穿越到明朝：幫鄭和設計生物發光燈塔，夜間導航更安全"; filename = "bioluminescence-ming-zhenghe.html" },
    @{ keyword = "如果現代紙飛機工程師穿越到宋朝：幫宋徽宗設計紙飛機競賽，皇宮變身飛行實驗場"; filename = "paper-plane-engineer-song-huizong.html" },
    @{ keyword = "如果現代雷射切割工程師穿越到唐朝：幫長安城設計雷射雕刻石碑，文字千年不壞"; filename = "laser-engraver-tang-changan.html" },
    @{ keyword = "如果現代水上滑板教練穿越到宋朝：幫蘇軾設計水上運動，西湖變身極限運動場"; filename = "wakeboard-instructor-song-sushi.html" },
    @{ keyword = "如果現代LED工程師穿越到明朝：幫朱元璋設計LED燈籠，紫禁城夜晚亮如白晝"; filename = "led-engineer-ming-forbidden-city.html" },
    @{ keyword = "如果現代碳纖維工程師穿越到元朝：幫成吉思汗設計碳纖維弓，射程翻倍，戰無不勝"; filename = "carbon-fiber-yuan-genghis.html" },
    @{ keyword = "如果現代投影工程師穿越到唐朝：幫楊貴妃設計投影舞蹈秀，長安城震撼不已"; filename = "projection-artist-tang-yangguifei.html" },
    @{ keyword = "如果現代物聯網農夫穿越到漢朝：幫張騫設計智慧絲路農場，西域作物產量暴增"; filename = "smart-farmer-han-zhangqian.html" },
    @{ keyword = "如果現代全息投影工程師穿越到宋朝：幫汴京設計全息夜市，古代科技震撼世界"; filename = "hologram-engineer-song-kaifeng.html" }
 )

Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 步驟 3：檢查 history/ 目錄
# ============================================================
Write-Log "[3/6] 檢查 history/ 目錄..."
Save-Checkpoint -Stage "directory_check"

$HistoryDir = "$ProjectRoot\history"
if (-not (Test-Path $HistoryDir)) {
    New-Item -ItemType Directory -Path $HistoryDir -Force | Out-Null
    Write-Log "   📁 history/ 目錄已建立"
}

$ExistingFiles = @()
if (Test-Path $HistoryDir) {
    $ExistingFiles = Get-ChildItem "$HistoryDir\*.html" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
}
Write-Log "   📄 已存在: $($ExistingFiles.Count) 篇"

$MissingArticles = @()
foreach ($article in $Articles) {
    if ($article.filename -notin $ExistingFiles) {
        $MissingArticles += $article
    }
}

if ($MissingArticles.Count -eq 0) {
    Write-Log "   ✅ 所有 20 篇文章已存在，無需生成"
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
    "category": "📜 歷史腦洞",
    "filename": "history/$($article.filename)",
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

# 即時顯示 + 同時寫入日誌
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
Write-Log "✅ 歷史腦洞 第九波 20 篇 — 即時顯示 + 排程優化版執行完畢！"
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
    $Subject = "📜 歷史腦洞 100 篇 — 即時顯示 + 排程優化版完成通知"
    $Body = @"
歷史腦洞 100 篇即時顯示 + 排程優化版已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 本次新增：$($MissingArticles.Count) 篇
   - 日誌位置：$LogFile
   - 部署狀態：✅ 已完成

請至 https://www.ahpal.com/category-history.html 查看最新文章。

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