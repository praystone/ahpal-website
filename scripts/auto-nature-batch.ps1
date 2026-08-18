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
    # 🦖 古生物、滅絕與生命演化歷史 (20篇)
    # ============================================================
    @{ keyword = "埃迪卡拉生物群：前寒武紀軟體生物的演化實驗與滅絕謎團"; filename = "ediacaran-biota-soft-bodied-extinction.html" },
    @{ keyword = "巨型陸行鳥（Gastornis）的頭骨力學與古新世生態位爭議"; filename = "gastornis-skull-mechanics-paleocene.html" },
    @{ keyword = "滑齒龍與上龍亞目的水中運動力學與海洋頂級獵手地位"; filename = "liopleurodon-pliosaur-hydrodynamics.html" },
    @{ keyword = "龍王鯨的後肢退化遺跡與古代鯨類海洋化演化關鍵"; filename = "basilosaurus-vestigial-limbs-whale-evolution.html" },
    @{ keyword = "棘龍的半水生生活型態：神經棘帆與尾槳構造力學解析"; filename = "spinosaurus-semi-aquatic-tail-paddle.html" },
    @{ keyword = "三疊紀末期大滅絕：盤古大陸裂解火山作用與恐龍崛起"; filename = "triassic-extinction-pangea-volcanism.html" },
    @{ keyword = "古巨蜥（Megalania）的體型極限與澳洲更新世巨型動物群滅絕"; filename = "megalania-giant-lizard-pleistocene.html" },
    @{ keyword = "包頭龍與甲龍科的尾槌力學碰撞與禦敵防衛策略"; filename = "ankylosaurus-tail-club-impact-mechanics.html" },
    @{ keyword = "副櫛龍的神經棘冠腔體與聲波共鳴頻率重建物理學"; filename = "parasaurolophus-crest-sound-resonance.html" },
    @{ keyword = "海口魚與無頜類的脊索演化：脊椎動物起源的關鍵里程碑"; filename = "haikouichthys-notochord-vertebrate-origin.html" },
    @{ keyword = "恐狼（Dire Wolf）的骨骼強度與冰河時期獵物競爭滅絕"; filename = "dire-wolf-skeletal-strength-extinction.html" },
    @{ keyword = "巨型杯首龍與巨首龍：早期羊膜卵出現對陸地開拓的革命影響"; filename = "amniote-egg-land-colonization-evolution.html" },
    @{ keyword = "笠頭螈（Diplocaulus）的回旋鏢狀頭骨流骨力學與水中防禦"; filename = "diplocaulus-boomerang-skull-hydrodynamics.html" },
    @{ keyword = "杯莖海百合的鈣化莖結構與古生代海底森林生態系"; filename = "crinoid-calcite-stem-paleozoic-reef.html" },
    @{ keyword = "薄板龍的極端頸椎演化與水中捕魚的流體力學限制"; filename = "elasmosaurus-long-neck-hydrodynamics.html" },
    @{ keyword = "古貓獸亞目與肉齒目：始新世哺乳動物捕食者的生態位替換"; filename = "miacidae-creodont-eocene-niche-shift.html" },
    @{ keyword = "翼肢鲎（板足鲎）的游動肢結構與志留紀海洋頂級掠食者"; filename = "eurypterid-pterygotus-paddles-silurian.html" },
    @{ keyword = "巨型短面熊的長骨槓桿結構與更新世獵食 scavenge 爭議"; filename = "short-faced-bear-locomotion-pleistocene.html" },
    @{ keyword = "平胸鳥類（Ratite）的多次失去飛行能力演化與趨同演化機制"; filename = "ratite-flightless-convergent-evolution.html" },
    @{ keyword = "泥盆紀後期大滅絕：陸地植物崛起導致海洋缺氧的連鎖效應"; filename = "late-devonian-extinction-plant-rise-anoxia.html" },

    # ============================================================
    # 🌋 地理、地質極限與大自然現象 (20篇)
    # ============================================================
    @{ keyword = "納特龍湖的高鹼性碳酸鹽成因與石化湖泊生物學解析"; filename = "lake-natron-alkaline-calcification.html" },
    @{ keyword = "羅賴馬山的天台桌狀山地質沉積歷史與獨特島嶼生態系"; filename = "tepui-roraima-tepui-geology-endemic.html" },
    @{ keyword = "奈卡水晶洞的超大石膏晶體生長機制與極限高溫礦化"; filename = "naica-crystal-cave-gypsum-growth.html" },
    @{ keyword = "卡特馬伊火山「萬煙谷」的高溫凝灰岩與火山碎屑流遺跡"; filename = "valley-of-ten-thousand-smokes-ignimbrite.html" },
    @{ keyword = "烏尤尼鹽沼的鋰礦沉積學與全球最大鏡面地貌水文動態"; filename = "uyuni-salt-flat-lithium-evaporite.html" },
    @{ keyword = "理查特結構（撒哈拉之眼）的地殼穹窿侵蝕成因解析"; filename = "richat-structure-dome-erosion-geology.html" },
    @{ keyword = "達洛爾火山（Dallol）的高酸高鹽地熱池與超極限生命邊界"; filename = "dallol-hydrothermal-acidic-brine.html" },
    @{ keyword = "伊瓦魯巨石（Moeraki Boulders）的方解石方結晶核沉積原理"; filename = "moeraki-boulders-septarian-concretion.html" },
    @{ keyword = "卡平加馬拉尼與珊瑚環礁的沉降理論：達爾文環礁演化學說"; filename = "coral-atoll-subsidence-darwin-theory.html" },
    @{ keyword = "莫赫懸崖與沉積斜坡的重力塌陷與海蝕地形動態學"; filename = "cliffs-of-moher-coastal-erosion.html" },
    @{ keyword = "喀拉喀托火山噴發引發的海嘯與全球大氣聲波震盪物理學"; filename = "krakatoa-eruption-atmospheric-shockwave.html" },
    @{ keyword = "巨人堤道玄武岩柱狀節理的冷卻收縮裂隙形成力學"; filename = "giants-causeway-basalt-columnar-jointing.html" },
    @{ keyword = "索科特拉島的隔離沉積地質與龍血樹奇觀演化"; filename = "socotra-island-isolation-dragon-blood.html" },
    @{ keyword = "米爾鑽石礦坑（Mir Mine）的超深漏斗對周圍氣流與直升機的影響"; filename = "mir-diamond-mine-air-vortex.html" },
    @{ keyword = "冰島冰川下火山（Subglacial Volcano）噴發與冰川潰壩洪流"; filename = "jokulhlaup-subglacial-volcano-eruption.html" },
    @{ keyword = "大藍洞（Great Blue Hole）內石筍倒塌與古氣候乾旱紀錄"; filename = "great-blue-hole-stalactite-drought-record.html" },
    @{ keyword = "懷奧塔普「香檳池」的高濃度重金屬沉積與熱帶地熱化學"; filename = "champagne-pool-heavy-metal-precipitation.html" },
    @{ keyword = "馬達加斯加貝馬拉哈「石林」的雨水溶蝕與刀刃狀喀斯特地貌"; filename = "tsingy-de-bemaraha-karst-pinnacles.html" },
    @{ keyword = "加拿大蘇必略湖巨型鐵礦床（BIF）與大氧化事件的地質紀錄"; filename = "banded-iron-formation-great-oxidation.html" },
    @{ keyword = "芬迪灣（Bay of Fundy）超大潮差的海洋潮汐共振物理學"; filename = "bay-of-fundy-tidal-resonance.html" },

    # ============================================================
    # 🌪️ 氣象、大氣物理與天候奇觀 (20篇)
    # ============================================================
    @{ keyword = "乳狀雲（Mammatus Clouds）的重力不穩定性與積雨雲下沉氣流"; filename = "mammatus-clouds-gravity-instability.html" },
    @{ keyword = "夜光雲（Noctilucent Clouds）的中層大氣冰晶與流星灰燼凝結核"; filename = "noctilucent-clouds-mesospheric-ice.html" },
    @{ keyword = "馬拉開波湖卡塔通博閃電的甲烷氣體與大氣靜電長年放電"; filename = "catatumbo-lightning-methane-discharge.html" },
    @{ keyword = "糙面雲（Asperitas Clouds）的波動流體力學與大氣重力波現象"; filename = "asperitas-clouds-atmospheric-gravity-waves.html" },
    @{ keyword = "海市蜃樓（Fata Morgana）的高空逆溫層折射與光線彎曲物理"; filename = "fata-morgana-mirage-refraction-physics.html" },
    @{ keyword = "綠閃光（Green Flash）的大氣折射色散與太陽邊緣極限光學現象"; filename = "green-flash-atmospheric-dispersion.html" },
    @{ keyword = "暴風雪（Blizzard）的白矇天（Whiteout）現象與光線多重散射物理"; filename = "whiteout-blizzard-multiple-scattering.html" },
    @{ keyword = "火旋風（Fire Whirl）的熱對流角動量守恆與火災風暴效應"; filename = "fire-whirl-angular-momentum-conservation.html" },
    @{ keyword = "海龍捲風（Waterspout）的蒸發冷凝與水面渦旋形成學"; filename = "waterspout-vortex-evaporation-physics.html" },
    @{ keyword = "鑽石塵（Diamond Dust）的高空清朗大氣直接冰晶凝華現象"; filename = "diamond-dust-ice-crystal-sublimation.html" },
    @{ keyword = "穿洞雲（Fallstreak Hole）的過冷水滴冰晶化連鎖反應原理"; filename = "fallstreak-hole-supercooled-water.html" },
    @{ keyword = "噴射氣流（Jet Stream）的 Rossby 波不穩定性與極端天氣連鎖"; filename = "jet-stream-rossby-waves-meandering.html" },
    @{ keyword = "霧霓（Fogbow）的小水滴光學衍射現象與白色彩虹形成原理"; filename = "fogbow-diffraction-white-rainbow.html" },
    @{ keyword = "強烈降雪中的雷暴（Thundersnow）成因與不穩定熱力對流機制"; filename = "thundersnow-thermodynamic-instability.html" },
    @{ keyword = "熱雷雨（Thermal Thunderstorm）的地表局地加熱與自由對流高度"; filename = "thermal-thunderstorm-convective-initiation.html" },
    @{ keyword = "高空彩煙（Iridescent Clouds）的薄雲微粒光學干涉與衍射現象"; filename = "cloud-iridescence-optical-interference.html" },
    @{ keyword = "平流層突然變暖（SSW）對極地渦旋破裂與低緯寒潮的預測"; filename = "sudden-stratospheric-warming-polar-vortex.html" },
    @{ keyword = "聖嬰南方振盪（ENSO）在大氣氣壓場中的 Walker 環流變異"; filename = "walker-circulation-enso-atmospheric-dynamics.html" },
    @{ keyword = "強烈陣風鋒面（Arcurus/Shelf Cloud）的冷空氣下沉滾動流體物理"; filename = "shelf-cloud-outflow-boundary-physics.html" },
    @{ keyword = "極地珠母雲（Nacreous Clouds）的極地平流層雲（PSC）與臭氧破壞"; filename = "nacreous-clouds-polar-stratospheric-cloud.html" },

    # ============================================================
    # 🪐 天文、宇宙學與星際探索 (20篇)
    # ============================================================
    @{ keyword = "開普勒-186f：宜居帶系外岩石行星的大氣與液態水存在條件"; filename = "kepler-186f-habitable-zone-exoplanet.html" },
    @{ keyword = "磁星（Magnetar）的星震現象與超強磁場引起的伽瑪射線閃耀"; filename = "magnetar-starquake-magnetic-field-outburst.html" },
    @{ keyword = "夸克星與奇異物質假說：中子星內部的極限壓強物理學"; filename = "quark-star-strange-matter-hypothesis.html" },
    @{ keyword = "參宿四（Betelgeuse）的異常變暗與恆星拋射塵埃雲衰老歷史"; filename = "betelgeuse-dimming-dust-ejection.html" },
    @{ keyword = "歐姆亞姆亞（'Oumuamua）：首個星際天體的非引力加速度與形狀謎團"; filename = "oumuamua-interstellar-object-acceleration.html" },
    @{ keyword = "土衛二（Enceladus）羽流中的有機分子與冰火山噴發機制"; filename = "enceladus-plumes-cryovolcanism-organics.html" },
    @{ keyword = "恆星潮汐破壞事件（TDE）：超大質量黑洞撕裂恆星的光學閃耀"; filename = "tidal-disruption-event-black-hole.html" },
    @{ keyword = "創生之柱（Pillars of Creation）的光化蒸發與恆星孕育區物理"; filename = "pillars-of-creation-photoevaporation.html" },
    @{ keyword = "宇宙微波背景輻射（CMB）的冷斑異常與宇宙暴脹理論驗證"; filename = "cmb-cold-spot-cosmic-inflation.html" },
    @{ keyword = "木星大紅斑（Great Red Spot）的高壓氣旋流體力學與縮小趨勢"; filename = "jupiter-great-red-spot-anticyclone.html" },
    @{ keyword = "水星的超大鐵芯構造與太陽系早期碰撞脫殼假說"; filename = "mercury-large-iron-core-giant-impact.html" },
    @{ keyword = "銀河系中心黑洞人馬座 A* 的吸積盤結構與事件視界望遠鏡影像"; filename = "sagittarius-a-black-hole-eht-image.html" },
    @{ keyword = "海王星大暗斑與極端風速：距離太陽最遠的風暴動態學"; filename = "neptune-great-dark-spot-supersonic-winds.html" },
    @{ keyword = "戴森球（Dyson Sphere）猜想與塔比星（Tabby's Star）光變曲線解析"; filename = "dyson-sphere-tabbys-star-light-curve.html" },
    @{ keyword = "雙星系統中的羅氏瓣（Roche Lobe）溢流與質量轉移演化"; filename = "roche-lobe-overflow-binary-stars.html" },
    @{ keyword = "原行星盤（Protoplanetary Disk）中的行星形成隙縫與吸積物理"; filename = "protoplanetary-disk-gap-accretion.html" },
    @{ keyword = "宇宙弦（Cosmic Strings）假說：早期宇宙相變產生的時空拓撲缺陷"; filename = "cosmic-strings-topological-defects.html" },
    @{ keyword = "冥王星的氮冰冰川與斯普特尼克高原的地熱對流動態"; filename = "pluto-sputnik-planitia-nitrogen-glaciers.html" },
    @{ keyword = "半人馬座 α 星 C（比鄰星 b）的紅矮星耀斑爆發與輻射威脅"; filename = "proxima-centauri-b-stellar-flare-radiation.html" },
    @{ keyword = "宇宙大擠壓（Big Crunch）與大撕裂（Big Rip）：宇宙終極命題學說"; filename = "big-crunch-big-rip-cosmological-fate.html" },

    # ============================================================
    # 🐙 深海、極限生物與生態適應 (20篇)
    # ============================================================
    @{ keyword = "大王具足蟲的低代謝率與深海極限飢餓適應生理學"; filename = "giant-isopod-low-metabolism-starvation.html" },
    @{ keyword = "水熊蟲（緩步動物）的隱生現象與 DNA 保護蛋白（Dsup）機制"; filename = "tardigrade-cryptobiosis-dsup-protein.html" },
    @{ keyword = "管蟲（Riftia pachyptila）與硫化氫氧化菌的無消化道共生生態"; filename = "giant-tube-worm-chemosynthesis-symbiosis.html" },
    @{ keyword = "燈塔水母的逆轉生命週期：細胞分化重轉化與理論永生現象"; filename = "turritopsis-dohrnii-transdifferentiation-immortality.html" },
    @{ keyword = "深海巨型章魚的透明血液：血藍蛋白在高壓低溫下的氧氣輸送"; filename = "deep-sea-octopus-hemocyanin-oxygen-transport.html" },
    @{ keyword = "裸鼴鼠的抗癌機制、耐缺氧能力與真社會性哺乳動物特徵"; filename = "naked-mole-rat-cancer-resistance-hypoxia.html" },
    @{ keyword = "嗜熱菌（Thermus aquaticus）的 Taq 聚合酶與極限地熱水體生存"; filename = "thermus-aquaticus-taq-polymerase-extreme.html" },
    @{ keyword = "深海鮟鱇魚的雄性寄生演化與免疫耐受機制謎團"; filename = "anglerfish-sexual-parasitism-immune-tolerance.html" },
    @{ keyword = "極地冰魚（Icefish）的抗凍蛋白（AFP）與無紅血球透明血液適應"; filename = "icefish-antifreeze-protein-hemoglobinless.html" },
    @{ keyword = "深海鯨落（Whale Fall）生態系：四個演化階段與極限有機物崩解"; filename = "whale-fall-ecosystem-succession-stages.html" },
    @{ keyword = "沙漠傀儡蜥蜴的皮膚毛細管取水結構與水分凝結生理學"; filename = "thorny-devil-skin-capillary-water-harvesting.html" },
    @{ keyword = "槍蝦（Pistol Shrimp）的空穴現象（Cavitation）與幾千度高溫衝擊波"; filename = "pistol-shrimp-cavitation-bubble-shockwave.html" },
    @{ keyword = "深海大王烏賊（Architeuthis）的巨型化與光氣感受器眼睛演化"; filename = "giant-squid-gigantism-visual-adaptation.html" },
    @{ keyword = "耐放射線奇異球菌（Deinococcus radiodurans）的超強 DNA 修復機制"; filename = "deinococcus-radiodurans-dna-repair.html" },
    @{ keyword = "深海後肛魚（Barreleye）的透明頭部與旋轉管狀眼結構解析"; filename = "barreleye-fish-transparent-head-tubular-eyes.html" },
    @{ keyword = "吸血鬼烏賊的低氧忍受力與深海有機碎屑（海雪）攝食"; filename = "vampire-squid-hypoxia-marine-snow.html" },
    @{ keyword = "紅樹林植物的排鹽腺體與根系缺氧氣孔構造動態"; filename = "mangrove-salt-excretion-pneumatophores.html" },
    @{ keyword = "龐貝蟲（Alvinella pompejana）的背部共生菌與極限高溫差耐受"; filename = "pompeii-worm-thermal-tolerance-symbiosis.html" }
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