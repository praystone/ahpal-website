// 每日挑戰功能 - 無需後端，純前端實現
(function() {
    const articles = [
        { title: "iPhone 電池壽命延長 10 招", url: "/tech/iphone-battery-tips.html", category: "💻 3C 科技教學" },
        { title: "Windows 11 隱藏技巧 15 個", url: "/tech/win11-hidden-tricks.html", category: "💻 3C 科技教學" },
        { title: "Mac 新手入門 12 個必學設定", url: "/tech/mac-beginner-setup.html", category: "💻 3C 科技教學" },
        { title: "手機網路太慢怎麼辦？5 個優化技巧實測", url: "/tech/mobile-network-slow-fix.html", category: "💻 3C 科技教學" },
        { title: "筆電過熱發燙？有效散熱與保養方法", url: "/tech/laptop-overheating-tips.html", category: "💻 3C 科技教學" },
        { title: "Line 聊天紀錄備份失敗的解決方案", url: "/tech/line-backup-failed-fix.html", category: "💻 3C 科技教學" },
        { title: "2026 最實用 Chrome 擴充功能 10 款推薦", url: "/tech/chrome-extensions-2026.html", category: "💻 3C 科技教學" },
        { title: "iPhone 16 拍照技巧 8 招 輕鬆變大師", url: "/tech/iphone-16-photo-tips.html", category: "💻 3C 科技教學" },
        { title: "原神 5.0 隱藏任務全攻略", url: "/game/genshin-5-0-quest.html", category: "🎮 遊戲攻略" },
        { title: "薩爾達傳說 王國之淚 全神廟攻略", url: "/game/zelda-tears-of-the-kingdom-shrines.html", category: "🎮 遊戲攻略" },
        { title: "2026 最熱門 10 款手機遊戲推薦", url: "/game/top-10-mobile-games-2026.html", category: "🎮 遊戲攻略" },
        { title: "艾爾登法環 DLC 全 Boss 攻略技巧", url: "/game/elden-ring-dlc-boss-guide.html", category: "🎮 遊戲攻略" },
        { title: "星露谷物語 新手賺錢攻略 10 招", url: "/game/stardew-valley-money-guide.html", category: "🎮 遊戲攻略" },
        { title: "原神 5.1 新角色配隊推薦", url: "/game/genshin-5-1-team-guide.html", category: "🎮 遊戲攻略" },
        { title: "2026 居家風水 10 大禁忌 讓你越住越順", url: "/life/home-feng-shui-tips.html", category: "🏠 生活小常識" },
        { title: "冰箱收納 7 秘訣 省電又保鮮", url: "/life/fridge-organization-tips.html", category: "🏠 生活小常識" },
        { title: "衣服去漬 8 招 超實用", url: "/life/clothes-stain-removal-tips.html", category: "🏠 生活小常識" },
        { title: "打造高效工作空間：居家辦公室佈置 8 大法則", url: "/life/home-office-setup-guide.html", category: "🏠 生活小常識" },
        { title: "一週無痛極簡生活計畫：減少浪費與雜物的訣竅", url: "/life/minimalist-living-tips.html", category: "🏠 生活小常識" },
        { title: "每天 30 分鐘高效率晨間儀式：成功人士的早晨習慣", url: "/life/morning-routine-tips.html", category: "🏠 生活小常識" },
        { title: "廚房清潔 7 招 輕鬆除油垢", url: "/life/kitchen-cleaning-tips.html", category: "🏠 生活小常識" },
        { title: "省錢妙招 10 招 一年多存 5 萬元", url: "/life/money-saving-tips-2026.html", category: "🏠 生活小常識" },
        { title: "2026 最佳免費 PDF 編輯軟體推薦與評測", url: "/review/best-free-pdf-editor-2026.html", category: "📊 軟體評測" },
        { title: "5 款免費 VPN 評測 2026 哪款最快最安全", url: "/review/free-vpn-review-2026.html", category: "📊 軟體評測" },
        { title: "2026 線上 AI 繪圖工具比較", url: "/review/ai-image-tools-comparison-2026.html", category: "📊 軟體評測" },
        { title: "2026 最強筆記軟體對決", url: "/review/note-app-comparison-2026.html", category: "📊 軟體評測" },
        { title: "免費剪片軟體推薦 2026", url: "/review/free-video-editor-2026.html", category: "📊 軟體評測" },
        { title: "Notion 新手入門 10 招 提升工作效率", url: "/review/notion-beginner-guide.html", category: "📊 軟體評測" },
        { title: "2026 最佳防毒軟體評測 5 款推薦", url: "/review/best-antivirus-2026.html", category: "📊 軟體評測" },
        { title: "ChatGPT 進階技巧 10 招 讓你工作效率翻倍", url: "/review/chatgpt-advanced-tips.html", category: "📊 軟體評測" },
        { title: "成功人士的 10 個習慣 改變你的人生", url: "/philosophy/successful-habits.html", category: "🌟 人生哲理" },
        { title: "醫生不會告訴你的 5 個健康秘密", url: "/philosophy/doctors-secrets.html", category: "🌟 人生哲理" },
        { title: "AI 時代即將消失的 7 種職業 你該如何應對", url: "/philosophy/jobs-disappearing-ai-era.html", category: "🌟 人生哲理" },
        { title: "2027 年將改變生活的 5 大 AI 新技術預測", url: "/philosophy/ai-future-trends-2027.html", category: "🌟 人生哲理" },
        { title: "從股市看趨勢：2026 下半年最具潛力的投資方向", url: "/philosophy/investment-trends-2026.html", category: "🌟 人生哲理" },
        { title: "2026 年你一定要認識的 3 個新興職業", url: "/philosophy/emerging-careers-2026.html", category: "🌟 人生哲理" },
        { title: "每天 15 分鐘冥想 改變你的大腦與人生", url: "/philosophy/meditation-benefits.html", category: "🌟 人生哲理" },
        { title: "高效能人士的 7 個習慣 讀書筆記與實踐指南", url: "/philosophy/7-habits-guide.html", category: "🌟 人生哲理" },
        { title: "2026 數位轉型趨勢與應用", url: "/trend/trend-fallback-1.html", category: "🤖 AI 趨勢" },
        { title: "AI 人工智慧生活應用實例解析", url: "/trend/trend-fallback-2.html", category: "🤖 AI 趨勢" },
        { title: "2026 台灣旅遊景點推薦", url: "/trend/trend-fallback-3.html", category: "🤖 AI 趨勢" },
        { title: "最新手機評測與比較 2026", url: "/trend/trend-fallback-4.html", category: "🤖 AI 趨勢" },
        { title: "網路安全與個資保護技巧", url: "/trend/trend-fallback-5.html", category: "🤖 AI 趨勢" },
        { title: "生成式 AI 工具 2026 年必學 5 款", url: "/trend/generative-ai-tools-2026.html", category: "🤖 AI 趨勢" },
    ];

    function getDailySeed() {
        const today = new Date();
        const dateStr = `${today.getFullYear()}-${today.getMonth()+1}-${today.getDate()}`;
        let hash = 0;
        for (let i = 0; i < dateStr.length; i++) {
            hash = ((hash << 5) - hash) + dateStr.charCodeAt(i);
            hash |= 0;
        }
        return Math.abs(hash);
    }

    function getDailyArticle() {
        const seed = getDailySeed();
        const index = seed % articles.length;
        return articles[index];
    }

    function renderDailyChallenge() {
        const article = getDailyArticle();
        const container = document.getElementById('daily-challenge');
        if (!container) return;
        container.innerHTML = `
            <div class="daily-challenge-card">
                <div class="daily-badge">🌟 每日精選</div>
                <div class="daily-category">${article.category}</div>
                <h3 class="daily-title">${article.title}</h3>
                <a href="${article.url}" class="daily-btn">📖 立即閱讀</a>
            </div>
        `;
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', renderDailyChallenge);
    } else {
        renderDailyChallenge();
    }

    window.dailyChallenge = {
        getDailyArticle: getDailyArticle,
        renderDailyChallenge: renderDailyChallenge,
        articles: articles
    };
})();
