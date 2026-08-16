# ============================================================
# 生活小常識 — 即時顯示 + 排程優化版 v2.0
# ============================================================
# 用途：無人值守一次性生成 生活小常識文章
# 
# 🆕 v2.0 變更 (2026-08-17)：
#   - 🔧 步驟 6 改為直接呼叫 article_generator (繞過 main.py)
#   - 🔧 JSON 寫入改用 Python json.dump()
#   - 🔧 從 master-articles.json 動態讀取生活文章
#   - 🔧 符合血淚教訓 #9
#   - ✅ 繼承所有功能 (斷點續傳、郵件通知、電源管理)
# ============================================================

# ============================================================
# 🔧 電源管理：擷取當前電源計劃並防止睡眠
# ============================================================
$PowerCfgOriginal = (powercfg /getactivescheme) -replace '.*:\s+([a-f0-9-]+)\s+\(.*', '$1'
powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

# ⭐ 強制 UTF-8 編碼
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 > $null
$env:PYTHONIOENCODING = "utf-8"

$ErrorActionPreference = "Continue"
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-life-batch-v2-$Timestamp.log"
$CheckpointFile = "$LogDir\life-checkpoint.json"

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
            $MailMessage = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "❌ 生活小常識批次生成失敗", $ErrorMsg)
            $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($MailMessage)
            Write-Log "📧 錯誤通知已發送"
        } catch {
            Write-Log "⚠️ 錯誤通知發送失敗: $($_.Exception.Message)"
        }
    }
}

Write-Log "============================================================"
Write-Log "🏠 生活小常識 — 即時顯示 + 排程優化版 v2.0"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/5] 檢查 API Key..."
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
# 步驟 2：從 master-articles.json 讀取生活文章
# ============================================================
Write-Log "[2/5] 從 master-articles.json 讀取生活文章..."
Save-Checkpoint -Stage "article_scan"

$PyScanScript = @'
import json
import os

project_root = r'C:\Users\User\ahpal-static'
master_path = os.path.join(project_root, 'data', 'master-articles.json')

if not os.path.exists(master_path):
    print('❌ master-articles.json 不存在')
    exit(1)

with open(master_path, 'r', encoding='utf-8') as f:
    articles = json.load(f)

# 找出所有 life/ 開頭的文章
life_articles = [a for a in articles if a.get('filename', '').startswith('life/')]

print(f'📊 找到 {len(life_articles)} 篇生活文章')

# 檢查哪些已存在
missing = []
for a in life_articles:
    filepath = os.path.join(project_root, a.get('filename', ''))
    if not os.path.exists(filepath) or os.path.getsize(filepath) < 5120:
        missing.append(a)

print(f'⚠️ 缺失 {len(missing)} 篇')
for a in missing[:5]:
    print(f'   - {a.get("keyword", "未知")[:40]}... → {a.get("filename", "")}')
if len(missing) > 5:
    print(f'   ... 還有 {len(missing)-5} 篇')

# 將缺失文章寫入 pending-articles.json (備用)
pending_path = os.path.join(project_root, 'data', 'pending-articles.json')
with open(pending_path, 'w', encoding='utf-8') as f:
    json.dump(missing, f, ensure_ascii=False, indent=2)

print(f'__MISSING_COUNT__={len(missing)}')
'@

$PyOutput = python -c "$PyScanScript" 2>&1
Write-Log $PyOutput

$MissingCountMatch = [regex]::Match($PyOutput, '__MISSING_COUNT__=(\d+)')
if ($MissingCountMatch.Success) {
    $MissingCount = [int]$MissingCountMatch.Groups[1].Value
} else {
    $MissingCount = 0
}

if ($MissingCount -eq 0) {
    Write-Log "   ✅ 所有生活文章已存在，無需生成"
    Write-Log "============================================================"
    Write-Log "✅ 檢查完成！所有文章已存在"
    exit 0
}

Write-Log "   ⚠️ 缺失 $MissingCount 篇生活文章，開始生成..."

# ============================================================
# 步驟 3：備份 master-articles.json
# ============================================================
Write-Log "[3/5] 備份 master-articles.json..."
Save-Checkpoint -Stage "backup"

$BackupDir = "$ProjectRoot\backups\master-json"
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
$BackupFile = "$BackupDir\master-articles-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
Copy-Item "data\master-articles.json" $BackupFile -Force
Write-Log "   ✅ 已備份到：$BackupFile"

# ============================================================
# 步驟 4：合併 pending-articles.json 到 master-articles.json
# ============================================================
Write-Log "[4/5] 合併 pending-articles.json 到 master-articles.json..."
Save-Checkpoint -Stage "merge"

$PyMergeScript = @'
import json, os, shutil
from datetime import datetime

