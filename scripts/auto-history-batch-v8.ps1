# ============================================================
# 歷史腦洞 第七波 20 篇 — 即時顯示 + 自動排程版 v8.0
# ============================================================
# 用途：無人值守一次性生成 20 篇全新歷史腦洞文章
# 執行時間：2026-08-15 04:30 AM（可調整）
#
# v8.0 核心改良 (2026-08-15)：
#   - 🆕 繼承 v7.0 即時顯示功能
#   - 🆕 新增文章主題：春秋戰國 + 秦漢 + 三國 + 唐宋 + 明清
#   - 🆕 自動偵測缺失文章，避免重複生成
#   - ✅ 完整錯誤處理與重試機制
#   - ✅ 無 BOM UTF-8 寫入
#   - ✅ 執行完成後自動發送通知郵件
# ============================================================

# ⭐ 強制 UTF-8 編碼
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
$env:PYTHONIOENCODING = "utf-8"

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# ============================================================
# 自動修復 html_builder.py
# ============================================================
$HtmlBuilderPath = "$ProjectRoot\src\html_builder.py"
if (Test-Path $HtmlBuilderPath) {
    $content = Get-Content $HtmlBuilderPath -Raw -Encoding UTF8
    $content = $content -replace '📄', '[📄]'
    $content = $content -replace '✅', '[✅]'
    $content = $content -replace '⚠️', '[⚠️]'
    $content = $content -replace 'ℹ️', '[ℹ️]'
    $content = $content -replace '📊', '[📊]'
    $content = $content -replace '📁', '[📁]'
    $content = $content -replace '🎮', '[🎮]'
    $content = $content -replace '🎯', '[🎯]'
    $content = $content -replace '📚', '[📚]'
    $content = $content -replace '🔍', '[🔍]'
    $content = $content -replace '💬', '[💬]'
    $content = $content -replace '📖', '[📖]'
    $content = $content -replace '🖼️', '[🖼️]'
    $content = $content -replace '🏆', '[🏆]'
    $content = $content -replace '📌', '[📌]'
    $content = $content -replace '📝', '[📝]'
    $content = $content -replace '🧠', '[🧠]'
    $content = $content -replace '🤖', '[🤖]'
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($HtmlBuilderPath, $content, $utf8NoBom)
}

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-history-batch-v8-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 第七波 20 篇 — 即時顯示 + 自動排程版 v8.0"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/6] 檢查 API Key..."

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
    exit 1
}
Write-Log "✅ API Key 檢查通過"

# ============================================================
# 步驟 2：定義第七波 20 篇文章 (春秋戰國 + 秦漢 + 三國 + 唐宋 + 明清)
# ============================================================
Write-Log "[2/6] 定義第七波 20 篇文章清單..."

$Articles = @(
    # ===== 春秋戰國 (4 篇) =====
    @{ keyword = "如果孔子有 Facebook：他會發什麼「正能量」貼文？"; filename = "kongzi-facebook-posts.html" },
    @{ keyword = "孫子兵法如果出 App：會成為「職場必勝」神器嗎？"; filename = "sunzi-bingfa-app.html" },
    @{ keyword = "如果墨子有 TikTok：他會拍「兼愛非攻」的宣導短片嗎？"; filename = "mozi-tiktok-promo.html" },
    @{ keyword = "莊子的「逍遙遊」其實是古代版的「躺平學」？"; filename = "zhuangzi-lay-flat.html" },

    # ===== 秦漢 (4 篇) =====
    @{ keyword = "如果秦始皇有 LINE 群組：他會怎麼管理大臣們的對話？"; filename = "qin-shi-huang-line-group.html" },
    @{ keyword = "劉邦與項羽的對決如果辦在電競世界：誰會贏？"; filename = "liu-bang-xiang-yu-esports.html" },
    @{ keyword = "如果漢武帝有 Google 搜尋：他會查什麼？"; filename = "han-wudi-google-search.html" },
    @{ keyword = "司馬遷寫《史記》其實是古代版的「爆料公社」？"; filename = "sima-qian-baoliao.html" },

    # ===== 三國 (4 篇) =====
    @{ keyword = "如果三國有 Spotify：曹操的「短歌行」會上榜嗎？"; filename = "cao-cao-spotify-ranking.html" },
    @{ keyword = "諸葛亮的「隆中對」其實是古代版的「創業 BP」？"; filename = "longzhong-dui-startup-bp.html" },
    @{ keyword = "如果周瑜有 IG：他會放什麼「美男照」？"; filename = "zhou-yu-ig-selfie.html" },
    @{ keyword = "司馬懿的「高平陵之變」其實是古代版的「敵意併購」？"; filename = "gaopingling-hostile-takeover.html" },

    # ===== 唐宋 (4 篇) =====
    @{ keyword = "如果唐太宗有 Slack：他會怎麼跟房玄齡開會？"; filename = "tang-taizong-slack-meeting.html" },
    @{ keyword = "李白如果開 Podcast：他會聊「喝酒」還是「寫詩」？"; filename = "li-bai-podcast-talks.html" },
    @{ keyword = "如果宋朝有 TikTok：李清照會拍什麼「文青廢片」？"; filename = "li-qingzhao-tiktok-vibes.html" },
    @{ keyword = "蘇軾的「赤壁賦」其實是古代版的「旅遊 Vlog」？"; filename = "su-shi-travel-vlog.html" },

    # ===== 明清 (4 篇) =====
    @{ keyword = "如果明朝有 YouTube：朱元璋會開「大明教學頻道」嗎？"; filename = "ming-taizu-youtube-channel.html" },
    @{ keyword = "鄭和下西洋其實是古代版的「跨國商務考察」？"; filename = "zheng-he-business-trip.html" },
    @{ keyword = "如果清朝有 Twitter：康熙會發什麼「皇帝日常」？"; filename = "kangxi-twitter-daily.html" },
    @{ keyword = "乾隆的「江南巡遊」其實是古代版的「網紅探店」？"; filename = "qianlong-food-tour.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 步驟 3：檢查 history/ 目錄
# ============================================================
Write-Log "[3/6] 檢查 history/ 目錄..."

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
        exit 1
    }
}
Write-Log "✅ 文章合併完成"

