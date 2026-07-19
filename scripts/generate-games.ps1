# ============================================================
# 雅寶社區 · 頂客論壇 - 遊戲生成腳本 v3.0 (完整版)
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }

$OutputDir = $env:AHPAL_OUTPUT_DIR
if (-not $OutputDir) { $OutputDir = "C:\Users\User\ahpal-static" }
if (-not (Test-Path $OutputDir)) {
    $OutputDir = Join-Path $ScriptDir "static"
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

Write-Host "📁 輸出目錄：$OutputDir" -ForegroundColor Cyan

$GiscusRepo = "praystone/ahpal-website"
$GiscusRepoId = "R_kgDOTbvurg"
$GiscusCategory = "Announcements"
$GiscusCategoryId = "DIC_kwDOTbvurs4DBhek"

# ============================================================
# 全部 23 款遊戲定義
# ============================================================
$newGames = @(
    @{ name = "2048"; title = "2048 - 數字合併挑戰"; filename = "game/2048.html"; description = "合併相同數字，挑戰 2048！"; category = "益智解謎" }
    @{ name = "snake"; title = "貪吃蛇 - 經典街機遊戲"; filename = "game/snake.html"; description = "控制小蛇吃食物，挑戰最高分數！"; category = "動作反應" }
    @{ name = "tetris"; title = "俄羅斯方塊 - 經典方塊遊戲"; filename = "game/tetris.html"; description = "旋轉、排列方塊，消除完整行數！"; category = "益智解謎" }
    @{ name = "sudoku"; title = "數獨 - 邏輯推理挑戰"; filename = "game/sudoku.html"; description = "經典 9x9 數獨，鍛鍊邏輯思維"; category = "益智解謎" }
    @{ name = "memory"; title = "記憶翻牌 - 配對挑戰"; filename = "game/memory.html"; description = "翻開卡片，記住位置，配對成功！"; category = "腦力訓練" }
    @{ name = "minesweeper"; title = "踩地雷 - 經典推理遊戲"; filename = "game/minesweeper.html"; description = "經典踩地雷推理遊戲"; category = "益智解謎" }
    @{ name = "wordsearch"; title = "文字搜尋 - 找單字挑戰"; filename = "game/wordsearch.html"; description = "在字母矩陣中找出隱藏的單字"; category = "腦力訓練" }
    @{ name = "colormatch"; title = "顏色配對 - 反應速度考驗"; filename = "game/colormatch.html"; description = "考驗你的反應速度和顏色辨識能力"; category = "休閒放鬆" }
    @{ name = "clicker"; title = "點點樂 - 快速點擊挑戰"; filename = "game/clicker.html"; description = "在時間內盡可能快速點擊！"; category = "休閒放鬆" }
    @{ name = "breakout"; title = "打磚塊 - 經典打磚塊遊戲"; filename = "game/breakout.html"; description = "控制擋板，反彈球消滅所有磚塊！"; category = "動作反應" }
    @{ name = "shooting-range"; title = "射擊靶場 - 瞄準挑戰"; filename = "game/shooting-range.html"; description = "瞄準靶心，考驗射擊精準度！"; category = "動作反應" }
    @{ name = "jigsaw-puzzle"; title = "拼圖挑戰 - 完成圖片"; filename = "game/jigsaw-puzzle.html"; description = "拖曳拼塊，完成美麗的圖片！"; category = "益智解謎" }
    @{ name = "color-memory"; title = "色彩記憶 - 顏色順序挑戰"; filename = "game/color-memory.html"; description = "記住顏色順序，挑戰記憶力！"; category = "腦力訓練" }
    @{ name = "archery"; title = "弓箭手 - 精準射擊"; filename = "game/archery.html"; description = "拉弓射箭，瞄準目標得分！"; category = "動作反應" }
    @{ name = "math-quiz"; title = "數學速算 - 腦力激盪"; filename = "game/math-quiz.html"; description = "在時間內回答數學問題！"; category = "腦力訓練" }
    @{ name = "tic-tac-toe"; title = "井字遊戲 - 經典對戰"; filename = "game/tic-tac-toe.html"; description = "與 AI 對戰井字遊戲！"; category = "益智解謎" }
    @{ name = "hangman"; title = "猜字遊戲 - 單字挑戰"; filename = "game/hangman.html"; description = "猜出隱藏的英文單字！"; category = "腦力訓練" }
    @{ name = "flappy-bird"; title = "飛翔小鳥 - 極限反應"; filename = "game/flappy-bird.html"; description = "控制小鳥穿越障礙！"; category = "動作反應" }
    @{ name = "simon-says"; title = "記憶節奏 - 跟著我唸"; filename = "game/simon-says.html"; description = "記住並重複顏色順序！"; category = "腦力訓練" }
    @{ name = "doodle-jump"; title = "塗鴉跳躍 - 向上冒險"; filename = "game/doodle-jump.html"; description = "控制塗鴉小人向上跳躍！"; category = "動作反應" }
    @{ name = "pong"; title = "乒乓球 - 經典對戰"; filename = "game/pong.html"; description = "經典乒乓球對戰！"; category = "動作反應" }
    @{ name = "solitaire"; title = "接龍 - 經典紙牌遊戲"; filename = "game/solitaire.html"; description = "經典接龍紙牌遊戲！"; category = "益智解謎" }
    @{ name = "bubble-shooter"; title = "泡泡射擊 - 消消樂"; filename = "game/bubble-shooter.html"; description = "瞄準射擊彩色泡泡！"; category = "益智解謎" }
)

# ============================================================
# 頁首/頁尾
# ============================================================
$headerHTML = @'
<header class="site-header"><div class="header-inner"><a href="/" class="logo">雅寶社區 · 頂客論壇</a><nav class="nav-links"><a href="/">首頁</a><a href="/categories.html">📚 全部分類</a><a href="/game/" class="game-link">🎮 遊戲間</a></nav></div></header>
'@

$footerHTML = @'
<footer class="site-footer"><div class="footer-inner"><div class="copy">&copy; 2026 雅寶社區 · 頂客論壇</div></div></footer>
'@

# ============================================================
# 取得完整遊戲內容（包含 HTML + JavaScript）
# ============================================================
function Get-GameContent {
    param([string]$GameName)
    switch ($GameName) {
        "2048" { return @'
<div class="game-container">
    <h1>🔢 2048</h1>
    <div class="score-box"><span>分數：<span id="score">0</span></span></div>
    <div class="grid" id="grid"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="game-over" id="gameOver"><h2>遊戲結束！</h2><p>最終分數：<span id="finalScore">0</span></p></div>
</div>
<script>
let grid, score, size=4, over;
const el=document.getElementById('grid'), sc=document.getElementById('score'), go=document.getElementById('gameOver');
function init(){
  grid=Array.from({length:size},()=>Array(size).fill(0)); score=0; over=false; go.style.display='none';
  add(); add(); render();
}
function add(){
  let e=[]; for(let i=0;i<size;i++)for(let j=0;j<size;j++)if(!grid[i][j])e.push({x:i,y:j});
  if(!e.length)return; let c=e[Math.floor(Math.random()*e.length)]; grid[c.x][c.y]=Math.random()<.9?2:4;
}
function render(){
  el.innerHTML='';
  for(let i=0;i<size;i++)for(let j=0;j<size;j++){let v=grid[i][j]; let d=document.createElement('div'); d.className='tile'+(v?' tile-'+v:''); d.textContent=v||''; el.appendChild(d);}
  sc.textContent=score;
}
function slide(r){let a=r.filter(v=>v), m=[]; for(let i=0;i<a.length;i++){if(i+1<a.length&&a[i]===a[i+1]){m.push(a[i]*2);score+=a[i]*2;i++;}else m.push(a[i]);}while(m.length<size)m.push(0);return m;}
function move(d){
  if(over)return; let o=grid.map(r=>[...r]);
  if(d==='l')for(let i=0;i<size;i++)grid[i]=slide(grid[i]);
  if(d==='r')for(let i=0;i<size;i++){let r=[...grid[i]].reverse();r=slide(r);grid[i]=r.reverse();}
  if(d==='u')for(let j=0;j<size;j++){let c=[];for(let i=0;i<size;i++)c.push(grid[i][j]);c=slide(c);for(let i=0;i<size;i++)grid[i][j]=c[i];}
  if(d==='d')for(let j=0;j<size;j++){let c=[];for(let i=size-1;i>=0;i--)c.push(grid[i][j]);c=slide(c);for(let i=0;i<size;i++)grid[size-1-i][j]=c[i];}
  if(JSON.stringify(o)!==JSON.stringify(grid)){add();render();check();}
}
function check(){
  for(let i=0;i<size;i++)for(let j=0;j<size;j++){if(!grid[i][j])return;if(j<size-1&&grid[i][j]===grid[i][j+1])return;if(i<size-1&&grid[i][j]===grid[i+1][j])return;}
  over=true; document.getElementById('finalScore').textContent=score; go.style.display='block';
}
document.addEventListener('keydown',e=>{let m={ArrowLeft:'l',ArrowRight:'r',ArrowUp:'u',ArrowDown:'d'};if(m[e.key]){e.preventDefault();move(m[e.key]);}});
window.init=init; init();
</script>
<style>.grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;max-width:280px;margin:10px auto}.tile{width:60px;height:60px;background:#eee;display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:bold;border-radius:4px}.tile-2{background:#eee4da}.tile-4{background:#ede0c8}.tile-8{background:#f2b179;color:#fff}.tile-16{background:#f59563;color:#fff}.tile-32{background:#f67c5f;color:#fff}.tile-64{background:#f65e3b;color:#fff}.tile-128{background:#edcf72;color:#fff}.tile-256{background:#edcc61;color:#fff}.tile-512{background:#edc850;color:#fff}.tile-1024{background:#edc53f;color:#fff}.tile-2048{background:#edc22e;color:#fff}.game-over{display:none;text-align:center;padding:20px;background:rgba(0,0,0,.8);color:#fff;border-radius:8px;margin-top:10px}
</style>
'@ }
        "snake" { return @'
<div class="game-container">
    <h1>🐍 貪吃蛇</h1>
    <div class="score">🏆 分數：<span id="score">0</span></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 重新開始</button></div>
    <div class="message" id="message">使用方向鍵控制</div>
</div>
<script>
const board=document.getElementById('board'), sc=document.getElementById('score'), msg=document.getElementById('message');
const COLS=20, ROWS=20; let snake, dir, food, score, loop, running;
function init(){
  snake=[{x:10,y:10},{x:9,y:10},{x:8,y:10}]; dir={x:1,y:0}; score=0; running=true; sc.textContent=0; msg.textContent='使用方向鍵控制';
  spawn(); render(); if(loop)clearInterval(loop); loop=setInterval(update,150);
}
function spawn(){let p;do{p={x:Math.floor(Math.random()*COLS),y:Math.floor(Math.random()*ROWS)}}while(snake.some(s=>s.x===p.x&&s.y===p.y));food=p;}
function render(){
  board.innerHTML=''; board.style.gridTemplateColumns='repeat('+COLS+',1fr)';
  for(let y=0;y<ROWS;y++)for(let x=0;x<COLS;x++){let c=document.createElement('div');c.style.width='18px';c.style.height='18px';c.style.border='1px solid #ddd';if(snake.some(s=>s.x===x&&s.y===y))c.style.background='#2ecc71';if(food.x===x&&food.y===y){c.style.background='#e74c3c';c.style.borderRadius='50%';}board.appendChild(c);}
}
function update(){
  if(!running)return; let h={x:snake[0].x+dir.x,y:snake[0].y+dir.y};
  if(h.x<0||h.x>=COLS||h.y<0||h.y>=ROWS||snake.some(s=>s.x===h.x&&s.y===h.y)){gameOver();return;}
  snake.unshift(h); if(h.x===food.x&&h.y===food.y){score+=10;sc.textContent=score;spawn();}else snake.pop(); render();
}
function gameOver(){running=false;clearInterval(loop);msg.textContent='💀 遊戲結束！點擊「重新開始」';}
function changeDirection(d){if(!running)return;let m={up:{x:0,y:-1},down:{x:0,y:1},left:{x:-1,y:0},right:{x:1,y:0}};let nd=m[d];if(nd.x===-dir.x&&nd.y===-dir.y)return;dir=nd;}
document.addEventListener('keydown',e=>{let m={ArrowUp:'up',ArrowDown:'down',ArrowLeft:'left',ArrowRight:'right'};if(m[e.key]){e.preventDefault();changeDirection(m[e.key]);}});
window.init=init; window.reset=init; init();
</script>
<style>#board{display:grid;gap:1px;max-width:400px;margin:10px auto}</style>
'@ }
        "tetris" { return @'
<div class="game-container">
    <h1>🧱 俄羅斯方塊</h1>
    <div class="info"><span>🏆 <span id="score">0</span></span> <span>📊 <span id="level">1</span></span></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 重新開始</button></div>
    <div class="message" id="message">方向鍵控制</div>
</div>
<script>
const boardEl=document.getElementById('board'), sc=document.getElementById('score'), lv=document.getElementById('level'), msg=document.getElementById('message');
const COLS=10, ROWS=20;
const SHAPES=[
{shape:[[1,1,1,1]],color:'#00f0f0'},
{shape:[[1,1,1],[0,1,0]],color:'#0000f0'},
{shape:[[1,1,1],[0,0,1]],color:'#f0a000'},
{shape:[[1,1,1],[1,0,0]],color:'#0000f0'},
{shape:[[1,1],[1,1]],color:'#f0f000'},
{shape:[[0,1,1],[1,1,0]],color:'#00f000'},
{shape:[[1,1,0],[0,1,1]],color:'#f00000'}
];
let board, piece, score, level, over, loop, interval=500;
function init(){
  board=Array.from({length:ROWS},()=>Array(COLS).fill(0)); score=0; level=1; over=false; interval=500;
  updateScore(); spawn(); if(loop)clearInterval(loop); loop=setInterval(drop,interval); render(); msg.textContent='方向鍵控制';
}
function spawn(){
  let i=Math.floor(Math.random()*SHAPES.length), p=SHAPES[i];
  piece={shape:p.shape,color:p.color,x:Math.floor((COLS-p.shape[0].length)/2),y:0};
  if(collision(piece.shape,piece.x,piece.y)){over=true;clearInterval(loop);msg.textContent='💀 遊戲結束！';}
}
function collision(s,ox,oy){for(let r=0;r<s.length;r++)for(let c=0;c<s[r].length;c++)if(s[r][c]){let bx=ox+c,by=oy+r;if(bx<0||bx>=COLS||by>=ROWS||by<0||(by>=0&&board[by][bx]))return true;}return false;}
function merge(){
  if(!piece)return;
  for(let r=0;r<piece.shape.length;r++)for(let c=0;c<piece.shape[r].length;c++)if(piece.shape[r][c]){let bx=piece.x+c,by=piece.y+r;if(by>=0&&by<ROWS&&bx>=0&&bx<COLS)board[by][bx]=piece.color;}
  clearRows(); spawn(); render();
}
function clearRows(){
  let cleared=0;
  for(let r=ROWS-1;r>=0;){if(board[r].every(c=>c)){board.splice(r,1);board.unshift(Array(COLS).fill(0));cleared++;}else r--;}
  if(cleared){let pts=[0,100,300,500,800];score+=pts[Math.min(cleared,4)]*level;level=Math.floor(score/1000)+1;interval=Math.max(100,500-(level-1)*30);clearInterval(loop);loop=setInterval(drop,interval);updateScore();}
}
function drop(){if(over||!piece)return;if(!collision(piece.shape,piece.x,piece.y+1)){piece.y++;render();}else{merge();render();}}
function moveLeft(){if(!over&&piece&&!collision(piece.shape,piece.x-1,piece.y)){piece.x--;render();}}
function moveRight(){if(!over&&piece&&!collision(piece.shape,piece.x+1,piece.y)){piece.x++;render();}}
function rotatePiece(){if(over||!piece)return;let r=piece.shape[0].map((_,i)=>piece.shape.map(row=>row[i]).reverse());if(!collision(r,piece.x,piece.y)){piece.shape=r;render();}}
function hardDrop(){while(!over&&piece&&!collision(piece.shape,piece.x,piece.y+1))piece.y++;merge();render();}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat('+COLS+',1fr)';
  for(let r=0;r<ROWS;r++)for(let c=0;c<COLS;c++){let d=document.createElement('div');d.style.width='30px';d.style.height='30px';d.style.border='1px solid #ccc';if(board[r][c])d.style.background=board[r][c];boardEl.appendChild(d);}
  if(piece&&!over)for(let r=0;r<piece.shape.length;r++)for(let c=0;c<piece.shape[r].length;c++)if(piece.shape[r][c]){let idx=(piece.y+r)*COLS+(piece.x+c);let cells=boardEl.children;if(idx<cells.length)cells[idx].style.background=piece.color;}
}
function updateScore(){sc.textContent=score;lv.textContent=level;}
document.addEventListener('keydown',e=>{if(over)return;if(e.key==='ArrowLeft')moveLeft();else if(e.key==='ArrowRight')moveRight();else if(e.key==='ArrowUp')rotatePiece();else if(e.key==='ArrowDown')drop();else if(e.key===' '){e.preventDefault();hardDrop();}});
window.init=init; window.reset=init; init();
</script>
<style>#board{display:grid;gap:1px;max-width:310px;margin:10px auto}</style>
'@ }
        "sudoku" { return @'
<div class="game-container">
    <h1>🧩 數獨</h1>
    <div class="board" id="board"></div>
    <div class="num-pad" id="numPad"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊空格再點數字</div>
</div>
<script>
let board, solution, selected;
const boardEl=document.getElementById('board'), msg=document.getElementById('message');
function init(){
  board=Array.from({length:9},()=>Array(9).fill(0)); solution=Array.from({length:9},()=>Array(9).fill(0));
  generate(); render(); msg.textContent='點擊空格，再點數字填入';
}
function generate(){
  let nums=[1,2,3,4,5,6,7,8,9]; for(let i=0;i<9;i++){for(let j=0;j<9;j++){board[i][j]=0;solution[i][j]=0;}}
  solve(0,0); for(let i=0;i<9;i++)for(let j=0;j<9;j++){board[i][j]=Math.random()<0.5?solution[i][j]:0;}
}
function solve(r,c){if(r===9)return true;if(c===9)return solve(r+1,0);let nums=[1,2,3,4,5,6,7,8,9].sort(()=>Math.random()-0.5);for(let n of nums){if(isValid(r,c,n)){solution[r][c]=n;if(solve(r,c+1))return true;solution[r][c]=0;}}return false;}
function isValid(r,c,n){for(let i=0;i<9;i++){if(solution[r][i]===n||solution[i][c]===n)return false;}let br=Math.floor(r/3)*3,bc=Math.floor(c/3)*3;for(let i=0;i<3;i++)for(let j=0;j<3;j++)if(solution[br+i][bc+j]===n)return false;return true;}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat(9,1fr)';
  for(let r=0;r<9;r++)for(let c=0;c<9;c++){let d=document.createElement('div');d.className='cell';d.textContent=board[r][c]||'';if(board[r][c])d.style.background='#d5e8d5';d.dataset.r=r;d.dataset.c=c;d.onclick=()=>select(r,c);boardEl.appendChild(d);}
}
function select(r,c){selected={r,c};}
function setNumber(n){if(!selected)return;let r=selected.r,c=selected.c;if(board[r][c])return;board[r][c]=n;render();}
function clearCell(){if(!selected)return;let r=selected.r,c=selected.c;if(board[r][c]){board[r][c]=0;render();}}
function hint(){if(!selected)return;let r=selected.r,c=selected.c;if(board[r][c])return;board[r][c]=solution[r][c];render();}
window.init=init; window.newGame=init; window.setNumber=setNumber; window.clearCell=clearCell; window.hint=hint; init();
</script>
<style>.cell{width:35px;height:35px;border:1px solid #999;text-align:center;font-size:18px;cursor:pointer;background:#fff}#board{display:grid;gap:1px;max-width:330px;margin:10px auto}</style>
'@ }
        "memory" { return @'
<div class="game-container">
    <h1>🃏 記憶翻牌</h1>
    <div class="info"><span>🎯 步數：<span id="moves">0</span></span> <span>✅ <span id="matches">0</span>/8</span></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">翻開兩張卡片配對</div>
</div>
<script>
const emojis=['🍎','🍌','🍇','🍓','🍉','🍒','🍑','🍊'];
let cards, flipped, matched, moves, lock;
const boardEl=document.getElementById('board'), movesEl=document.getElementById('moves'), matchEl=document.getElementById('matches'), msg=document.getElementById('message');
function init(){
  let d=[...emojis,...emojis]; cards=d.sort(()=>Math.random()-0.5); flipped=[]; matched=[]; moves=0; lock=false;
  movesEl.textContent='0'; matchEl.textContent='0'; msg.textContent='翻開兩張卡片，找到配對！'; render();
}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat(4,1fr)';
  cards.forEach((e,i)=>{let d=document.createElement('div');d.className='card';d.textContent=matched.includes(i)?e:flipped.includes(i)?e:'?';d.style.background=matched.includes(i)||flipped.includes(i)?'#fff':'#2c3e50';d.onclick=()=>flip(i);boardEl.appendChild(d);});
}
function flip(i){if(lock||flipped.includes(i)||matched.includes(i))return;flipped.push(i);render();if(flipped.length===2){moves++;movesEl.textContent=moves;lock=true;setTimeout(()=>{let [a,b]=flipped;if(cards[a]===cards[b]){matched.push(a,b);matchEl.textContent=Math.floor(matched.length/2);msg.textContent='✅ 配對成功！';if(matched.length===cards.length)msg.textContent='🎉 恭喜完成！';}else msg.textContent='❌ 配對失敗，再試一次！';flipped=[];lock=false;render();},500);}}
window.init=init; init();
</script>
<style>.card{width:60px;height:60px;display:flex;align-items:center;justify-content:center;font-size:28px;border-radius:8px;cursor:pointer;background:#2c3e50;color:#fff;transition:.3s}#board{display:grid;gap:8px;max-width:280px;margin:10px auto}</style>
'@ }
        "minesweeper" { return @'
<div class="game-container">
    <h1>💣 踩地雷</h1>
    <div class="info"><span>💣 <span id="mineCount">10</span></span> <span>🚩 <span id="flagCount">0</span></span></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">左鍵翻開，右鍵標記</div>
</div>
<script>
const R=9,C=9,M=10; let board, revealed, flagged, over, flags=0;
const boardEl=document.getElementById('board'), mineEl=document.getElementById('mineCount'), flagEl=document.getElementById('flagCount'), msg=document.getElementById('message');
function init(){
  board=Array.from({length:R},()=>Array(C).fill(0)); revealed=Array.from({length:R},()=>Array(C).fill(false)); flagged=Array.from({length:R},()=>Array(C).fill(false)); over=false; flags=0;
  mineEl.textContent=M; flagEl.textContent='0'; msg.textContent='左鍵翻開，右鍵標記';
  place(); calc(); render();
}
function place(){let p=0;while(p<M){let x=Math.floor(Math.random()*C),y=Math.floor(Math.random()*R);if(board[y][x]!==-1){board[y][x]=-1;p++;}}}
function calc(){for(let y=0;y<R;y++)for(let x=0;x<C;x++){if(board[y][x]===-1)continue;let c=0;for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){let ny=y+dy,nx=x+dx;if(ny>=0&&ny<R&&nx>=0&&nx<C&&board[ny][nx]===-1)c++;}board[y][x]=c;}}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat('+C+',1fr)';
  for(let y=0;y<R;y++)for(let x=0;x<C;x++){let d=document.createElement('div');d.className='cell';if(revealed[y][x]){if(board[y][x]===-1){d.textContent='💣';d.style.background='#e74c3c';}else if(board[y][x]>0){d.textContent=board[y][x];d.style.background='#ecf0f1';}else d.style.background='#ecf0f1';}else{d.textContent=flagged[y][x]?'🚩':'';d.style.background='#bdc3c7';}d.onclick=()=>reveal(x,y);d.oncontextmenu=(e)=>{e.preventDefault();toggleFlag(x,y);};boardEl.appendChild(d);}
}
function reveal(x,y){if(over||flagged[y][x]||revealed[y][x])return;if(board[y][x]===-1){revealAll();msg.textContent='💀 踩到地雷！點擊「新遊戲」';return;}revealCell(x,y);render();checkWin();}
function revealCell(x,y){if(revealed[y][x])return;revealed[y][x]=true;if(board[y][x]===0){for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){let ny=y+dy,nx=x+dx;if(ny>=0&&ny<R&&nx>=0&&nx<C&&!revealed[ny][nx])revealCell(nx,ny);}}}
function toggleFlag(x,y){if(over||revealed[y][x])return;flagged[y][x]=!flagged[y][x];flags+=flagged[y][x]?1:-1;flagEl.textContent=flags;render();}
function revealAll(){for(let y=0;y<R;y++)for(let x=0;x<C;x++)revealed[y][x]=true;render();}
function checkWin(){let total=R*C;let revealedCount=revealed.flat().filter(r=>r).length;if(total-revealedCount===M){msg.textContent='🎉 恭喜你贏了！';over=true;}}
window.init=init; init();
</script>
<style>.cell{width:30px;height:30px;display:flex;align-items:center;justify-content:center;font-size:14px;border-radius:4px;cursor:pointer;background:#bdc3c7}#board{display:grid;gap:2px;max-width:290px;margin:10px auto}</style>
'@ }
        "wordsearch" { return @'
<div class="game-container">
    <h1>🔍 文字搜尋</h1>
    <div class="word-list" id="wordList"></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊字母選取單字</div>
</div>
<script>
const words=['APPLE','BANANA','CHERRY','GRAPE','MANGO','PEACH','PEAR','WATERMELON'];
let grid, found;
const boardEl=document.getElementById('board'), wordList=document.getElementById('wordList'), msg=document.getElementById('message');
function init(){
  grid=Array.from({length:8},()=>Array(8).fill('')); found=[];
  placeWords(); fillEmpty(); renderWords(); render(); msg.textContent='點擊字母選取單字';
}
function placeWords(){
  let dirs=[[0,1],[1,0],[1,1],[0,-1],[-1,0],[-1,-1],[1,-1],[-1,1]];
  for(let w of words){let placed=false;for(let tries=0;tries<100&&!placed;tries++){let r=Math.floor(Math.random()*8),c=Math.floor(Math.random()*8);let d=dirs[Math.floor(Math.random()*dirs.length)];let ok=true;for(let i=0;i<w.length;i++){let nr=r+d[0]*i,nc=c+d[1]*i;if(nr<0||nr>=8||nc<0||nc>=8||(grid[nr][nc]&&grid[nr][nc]!==w[i])){ok=false;break;}}if(ok){for(let i=0;i<w.length;i++)grid[r+d[0]*i][c+d[1]*i]=w[i];placed=true;}}}
}
function fillEmpty(){for(let r=0;r<8;r++)for(let c=0;c<8;c++)if(!grid[r][c])grid[r][c]=String.fromCharCode(65+Math.floor(Math.random()*26));}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat(8,1fr)';
  for(let r=0;r<8;r++)for(let c=0;c<8;c++){let d=document.createElement('div');d.className='letter';d.textContent=grid[r][c];d.dataset.r=r;d.dataset.c=c;d.onclick=()=>select(r,c);boardEl.appendChild(d);}
}
function renderWords(){wordList.innerHTML=words.map(w=>'<span class="word'+(found.includes(w)?' found':'')+'">'+w+'</span>').join(' ');}
let selected=[];
function select(r,c){let idx=r*8+c; if(selected.includes(idx)){selected=[];return;}selected.push(idx); if(selected.length===2){checkWord();}}
function checkWord(){let word=''; for(let i of selected){let r=Math.floor(i/8),c=i%8;word+=grid[r][c];}let rev=word.split('').reverse().join('');let foundWord=null;for(let w of words){if((word===w||rev===w)&&!found.includes(w))foundWord=w;}if(foundWord){found.push(foundWord);renderWords();msg.textContent='✅ 找到：'+foundWord;}else msg.textContent='❌ 再試一次！';selected=[];render();}
window.init=init; init();
</script>
<style>.letter{width:35px;height:35px;border:1px solid #ccc;display:flex;align-items:center;justify-content:center;font-size:18px;cursor:pointer;background:#fff}#board{display:grid;gap:1px;max-width:300px;margin:10px auto}.word{margin:4px;padding:4px 8px;background:#eee;border-radius:4px}.found{background:#a8e6cf;text-decoration:line-through}
</style>
'@ }
        "colormatch" { return @'
<div class="game-container">
    <h1>🎯 顏色配對</h1>
    <div class="info"><span>🎯 回合 <span id="round">1</span>/10</span> <span>⭐ 分數 <span id="score">0</span></span></div>
    <div class="color-display" id="colorDisplay"></div>
    <div class="color-name" id="colorName">準備開始</div>
    <div class="options" id="options"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊與顯示顏色名稱相符的色塊</div>
</div>
<script>
const colors=['red','blue','green','yellow','purple','orange'];
let round=1, score=0, target;
const display=document.getElementById('colorDisplay'), nameEl=document.getElementById('colorName'), options=document.getElementById('options'), msg=document.getElementById('message'), roundEl=document.getElementById('round'), scoreEl=document.getElementById('score');
function init(){
  round=1; score=0; roundEl.textContent=round; scoreEl.textContent=score; next(); msg.textContent='點擊與顯示顏色名稱相符的色塊';
}
function next(){
  target=colors[Math.floor(Math.random()*colors.length)];
  let shuffled=[...colors].sort(()=>Math.random()-0.5);
  display.style.background=target; nameEl.textContent=target.toUpperCase();
  options.innerHTML=''; for(let c of shuffled){let b=document.createElement('button');b.style.background=c;b.style.width='60px';b.style.height='60px';b.style.border='2px solid #ccc';b.style.borderRadius='8px';b.style.cursor='pointer';b.onclick=()=>check(c);options.appendChild(b);}
}
function check(c){if(c===target){score+=10;msg.textContent='✅ 正確！';}else{score-=5;msg.textContent='❌ 錯誤！';}scoreEl.textContent=score;round++;roundEl.textContent=round;if(round>10){msg.textContent='🎉 遊戲結束！分數：'+score;return;}setTimeout(next,500);}
window.init=init; init();
</script>
<style>#colorDisplay{width:100px;height:100px;border-radius:12px;margin:10px auto;border:2px solid #ccc}#options{display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin:10px 0}</style>
'@ }
        "clicker" { return @'
<div class="game-container">
    <h1>👆 點點樂</h1>
    <div class="info"><span>⏱️ <span id="timer">10</span>s</span> <span>👆 <span id="clicks">0</span></span> <span>🏆 <span id="best">0</span></span></div>
    <div class="click-area" id="clickArea"><div class="count" id="countDisplay">0</div><div class="label" id="statusLabel">點我開始</div></div>
    <div class="controls"><button onclick="startGame()">🚀 開始挑戰</button><button onclick="resetGame()">🔄 重置</button></div>
    <div class="message" id="message">點擊「開始挑戰」或點擊方塊開始</div>
</div>
<script>
let clicks=0, timeLeft=10, running=false, best=0;
const timer=document.getElementById('timer'), clickDisplay=document.getElementById('clicks'), bestDisplay=document.getElementById('best'), countDisplay=document.getElementById('countDisplay'), status=document.getElementById('statusLabel'), msg=document.getElementById('message');
function startGame(){
  if(running)return; running=true; clicks=0; timeLeft=10; clickDisplay.textContent=0; timer.textContent=10; status.textContent='點擊！'; msg.textContent='快點點擊！';
  let interval=setInterval(()=>{timeLeft--;timer.textContent=timeLeft;if(timeLeft<=0){clearInterval(interval);running=false;status.textContent='時間到！';if(clicks>best){best=clicks;bestDisplay.textContent=best;}msg.textContent='🏆 分數：'+clicks;}},1000);
}
function clickArea(){if(!running)return;clicks++;clickDisplay.textContent=clicks;countDisplay.textContent=clicks;}
function resetGame(){running=false;clicks=0;timeLeft=10;timer.textContent=10;clickDisplay.textContent=0;countDisplay.textContent=0;status.textContent='點我開始';msg.textContent='點擊「開始挑戰」或點擊方塊開始';}
window.startGame=startGame; window.resetGame=resetGame; window.clickArea=clickArea;
</script>
<style>.click-area{width:200px;height:200px;background:#3498db;border-radius:16px;display:flex;flex-direction:column;align-items:center;justify-content:center;cursor:pointer;margin:10px auto;color:#fff;font-size:24px}.click-area:hover{background:#2980b9}</style>
'@ }
        "breakout" { return @'
<div class="game-container">
    <h1>🏏 打磚塊</h1>
    <div class="info"><span>🏆 <span id="score">0</span></span> <span>🧱 <span id="bricksLeft">0</span></span> <span>❤️ <span id="lives">3</span></span></div>
    <canvas id="gameCanvas" width="450" height="320"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">使用滑鼠或鍵盤 ← → 控制擋板</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), bricksEl=document.getElementById('bricksLeft'), livesEl=document.getElementById('lives'), msg=document.getElementById('message');
canvas.width=450; canvas.height=320;
let score=0, lives=3, ball, paddle, bricks=[], gameRunning=false;
function init(){
  score=0; lives=3; scoreEl.textContent=0; livesEl.textContent=3; msg.textContent='使用滑鼠或鍵盤 ← → 控制擋板';
  ball={x:225,y:280,dx:3,dy:-3,radius:6};
  paddle={x:200,y:305,width:60,height:10};
  bricks=[]; for(let r=0;r<5;r++)for(let c=0;c<8;c++)bricks.push({x:c*55+10,y:r*25+30,width:50,height:15,alive:true});
  bricksEl.textContent=bricks.filter(b=>b.alive).length; gameRunning=true; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){
  ball.x+=ball.dx; ball.y+=ball.dy;
  if(ball.x-ball.radius<0||ball.x+ball.radius>canvas.width)ball.dx=-ball.dx;
  if(ball.y-ball.radius<0)ball.dy=-ball.dy;
  if(ball.y+ball.radius>canvas.height){lives--;livesEl.textContent=lives;if(lives<=0){gameRunning=false;msg.textContent='💀 遊戲結束！點擊「新遊戲」';return;}resetBall();}
  if(ball.x>paddle.x&&ball.x<paddle.x+paddle.width&&ball.y+ball.radius>=paddle.y){ball.dy=-ball.dy;ball.y=paddle.y-ball.radius;}
  for(let b of bricks){if(!b.alive)continue;if(ball.x>b.x&&ball.x<b.x+b.width&&ball.y>b.y&&ball.y<b.y+b.height){b.alive=false;ball.dy=-ball.dy;score+=10;scoreEl.textContent=score;bricksEl.textContent=bricks.filter(b=>b.alive).length;if(bricks.every(b=>!b.alive)){msg.textContent='🎉 恭喜贏了！';gameRunning=false;}}}
}
function resetBall(){ball.x=225;ball.y=280;ball.dx=3;ball.dy=-3;}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  ctx.fillStyle='#e74c3c'; ctx.beginPath(); ctx.arc(ball.x,ball.y,ball.radius,0,Math.PI*2); ctx.fill();
  ctx.fillStyle='#2c3e50'; ctx.fillRect(paddle.x,paddle.y,paddle.width,paddle.height);
  for(let b of bricks){if(!b.alive)continue;ctx.fillStyle=b.y<75?'#e74c3c':b.y<125?'#f39c12':'#3498db';ctx.fillRect(b.x,b.y,b.width,b.height);}
}
document.addEventListener('mousemove',e=>{let rect=canvas.getBoundingClientRect();paddle.x=e.clientX-rect.left-paddle.width/2;if(paddle.x<0)paddle.x=0;if(paddle.x+paddle.width>canvas.width)paddle.x=canvas.width-paddle.width;});
document.addEventListener('keydown',e=>{if(e.key==='ArrowLeft')paddle.x=Math.max(0,paddle.x-20);if(e.key==='ArrowRight')paddle.x=Math.min(canvas.width-paddle.width,paddle.x+20);});
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#ecf0f1;border-radius:8px}</style>
'@ }
        "shooting-range" { return @'
<div class="game-container">
    <h1>🎯 射擊靶場</h1>
    <div class="info"><span>🎯 分數 <span id="score">0</span></span> <span>💨 剩餘 <span id="shots">10</span></span></div>
    <canvas id="gameCanvas" width="400" height="400"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊靶心射擊！</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), shotsEl=document.getElementById('shots'), msg=document.getElementById('message');
canvas.width=400; canvas.height=400;
let score=0, shots=10, targets=[], gameRunning=false;
function init(){
  score=0; shots=10; targets=[]; scoreEl.textContent=0; shotsEl.textContent=10; msg.textContent='點擊靶心射擊！'; gameRunning=true;
  for(let i=0;i<5;i++)targets.push({x:Math.random()*360+20,y:Math.random()*360+20,r:20+Math.random()*20,dx:(Math.random()-0.5)*2,dy:(Math.random()-0.5)*2});
  loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){
  for(let t of targets){t.x+=t.dx;t.y+=t.dy;if(t.x<20||t.x>380)t.dx=-t.dx;if(t.y<20||t.y>380)t.dy=-t.dy;}
}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  for(let t of targets){ctx.beginPath();ctx.arc(t.x,t.y,t.r,0,Math.PI*2);ctx.fillStyle='#e74c3c';ctx.fill();ctx.fillStyle='#fff';ctx.beginPath();ctx.arc(t.x,t.y,t.r*0.5,0,Math.PI*2);ctx.fill();}
}
canvas.onclick=function(e){
  if(!gameRunning||shots<=0)return;
  let rect=canvas.getBoundingClientRect(); let x=e.clientX-rect.left,y=e.clientY-rect.top;
  let hit=false; for(let t of targets){if(Math.hypot(x-t.x,y-t.y)<t.r){score+=10;hit=true;t.x=Math.random()*360+20;t.y=Math.random()*360+20;}}
  shots--; shotsEl.textContent=shots; scoreEl.textContent=score;
  if(hit)msg.textContent='🎯 命中！'; else msg.textContent='❌ 沒中！';
  if(shots<=0){msg.textContent='⏱️ 射擊結束！分數：'+score;gameRunning=false;}
}
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#f5f5f5;border-radius:8px;cursor:crosshair}</style>
'@ }
        "jigsaw-puzzle" { return @'
<div class="game-container">
    <h1>🧩 拼圖挑戰</h1>
    <div class="info"><span>👆 步數 <span id="moves">0</span></span> <span>⏱️ 時間 <span id="timer">0</span>s</span></div>
    <div class="puzzle-grid" id="puzzleGrid"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊相鄰拼塊移動</div>
</div>
<script>
const grid=document.getElementById('puzzleGrid'), movesEl=document.getElementById('moves'), timerEl=document.getElementById('timer'), msg=document.getElementById('message');
let tiles=[], empty, moves=0, seconds=0, timerInterval=null, gameRunning=false;
function init(){
  tiles=[]; for(let i=0;i<9;i++)tiles.push(i); empty=8; moves=0; seconds=0; movesEl.textContent=0; timerEl.textContent=0; msg.textContent='點擊相鄰拼塊移動';
  if(timerInterval)clearInterval(timerInterval); timerInterval=setInterval(()=>{seconds++;timerEl.textContent=seconds;},1000);
  shuffle(); render(); gameRunning=true;
}
function shuffle(){for(let i=0;i<100;i++){let neighbors=getNeighbors(empty);let r=neighbors[Math.floor(Math.random()*neighbors.length)];[tiles[empty],tiles[r]]=[tiles[r],tiles[empty]];empty=r;}}
function getNeighbors(pos){let r=Math.floor(pos/3),c=pos%3,result=[];if(r>0)result.push(pos-3);if(r<2)result.push(pos+3);if(c>0)result.push(pos-1);if(c<2)result.push(pos+1);return result;}
function render(){
  grid.innerHTML=''; grid.style.gridTemplateColumns='repeat(3,1fr)';
  for(let i=0;i<9;i++){let d=document.createElement('div');d.className='puzzle-tile';if(tiles[i]===8){d.style.background='transparent';d.style.border='none';}else{d.textContent=tiles[i]+1;d.style.background='#3498db';d.style.color='#fff';d.onclick=()=>move(i);}grid.appendChild(d);}
}
function move(pos){if(!gameRunning)return;if(!getNeighbors(empty).includes(pos))return;moves++;movesEl.textContent=moves;[tiles[empty],tiles[pos]]=[tiles[pos],tiles[empty]];empty=pos;render();checkWin();}
function checkWin(){if(tiles.every((v,i)=>v===i)){gameRunning=false;clearInterval(timerInterval);msg.textContent='🎉 完成拼圖！步數：'+moves+' 時間：'+seconds+'秒';}}
window.init=init; init();
</script>
<style>.puzzle-tile{width:70px;height:70px;display:flex;align-items:center;justify-content:center;font-size:28px;border-radius:8px;cursor:pointer;background:#3498db;color:#fff;border:2px solid #2980b9}#puzzleGrid{display:grid;gap:4px;max-width:220px;margin:10px auto}</style>
'@ }
        "color-memory" { return @'
<div class="game-container">
    <h1>🎨 色彩記憶</h1>
    <div class="info"><span>🎯 回合 <span id="round">1</span></span> <span>⭐ 分數 <span id="score">0</span></span></div>
    <div class="color-panel" id="colorPanel"></div>
    <div class="controls"><button onclick="startGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">觀察顏色順序，然後重複點擊！</div>
</div>
<script>
const colors=['red','blue','green','yellow'];
let sequence=[], player=[], round=1, score=0, playing=false, playerTurn=false;
const roundEl=document.getElementById('round'), scoreEl=document.getElementById('score'), msg=document.getElementById('message'), panel=document.getElementById('colorPanel');
function init(){
  sequence=[]; player=[]; round=1; score=0; playing=false; playerTurn=false;
  roundEl.textContent=1; scoreEl.textContent=0; msg.textContent='點擊「新遊戲」開始！'; panel.innerHTML='';
  colors.forEach(c=>{let b=document.createElement('div');b.className='color-btn';b.style.background=c;b.dataset.color=c;b.onclick=()=>handleClick(c);panel.appendChild(b);});
}
function startGame(){init();playing=true;nextRound();}
function nextRound(){
  if(!playing)return; player=[]; playerTurn=false; msg.textContent='👀 觀察顏色順序...'; roundEl.textContent=round;
  let random=colors[Math.floor(Math.random()*colors.length)]; sequence.push(random);
  let i=0; let interval=setInterval(()=>{if(i>=sequence.length){clearInterval(interval);playerTurn=true;msg.textContent='👆 點擊重複顏色順序！';return;}flash(sequence[i]);i++;},600);
}
function flash(color){document.querySelectorAll('.color-btn').forEach(b=>{if(b.dataset.color===color){b.style.opacity='0.3';setTimeout(()=>b.style.opacity='1',300);}});}
function handleClick(color){if(!playing||!playerTurn)return;player.push(color);flash(color);let idx=player.length-1;if(player[idx]!==sequence[idx]){playing=false;playerTurn=false;msg.textContent='❌ 順序錯誤！遊戲結束';return;}if(player.length===sequence.length){score+=10;round++;scoreEl.textContent=score;roundEl.textContent=round;msg.textContent='✅ 正確！進入下一關！';playerTurn=false;setTimeout(nextRound,1000);}}
window.init=init; window.startGame=startGame; window.resetGame=startGame; init();
</script>
<style>.color-btn{width:80px;height:80px;border-radius:12px;cursor:pointer;border:3px solid #ccc;transition:.3s;margin:5px}.color-panel{display:flex;gap:10px;justify-content:center;flex-wrap:wrap;margin:10px 0}</style>
'@ }
        "archery" { return @'
<div class="game-container">
    <h1>🏹 弓箭手</h1>
    <div class="info"><span>🎯 分數 <span id="score">0</span></span> <span>🏹 箭矢 <span id="arrows">10</span></span></div>
    <canvas id="gameCanvas" width="400" height="300"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊畫布射箭！</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), arrowsEl=document.getElementById('arrows'), msg=document.getElementById('message');
canvas.width=400; canvas.height=300;
let score=0, arrows=10, target={x:200,y:100,r:30}, gameRunning=false;
function init(){
  score=0; arrows=10; scoreEl.textContent=0; arrowsEl.textContent=10; msg.textContent='點擊畫布射箭！'; gameRunning=true; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){target.x+=Math.sin(Date.now()/1000)*1.5;target.y+=Math.cos(Date.now()/1500)*1.2;}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  for(let i=10;i>0;i--){ctx.beginPath();ctx.arc(target.x,target.y,target.r*i/10,0,Math.PI*2);ctx.strokeStyle=i===1?'#e74c3c':'#2c3e50';ctx.lineWidth=i===1?3:1;ctx.stroke();}
}
canvas.onclick=function(e){
  if(!gameRunning||arrows<=0)return;
  let rect=canvas.getBoundingClientRect(); let x=e.clientX-rect.left,y=e.clientY-rect.top;
  let dist=Math.hypot(x-target.x,y-target.y); let points=Math.max(0,Math.floor(10-dist/target.r*10));
  score+=points; arrows--; scoreEl.textContent=score; arrowsEl.textContent=arrows;
  msg.textContent='🎯 '+points+'分！';
  if(arrows<=0){msg.textContent='🏹 射擊結束！分數：'+score;gameRunning=false;}
}
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#f0f8ff;border-radius:8px;cursor:crosshair}</style>
'@ }
        "math-quiz" { return @'
<div class="game-container">
    <h1>🧠 數學速算</h1>
    <div class="info"><span>✅ 正確 <span id="correct">0</span></span> <span>❌ 錯誤 <span id="wrong">0</span></span> <span>⏱️ <span id="timer">60</span>s</span></div>
    <div class="question" id="question">準備開始</div>
    <div class="options" id="options"></div>
    <div class="controls"><button onclick="startGame()">🚀 開始挑戰</button><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊「開始挑戰」開始！</div>
</div>
<script>
let correct=0,wrong=0,timeLeft=60,running=false;
const correctEl=document.getElementById('correct'), wrongEl=document.getElementById('wrong'), timerEl=document.getElementById('timer'), questionEl=document.getElementById('question'), optionsEl=document.getElementById('options'), msg=document.getElementById('message');
function init(){
  correct=0; wrong=0; timeLeft=60; running=false; correctEl.textContent=0; wrongEl.textContent=0; timerEl.textContent=60; questionEl.textContent='準備開始'; optionsEl.innerHTML=''; msg.textContent='點擊「開始挑戰」開始！';
}
function startGame(){
  if(running)return; running=true; generate(); let interval=setInterval(()=>{timeLeft--;timerEl.textContent=timeLeft;if(timeLeft<=0){clearInterval(interval);running=false;msg.textContent='⏱️ 時間到！正確：'+correct+' 錯誤：'+wrong;}},1000);
}
function generate(){
  if(!running)return; let a=Math.floor(Math.random()*20)+1,b=Math.floor(Math.random()*20)+1; let ops=['+','-','*']; let op=ops[Math.floor(Math.random()*ops.length)]; let ans; if(op==='+')ans=a+b;else if(op==='-')ans=a-b;else ans=a*b;
  questionEl.textContent=a+' '+op+' '+b+' = ?';
  let choices=[ans,ans+Math.floor(Math.random()*10)+1,ans-Math.floor(Math.random()*10)-1,ans+Math.floor(Math.random()*5)+3]; choices=choices.sort(()=>Math.random()-0.5);
  optionsEl.innerHTML=''; choices.forEach(c=>{let b=document.createElement('button');b.textContent=c;b.onclick=()=>check(c,ans);optionsEl.appendChild(b);});
}
function check(choice,ans){if(!running)return;if(choice===ans){correct++;correctEl.textContent=correct;msg.textContent='✅ 正確！';}else{wrong++;wrongEl.textContent=wrong;msg.textContent='❌ 錯誤！答案是 '+ans;}generate();}
window.init=init; window.startGame=startGame; init();
</script>
<style>#options button{margin:5px;padding:10px 20px;font-size:18px;border-radius:8px;border:2px solid #ccc;cursor:pointer;background:#fff}#options button:hover{background:#3498db;color:#fff}</style>
'@ }
        "tic-tac-toe" { return @'
<div class="game-container">
    <h1>❌ 井字遊戲</h1>
    <div class="info"><span>❌ 玩家 <span id="playerScore">0</span></span> <span>⚖️ 平手 <span id="drawScore">0</span></span> <span>⭕ AI <span id="aiScore">0</span></span></div>
    <div class="board" id="board"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊格子開始遊戲！</div>
</div>
<script>
let board, player='X', ai='O', playerScore=0, aiScore=0, drawScore=0, gameOver=false;
const boardEl=document.getElementById('board'), pScore=document.getElementById('playerScore'), aScore=document.getElementById('aiScore'), dScore=document.getElementById('drawScore'), msg=document.getElementById('message');
function init(){
  board=Array(9).fill(null); gameOver=false; msg.textContent='點擊格子開始遊戲！'; render();
}
function render(){
  boardEl.innerHTML=''; boardEl.style.gridTemplateColumns='repeat(3,1fr)';
  board.forEach((v,i)=>{let d=document.createElement('div');d.className='cell';d.textContent=v||'';d.onclick=()=>move(i);boardEl.appendChild(d);});
}
function move(i){
  if(gameOver||board[i])return; board[i]=player; render(); if(checkWin(player)){playerScore++;pScore.textContent=playerScore;msg.textContent='🎉 玩家贏了！';gameOver=true;return;} if(board.every(v=>v)){drawScore++;dScore.textContent=drawScore;msg.textContent='🤝 平手！';gameOver=true;return;} aiMove();
}
function aiMove(){
  let best=-1,bestScore=-Infinity; for(let i=0;i<9;i++){if(board[i])continue;board[i]=ai;let score=minimax(board,0,false);board[i]=null;if(score>bestScore){bestScore=score;best=i;}} if(best!==-1){board[best]=ai;render();if(checkWin(ai)){aiScore++;aScore.textContent=aiScore;msg.textContent='🤖 AI 贏了！';gameOver=true;return;}if(board.every(v=>v)){drawScore++;dScore.textContent=drawScore;msg.textContent='🤝 平手！';gameOver=true;}}
}
function minimax(board,depth,isMax){
  if(checkWin(ai))return 10-depth; if(checkWin(player))return depth-10; if(board.every(v=>v))return 0;
  if(isMax){let best=-Infinity;for(let i=0;i<9;i++){if(board[i])continue;board[i]=ai;let score=minimax(board,depth+1,false);board[i]=null;best=Math.max(best,score);}return best;}else{let best=Infinity;for(let i=0;i<9;i++){if(board[i])continue;board[i]=player;let score=minimax(board,depth+1,true);board[i]=null;best=Math.min(best,score);}return best;}
}
function checkWin(p){let wins=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];return wins.some(w=>board[w[0]]===p&&board[w[1]]===p&&board[w[2]]===p);}
window.init=init; init();
</script>
<style>.cell{width:80px;height:80px;border:2px solid #333;display:flex;align-items:center;justify-content:center;font-size:36px;cursor:pointer;background:#fff}#board{display:grid;gap:2px;max-width:250px;margin:10px auto}</style>
'@ }
        "hangman" { return @'
<div class="game-container">
    <h1>🔤 猜字遊戲</h1>
    <div class="info"><span>❌ 錯誤 <span id="mistakes">0</span>/6</span> <span>🏆 勝場 <span id="wins">0</span></span></div>
    <div class="hangman-ascii" id="hangmanDisplay"></div>
    <div class="word-display" id="wordDisplay"></div>
    <div class="letters" id="letters"></div>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊字母猜字！</div>
</div>
<script>
const words=['APPLE','BANANA','CHERRY','DRAGON','EAGLE','FLOWER','GARDEN','HAPPY','ISLAND','JUNGLE'];
let word, guessed, mistakes, wins=0;
const display=document.getElementById('hangmanDisplay'), wordDisplay=document.getElementById('wordDisplay'), lettersEl=document.getElementById('letters'), mistakesEl=document.getElementById('mistakes'), winsEl=document.getElementById('wins'), msg=document.getElementById('message');
function init(){
  word=words[Math.floor(Math.random()*words.length)]; guessed=[]; mistakes=0; mistakesEl.textContent='0'; msg.textContent='點擊字母猜字！'; render();
}
function render(){
  wordDisplay.textContent=word.split('').map(c=>guessed.includes(c)?c:'_').join(' ');
  lettersEl.innerHTML=''; for(let i=65;i<=90;i++){let c=String.fromCharCode(i);let b=document.createElement('button');b.textContent=c;b.disabled=guessed.includes(c);b.onclick=()=>guess(c);lettersEl.appendChild(b);}
  display.textContent=['  +---+\n  |   |\n      |\n      |\n      |\n      |\n=========','  +---+\n  |   |\n  O   |\n      |\n      |\n      |\n=========','  +---+\n  |   |\n  O   |\n  |   |\n      |\n      |\n=========','  +---+\n  |   |\n  O   |\n /|   |\n      |\n      |\n=========','  +---+\n  |   |\n  O   |\n /|\\  |\n      |\n      |\n=========','  +---+\n  |   |\n  O   |\n /|\\  |\n /    |\n      |\n=========','  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n========='][mistakes];
}
function guess(c){if(guessed.includes(c))return;guessed.push(c);if(!word.includes(c)){mistakes++;mistakesEl.textContent=mistakes;msg.textContent='❌ 錯誤 '+mistakes+'/6';if(mistakes>=6){msg.textContent='💀 遊戲結束！正確答案是 '+word;render();return;}}else{msg.textContent='✅ 正確！';}render();if(word.split('').every(c=>guessed.includes(c))){wins++;winsEl.textContent=wins;msg.textContent='🎉 你贏了！單字：'+word;}}
window.init=init; init();
</script>
<style>#letters button{margin:3px;padding:6px 12px;border-radius:4px;border:1px solid #ccc;cursor:pointer;background:#fff}#letters button:disabled{opacity:.5;cursor:not-allowed}</style>
'@ }
        "flappy-bird" { return @'
<div class="game-container">
    <h1>🐦 飛翔小鳥</h1>
    <div class="info"><span>🏆 分數 <span id="score">0</span></span> <span>🏅 最高 <span id="best">0</span></span></div>
    <canvas id="gameCanvas" width="360" height="500"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊畫面或按空白鍵跳躍！</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), bestEl=document.getElementById('best'), msg=document.getElementById('message');
canvas.width=360; canvas.height=500;
let bird={x:50,y:250,vy:0,radius:15}, pipes=[], score=0, best=0, gameRunning=false, gravity=0.3, jump=-5, speed=2;
function init(){
  bird.y=250; bird.vy=0; pipes=[]; score=0; scoreEl.textContent=0; msg.textContent='點擊畫面或按空白鍵跳躍！'; gameRunning=true; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){
  bird.vy+=gravity; bird.y+=bird.vy; if(bird.y<0){bird.y=0;bird.vy=0;} if(bird.y>canvas.height){gameOver();return;}
  if(pipes.length===0||pipes[pipes.length-1].x<canvas.width-150){let gap=120+Math.random()*60;let top=Math.random()*(canvas.height-200-50)+50;pipes.push({x:canvas.width,top:top,gap:gap});}
  for(let i=pipes.length-1;i>=0;i--){pipes[i].x-=speed;if(pipes[i].x+30<0){pipes.splice(i,1);continue;}if(pipes[i].x<bird.x&&!pipes[i].scored){pipes[i].scored=true;score++;scoreEl.textContent=score;if(score>best){best=score;bestEl.textContent=best;}}if(bird.x+15>pipes[i].x&&bird.x-15<pipes[i].x+30&&(bird.y-15<pipes[i].top||bird.y+15>pipes[i].top+pipes[i].gap)){gameOver();return;}}if(bird.y+15>canvas.height)gameOver();
}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height); ctx.fillStyle='#2ecc71'; ctx.fillRect(0,0,canvas.width,canvas.height);
  ctx.fillStyle='#e74c3c'; ctx.beginPath(); ctx.arc(bird.x,bird.y,bird.radius,0,Math.PI*2); ctx.fill();
  for(let p of pipes){ctx.fillStyle='#27ae60';ctx.fillRect(p.x,0,30,p.top);ctx.fillRect(p.x,p.top+p.gap,30,canvas.height-p.top-p.gap);}
}
function gameOver(){gameRunning=false;msg.textContent='💀 遊戲結束！分數：'+score;if(score>best){best=score;bestEl.textContent=best;}}
canvas.onclick=function(){if(!gameRunning){init();return;}bird.vy=jump;};
document.addEventListener('keydown',e=>{if(e.key===' '){e.preventDefault();if(!gameRunning){init();return;}bird.vy=jump;}});
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#2ecc71;border-radius:8px}</style>
'@ }
        "simon-says" { return @'
<div class="game-container">
    <h1>🎵 記憶節奏</h1>
    <div class="info"><span>🎯 回合 <span id="round">0</span></span> <span>⭐ 分數 <span id="score">0</span></span></div>
    <div class="simon-grid" id="simonGrid"><div class="simon-btn green" data-color="green"></div><div class="simon-btn red" data-color="red"></div><div class="simon-btn yellow" data-color="yellow"></div><div class="simon-btn blue" data-color="blue"></div></div>
    <div class="controls"><button onclick="startGame()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊「新遊戲」開始！</div>
</div>
<script>
const colors=['green','red','yellow','blue'];
let sequence=[], player=[], round=0, score=0, playing=false, playerTurn=false;
const roundEl=document.getElementById('round'), scoreEl=document.getElementById('score'), msg=document.getElementById('message'), grid=document.getElementById('simonGrid');
function init(){
  sequence=[]; player=[]; round=0; score=0; playing=false; playerTurn=false;
  roundEl.textContent='0'; scoreEl.textContent='0'; msg.textContent='點擊「新遊戲」開始！';
}
function startGame(){
  init(); playing=true; nextRound();
}
function nextRound(){
  if(!playing)return; player=[]; playerTurn=false; msg.textContent='👀 觀察...'; round++; roundEl.textContent=round;
  let c=colors[Math.floor(Math.random()*colors.length)]; sequence.push(c);
  let i=0; let interval=setInterval(()=>{if(i>=sequence.length){clearInterval(interval);playerTurn=true;msg.textContent='👆 重複順序！';return;}flash(sequence[i]);i++;},500);
}
function flash(color){
  let btn=grid.querySelector('[data-color="'+color+'"]'); if(!btn)return; btn.style.opacity='0.3'; setTimeout(()=>btn.style.opacity='1',300);
}
function handleClick(color){
  if(!playing||!playerTurn)return; player.push(color); flash(color); let idx=player.length-1; if(player[idx]!==sequence[idx]){playing=false;playerTurn=false;msg.textContent='❌ 錯誤！遊戲結束';return;} if(player.length===sequence.length){score+=10;scoreEl.textContent=score;msg.textContent='✅ 正確！下一關！';playerTurn=false;setTimeout(nextRound,800);}
}
grid.querySelectorAll('.simon-btn').forEach(b=>b.onclick=()=>handleClick(b.dataset.color));
window.init=init; window.startGame=startGame; window.resetGame=startGame; init();
</script>
<style>.simon-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:10px;max-width:220px;margin:10px auto}.simon-btn{width:100px;height:100px;border-radius:12px;cursor:pointer;border:3px solid #ccc;transition:.2s}.green{background:#2ecc71}.red{background:#e74c3c}.yellow{background:#f1c40f}.blue{background:#3498db}</style>
'@ }
        "doodle-jump" { return @'
<div class="game-container">
    <h1>🦘 塗鴉跳躍</h1>
    <div class="info"><span>🏆 分數 <span id="score">0</span></span> <span>🏅 最高 <span id="best">0</span></span></div>
    <canvas id="gameCanvas" width="360" height="500"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">按住滑鼠左右移動控制跳躍方向</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), bestEl=document.getElementById('best'), msg=document.getElementById('message');
canvas.width=360; canvas.height=500;
let player={x:160,y:400,w:30,h:30}, platforms=[], score=0, best=0, vy=0, gravity=0.4, jump=-8, gameRunning=false;
function init(){
  player.y=400; vy=0; score=0; platforms=[]; scoreEl.textContent=0; msg.textContent='按住滑鼠左右移動控制跳躍方向';
  for(let i=0;i<6;i++)platforms.push({x:Math.random()*300,y:100+i*70,w:60,h:10});
  gameRunning=true; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){
  vy+=gravity; player.y+=vy; if(player.y<0){player.y=0;vy=0;}
  if(player.y>canvas.height){gameOver();return;}
  let onPlatform=false; for(let p of platforms){if(player.x+player.w>p.x&&player.x<p.x+p.w&&player.y+player.h>p.y&&player.y+player.h<p.y+20&&vy>0){vy=jump;onPlatform=true;player.y=p.y-player.h;score++;scoreEl.textContent=score;if(score>best){best=score;bestEl.textContent=best;}}}
  if(!onPlatform&&vy>0){for(let p of platforms){if(player.x+player.w>p.x&&player.x<p.x+p.w&&player.y+player.h>p.y&&player.y+player.h<p.y+20){vy=jump;player.y=p.y-player.h;}}}
}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height); ctx.fillStyle='#2c3e50'; ctx.fillRect(player.x,player.y,player.w,player.h);
  for(let p of platforms){ctx.fillStyle='#3498db';ctx.fillRect(p.x,p.y,p.w,p.h);}
}
function gameOver(){gameRunning=false;msg.textContent='💀 遊戲結束！分數：'+score;}
canvas.addEventListener('mousemove',e=>{if(!gameRunning)return;let rect=canvas.getBoundingClientRect();player.x=e.clientX-rect.left-player.w/2;if(player.x<0)player.x=0;if(player.x+player.w>canvas.width)player.x=canvas.width-player.w;});
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#ecf0f1;border-radius:8px;cursor:pointer}</style>
'@ }
        "pong" { return @'
<div class="game-container">
    <h1>🏓 乒乓球</h1>
    <div class="info"><span>👈 玩家 <span id="playerScore">0</span></span> <span>🤖 AI <span id="aiScore">0</span></span></div>
    <canvas id="gameCanvas" width="400" height="300"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">滑鼠上下移動控制</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const pScore=document.getElementById('playerScore'), aScore=document.getElementById('aiScore'), msg=document.getElementById('message');
canvas.width=400; canvas.height=300;
let player={y:120,w:10,h:60}, ai={y:120,w:10,h:60}, ball={x:200,y:150,dx:3,dy:2,r:6};
let scoreP=0, scoreA=0, gameRunning=false;
function init(){
  player.y=120; ai.y=120; ball.x=200; ball.y=150; ball.dx=3; ball.dy=2; scoreP=0; scoreA=0;
  pScore.textContent='0'; aScore.textContent='0'; msg.textContent='滑鼠上下移動控制'; gameRunning=true; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){
  ball.x+=ball.dx; ball.y+=ball.dy;
  if(ball.y-ball.r<0||ball.y+ball.r>canvas.height)ball.dy=-ball.dy;
  if(ball.x-ball.r<0){scoreA++;aScore.textContent=scoreA;if(scoreA>=5){msg.textContent='🤖 AI 贏了！';gameRunning=false;}resetBall();return;}
  if(ball.x+ball.r>canvas.width){scoreP++;pScore.textContent=scoreP;if(scoreP>=5){msg.textContent='🎉 玩家贏了！';gameRunning=false;}resetBall();return;}
  if(ball.x-ball.r<player.w&&ball.y>player.y&&ball.y<player.y+player.h){ball.dx=Math.abs(ball.dx);let diff=ball.y-(player.y+player.h/2);ball.dy=diff*0.1;}
  if(ball.x+ball.r>canvas.width-ai.w&&ball.y>ai.y&&ball.y<ai.y+ai.h){ball.dx=-Math.abs(ball.dx);let diff=ball.y-(ai.y+ai.h/2);ball.dy=diff*0.1;}
  ai.y+= (ball.y-ai.y-ai.h/2)*0.05;
}
function resetBall(){ball.x=200;ball.y=150;ball.dx=3*(Math.random()>.5?1:-1);ball.dy=2*(Math.random()>.5?1:-1);}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  ctx.fillStyle='#fff'; ctx.fillRect(0,player.y,player.w,player.h); ctx.fillRect(canvas.width-ai.w,ai.y,ai.w,ai.h);
  ctx.beginPath(); ctx.arc(ball.x,ball.y,ball.r,0,Math.PI*2); ctx.fillStyle='#fff'; ctx.fill();
  ctx.strokeStyle='#fff'; ctx.setLineDash([10,10]); ctx.beginPath(); ctx.moveTo(canvas.width/2,0); ctx.lineTo(canvas.width/2,canvas.height); ctx.stroke();
}
canvas.addEventListener('mousemove',e=>{let rect=canvas.getBoundingClientRect();player.y=e.clientY-rect.top-player.h/2;if(player.y<0)player.y=0;if(player.y+player.h>canvas.height)player.y=canvas.height-player.h;});
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#2c3e50;border-radius:8px}</style>
'@ }
        "solitaire" { return @'
<div class="game-container">
    <h1>🃏 接龍</h1>
    <div class="info"><span>⏱️ <span id="moves">0</span></span> <span>✅ 完成 <span id="done">0</span>/4</span></div>
    <canvas id="gameCanvas" width="650" height="400"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">點擊卡片移動到正確位置</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const movesEl=document.getElementById('moves'), doneEl=document.getElementById('done'), msg=document.getElementById('message');
canvas.width=650; canvas.height=400;
let deck=[], table=[], foundations=[], moves=0, done=0;
const suits=['♠','♥','♦','♣'];
const ranks=['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
function init(){
  deck=[]; for(let s of suits)for(let r of ranks)deck.push({rank:r,suit:s,face:true});
  deck=deck.sort(()=>Math.random()-0.5);
  table=Array.from({length:7},()=>[]); foundations=Array.from({length:4},()=>[]);
  for(let i=0;i<7;i++){for(let j=0;j<=i;j++){let c=deck.pop();c.face=j===i;table[i].push(c);}}
  moves=0; done=0; movesEl.textContent='0'; doneEl.textContent='0'; msg.textContent='點擊卡片移動到正確位置'; draw();
}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height);
  for(let i=0;i<7;i++){for(let j=0;j<table[i].length;j++){let c=table[i][j];let x=50+i*80,y=50+j*20;ctx.fillStyle=c.face?'#fff':'#2c3e50';ctx.fillRect(x,y,70,90);ctx.strokeStyle='#333';ctx.strokeRect(x,y,70,90);if(c.face){ctx.fillStyle='#000';ctx.font='16px Arial';ctx.fillText(c.rank+c.suit,x+10,y+30);}}}
  for(let i=0;i<4;i++){let x=450+i*80,y=50;ctx.fillStyle='#fff';ctx.fillRect(x,y,70,90);ctx.strokeStyle='#333';ctx.strokeRect(x,y,70,90);if(foundations[i].length){let c=foundations[i][foundations[i].length-1];ctx.fillStyle='#000';ctx.font='16px Arial';ctx.fillText(c.rank+c.suit,x+10,y+30);}}
}
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#2ecc71;border-radius:8px;cursor:pointer}</style>
'@ }
        "bubble-shooter" { return @'
<div class="game-container">
    <h1>🫧 泡泡射擊</h1>
    <div class="info"><span>🎯 <span id="score">0</span></span> <span>💨 剩餘 <span id="shots">20</span></span></div>
    <canvas id="gameCanvas" width="380" height="450"></canvas>
    <div class="controls"><button onclick="init()">🔄 新遊戲</button></div>
    <div class="message" id="message">移動滑鼠瞄準，點擊射擊</div>
</div>
<script>
const canvas=document.getElementById('gameCanvas'), ctx=canvas.getContext('2d');
const scoreEl=document.getElementById('score'), shotsEl=document.getElementById('shots'), msg=document.getElementById('message');
canvas.width=380; canvas.height=450;
let bubbles=[], current, score=0, shots=20, gameRunning=false;
const COLORS=['#e74c3c','#3498db','#2ecc71','#f1c40f','#9b59b6'];
function init(){
  bubbles=[]; score=0; shots=20; gameRunning=true; scoreEl.textContent='0'; shotsEl.textContent='20'; msg.textContent='移動滑鼠瞄準，點擊射擊';
  for(let row=0;row<6;row++){for(let col=0;col<12;col++){if(Math.random()>.2){let x=col*32+16+(row%2)*16;let y=row*28+20;bubbles.push({x:x,y:y,r:14,color:COLORS[Math.floor(Math.random()*COLORS.length)]});}}}
  current={x:190,y:420,color:COLORS[Math.floor(Math.random()*COLORS.length)]}; loop();
}
function loop(){if(!gameRunning)return;update();draw();requestAnimationFrame(loop);}
function update(){}
function draw(){
  ctx.clearRect(0,0,canvas.width,canvas.height); ctx.fillStyle='#2c3e50'; ctx.fillRect(0,0,canvas.width,canvas.height);
  for(let b of bubbles){ctx.beginPath();ctx.arc(b.x,b.y,b.r,0,Math.PI*2);ctx.fillStyle=b.color;ctx.fill();ctx.strokeStyle='#fff';ctx.stroke();}
  ctx.beginPath();ctx.arc(current.x,current.y,14,0,Math.PI*2);ctx.fillStyle=current.color;ctx.fill();ctx.strokeStyle='#fff';ctx.stroke();
}
canvas.onmousemove=function(e){let rect=canvas.getBoundingClientRect();current.x=e.clientX-rect.left;if(current.x<20)current.x=20;if(current.x>360)current.x=360;};
canvas.onclick=function(){
  if(!gameRunning||shots<=0)return; shots--; shotsEl.textContent=shots;
  let angle=Math.atan2(0-420,current.x-190); let dx=Math.cos(angle)*5,dy=Math.sin(angle)*5;
  let bx=190,by=420; let interval=setInterval(()=>{bx+=dx;by+=dy;if(by<20){clearInterval(interval);let hit=false;for(let b of bubbles){if(Math.hypot(bx-b.x,by-b.y)<20){hit=true;b.color=current.color;}}if(!hit){let col=Math.round((bx-16)/32);let row=Math.round((by-20)/28);if(row<6&&col>=0&&col<12){bubbles.push({x:col*32+16+(row%2)*16,y:row*28+20,r:14,color:current.color});}}checkMatch();current.color=COLORS[Math.floor(Math.random()*COLORS.length)];if(shots<=0){msg.textContent='⏱️ 射擊結束！分數：'+score;gameRunning=false;}}},20);
};
function checkMatch(){let groups=[]; for(let b of bubbles){let found=false;for(let g of groups){if(g.some(p=>Math.hypot(p.x-b.x,p.y-b.y)<20)){g.push(b);found=true;break;}}if(!found)groups.push([b]);}for(let g of groups){if(g.length>=3){let color=g[0].color;bubbles=bubbles.filter(b=>b.color!==color);score+=g.length*10;scoreEl.textContent=score;}}}
window.init=init; init();
</script>
<style>#gameCanvas{display:block;margin:10px auto;background:#2c3e50;border-radius:8px;cursor:crosshair}</style>
'@ }
        default { return '<div class="game-container"><h1>🎮 遊戲開發中</h1><p>敬請期待！</p></div>' }
    }
}

# ============================================================
# 生成單一遊戲 HTML
# ============================================================
function Generate-GameHTML {
    param([string]$GameName, [string]$GameTitle, [string]$OutputPath, [string]$Description)

    Write-Host "📄 生成：$GameTitle" -ForegroundColor Cyan

    $gameDir = Split-Path $OutputPath -Parent
    if (-not (Test-Path $gameDir)) { New-Item -ItemType Directory -Path $gameDir -Force | Out-Null }

    $fullContent = Get-GameContent -GameName $GameName

    $html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$GameTitle - 雅寶遊戲間</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif;
            background: #f7fafc;
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 20px;
            margin: 0;
            min-height: 100vh;
        }
        .game-container {
            max-width: 500px;
            width: 100%;
            background: #fff;
            padding: 24px;
            border-radius: 16px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.08);
            margin: 20px 0;
            text-align: center;
        }
        .how-to-play {
            background: #f0f4f8;
            padding: 16px 20px;
            border-radius: 12px;
            margin: 16px auto;
            max-width: 500px;
            width: 100%;
            border-left: 4px solid #005A9C;
            font-size: 14px;
        }
        .how-to-play h3 {
            font-size: 16px;
            font-weight: 700;
            color: #005A9C;
            margin-bottom: 4px;
        }
        .controls {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            justify-content: center;
            margin: 10px 0;
        }
        .controls button {
            padding: 8px 16px;
            border-radius: 8px;
            border: 2px solid #005A9C;
            background: #fff;
            color: #005A9C;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.2s;
        }
        .controls button:hover {
            background: #005A9C;
            color: #fff;
        }
        .comments-section {
            max-width: 500px;
            width: 100%;
            margin: 20px auto;
            padding-top: 20px;
            border-top: 2px solid #e2e8f0;
        }
        .info {
            display: flex;
            justify-content: center;
            gap: 20px;
            margin: 10px 0;
            font-size: 14px;
        }
        .info span {
            background: #f0f4f8;
            padding: 4px 12px;
            border-radius: 20px;
        }
        .message {
            margin-top: 10px;
            color: #4a5568;
            font-weight: 500;
        }
        .board, .grid {
            display: grid;
            gap: 2px;
            margin: 10px auto;
        }
        .site-header {
            background: #005A9C;
            color: white;
            padding: 12px 0;
            width: 100%;
            text-align: center;
            position: sticky;
            top: 0;
            z-index: 50;
        }
        .header-inner {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
        }
        .logo {
            font-size: 20px;
            font-weight: 700;
            color: white;
            text-decoration: none;
        }
        .nav-links {
            display: flex;
            gap: 20px;
            font-size: 14px;
            align-items: center;
        }
        .nav-links a {
            color: rgba(255,255,255,0.85);
            text-decoration: none;
        }
        .nav-links a:hover {
            color: white;
        }
        .game-link {
            background: rgba(255,255,255,0.15);
            padding: 4px 14px;
            border-radius: 20px;
        }
        .site-footer {
            background: #2D3748;
            color: #A0AEC0;
            padding: 20px 0;
            width: 100%;
            text-align: center;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    $headerHTML
    $fullContent
    <div class="how-to-play"><h3>🎯 玩法說明</h3><p>$Description</p></div>
    <div class="comments-section"><h3>💬 討論與留言</h3><p>歡迎分享心得！</p></div>
    $footerHTML
</body>
</html>
"@

    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    Write-Host "   ✅ $OutputPath" -ForegroundColor Green
}

# ============================================================
# 生成索引頁
# ============================================================
function Generate-GameIndex {
    param([string]$OutputDir, [array]$Games)
    Write-Host "📄 生成索引頁..." -ForegroundColor Cyan
    $path = Join-Path $OutputDir "game\index.html"
    $content = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>雅寶遊戲間</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Microsoft JhengHei", sans-serif;
            background: #f7fafc;
            padding: 20px;
            display: flex;
            flex-direction: column;
            align-items: center;
            margin: 0;
        }
        .container { max-width: 900px; width: 100%; }
        h1 { text-align: center; color: #005A9C; }
        .game-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
            gap: 16px;
            margin-top: 20px;
        }
        .game-card {
            background: #fff;
            border-radius: 14px;
            padding: 20px;
            text-align: center;
            text-decoration: none;
            color: inherit;
            box-shadow: 0 4px 12px rgba(0,0,0,0.06);
            border: 1px solid #e2e8f0;
            transition: all 0.3s;
        }
        .game-card:hover {
            transform: translateY(-6px);
            box-shadow: 0 8px 25px rgba(0,0,0,0.12);
        }
        .game-card .icon { font-size: 40px; display: block; }
        .game-card .name { font-size: 16px; font-weight: 700; }
        .game-card .badge {
            display: inline-block;
            background: #005A9C;
            color: #fff;
            padding: 2px 14px;
            border-radius: 20px;
            font-size: 11px;
            margin-top: 8px;
        }
    </style>
</head>
<body>
    $headerHTML
    <div class="container">
        <h1>🎮 雅寶遊戲間</h1>
        <div class="game-grid">
"@
    foreach ($g in $Games) {
        $icon = switch($g.name){"2048"{'🔢'} "snake"{'🐍'} "tetris"{'🧱'} "sudoku"{'🧩'} "memory"{'🃏'} "minesweeper"{'💣'} "wordsearch"{'🔍'} "colormatch"{'🎯'} "clicker"{'👆'} "breakout"{'🏏'} "shooting-range"{'🎯'} "jigsaw-puzzle"{'🧩'} "color-memory"{'🎨'} "archery"{'🏹'} "math-quiz"{'🧠'} "tic-tac-toe"{'❌'} "hangman"{'🔤'} "flappy-bird"{'🐦'} "simon-says"{'🎵'} "doodle-jump"{'🦘'} "pong"{'🏓'} "solitaire"{'🃏'} "bubble-shooter"{'🫧'} default{'🎮'}}
        $content += "<a href='/$($g.filename)' class='game-card'><span class='icon'>$icon</span><span class='name'>$($g.title)</span><span class='badge'>立即遊玩</span></a>"
    }
    $content += @"
        </div>
    </div>
    $footerHTML
</body>
</html>
"@
    Set-Content -Path $path -Value $content -Encoding UTF8
    Write-Host "✅ 索引頁：$path" -ForegroundColor Green
}

# ============================================================
# 執行
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   🎮 雅寶遊戲生成 v3.0 (完整版)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 共 $($newGames.Count) 款遊戲" -ForegroundColor Yellow

foreach ($game in $newGames) {
    $path = Join-Path $OutputDir $game.filename
    Generate-GameHTML -GameName $game.name -GameTitle $game.title -OutputPath $path -Description $game.description
}

Generate-GameIndex -OutputDir $OutputDir -Games $newGames

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 全部完成！" -ForegroundColor Green
Write-Host "🎮 遊戲總數：$($newGames.Count) 款" -ForegroundColor Cyan
Write-Host "🌐 遊戲入口：https://ahpal.com/game/" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green