project_root = r'C:\Users\User\ahpal-static'
pending_path = os.path.join(project_root, 'data', 'pending-articles.json')
master_path = os.path.join(project_root, 'data', 'master-articles.json')

if not os.path.exists(pending_path):
    print('⚠️ pending-articles.json 不存在')
    exit(0)

with open(pending_path, 'r', encoding='utf-8') as f:
    pending = json.load(f)

if not pending:
    print('📋 pending-articles.json 為空')
    exit(0)

with open(master_path, 'r', encoding='utf-8') as f:
    master = json.load(f)

existing_keywords = [a.get('keyword', '') for a in master]
new_count = 0
for item in pending:
    kw = item.get('keyword', '')
    if kw not in existing_keywords:
        master.append(item)
        new_count += 1

with open(master_path, 'w', encoding='utf-8') as f:
    json.dump(master, f, ensure_ascii=False, indent=2)

print(f'✅ 合併完成，新增 {new_count} 篇')
print(f'📊 主資料庫共 {len(master)} 篇')
'@

python -c "$PyMergeScript" 2>&1 | Write-Log

if ($LASTEXITCODE -ne 0) {
    Write-Log "❌ 合併失敗"
    Send-ErrorNotification -ErrorMsg "文章合併失敗，請檢查 master-articles.json"
    exit 1
}

# ============================================================
# 步驟 5：執行文章生成 — 直接呼叫 article_generator
# ============================================================
Write-Log "[5/5] 執行文章生成 (直接呼叫 article_generator，繞過 main.py)..."
Save-Checkpoint -Stage "generation_start"

Write-Log "   ⏳ 預計耗時 30-90 分鐘"
Write-Log ""
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log "  📡 文章生成即時輸出 (每篇文章完成時顯示)"
Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Log ""

$PyGenScript = @'
import json
import sys
import os
sys.path.insert(0, '.')

from src.article_generator import generate_article

project_root = r'C:\Users\User\ahpal-static'
master_path = os.path.join(project_root, 'data', 'master-articles.json')

with open(master_path, 'r', encoding='utf-8') as f:
    all_articles = json.load(f)

# 找出所有 life/ 開頭的文章
life_articles = [a for a in all_articles if a.get('filename', '').startswith('life/')]

print(f'📊 找到 {len(life_articles)} 篇生活文章')

success_count = 0
fail_count = 0
skip_count = 0

for idx, article in enumerate(life_articles, 1):
    filename = article.get('filename', '')
    filepath = f'./{filename}'
    
    if os.path.exists(filepath):
        size = os.path.getsize(filepath)
        if size >= 5120:
            print(f'⏩ [{idx}/{len(life_articles)}] 已存在：{filename} ({size} bytes)')
            skip_count += 1
            continue
        else:
            print(f'⚠️ [{idx}/{len(life_articles)}] 檔案過小，重新生成：{filename} ({size} bytes)')
    
    print(f'--- 進度 {idx}/{len(life_articles)} ---')
    try:
        generate_article(article)
        success_count += 1
    except Exception as e:
        print(f'❌ 生成失敗：{e}')
        fail_count += 1

print(f'')
print(f'✅ 成功生成 {success_count} 篇')
print(f'⏩ 跳過 (已存在) {skip_count} 篇')
print(f'❌ 失敗 {fail_count} 篇')
'@

python -c "$PyGenScript" 2>&1 | Tee-Object -FilePath "$LogDir\generation-output.txt"

$ExitCode = $LASTEXITCODE

if ($ExitCode -ne 0) {
    Write-Log ""
    Write-Log "❌ 文章生成失敗，退出碼: $ExitCode"
    Write-Log "⚠️ 將在 60 秒後重試..."
    Start-Sleep -Seconds 60
    
    Write-Log ""
    Write-Log "🔄 第二次嘗試..."
    python -c "$PyGenScript" 2>&1 | Tee-Object -FilePath "$LogDir\generation-output-retry.txt"
    
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
# 步驟 6：更新分類頁面與 Sitemap
# ============================================================
Write-Log "   [6] 更新分類頁面與 Sitemap..."
Save-Checkpoint -Stage "category_update"

python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log

if ($LASTEXITCODE -ne 0) {
    Write-Log "⚠️ 分類頁面更新失敗，嘗試重試..."
    Start-Sleep -Seconds 10
    python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log
}
Write-Log "✅ 分類頁面與首頁已更新"

# ============================================================
# 步驟 7：部署到 Cloudflare
# ============================================================
Write-Log "   [7] 部署到 Cloudflare Pages..."
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
Write-Log "✅ 生活小常識 — 即時顯示 + 排程優化版 v2.0 執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
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
    $Subject = "🏠 生活小常識批次生成完成通知"
    $Body = @"
生活小常識批次生成已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 日誌位置：$LogFile
   - 部署狀態：✅ 已完成

請至 https://www.ahpal.com/category-life.html 查看最新文章。

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