# ============================================================
# 步驟 6：執行文章生成 — 🆕 即時顯示模式
# ============================================================
Write-Log "[6/6] 執行文章生成與部署..."

Write-Log "   [6a] 生成文章 (python src/main.py --force deepseek)..."
Write-Log "   ⏳ 預計耗時 60-90 分鐘"
Write-Log ""
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  📡 文章生成即時輸出 (每篇文章完成時顯示)"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log ""

# 🆕 關鍵改良：即時顯示 + 同時寫入日誌
$MainOutputPath = "$LogDir\main-output.txt"
$MainErrorPath = "$LogDir\main-error.txt"

# 使用 Tee-Object 即時顯示並寫入檔案
python src/main.py --force deepseek 2>&1 | Tee-Object -FilePath $MainOutputPath

$ExitCode = $LASTEXITCODE

# 擷取錯誤輸出（如果有）
if (Test-Path $MainErrorPath) {
    $MainError = Get-Content $MainErrorPath -Raw -ErrorAction SilentlyContinue -Encoding UTF8
    if ($MainError) {
        Write-Log "   ⚠️ 錯誤輸出: $MainError"
    }
}

if ($ExitCode -ne 0) {
    Write-Log ""
    Write-Log "❌ 文章生成失敗，退出碼: $ExitCode"
    Write-Log "⚠️ 將在 60 秒後重試..."
    Start-Sleep -Seconds 60
    
    # 重試：再次執行即時顯示
    Write-Log ""
    Write-Log "🔄 第二次嘗試..."
    python src/main.py --force deepseek 2>&1 | Tee-Object -FilePath "$LogDir\main-output-retry.txt"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ 第二次重試仍失敗"
        exit 1
    }
}

Write-Log ""
Write-Log "✅ 文章生成完成"

# ============================================================
# 步驟 7：更新分類頁面與 Sitemap
# ============================================================
Write-Log "   [6b] 更新分類頁面與 Sitemap..."

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

$DeployResult = & npx wrangler pages deploy . --project-name=ahpal-pages 2>&1
Write-Log $DeployResult

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ 部署失敗，10 分鐘後重試..."
    Start-Sleep -Seconds 600
    $DeployResult = & npx wrangler pages deploy . --project-name=ahpal-pages 2>&1
    Write-Log $DeployResult
    if ($LASTEXITCODE -ne 0) {
        Write-Log "❌ 第二次部署仍失敗，請手動檢查"
        exit 1
    }
}
Write-Log "✅ 部署完成"

# ============================================================
# 完成報告
# ============================================================
Write-Log "============================================================"
Write-Log "✅ 歷史腦洞 第七波 20 篇 — 即時顯示 + 自動排程版執行完畢！"
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
    $Subject = "📜 歷史腦洞 第七波 20 篇 — 即時顯示 + 自動排程版完成通知"
    $Body = @"
歷史腦洞 第七波 20 篇即時顯示 + 自動排程版已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

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

Write-Log "============================================================"
exit 0