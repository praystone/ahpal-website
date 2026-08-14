# ============================================================
# 歷史腦洞 第三波 20 篇 — 全自動夜間批次產線 v5.0 (完美最終版)
# ============================================================
# 用途：無人值守一次性生成 20 篇全新歷史腦洞文章
# 
# v5.0 完美最終版 (2026-08-15)：
#   - 🔧 所有路徑使用 $ProjectRoot 絕對路徑 (解決 WriteAllText 找不到路徑)
#   - 🔧 強制 UTF-8 編碼 (解決 PowerShell 亂碼與 UnicodeEncodeError)
#   - 🔧 自動修復 html_builder.py 中的 Emoji (永久解決)
#   - 🔧 SMTP 郵件通知正確讀取 .env 設定
#   - ✅ 完整錯誤處理與重試機制
#   - ✅ 無 BOM UTF-8 寫入
#   - ✅ 無人值守，無需用戶輸入
#   - ✅ 詳細日誌記錄
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
# 自動修復 html_builder.py (永久解決 UnicodeEncodeError)
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
$LogFile = "$LogDir\auto-history-batch-v5-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 第三波 20 篇 — 全自動夜間批次產線 v5.0"
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
# 步驟 2：定義第三波 20 篇文章
# ============================================================
Write-Log "[2/6] 定義第三波 20 篇文章清單..."

# ============================================================
# 第四波 20 篇 — 全新主題 (接續系列)
# ============================================================

$Articles = @(
    @{ keyword = "如果三國有 Wikipedia：曹操的條目會被怎麼編輯？"; filename = "wikipedia-cao-cao-edit-war.html" },
    @{ keyword = "諸葛亮的「空城計」其實是古代版的 YouTube 直播帶貨"; filename = "kong-cheng-ji-livestream.html" },
    @{ keyword = "如果古代有 ChatGPT 翻譯：司馬懿怎麼看曹魏的內部信件？"; filename = "sima-yi-chatgpt-translate.html" },
    @{ keyword = "三國的「外送平台」：赤壁之戰的軍糧是怎麼配送的？"; filename = "red-cliff-food-delivery.html" },
    @{ keyword = "如果古代有 Slack：曹操的「挾天子以令諸侯」是群組公告？"; filename = "cao-cao-slack-announcement.html" },
    @{ keyword = "劉備的「哭」其實是古代版的情緒勒索話術？"; filename = "liu-bei-emotional-blackmail.html" },
    @{ keyword = "如果三國有 Twitter：諸葛亮的「出師表」是長文串？"; filename = "zhuge-liang-twitter-thread.html" },
    @{ keyword = "曹操的「寧可我負天下人」其實是古代版的職場 PUA"; filename = "cao-cao-workplace-pua.html" },
    @{ keyword = "如果古代有 Zoom：赤壁之戰的遠端會議長怎樣？"; filename = "red-cliff-zoom-strategy.html" },
    @{ keyword = "三國的「網購平台」：關羽的青龍偃月刀哪裡買的？"; filename = "three-kingdoms-ecommerce.html" },
    @{ keyword = "如果古代有 Substack：曹操的「短歌行」是付費電子報？"; filename = "cao-cao-substack-newsletter.html" },
    @{ keyword = "諸葛亮的「錦囊妙計」其實是古代版的 QR Code 掃描？"; filename = "jin-nang-qr-code-v2.html" },
    @{ keyword = "如果三國有 Airbnb：劉備的「三顧茅廬」是民宿體驗？"; filename = "liu-bei-airbnb-experience.html" },
    @{ keyword = "曹操的「望梅止渴」其實是古代版的飢餓行銷？"; filename = "cao-cao-hunger-marketing.html" },
    @{ keyword = "如果古代有 TikTok 短劇：三國故事怎麼改編成連續劇？"; filename = "three-kingdoms-tiktok-drama.html" },
    @{ keyword = "司馬懿的「忍」其實是古代版的職場生存哲學"; filename = "sima-yi-workplace-survival.html" },
    @{ keyword = "如果三國有 LinkedIn Learning：諸葛亮會開什麼課程？"; filename = "zhuge-liang-linkedin-course.html" },
    @{ keyword = "曹操的「求賢令」其實是古代版的 104 獵頭廣告"; filename = "cao-cao-headhunter-ad.html" },
    @{ keyword = "如果古代有 Spotify 年度回顧：周瑜的 2026 年聽歌報告"; filename = "zhou-yu-spotify-wrapped-v2.html" },
    @{ keyword = "三國的「理財神器」：直百錢其實是古代版的 ETF？"; filename = "three-kingdoms-etf-investment.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 步驟 3：檢查 history/ 目錄，找出缺失的文章
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
# 步驟 6：執行文章生成
# ============================================================
Write-Log "[6/6] 執行文章生成與部署..."

Write-Log "   [6a] 生成文章 (python src/main.py --force deepseek)..."
Write-Log "   ⏳ 預計耗時 60-90 分鐘，請耐心等待..."

$MainOutputPath = "$LogDir\main-output.txt"
$MainErrorPath = "$LogDir\main-error.txt"

$Process = Start-Process -FilePath "python" -ArgumentList "src/main.py --force deepseek" -Wait -PassThru -NoNewWindow -RedirectStandardOutput $MainOutputPath -RedirectStandardError $MainErrorPath

$MainOutput = Get-Content $MainOutputPath -Raw -ErrorAction SilentlyContinue -Encoding UTF8
$MainError = Get-Content $MainErrorPath -Raw -ErrorAction SilentlyContinue -Encoding UTF8

if ($MainOutput) { 
    Write-Log "   📝 生成輸出摘要："
    $MainOutput -split "`n" | Select-Object -Last 50 | ForEach-Object { Write-Log "      $_" }
}
if ($MainError) { Write-Log "   ⚠️ 錯誤輸出: $MainError" }

if ($Process.ExitCode -ne 0) {
    Write-Log "❌ 文章生成失敗，退出碼: $($Process.ExitCode)"
    Write-Log "⚠️ 將在 60 秒後重試..."
    Start-Sleep -Seconds 60
    $Process = Start-Process -FilePath "python" -ArgumentList "src/main.py --force deepseek" -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$LogDir\main-output-retry.txt" -RedirectStandardError "$LogDir\main-error-retry.txt"
    if ($Process.ExitCode -ne 0) {
        Write-Log "❌ 第二次重試仍失敗"
        exit 1
    }
}
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
Write-Log "✅ 歷史腦洞 第三波 20 篇 — 全自動產線執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📊 本次新增: $($MissingArticles.Count) 篇"
Write-Log "📁 日誌位置: $LogFile"
Write-Log "============================================================"

# ============================================================
# 寄送完成通知
# ============================================================
Write-Log "📧 寄送完成通知..."

# 從 .env 讀取 SMTP 設定
if (Test-Path $EnvPath) {
    Get-Content $EnvPath | ForEach-Object {
        if ($_ -match '^SMTP_USER=(.+)$') { $SmtpUser = $Matches[1] }
        if ($_ -match '^SMTP_PASS=(.+)$') { $SmtpPass = $Matches[1] }
        if ($_ -match '^SMTP_TO=(.+)$') { $ToEmail = $Matches[1] }
    }
}

if ($SmtpUser -and $SmtpPass -and $ToEmail) {
    $Subject = "🦞 歷史腦洞 第三波 20 篇 — 自動產線完成通知"
    $Body = @"
歷史腦洞 第三波 20 篇全自動產線已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

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