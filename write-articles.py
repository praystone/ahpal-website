import json

articles = [
    {
        "keyword": "現代 YouTuber 穿越到明朝：用 vlog 記錄紫禁城日常，皇帝成為第一代網紅",
        "category": "📜 歷史腦洞",
        "filename": "history/youtuber-ming-forbidden-city.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代 TikTok 舞者穿越到唐朝：把胡旋舞變成病毒式短影音，長安城人人模仿",
        "category": "📜 歷史腦洞",
        "filename": "history/tiktok-dancer-tang-huxuan.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代心理諮商師穿越到宋朝：幫蘇軾治療被貶後的創傷後壓力症候群",
        "category": "📜 歷史腦洞",
        "filename": "history/therapist-song-sushi-ptsd.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代駭客穿越到三國：幫曹操破解袁紹的軍事加密訊息，逆轉官渡之戰",
        "category": "📜 歷史腦洞",
        "filename": "history/hacker-three-kingdoms-cao-cao.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代廚師穿越到秦朝：用分子料理重現秦始皇尋找的長生不老藥",
        "category": "📜 歷史腦洞",
        "filename": "history/chef-qin-elixir-molecular.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代理財專員穿越到明朝：幫朱元璋設計大明國庫投資組合，年化報酬率 15%",
        "category": "📜 歷史腦洞",
        "filename": "history/financial-advisor-ming-investment.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代健身教練穿越到唐朝：幫唐玄宗制定皇家健身計畫，楊貴妃也跟著練",
        "category": "📜 歷史腦洞",
        "filename": "history/fitness-trainer-tang-xuanzong.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代音樂製作人穿越到宋朝：幫柳永錄製第一張華語專輯，成為古代流行天王",
        "category": "📜 歷史腦洞",
        "filename": "history/music-producer-song-liuyong.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代資料科學家穿越到漢朝：用大數據分析絲綢之路貿易，找出最賺錢的商品",
        "category": "📜 歷史腦洞",
        "filename": "history/data-scientist-han-silkroad.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代電商營運穿越到元朝：幫馬可波羅開設跨國線上商店，成為古代亞馬遜",
        "category": "📜 歷史腦洞",
        "filename": "history/ecommerce-yuan-marco-polo.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代咖啡師穿越到宋朝：開設汴京第一家精品咖啡館，文人雅士都來打卡",
        "category": "📜 歷史腦洞",
        "filename": "history/barista-song-kaifeng-cafe.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代公關專家穿越到清朝：幫慈禧太后經營國際形象，打造大清新品牌",
        "category": "📜 歷史腦洞",
        "filename": "history/pr-expert-qing-cixi-image.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代潛水教練穿越到明朝：幫鄭和探勘海底寶藏，發現沉船千年秘密",
        "category": "📜 歷史腦洞",
        "filename": "history/diving-instructor-ming-zhenghe.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代電競教練穿越到唐朝：幫唐玄宗組建皇室戰隊，征戰天下遊戲大賽",
        "category": "📜 歷史腦洞",
        "filename": "history/esports-coach-tang-xuanzong.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代珠寶設計師穿越到漢朝：幫呂后設計傳世后冠，成為古代時尚 icon",
        "category": "📜 歷史腦洞",
        "filename": "history/jewelry-designer-han-lvhou.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代營養師穿越到宋朝：幫蘇軾設計低卡東坡肉食譜，減肥也能吃美食",
        "category": "📜 歷史腦洞",
        "filename": "history/nutritionist-song-sushi-diet.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代馴獸師穿越到唐朝：幫唐玄宗訓練皇家馬戲團，成為古代太陽馬戲團",
        "category": "📜 歷史腦洞",
        "filename": "history/animal-trainer-tang-circus.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代電影導演穿越到宋朝：幫宋徽宗拍攝第一部紀錄片《清明上河圖》",
        "category": "📜 歷史腦洞",
        "filename": "history/film-director-song-huizong.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代園藝師穿越到明朝：幫朱元璋設計紫禁城空中花園，成為古代巴比倫",
        "category": "📜 歷史腦洞",
        "filename": "history/gardener-ming-rooftop-garden.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代催眠師穿越到秦朝：幫秦始皇治療長生不老的執念，讓他放下執著",
        "category": "📜 歷史腦洞",
        "filename": "history/hypnotist-qin-shihuang.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代平面設計師穿越到漢朝：幫司馬遷設計《史記》封面，成為古代暢銷書",
        "category": "📜 歷史腦洞",
        "filename": "history/graphic-designer-han-simaqian.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代品茶師穿越到唐朝：幫陸羽寫出《茶經》精裝版，成為古代星巴克創辦人",
        "category": "📜 歷史腦洞",
        "filename": "history/tea-master-tang-luyu.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代律師穿越到宋朝：幫岳飛辯護，用法律證據逆轉秦檜的指控",
        "category": "📜 歷史腦洞",
        "filename": "history/lawyer-song-yuefei-defense.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代彩妝師穿越到唐朝：幫武則天設計天后級妝容，成為古代美妝品牌創辦人",
        "category": "📜 歷史腦洞",
        "filename": "history/makeup-artist-tang-wu-zetian.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代心理戰專家穿越到楚漢相爭：用認知作戰讓項羽潰敗，劉邦稱帝",
        "category": "📜 歷史腦洞",
        "filename": "history/psy-war-chu-han-xiangyu.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代基因科學家穿越到漢朝：改良絲路馬匹品種，培育出古代超級賽馬",
        "category": "📜 歷史腦洞",
        "filename": "history/geneticist-han-silkroad-horses.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代建築師穿越到隋朝：幫隋煬帝設計抗震大運河，千年不倒",
        "category": "📜 歷史腦洞",
        "filename": "history/architect-sui-grandcanal.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代聲學工程師穿越到唐朝：改良長安城寺廟鐘聲，成為古代音響大師",
        "category": "📜 歷史腦洞",
        "filename": "history/acoustics-engineer-tang-bells.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代燈光設計師穿越到明朝：幫紫禁城設計夜景燈光秀，皇帝天天看秀",
        "category": "📜 歷史腦洞",
        "filename": "history/lighting-designer-ming-night-show.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代材料科學家穿越到宋朝：發明輕量化盔甲，岳家軍戰力大增",
        "category": "📜 歷史腦洞",
        "filename": "history/materials-scientist-song-armor.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代水利工程師穿越到秦朝：幫秦始皇解決長城缺水問題，戍邊士兵不再口渴",
        "category": "📜 歷史腦洞",
        "filename": "history/hydraulic-engineer-qin-greatwall.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代機器人工程師穿越到三國：幫諸葛亮設計木牛流馬 2.0 自動化運輸系統",
        "category": "📜 歷史腦洞",
        "filename": "history/robotics-engineer-zhuge-muniu.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代無人機飛手穿越到元朝：幫成吉思汗空中偵查，蒙古鐵騎戰無不勝",
        "category": "📜 歷史腦洞",
        "filename": "history/drone-pilot-yuan-genghis-recon.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代材料工程師穿越到唐朝：發明防彈絲綢，唐代將領刀槍不入",
        "category": "📜 歷史腦洞",
        "filename": "history/materials-engineer-tang-bulletproof-silk.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代能源工程師穿越到宋朝：發明汴京太陽能系統，成為古代綠色能源先驅",
        "category": "📜 歷史腦洞",
        "filename": "history/energy-engineer-song-solar.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代生物學家穿越到明朝：改良紫禁城生態系統，打造古代綠建築",
        "category": "📜 歷史腦洞",
        "filename": "history/biologist-ming-forbidden-city-eco.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代機械工程師穿越到秦朝：幫秦始皇設計自動化兵器，橫掃六國",
        "category": "📜 歷史腦洞",
        "filename": "history/mechanical-engineer-qin-weapons.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代軟體工程師穿越到漢朝：幫張衡設計地震預測 App，提前預警所有地震",
        "category": "📜 歷史腦洞",
        "filename": "history/software-engineer-han-zhangheng-app.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代化學家穿越到唐朝：發明長安城滅火系統，火災不再蔓延",
        "category": "📜 歷史腦洞",
        "filename": "history/chemist-tang-firefighting.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代光學工程師穿越到宋朝：發明古代望遠鏡，宋軍戰場上掌握先機",
        "category": "📜 歷史腦洞",
        "filename": "history/optics-engineer-song-telescope.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代環境科學家穿越到隋朝：解決大運河汙染問題，讓河水變清澈",
        "category": "📜 歷史腦洞",
        "filename": "history/environmental-scientist-sui-grandcanal.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代航天工程師穿越到明朝：幫萬戶升級火箭座椅，成為世界航天第一人",
        "category": "📜 歷史腦洞",
        "filename": "history/aerospace-engineer-ming-wanhu-v2.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代核子物理學家穿越到秦朝：發現古代輻射源，改寫中國科技史",
        "category": "📜 歷史腦洞",
        "filename": "history/nuclear-physicist-qin-radiation.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代神經科學家穿越到唐朝：研究李白大腦創造力，揭開詩仙的秘密",
        "category": "📜 歷史腦洞",
        "filename": "history/neuroscientist-tang-libo-brain.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代地質學家穿越到宋朝：預測黃河氾濫，拯救萬千百姓",
        "category": "📜 歷史腦洞",
        "filename": "history/geologist-song-yellow-river.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代海洋學家穿越到明朝：幫鄭和繪製洋流圖，航海技術領先世界",
        "category": "📜 歷史腦洞",
        "filename": "history/oceanographer-ming-zhenghe-currents.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代氣象學家穿越到清朝：用現代預測術化解旱災，拯救百姓於水火",
        "category": "📜 歷史腦洞",
        "filename": "history/meteorologist-qing-drought.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代都市規劃師穿越到漢朝：設計長安城地下交通網，解決塞車問題",
        "category": "📜 歷史腦洞",
        "filename": "history/urban-planner-han-changan-metro.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代農業專家穿越到唐朝：改良絲路農業產量，糧食產量翻倍",
        "category": "📜 歷史腦洞",
        "filename": "history/agronomist-tang-silkroad-farming.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    },
    {
        "keyword": "現代電機工程師穿越到宋朝：發明古代發電機，汴京進入電氣時代",
        "category": "📜 歷史腦洞",
        "filename": "history/electrical-engineer-song-generator.html",
        "use_responses_api": True,
        "enable_reasoning": True,
        "enable_search": False
    }
]

with open('data/pending-articles.json', 'w', encoding='utf-8') as f:
    json.dump(articles, f, ensure_ascii=False, indent=2)

print(f'✅ 已寫入 {len(articles)} 篇文章 (UTF-8 無 BOM)')
