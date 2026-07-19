# ============================================================
# 雅寶社區 · 頂客論壇 - 遊戲生成腳本 v2.0 (模組化重構版)
# ============================================================
# 功能：
#   1. 生成遊戲索引頁面（game/index.html）
#   2. 生成所有遊戲 HTML 檔案（含統一的頁首/頁尾）
#   3. 自動注入玩法說明 + Giscus 留言區塊（通用模板）
# ============================================================
# 使用方法：
#   1. 在「自訂新增遊戲」區塊填入你要新增的遊戲
#   2. 以 PowerShell 執行：.\generate-games.ps1
# ============================================================

# ============================================================
# 1. 路徑設定（改為相對路徑 + 環境變數）
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

# 輸出目錄：優先使用環境變數，否則使用預設路徑
$OutputDir = $env:AHPAL_OUTPUT_DIR
if (-not $OutputDir) {
    $OutputDir = "C:\ahpal-static"
}
# 如果預設路徑不存在，嘗試使用腳本目錄下的 static
if (-not (Test-Path $OutputDir)) {
    $OutputDir = Join-Path $ScriptDir "static"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "📁 腳本目錄：$ScriptDir" -ForegroundColor Cyan
Write-Host "📁 輸出目錄：$OutputDir" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 2. Giscus 配置參數（統一管理）
# ============================================================
$GiscusRepo = "praystone/ahpal-website"
$GiscusRepoId = "R_kgDOTbvurg"
$GiscusCategory = "Announcements"
$GiscusCategoryId = "DIC_kwDOTbvurs4DBhek"

# ============================================================
# 3. 自訂新增小遊戲（HTML 遊戲檔案）
# ============================================================
$newGames = @(
    # === 原有 10 款遊戲 ===
    @{
        name     = "2048"
        title    = "2048 - 數字合併挑戰"
        filename = "game/2048.html"
        description = "合併相同數字，挑戰 2048！經典益智遊戲"
        category = "益智解謎"
    },
    @{
        name     = "sudoku"
        title    = "數獨 - 邏輯推理挑戰"
        filename = "game/sudoku.html"
        description = "經典 9x9 數獨，鍛鍊你的邏輯思維"
        category = "益智解謎"
    },
    @{
        name     = "snake"
        title    = "貪吃蛇 - 經典街機遊戲"
        filename = "game/snake.html"
        description = "控制小蛇吃食物，挑戰最高分數！"
        category = "動作反應"
    },
    @{
        name     = "tetris"
        title    = "俄羅斯方塊 - 經典方塊遊戲"
        filename = "game/tetris.html"
        description = "旋轉、排列方塊，消除完整行數！"
        category = "益智解謎"
    },
    @{
        name     = "memory"
        title    = "記憶翻牌 - 配對挑戰"
        filename = "game/memory.html"
        description = "翻開卡片，記住位置，配對成功！"
        category = "腦力訓練"
    },
    @{
        name     = "minesweeper"
        title    = "踩地雷 - 經典推理遊戲"
        filename = "game/minesweeper.html"
        description = "經典踩地雷推理遊戲，考驗你的邏輯"
        category = "益智解謎"
    },
    @{
        name     = "wordsearch"
        title    = "文字搜尋 - 找單字挑戰"
        filename = "game/wordsearch.html"
        description = "在字母矩陣中找出隱藏的單字"
        category = "腦力訓練"
    },
    @{
        name     = "colormatch"
        title    = "顏色配對 - 反應速度考驗"
        filename = "game/colormatch.html"
        description = "考驗你的反應速度和顏色辨識能力"
        category = "休閒放鬆"
    },
    @{
        name     = "clicker"
        title    = "點點樂 - 快速點擊挑戰"
        filename = "game/clicker.html"
        description = "在時間內盡可能快速點擊！"
        category = "休閒放鬆"
    },
    @{
        name     = "breakout"
        title    = "打磚塊 - 經典打磚塊遊戲"
        filename = "game/breakout.html"
        description = "控制擋板，反彈球消滅所有磚塊！"
        category = "動作反應"
    },
    
    # === 🆕 新增 5 款遊戲（董事會決議） ===
    @{
        name     = "shooting-range"
        title    = "射擊靶場 - 瞄準挑戰"
        filename = "game/shooting-range.html"
        description = "瞄準靶心，考驗你的射擊精準度！"
        category = "動作反應"
    },
    @{
        name     = "jigsaw-puzzle"
        title    = "拼圖挑戰 - 完成圖片"
        filename = "game/jigsaw-puzzle.html"
        description = "拖曳拼塊，完成美麗的圖片！"
        category = "益智解謎"
    },
    @{
        name     = "color-memory"
        title    = "色彩記憶 - 顏色順序挑戰"
        filename = "game/color-memory.html"
        description = "記住顏色順序，挑戰你的記憶力！"
        category = "腦力訓練"
    },
    @{
        name     = "archery"
        title    = "弓箭手 - 精準射擊"
        filename = "game/archery.html"
        description = "拉弓射箭，瞄準目標得分！"
        category = "動作反應"
    },
    @{
        name     = "math-quiz"
        title    = "數學速算 - 腦力激盪"
        filename = "game/math-quiz.html"
        description = "在時間內回答數學問題，考驗你的計算能力！"
        category = "腦力訓練"
    },

    # === 🆕 董事會決議新增 4 款遊戲 ===
    @{
        name     = "tic-tac-toe"
        title    = "井字遊戲 - 經典對戰"
        filename = "game/tic-tac-toe.html"
        description = "與 AI 對戰井字遊戲，考驗你的策略思維！"
        category = "益智解謎"
    },
    @{
        name     = "hangman"
        title    = "猜字遊戲 - 單字挑戰"
        filename = "game/hangman.html"
        description = "猜出隱藏的英文單字，拯救小人物！"
        category = "腦力訓練"
    },
    @{
        name     = "flappy-bird"
        title    = "飛翔小鳥 - 極限反應"
        filename = "game/flappy-bird.html"
        description = "控制小鳥穿越障礙，挑戰你的反應極限！"
        category = "動作反應"
    },
    @{
        name     = "simon-says"
        title    = "記憶節奏 - 跟著我唸"
        filename = "game/simon-says.html"
        description = "記住並重複顏色順序，考驗你的短期記憶！"
        category = "腦力訓練"
    },

    # === 🆕 新增 4 款遊戲 ===
    @{
        name     = "doodle-jump"
        title    = "塗鴉跳躍 - 向上冒險"
        filename = "game/doodle-jump.html"
        description = "控制塗鴉小人向上跳躍，挑戰最高分數！"
        category = "動作反應"
    },
    @{
        name     = "pong"
        title    = "乒乓球 - 經典對戰"
        filename = "game/pong.html"
        description = "經典乒乓球對戰，考驗你的反應速度！"
        category = "動作反應"
    },
    @{
        name     = "solitaire"
        title    = "接龍 - 經典紙牌遊戲"
        filename = "game/solitaire.html"
        description = "經典接龍紙牌遊戲，考驗你的策略思維！"
        category = "益智解謎"
    },
    @{
        name     = "bubble-shooter"
        title    = "泡泡射擊 - 消消樂"
        filename = "game/bubble-shooter.html"
        description = "瞄準射擊彩色泡泡，消除所有泡泡！"
        category = "益智解謎"
    }
)

# ============================================================
# 4. 統一的頁首樣式（與首頁一致）
# ============================================================
$headerCSS = @"
        /* ============================================================
           頁首樣式（與首頁一致）
           ============================================================ */
        .site-header {
            background: #005A9C;
            color: white;
            padding: 12px 0;
            position: sticky;
            top: 0;
            z-index: 50;
            box-shadow: 0 2px 8px rgba(0,0,0,0.10);
            width: 100%;
        }
        .header-inner {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 10px;
        }
        .logo {
            font-size: 20px;
            font-weight: 700;
            color: white;
            text-decoration: none;
            letter-spacing: 0.5px;
            white-space: nowrap;
        }
        .logo:hover { color: rgba(255,255,255,0.85); }
        .nav-links {
            display: flex;
            gap: 20px;
            font-size: 14px;
            align-items: center;
            flex-wrap: wrap;
        }
        .nav-links a {
            color: rgba(255,255,255,0.85);
            text-decoration: none;
            transition: color 0.2s;
        }
        .nav-links a:hover {
            color: white;
            border-bottom: 2px solid #00A86B;
        }
        .nav-links .game-link {
            background: rgba(255,255,255,0.15);
            padding: 4px 14px;
            border-radius: 20px;
            font-weight: 500;
        }
        .nav-links .game-link:hover {
            border-bottom: none;
            background: rgba(255,255,255,0.25);
        }
"@

# ============================================================
# 5. 統一的頁首 HTML（與首頁一致）
# ============================================================
$headerHTML = @'
    <header class="site-header">
        <div class="header-inner">
            <a href="/" class="logo">雅寶社區 · 頂客論壇</a>
            <nav class="nav-links">
                <a href="/">首頁</a>
                <a href="/memorial.html">歲月迴聲</a>
                <a href="/royal_dragon_karma.html">公義史錄</a>
                <a href="/categories.html">📚 全部分類</a>
                <a href="/game/" class="game-link">🎮 遊戲間</a>
            </nav>
        </div>
    </header>
'@

# ============================================================
# 6. 統一的頁尾樣式（與首頁一致）
# ============================================================
$footerCSS = @"
        /* ============================================================
           頁尾樣式（與首頁一致）
           ============================================================ */
        .site-footer {
            background: #2D3748;
            color: #A0AEC0;
            padding: 40px 0 28px 0;
            margin-top: 40px;
            font-size: 14px;
            width: 100%;
        }
        .footer-inner {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
            text-align: center;
        }
        .footer-inner .copy {
            font-size: 13px;
            color: #718096;
        }
        .footer-inner .declaration {
            font-size: 12px;
            color: #FF6F61;
            letter-spacing: 1px;
            font-weight: 300;
            margin-top: 4px;
        }
        .footer-inner a {
            color: #A0AEC0;
            text-decoration: none;
        }
        .footer-inner a:hover {
            color: white;
            text-decoration: underline;
        }
"@

# ============================================================
# 7. 統一的頁尾 HTML（與首頁一致）
# ============================================================
$footerHTML = @'
    <footer class="site-footer">
        <div class="footer-inner">
            <div class="copy">&copy; 2026 雅寶社區 · 頂客論壇 (AHPAL.COM) — 版權所有</div>
            <div style="margin-top:6px;font-size:13px;">
                <a href="/sitemap.xml" style="color:#A0AEC0;text-decoration:none;margin:0 12px;">📄 Sitemap</a>
                <a href="/categories.html" style="color:#A0AEC0;text-decoration:none;margin:0 12px;">📚 全部分類</a>
                <a href="/game/" style="color:#A0AEC0;text-decoration:none;margin:0 12px;">🎮 遊戲間</a>
            </div>
            <div class="declaration">「從社區法治，走向知識共創」</div>
        </div>
    </footer>
'@

# ============================================================
# 8. 函數：生成遊戲索引頁面
# ============================================================
function Generate-GameIndex {
    param(
        [string]$OutputDir,
        [array]$Games
    )
    
    Write-Host "正在生成遊戲索引頁面..." -ForegroundColor Cyan
    
    $gameIndexPath = Join-Path $OutputDir "game\index.html"
    
    $gameIndexContent = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>雅寶遊戲間 - 雅寶社區 · 頂客論壇</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif;
            background: #f7fafc;
            color: #1a202c;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        $headerCSS
        $footerCSS
        .container { max-width: 900px; width: 100%; }
        .header { text-align: center; padding: 30px 0 20px 0; }
        .header h1 { font-size: 36px; color: #005A9C; margin-bottom: 4px; }
        .header p { color: #4a5568; font-size: 16px; }
        .back-link { display: inline-block; margin-bottom: 20px; color: #005A9C; text-decoration: none; font-weight: 500; }
        .back-link:hover { text-decoration: underline; }
        .stats { display: flex; flex-wrap: wrap; gap: 16px; justify-content: center; margin-bottom: 20px; }
        .stats .stat { background: white; padding: 8px 20px; border-radius: 20px; font-size: 13px; color: #4a5568; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
        .stats .stat strong { color: #005A9C; }
        .game-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .game-card {
            background: white;
            border-radius: 14px;
            padding: 24px 20px;
            text-align: center;
            text-decoration: none;
            color: inherit;
            box-shadow: 0 4px 12px rgba(0,0,0,0.06);
            border: 1px solid #e2e8f0;
            transition: all 0.3s ease;
        }
        .game-card:hover { transform: translateY(-6px); box-shadow: 0 8px 25px rgba(0,0,0,0.12); border-color: #005A9C; }
        .game-card .icon { font-size: 48px; display: block; margin-bottom: 8px; }
        .game-card .name { font-size: 18px; font-weight: 700; color: #1a202c; }
        .game-card .desc { font-size: 13px; color: #718096; margin-top: 4px; }
        .game-card .badge { display: inline-block; background: #005A9C; color: white; padding: 2px 14px; border-radius: 20px; font-size: 11px; margin-top: 8px; }
        .game-card .category-tag { display: inline-block; background: #edf2f7; color: #4a5568; padding: 2px 12px; border-radius: 12px; font-size: 11px; margin-top: 4px; }
        .search-box {
            width: 100%;
            max-width: 400px;
            padding: 10px 18px;
            border: 2px solid #e2e8f0;
            border-radius: 30px;
            font-size: 14px;
            outline: none;
            transition: border-color 0.3s;
            margin-bottom: 16px;
        }
        .search-box:focus { border-color: #005A9C; }
        @media (max-width: 480px) {
            .game-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
            .game-card { padding: 16px 12px; }
            .game-card .icon { font-size: 36px; }
            .game-card .name { font-size: 15px; }
        }
    </style>
</head>
<body>
    $headerHTML
    <div class="container">
        <a href="/" class="back-link">← 返回首頁</a>
        <div class="header">
            <h1>🎮 雅寶遊戲間</h1>
            <p>閱讀之餘，放鬆一下！精選 HTML5 小遊戲，免下載、即開即玩。</p>
        </div>
        <div class="stats">
            <span class="stat">🎮 總遊戲：<strong>$($Games.Count)</strong> 款</span>
            <span class="stat">✅ 已上線：<strong>$($Games.Count)</strong> 款</span>
        </div>
        <input type="text" class="search-box" id="searchBox" placeholder="🔍 搜尋遊戲名稱或類型...">
        <div class="game-grid" id="gameGrid">
"@

    $categoryIcons = @{
        '益智解謎' = '🧩'
        '腦力訓練' = '🧠'
        '休閒放鬆' = '🎯'
        '動作反應' = '⚡'
    }

    foreach ($game in $Games) {
        $cat = if ($game.category) { $game.category } else { '其他' }
        $catIcon = if ($categoryIcons[$cat]) { $categoryIcons[$cat] } else { '🎮' }
        $icon = switch ($game.name) {
            '2048' { '🔢' }
            'sudoku' { '🧩' }
            'snake' { '🐍' }
            'tetris' { '🧱' }
            'memory' { '🃏' }
            'minesweeper' { '💣' }
            'wordsearch' { '🔍' }
            'colormatch' { '🎯' }
            'clicker' { '👆' }
            'breakout' { '🏏' }
            'shooting-range' { '🎯' }
            'jigsaw-puzzle' { '🧩' }
            'color-memory' { '🎨' }
            'archery' { '🏹' }
            'math-quiz' { '🧠' }
            'tic-tac-toe' { '❌' }
            'hangman' { '🔤' }
            'flappy-bird' { '🐦' }
            'simon-says' { '🎵' }
            'doodle-jump' { '🦘' }
            'pong' { '🏓' }
            'solitaire' { '🃏' }
            'bubble-shooter' { '🫧' }
            default { '🎮' }
        }
        $gameIndexContent += @"
            <a href="/$($game.filename)" class="game-card" data-name="$($game.title)" data-category="$cat">
                <span class="icon">$icon</span>
                <span class="name">$($game.title)</span>
                <span class="desc">$($game.description)</span>
                <span class="category-tag">$catIcon $cat</span>
                <span class="badge">立即遊玩</span>
            </a>
"@
    }

    $gameIndexContent += @"
        </div>
    </div>
    $footerHTML
    <script>
        document.getElementById('searchBox').addEventListener('input', function() {
            const query = this.value.toLowerCase();
            const cards = document.querySelectorAll('.game-card');
            for (const card of cards) {
                const name = card.dataset.name.toLowerCase();
                const category = card.dataset.category.toLowerCase();
                if (name.includes(query) || category.includes(query)) {
                    card.style.display = '';
                } else {
                    card.style.display = 'none';
                }
            }
        });
    </script>
</body>
</html>
"@

    Set-Content -Path $gameIndexPath -Value $gameIndexContent -Encoding UTF8
    Write-Host "✅ 已建立遊戲索引頁面：$gameIndexPath" -ForegroundColor Green
}

# ============================================================
# 9. 函數：生成單一遊戲 HTML（模組化重構版）
# ============================================================
function Generate-GameHTML {
    param(
        [string]$GameName,
        [string]$GameTitle,
        [string]$OutputPath,
        [string]$Description
    )
    
    Write-Host "正在生成遊戲：$GameTitle" -ForegroundColor Cyan
    
    $gameDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $gameDir)) {
        New-Item -ItemType Directory -Path $gameDir -Force | Out-Null
    }
    
    # ============================================================
    # 9a. 定義遊戲核心內容（每個遊戲的專屬 HTML）
    # ============================================================
    $gameContent = switch ($GameName) {
        "2048" { 
            @'
<div class="game-container">
    <div class="header">
        <h1>2048</h1>
        <div class="score-box">
            <div class="label">分數</div>
            <div class="value" id="score">0</div>
        </div>
    </div>
    <div class="game-wrapper">
        <div class="grid" id="grid"></div>
        <div class="game-over" id="gameOver">
            <h2>遊戲結束！</h2>
            <p>最終分數：<span id="finalScore">0</span></p>
            <button onclick="initGame()">🔄 重新開始</button>
        </div>
    </div>
    <div class="controls">
        <button onclick="initGame()" class="new-game">🔄 新遊戲</button>
    </div>
    <p style="text-align:center;color:#776e65;margin-top:12px;font-size:13px;">
        使用 ← ↑ → ↓ 或 WASD 控制
    </p>
</div>
'@
        }
        "sudoku" {
            @'
<div class="game-container">
    <h1>🧩 數獨</h1>
    <div class="board" id="board"></div>
    <div class="num-pad" id="numPad">
        <button onclick="setNumber(1)">1</button>
        <button onclick="setNumber(2)">2</button>
        <button onclick="setNumber(3)">3</button>
        <button onclick="setNumber(4)">4</button>
        <button onclick="setNumber(5)">5</button>
        <button onclick="setNumber(6)">6</button>
        <button onclick="setNumber(7)">7</button>
        <button onclick="setNumber(8)">8</button>
        <button onclick="setNumber(9)">9</button>
    </div>
    <div class="controls">
        <button onclick="newGame()">🔄 新遊戲</button>
        <button onclick="clearCell()">✕ 清除</button>
        <button onclick="hint()">💡 提示</button>
    </div>
    <div class="message" id="message">點擊空格，再點數字填入</div>
</div>
'@
        }
        "snake" {
            @'
<div class="game-container">
    <div class="header">
        <h1>🐍 貪吃蛇</h1>
        <div class="score">🏆 <span id="score">0</span></div>
    </div>
    <div class="board" id="board"></div>
    <div class="controls">
        <button onclick="changeDirection('up')">⬆</button>
        <button onclick="changeDirection('left')">⬅</button>
        <button onclick="changeDirection('down')">⬇</button>
        <button onclick="changeDirection('right')">➡</button>
        <button onclick="resetGame()">🔄 重新開始</button>
    </div>
    <div class="message" id="message">使用方向鍵或按鈕控制</div>
</div>
'@
        }
        "tetris" {
            @'
<div class="game-container">
    <div class="header">
        <h1>🧱 俄羅斯方塊</h1>
        <div class="info">
            <div>🏆 <span id="score">0</span></div>
            <div>📊 <span id="level">1</span></div>
        </div>
    </div>
    <div class="board" id="board"></div>
    <div class="controls">
        <button onclick="moveLeft()">⬅</button>
        <button onclick="rotatePiece()">🔄</button>
        <button onclick="moveRight()">➡</button>
        <button onclick="hardDrop()">⬇⬇</button>
        <button onclick="resetGame()">🔄 重新開始</button>
    </div>
    <div class="message" id="message">使用方向鍵控制</div>
</div>
'@
        }
        "memory" {
            @'
<div class="game-container">
    <div class="header">
        <h1>🃏 記憶翻牌</h1>
        <div class="info">
            <span>🎯 <span id="moves">0</span></span>
            <span>✅ <span id="matches">0</span>/8</span>
        </div>
    </div>
    <div class="board" id="board"></div>
    <div class="controls">
        <button onclick="initGame()">🔄 新遊戲</button>
    </div>
    <div class="message" id="message">翻開兩張卡片，找到配對！</div>
</div>
'@
        }
        "minesweeper" {
            @'
<div class="game-container">
    <h1>💣 踩地雷</h1>
    <div class="header">
        <span class="info">💣 <span id="mineCount">10</span></span>
        <span class="info">🏆 <span id="flagCount">0</span></span>
    </div>
    <div class="board" id="board"></div>
    <div class="controls">
        <button onclick="initGame()">🔄 新遊戲</button>
    </div>
    <div class="message" id="message">點擊左鍵翻開，右鍵標記旗子</div>
</div>
'@
        }
        "wordsearch" {
            @'
<div class="game-container">
    <h1>🔍 文字搜尋</h1>
    <div class="word-list" id="wordList"></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊字母選取單字</div>
</div>
'@
        }
        "colormatch" {
            @'
<div class="game-container">
    <h1>🎯 顏色配對</h1>
    <div class="header">
        <span class="info">🎯 回合 <span id="round">1</span>/10</span>
        <span class="info">⭐ 分數 <span id="score">0</span></span>
    </div>
    <div class="color-display" id="colorDisplay"></div>
    <div class="color-name" id="colorName">準備開始</div>
    <div class="options" id="options"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="score" id="message">點擊與顯示顏色名稱相符的色塊</div>
</div>
'@
        }
        "clicker" {
            @'
<div class="game-container">
    <h1>👆 點點樂</h1>
    <div class="header">
        <span class="info">⏱️ <span id="timer">10</span>s</span>
        <span class="info">👆 <span id="clicks">0</span></span>
        <span class="info">🏆 <span id="best">0</span></span>
    </div>
    <div class="click-area" id="clickArea">
        <div class="count" id="countDisplay">0</div>
        <div class="label" id="statusLabel">點我開始</div>
    </div>
    <div class="controls">
        <button onclick="startGame()">🚀 開始挑戰</button>
        <button onclick="resetGame()">🔄 重置</button>
    </div>
    <div class="message" id="message">點擊「開始挑戰」或點擊方塊開始</div>
</div>
'@
        }
        "breakout" {
            @'
<div class="game-container">
    <h1>🏏 打磚塊</h1>
    <div class="header">
        <span class="info">🏆 <span id="score">0</span></span>
        <span class="info">🧱 <span id="bricksLeft">0</span></span>
        <span class="info">❤️ <span id="lives">3</span></span>
    </div>
    <canvas id="gameCanvas" width="450" height="320"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">使用滑鼠或鍵盤 ← → 控制擋板</div>
</div>
'@
        }
        "shooting-range" {
            @'
<div class="game-container">
    <h1>🎯 射擊靶場</h1>
    <div class="header">
        <span class="info">🎯 分數 <span id="score">0</span></span>
        <span class="info">💨 剩餘 <span id="shots">10</span></span>
    </div>
    <canvas id="gameCanvas" width="400" height="400"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊靶心射擊！</div>
</div>
'@
        }
        "jigsaw-puzzle" {
            @'
<div class="game-container">
    <h1>🧩 拼圖挑戰</h1>
    <div class="header">
        <span class="info">👆 步數 <span id="moves">0</span></span>
        <span class="info">⏱️ 時間 <span id="timer">0</span>s</span>
    </div>
    <div class="puzzle-grid" id="puzzleGrid"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊相鄰拼塊移動</div>
</div>
'@
        }
        "color-memory" {
            @'
<div class="game-container">
    <h1>🎨 色彩記憶</h1>
    <div class="header">
        <span class="info">🎯 回合 <span id="round">1</span></span>
        <span class="info">⭐ 分數 <span id="score">0</span></span>
    </div>
    <div class="color-panel" id="colorPanel"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">觀察顏色順序，然後重複點擊！</div>
</div>
'@
        }
        "archery" {
            @'
<div class="game-container">
    <h1>🏹 弓箭手</h1>
    <div class="header">
        <span class="info">🎯 分數 <span id="score">0</span></span>
        <span class="info">🏹 箭矢 <span id="arrows">10</span></span>
    </div>
    <canvas id="gameCanvas" width="400" height="300"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊畫布射箭！</div>
</div>
'@
        }
        "math-quiz" {
            @'
<div class="game-container">
    <h1>🧠 數學速算</h1>
    <div class="header">
        <span class="info">✅ 正確 <span id="correct">0</span></span>
        <span class="info">❌ 錯誤 <span id="wrong">0</span></span>
        <span class="info">⏱️ <span id="timer">60</span>s</span>
    </div>
    <div class="question" id="question">準備開始</div>
    <div class="options" id="options"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊「新遊戲」開始挑戰！</div>
</div>
'@
        }
        "tic-tac-toe" {
            @'
<div class="game-container">
    <h1>❌ 井字遊戲</h1>
    <div class="header">
        <span class="info">❌ 玩家 <span id="playerScore">0</span></span>
        <span class="info">⚖️ 平手 <span id="drawScore">0</span></span>
        <span class="info">⭕ AI <span id="aiScore">0</span></span>
    </div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊格子開始遊戲！</div>
</div>
'@
        }
        "hangman" {
            @'
<div class="game-container">
    <h1>🔤 猜字遊戲</h1>
    <div class="header">
        <span class="info">❌ 錯誤 <span id="mistakes">0</span>/6</span>
        <span class="info">🏆 勝場 <span id="wins">0</span></span>
    </div>
    <div class="hangman-ascii" id="hangmanDisplay"></div>
    <div class="word-display" id="wordDisplay"></div>
    <div class="letters" id="letters"></div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊字母猜字！</div>
</div>
'@
        }
        "flappy-bird" {
            @'
<div class="game-container">
    <h1>🐦 飛翔小鳥</h1>
    <div class="header">
        <span class="info">🏆 分數 <span id="score">0</span></span>
        <span class="info">🏅 最高 <span id="best">0</span></span>
    </div>
    <canvas id="gameCanvas" width="360" height="500"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊畫面或按空白鍵跳躍！</div>
</div>
'@
        }
        "simon-says" {
            @'
<div class="game-container">
    <h1>🎵 記憶節奏</h1>
    <div class="header">
        <span class="info">🎯 回合 <span id="round">0</span></span>
        <span class="info">⭐ 分數 <span id="score">0</span></span>
    </div>
    <div class="simon-grid" id="simonGrid">
        <div class="simon-btn green" data-color="green"></div>
        <div class="simon-btn red" data-color="red"></div>
        <div class="simon-btn yellow" data-color="yellow"></div>
        <div class="simon-btn blue" data-color="blue"></div>
    </div>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊「新遊戲」開始！</div>
</div>
'@
        }
        "doodle-jump" {
            @'
<div class="game-container">
    <h1>🦘 塗鴉跳躍</h1>
    <div class="header">
        <span class="info">🏆 分數 <span id="score">0</span></span>
        <span class="info">🏅 最高 <span id="best">0</span></span>
    </div>
    <canvas id="gameCanvas" width="360" height="500"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">按住滑鼠/手指左右移動控制跳躍方向</div>
</div>
'@
        }
        "pong" {
            @'
<div class="game-container">
    <h1>🏓 乒乓球</h1>
    <div class="header">
        <span class="info">👈 玩家 <span id="playerScore">0</span></span>
        <span class="info">🤖 AI <span id="aiScore">0</span></span>
    </div>
    <canvas id="gameCanvas" width="400" height="300"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">滑鼠上下移動控制</div>
</div>
'@
        }
        "solitaire" {
            @'
<div class="game-container">
    <h1>🃏 接龍</h1>
    <div class="header">
        <span class="info">⏱️ <span id="moves">0</span></span>
        <span class="info">✅ 完成 <span id="done">0</span>/4</span>
    </div>
    <canvas id="gameCanvas" width="650" height="400"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊卡片移動到正確位置</div>
</div>
'@
        }
        "bubble-shooter" {
            @'
<div class="game-container">
    <h1>🫧 泡泡射擊</h1>
    <div class="header">
        <span class="info">🎯 <span id="score">0</span></span>
        <span class="info">💨 剩餘 <span id="shots">20</span></span>
    </div>
    <canvas id="gameCanvas" width="380" height="450"></canvas>
    <div class="controls"><button onclick="initGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">移動滑鼠瞄準，點擊射擊</div>
</div>
'@
        }
        default {
            @'
<div class="game-container">
    <h1>🎮 遊戲開發中</h1>
    <p>敬請期待！</p>
</div>
'@
        }
    }
    
    # ============================================================
    # 9b. 定義通用的玩法說明
    # ============================================================
    $gameInstructions = @{
        "2048" = "使用方向鍵 (← ↑ → ↓) 或 WASD 移動方塊。相同數字的方塊碰撞後會合併，目標是拼出 2048 方塊！每次移動都會在空白處產生一個新的 2 或 4。"
        "sudoku" = "點擊空格，填入 1-9，確保每行、每列、每個 3x3 宮格內數字不重複。"
        "snake" = "方向鍵控制移動，吃食物變長，不要撞牆或撞自己的身體。"
        "tetris" = "方向鍵移動/旋轉方塊，消除完整行得分，方塊堆疊到頂端則遊戲結束。"
        "memory" = "翻開兩張卡片，記住位置並配對成功！考驗你的記憶力。"
        "minesweeper" = "左鍵翻開格子，右鍵標記地雷。不要踩到地雷！"
        "wordsearch" = "拖曳選取字母，找出隱藏在矩陣中的單字。"
        "colormatch" = "點擊與顯示顏色名稱相符的色塊，考驗你的反應速度！"
        "clicker" = "在時間內盡可能快速點擊，挑戰最高分數！"
        "breakout" = "滑鼠移動擋板，反彈球消滅所有磚塊！"
        "shooting-range" = "點擊移動的靶心射擊，考驗你的精準度！"
        "jigsaw-puzzle" = "點擊相鄰拼塊移動，完成完整圖片！"
        "color-memory" = "記住顏色順序，正確重複點擊，挑戰你的記憶力！"
        "archery" = "點擊畫布射箭，瞄準移動的靶心得分！"
        "math-quiz" = "在時間內回答數學問題，考驗你的計算能力！"
        "tic-tac-toe" = "與 AI 對戰，連成三條線獲勝！"
        "hangman" = "點擊字母猜單字，錯誤超過 6 次則遊戲結束。"
        "flappy-bird" = "點擊畫面或按空白鍵讓小鳥跳躍，穿越障礙！"
        "simon-says" = "記住並重複顏色順序，考驗你的短期記憶！"
        "doodle-jump" = "按住滑鼠左右移動控制跳躍方向，挑戰最高分數！"
        "pong" = "滑鼠上下移動控制擋板，與 AI 對戰！"
        "solitaire" = "點擊卡片移動到正確位置，完成所有牌堆！"
        "bubble-shooter" = "移動滑鼠瞄準，點擊射擊消除泡泡！"
    }
    
    $instruction = if ($gameInstructions.ContainsKey($GameName)) {
        $gameInstructions[$GameName]
    } else {
        "享受遊戲樂趣！"
    }
    
    # ============================================================
    # 9c. 構建通用頁尾模板（玩法說明 + Giscus 留言）
    # ============================================================
    $footerTemplate = @"
    <!-- ============================================================
    🎮 玩法說明
    ============================================================ -->
    <div class="how-to-play">
        <h3>🎯 玩法說明</h3>
        <p>$instruction</p>
    </div>

    <!-- ============================================================
    💬 留言討論區 (Giscus)
    ============================================================ -->
    <div class="comments-section">
        <h3>💬 討論與留言</h3>
        <p>歡迎分享你的遊戲心得、技巧或疑問！</p>
        <div class="giscus"></div>
    </div>

    <script src="https://giscus.app/client.js"
        data-repo="$GiscusRepo"
        data-repo-id="$GiscusRepoId"
        data-category="$GiscusCategory"
        data-category-id="$GiscusCategoryId"
        data-mapping="pathname"
        data-strict="0"
        data-reactions-enabled="1"
        data-emit-metadata="0"
        data-input-position="bottom"
        data-theme="preferred_color_scheme"
        data-lang="zh-TW"
        crossorigin="anonymous"
        async>
    </script>
"@
    
    # ============================================================
    # 9d. 組合完整 HTML
    # ============================================================
    $htmlContent = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$GameTitle - 雅寶遊戲間</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif;
            background: #f7fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
            padding: 20px;
        }
        $headerCSS
        $footerCSS
        
        /* ============================================================
           遊戲容器基本樣式
           ============================================================ */
        .game-container {
            max-width: 500px;
            width: 100%;
            background: white;
            padding: 24px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin: 20px 0;
        }
        
        /* ============================================================
           玩法說明與留言區塊樣式
           ============================================================ */
        .how-to-play {
            background: #f0f4f8;
            padding: 16px 20px;
            border-radius: 12px;
            margin: 16px auto;
            max-width: 500px;
            width: 100%;
            font-size: 14px;
            color: #2d3748;
            border-left: 4px solid #005A9C;
        }
        .how-to-play h3 {
            font-size: 16px;
            font-weight: 700;
            color: #005A9C;
            margin-bottom: 4px;
        }
        .how-to-play p {
            margin: 0;
        }
        .how-to-play strong {
            color: #005A9C;
        }
        .comments-section {
            max-width: 500px;
            width: 100%;
            margin: 20px auto;
            padding-top: 20px;
            border-top: 2px solid #e2e8f0;
        }
        .comments-section h3 {
            font-size: 18px;
            font-weight: 700;
            color: #1a202c;
            margin-bottom: 2px;
        }
        .comments-section p {
            font-size: 14px;
            color: #4a5568;
            margin-bottom: 16px;
        }
        @media (max-width: 480px) {
            .how-to-play { font-size: 13px; padding: 14px 16px; }
            .comments-section h3 { font-size: 16px; }
            .game-container { padding: 16px; }
        }
    </style>
</head>
<body>
    $headerHTML
    
    <!-- ============================================================
    遊戲核心內容
    ============================================================ -->
    $gameContent
    
    <!-- ============================================================
    通用頁尾模板（玩法說明 + Giscus 留言）
    ============================================================ -->
    $footerTemplate
    
    $footerHTML
</body>
</html>
"@
    
    # ============================================================
    # 9e. 寫入檔案
    # ============================================================
    try {
        Set-Content -Path $OutputPath -Value $htmlContent -Encoding UTF8
        Write-Host "   ✅ 已生成：$OutputPath" -ForegroundColor Green
    } catch {
        Write-Host "   ❌ 寫入失敗：$_" -ForegroundColor Red
    }
}

# ============================================================
# 10. 主程式執行
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  雅寶社區 · 頂客論壇 - 遊戲生成工具 v2.0 (模組化重構版)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "步驟 1：生成遊戲 HTML..." -ForegroundColor Yellow
foreach ($game in $newGames) {
    $outputPath = Join-Path $OutputDir $game.filename
    Generate-GameHTML -GameName $game.name -GameTitle $game.title -OutputPath $outputPath -Description $game.description
}

Write-Host ""
Write-Host "步驟 2：生成遊戲索引頁面..." -ForegroundColor Yellow
Generate-GameIndex -OutputDir $OutputDir -Games $newGames

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 全部完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "遊戲總數：$($newGames.Count) 款" -ForegroundColor Cyan
Write-Host "遊戲入口：https://ahpal.com/game/" -ForegroundColor Yellow
Write-Host ""

# 正常結束
exit 0