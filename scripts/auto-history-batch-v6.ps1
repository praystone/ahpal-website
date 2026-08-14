# ============================================================
# 歷史腦洞 第五波 20 篇 — 唐宋元明清 擴展系列 v6.0
# ============================================================
# 用途：無人值守一次性生成 20 篇全新歷史腦洞文章
# 執行時間：2026-08-15 02:30 AM
# 
# v6.0 戰略部署 (2026-08-15)：
#   - 📜 擴展至唐宋元明清 五個朝代
#   - 🔧 繼承 v5.0 所有修復 (UTF-8、絕對路徑、重試機制)
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
$LogFile = "$LogDir\auto-history-batch-v6-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 第五波 20 篇 — 唐宋元明清 擴展系列 v6.0"
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
# 步驟 2：定義第五波 20 篇文章 (唐宋元明清)
# ============================================================
Write-Log "[2/6] 定義第五波 20 篇文章清單 (唐宋元明清)..."

$Articles = @(
    # ===== 唐朝 (4 篇) =====
    @{ keyword = "如果李白有 Instagram：他的詩會配什麼照片和 hashtag？"; filename = "li-bai-instagram-poetry.html" },
    @{ keyword = "唐太宗與魏徵其實是古代版的「職場導師 vs 實習生」"; filename = "tang-taizong-weizheng-mentor.html" },
    @{ keyword = "如果楊貴妃有 TikTok：她會成為古代版的美妝帶貨一姐嗎？"; filename = "yang-guifei-tiktok-beauty.html" },
    @{ keyword = "杜甫如果活在現代：他會是「社畜詩人」還是「厭世作家」？"; filename = "du-fu-modern-poet.html" },

    # ===== 宋朝 (4 篇) =====
    @{ keyword = "如果蘇軾有 YouTube：他會成為古代版的「生活型 YouTuber」？"; filename = "su-shi-youtube-lifestyle.html" },
    @{ keyword = "岳飛的「精忠報國」其實是古代版的「員工忠誠度培訓」"; filename = "yue-fei-loyalty-training.html" },
    @{ keyword = "如果宋朝有 Uber Eats：清明上河圖裡的外送員在哪裡？"; filename = "song-dynasty-uber-eats.html" },
    @{ keyword = "宋徽宗如果當 YouTuber：他會拍「一日藝術家」還是「亡國日記」？"; filename = "song-huizong-youtuber-artist.html" },

    # ===== 元朝 (3 篇) =====
    @{ keyword = "成吉思汗如果開 LinkedIn：他的履歷會怎麼寫「征服世界」？"; filename = "genghis-khan-linkedin-profile.html" },
    @{ keyword = "如果元朝有 Google Maps：蒙古鐵騎怎麼靠導航征服歐亞？"; filename = "yuan-dynasty-google-maps.html" },
    @{ keyword = "忽必烈如果辦「帝國股東大會」：元朝的 KPI 考核怎麼做？"; filename = "kublai-khan-kpi-meeting.html" },

    # ===== 明朝 (5 篇) =====
    @{ keyword = "朱元璋其實是古代版的「草根創業家」：從乞丐到皇帝的職場逆襲"; filename = "zhu-yuanzhang-startup-story.html" },
    @{ keyword = "鄭和如果開 TikTok：他會成為古代版的「航海冒險網紅」？"; filename = "zheng-he-tiktok-adventure.html" },
    @{ keyword = "如果明朝有 Slack：錦衣衛的「機密任務」是怎麼派發的？"; filename = "ming-dynasty-slack-secret.html" },
    @{ keyword = "唐伯虎如果當 YouTuber：他會拍「點秋香實況」還是「畫畫教學」？"; filename = "tang-bo-hu-youtuber-art.html" },
    @{ keyword = "如果明朝有 Airbnb：紫禁城會變成「最高級民宿」嗎？"; filename = "ming-dynasty-airbnb-forbidden.html" },

    # ===== 清朝 (4 篇) =====
    @{ keyword = "康熙如果開 Podcast：他會聊「治國心法」還是「後宮八卦」？"; filename = "kangxi-podcast-governance.html" },
    @{ keyword = "乾隆其實是古代版的「曬娃魔人」：他的「十全老人」貼文有多浮誇？"; filename = "qianlong-social-media-brag.html" },
    @{ keyword = "如果清朝有 Zoom：慈禧太后的「垂簾聽政」是遠端會議？"; filename = "cixi-zoom-remote-govern.html" },
    @{ keyword = "林則徐如果開 LinkedIn：他的「虎門銷煙」專案管理怎麼寫？"; filename = "lin-zexu-project-management.html" }
)

Write-Log "✅ 已定義 $($Articles.Count) 篇文章 (唐 $($Articles | Where-Object { $_.filename -match 'tang|li-bai|du-fu|yang-guifei' } | Measure-Object).Count 篇, 宋 $($Articles | Where-Object { $_.filename -match 'su-shi|yue-fei|song|huizong' } | Measure-Object).Count 篇, 元 $($Articles | Where-Object { $_.filename -match 'genghis|yuan|kublai' } | Measure-Object).Count 篇, 明 $($Articles | Where-Object { $_.filename -match 'zhu|zheng|ming|tang-bo' } | Measure-Object).Count 篇, 清 $($Articles | Where-Object { $_.filename -match 'kangxi|qianlong|cixi|lin-ze' } | Measure-Object).Count 篇)"

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
Write-Log "✅ 歷史腦洞 第五波 20 篇 — 唐宋元明清 擴展系列執行完畢！"
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
    $Subject = "📜 歷史腦洞 第五波 20 篇 — 唐宋元明清 擴展系列完成通知"
    $Body = @"
歷史腦洞 第五波 20 篇 — 唐宋元明清擴展系列已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 本次新增：$($MissingArticles.Count) 篇
   - 朝代範圍：唐、宋、元、明、清
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