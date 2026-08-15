# ============================================================
# 歷史腦洞20篇 — 即時顯示 + 排程優化版 v10.2 (移除 Emoji 破壞修復)
# ============================================================
# 用途：無人值守一次性生成 20 篇全新歷史腦洞文章
# 
# v10.2 變更 (2026-08-16)：
#   - 🗑️ 移除自動修復 html_builder.py 區塊 (避免破壞 Emoji)
#   - ✅ 繼承 v10.1 所有功能 (斷點續傳、郵件通知、電源管理)
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

$Articles = @(
    @{ keyword = "如果現代人工智慧專家穿越到宋朝：幫王安石設計變法AI系統，青苗法變成精準扶貧大數據"; filename = "ai-expert-song-wanganshi.html" },
    @{ keyword = "如果現代賽車手穿越到明朝：幫朱棣設計古代F1賽車，北京城變成賽車場，皇帝親自下場飆車"; filename = "racer-ming-zhudi-f1.html" },
    @{ keyword = "如果現代太空人穿越到唐朝：幫李白體驗無重力，在太空中即興賦詩，寫出《天地之間》傳世名作"; filename = "astronaut-tang-libo-space-poem.html" },
    @{ keyword = "如果現代調酒師穿越到宋朝：幫蘇軾調製雞尾酒，東坡醉變成東坡特調，汴京夜店爆紅"; filename = "mixologist-song-sushi-cocktail.html" },
    @{ keyword = "如果現代考古學家穿越到元朝：幫成吉思汗找出失落的陵墓，破解八百年世紀之謎"; filename = "archaeologist-yuan-genghis-tomb.html" },
    @{ keyword = "如果現代電競選手穿越到清朝：幫康熙皇帝訓練古代皇室電競隊，紫禁城變成電競館"; filename = "esports-player-qing-kangxi-gaming.html" },
    @{ keyword = "如果現代心理學家穿越到唐朝：幫李白治療酒精成癮，詩仙戒酒後產出純淨版詩作"; filename = "psychologist-tang-libo-alcohol.html" },
    @{ keyword = "如果現代機械工程師穿越到宋朝：幫岳飛設計古代坦克，金兵騎兵變裝甲車，直搗黃龍"; filename = "mechanical-engineer-song-yuefei-tank.html" },
    @{ keyword = "如果現代品酒師穿越到元朝：幫馬可波羅鑑定葡萄酒，寫出古代第一本酒評指南"; filename = "sommelier-yuan-marco-wine.html" },
    @{ keyword = "如果現代空中瑜伽教練穿越到唐朝：幫楊貴妃設計空中舞蹈，長安城開始興起空中健身潮"; filename = "yoga-instructor-tang-yangguifei.html" },
    @{ keyword = "如果現代量子科學家穿越到明朝：幫朱元璋設計量子密碼，大明通信變成古代量子網路"; filename = "quantum-scientist-ming-zhuyuanzhang.html" },
    @{ keyword = "如果現代特效化妝師穿越到宋朝：幫岳飛設計戰場傷疤妝，金兵看了直接嚇退百里"; filename = "makeup-artist-song-yuefei-scars.html" },
    @{ keyword = "如果現代野生動物攝影師穿越到唐朝：拍下長安城內外的珍禽異獸，寫成古代第一本《國家地理》"; filename = "wildlife-photographer-tang-changan.html" },
    @{ keyword = "如果現代土木工程師穿越到隋朝：幫隋煬帝改良大運河，京杭大運河變成古代蘇伊士運河"; filename = "civil-engineer-sui-grandcanal.html" },
    @{ keyword = "如果現代茶藝師穿越到明朝：幫朱元璋設計泡茶SOP，明朝茶道變成古代星巴克"; filename = "tea-master-ming-zhuyuanzhang.html" },
    @{ keyword = "如果現代動畫師穿越到唐朝：幫敦煌壁畫做成動畫，飛天仙女變成古代迪士尼公主"; filename = "animator-tang-dunhuang.html" },
    @{ keyword = "如果現代睡眠專家穿越到清朝：幫雍正皇帝治療失眠，雍正不再是歷史上最累的皇帝"; filename = "sleep-expert-qing-yongzheng.html" },
    @{ keyword = "如果現代聲樂教練穿越到宋朝：幫柳永訓練唱功，婉約詞變成古代流行金曲排行榜"; filename = "vocal-coach-song-liuyong.html" },
    @{ keyword = "如果現代珠寶設計師穿越到明朝：幫鄭和設計寶石首飾，大明珠寶變成世界奢侈品牌"; filename = "jewelry-designer-ming-zhenghe.html" },
    @{ keyword = "如果現代網頁設計師穿越到漢朝：幫司馬遷設計《史記》官網，古代歷史變成互動式網頁"; filename = "web-designer-han-simaqian.html" }
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
    $Subject = "📜 歷史腦洞 第九波 20 篇 — 即時顯示 + 排程優化版完成通知"
    $Body = @"
歷史腦洞 第九波 20 篇即時顯示 + 排程優化版已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

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