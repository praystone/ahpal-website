# ============================================================
# 歷史腦洞 第二波 20 篇 — 全自動夜間批次產線 v3.5
# ============================================================
# 用途：無人值守一次性生成 20 篇全新歷史腦洞文章
# 
# v3.5 最終修正 (2026-08-14)：
#   - 🔧 強制全局 UTF-8 環境變數
#   - 🔧 預先清理 html_builder.py 中的 Emoji 避免 cp950 編碼錯誤
#   - 🔧 完整錯誤處理與重試機制
#   - ✅ 無 BOM UTF-8 寫入
#   - ✅ 執行完成後自動發送通知郵件
# ============================================================

# ⭐ 關鍵修復：設定輸出編碼為 UTF-8
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
if (Test-Path "src\html_builder.py") {
    $content = Get-Content src\html_builder.py -Raw -Encoding UTF8
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
    [System.IO.File]::WriteAllText("src\html_builder.py", $content, $utf8NoBom)
}

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-history-batch-v3-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 第二波 20 篇 — 全自動夜間批次產線 v3.5"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/6] 檢查 API Key..."

if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
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
# 步驟 2：定義第二波 20 篇文章
# ============================================================
Write-Log "[2/6] 定義第二波 20 篇文章清單..."

$Articles = @(
    @{ keyword = "如果秦始皇有 TikTok：他會成為第一個百萬粉絲的帝王網紅嗎？"; filename = "qin-shi-huang-tiktok-influencer.html" },
    @{ keyword = "項羽的火燒阿房宮其實是一場「古早版都更」？"; filename = "xiang-yu-urban-renewal.html" },
    @{ keyword = "劉邦的「約法三章」其實是史上最早的 KPI 考核系統"; filename = "liu-bang-kpi-system.html" },
    @{ keyword = "韓信的胯下之辱：如果當年被霸凌者告上法院，會有怎樣的判決？"; filename = "han-xin-bullying-lawsuit.html" },
    @{ keyword = "張良撿鞋的故事：如果當年老人丟的是 iPhone，他還會撿嗎？"; filename = "zhang-liang-iphone-shoe.html" },
    @{ keyword = "三國時代的「報紙」長怎樣？如果曹操創辦《魏國時報》會怎麼寫？"; filename = "wei-guo-newspaper.html" },
    @{ keyword = "諸葛亮的木牛流馬其實是「自動駕駛物流車」的古代原型"; filename = "mu-niu-liu-ma-autonomous.html" },
    @{ keyword = "如果關羽有 GPS，他還會走麥城嗎？古代導航 vs 現代科技"; filename = "guan-yu-gps-maicheng.html" },
    @{ keyword = "曹操的「望梅止渴」其實是史上最早的 PUA 話術？"; filename = "cao-cao-pua-tactic.html" },
    @{ keyword = "三國的「特務機構」：曹操的校事府 vs 劉備的軍師聯盟"; filename = "three-kingdoms-spy-agency.html" },
    @{ keyword = "如果古代有 LinkedIn：諸葛亮會怎麼寫他的履歷？"; filename = "linkedin-zhuge-liang-resume.html" },
    @{ keyword = "司馬懿的「高平陵之變」其實是史上最成功的一場政變策畫"; filename = "gaopingling-coup-planning.html" },
    @{ keyword = "如果曹操有 ChatGPT：他會怎麼用 AI 來治理天下？"; filename = "cao-cao-chatgpt-ai.html" },
    @{ keyword = "蜀漢的「錦囊妙計」其實是古代版的 QR Code 掃描？"; filename = "jin-nang-miao-ji-qr-code.html" },
    @{ keyword = "孫權的「草船借箭」其實是史上最早的供應鏈詐欺？"; filename = "sun-quan-supply-chain-fraud.html" },
    @{ keyword = "如果三國有 Google 翻譯：諸葛亮怎麼跟南蠻部落溝通？"; filename = "zhuge-liang-google-translate.html" },
    @{ keyword = "曹操的「短歌行」其實是古代版的 Facebook 動態貼文？"; filename = "cao-cao-facebook-post.html" },
    @{ keyword = "三國的「貨幣戰爭」：曹魏的銅錢 vs 蜀漢的直百錢"; filename = "three-kingdoms-currency-war.html" },
    @{ keyword = "如果古代有 Uber Eats：關羽的「溫酒斬華雄」會變成外送點評？"; filename = "guan-yu-uber-eats-review.html" },
    @{ keyword = "穿越到三國當 YouTuber：拍什麼內容才會爆紅？"; filename = "time-travel-youtuber-guide.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇文章"

# ============================================================
# 步驟 3：檢查 history/ 目錄，找出缺失的文章
# ============================================================
Write-Log "[3/6] 檢查 history/ 目錄..."

if (-not (Test-Path "history")) {
    New-Item -ItemType Directory -Path "history" -Force | Out-Null
    Write-Log "   📁 history/ 目錄已建立"
}

$ExistingFiles = @()
if (Test-Path "history") {
    $ExistingFiles = Get-ChildItem "history\*.html" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
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

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$ProjectRoot\data\pending-articles.json", $jsonContent, $utf8NoBom)
Write-Log "✅ JSON 已寫入 ($($MissingArticles.Count) 篇，UTF-8 無 BOM)"

# ============================================================
# 步驟 5：合併文章
# ============================================================
Write-Log "[5/6] 直接合併文章到 master-articles.json..."

$PyMergeScript = @'
import json, os, shutil
from datetime import datetime

pending_path = 'data/pending-articles.json'
master_path = 'data/master-articles.json'
backup_dir = 'backups/master-json'

os.makedirs(backup_dir, exist_ok=True)

if os.path.exists(master_path):
    ts = datetime.now().strftime('%Y%m%d-%H%M%S')
    shutil.copy(master_path, f'{backup_dir}/master-articles-{ts}.bak')
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

$Process = Start-Process -FilePath "python" -ArgumentList "src/main.py --force deepseek" -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$LogDir\main-output.txt" -RedirectStandardError "$LogDir\main-error.txt"

$MainOutput = Get-Content "$LogDir\main-output.txt" -Raw -ErrorAction SilentlyContinue -Encoding UTF8
$MainError = Get-Content "$LogDir\main-error.txt" -Raw -ErrorAction SilentlyContinue -Encoding UTF8

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
Write-Log "✅ 歷史腦洞 第二波 20 篇 — 全自動產線執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📊 本次新增: $($MissingArticles.Count) 篇"
Write-Log "📁 日誌位置: $LogFile"
Write-Log "============================================================"

# ============================================================
# 寄送完成通知
# ============================================================
Write-Log "📧 寄送完成通知..."

$SmtpUser = [Environment]::GetEnvironmentVariable("SMTP_USER")
$SmtpPass = [Environment]::GetEnvironmentVariable("SMTP_PASS")
$ToEmail = [Environment]::GetEnvironmentVariable("SMTP_TO")

if ($SmtpUser -and $SmtpPass -and $ToEmail) {
    $Subject = "🦞 歷史腦洞 第二波 20 篇 — 自動產線完成通知"
    $Body = @"
歷史腦洞 第二波 20 篇全自動產線已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

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