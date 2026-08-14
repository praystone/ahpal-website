# ============================================================
# 歷史腦洞 20 篇 — 全自動夜間批次產線 v1.0
# ============================================================
# 用途：無人值守一次性生成 20 篇歷史腦洞文章
# 執行時間：2026-08-15 03:00 AM
# 執行方式：.\scripts\auto-history-batch.ps1
# ============================================================

# 防止休眠/睡眠
$ErrorActionPreference = "Continue"

# 切換至專案目錄
$ProjectRoot = "C:\Users\User\ahpal-static"
Set-Location $ProjectRoot

# ============================================================
# 設定日誌
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$LogDir = "$ProjectRoot\logs"
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
$LogFile = "$LogDir\auto-history-batch-$Timestamp.log"

function Write-Log {
    param([string]$Message)
    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Entry = "[$Time] $Message"
    Write-Host $Entry
    Add-Content -Path $LogFile -Value $Entry -Encoding UTF8
}

Write-Log "============================================================"
Write-Log "📜 歷史腦洞 20 篇 — 全自動夜間批次產線 v1.0"
Write-Log "⏰ 啟動時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "============================================================"

# ============================================================
# 步驟 1：檢查 API Key
# ============================================================
Write-Log "[1/6] 檢查 API Key..."

$DeepSeekKey = [Environment]::GetEnvironmentVariable("DEEPSEEK_API_KEY")
if (-not $DeepSeekKey) {
    Write-Log "❌ DEEPSEEK_API_KEY 未設定，嘗試從 .env 載入..."
    if (Test-Path ".env") {
        Get-Content ".env" | ForEach-Object {
            if ($_ -match '^DEEPSEEK_API_KEY=(.+)$') {
                [Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", $Matches[1])
                Write-Log "✅ DEEPSEEK_API_KEY 已從 .env 載入"
            }
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
# 步驟 2：建立 20 篇文章 JSON
# ============================================================
Write-Log "[2/6] 建立 20 篇文章 JSON..."

$jsonContent = @'
[
  {
    "keyword": "當秦始皇拿到全中國地圖與高德導航：歷史穿越的黑色幽默",
    "category": "📜 歷史腦洞",
    "filename": "history/qin-shi-huang-gaode-navigation.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "三國普通農民視角：今天曹操來了，明天劉備又來了",
    "category": "📜 歷史腦洞",
    "filename": "history/three-kingdoms-peasant-perspective.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "紫微星與破軍星之爭：楚漢相爭背後的天界局",
    "category": "📜 歷史腦洞",
    "filename": "history/ziwei-star-chu-han-war.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "穿越到秦朝當兵：如何靠考取「爵位」活下來？",
    "category": "📜 歷史腦洞",
    "filename": "history/time-travel-qin-dynasty-soldier.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "諸葛亮使用 AI 算力預測北方天氣與出師表：科幻三國",
    "category": "📜 歷史腦洞",
    "filename": "history/zhuge-liang-ai-weather-forecast.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "蜀漢五虎將：下凡渡劫的五方神獸",
    "category": "📜 歷史腦洞",
    "filename": "history/five-tiger-generals-reincarnation.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "如果韓信擁有現代電競的微操視角：兵仙的極限操作",
    "category": "📜 歷史腦洞",
    "filename": "history/han-xin-esports-micro-operation.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "長城背後的「天界監獄」：秦始皇為何要築牆鎮壓龍脈？",
    "category": "📜 歷史腦洞",
    "filename": "history/great-wall-celestial-prison.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "三國英雄渡劫錄：諸葛亮六出祁山與天機星的命數",
    "category": "📜 歷史腦洞",
    "filename": "history/three-kingdoms-heroes-tribulation.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "假如趙高是 AI：指鹿為馬的背後竟是一場系統錯亂",
    "category": "📜 歷史腦洞",
    "filename": "history/zhao-gao-ai-system-glitch.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "項羽不肯過江東：如果當年他搭上高鐵，歷史會改寫嗎？",
    "category": "📜 歷史腦洞",
    "filename": "history/xiang-yu-high-speed-rail.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "劉邦的「大風起兮雲飛揚」：一個流氓皇帝的 KTV 點歌單",
    "category": "📜 歷史腦洞",
    "filename": "history/liu-bang-ktv-playlist.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "曹操的頭痛不是病：華佗如果開刀，三國會提前結束？",
    "category": "📜 歷史腦洞",
    "filename": "history/cao-cao-headache-surgery.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "司馬懿的忍者哲學：裝病裝了十幾年，就為了那一場高平陵",
    "category": "📜 歷史腦洞",
    "filename": "history/sima-yi-ninja-philosophy.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "關羽的青龍偃月刀其實是「冷兵器界的 iPhone」？",
    "category": "📜 歷史腦洞",
    "filename": "history/guan-yu-green-dragon-saber.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "如果三國有 Line 群組：曹操、劉備、孫權的聊天紀錄",
    "category": "📜 歷史腦洞",
    "filename": "history/three-kingdoms-line-group-chat.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "諸葛亮的「空城計」其實是司馬懿故意放水？職場潛規則",
    "category": "📜 歷史腦洞",
    "filename": "history/empty-city-strategy-workplace.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "三國時代的「公關災難」：曹操殺呂伯奢的危機處理",
    "category": "📜 歷史腦洞",
    "filename": "history/cao-cao-crisis-management.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "古代公務員考試：漢代的「察舉制」其實比聯考還難？",
    "category": "📜 歷史腦洞",
    "filename": "history/han-dynasty-civil-service-exam.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  },
  {
    "keyword": "如果你穿越到赤壁之戰前夕，該怎麼用現代知識活下去？",
    "category": "📜 歷史腦洞",
    "filename": "history/red-cliff-survival-guide.html",
    "use_responses_api": true,
    "enable_reasoning": true,
    "enable_search": false
  }
]
'@

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText("$ProjectRoot\data\pending-articles.json", $jsonContent, $utf8NoBom)
Write-Log "✅ 20 篇文章 JSON 已寫入 (UTF-8 無 BOM)"

# ============================================================
# 步驟 3：執行 add-articles.ps1
# ============================================================
Write-Log "[3/6] 執行 add-articles.ps1 ..."

$AddResult = & "$ProjectRoot\scripts\add-articles.ps1" -Force 2>&1
Write-Log $AddResult

if ($LASTEXITCODE -ne 0) {
    Write-Log "❌ add-articles.ps1 執行失敗，退出碼: $LASTEXITCODE"
    exit 1
}
Write-Log "✅ add-articles.ps1 執行完成"

# ============================================================
# 步驟 4：執行文章生成
# ============================================================
Write-Log "[4/6] 執行文章生成 (python src/main.py --force deepseek)..."

# 使用 Start-Process 捕獲完整輸出
$Process = Start-Process -FilePath "python" -ArgumentList "src/main.py --force deepseek" -Wait -PassThru -NoNewWindow -RedirectStandardOutput "$LogDir\main-output.txt" -RedirectStandardError "$LogDir\main-error.txt"

$MainOutput = Get-Content "$LogDir\main-output.txt" -Raw -ErrorAction SilentlyContinue
$MainError = Get-Content "$LogDir\main-error.txt" -Raw -ErrorAction SilentlyContinue

Write-Log $MainOutput
if ($MainError) { Write-Log "⚠️ 錯誤輸出: $MainError" }

if ($Process.ExitCode -ne 0) {
    Write-Log "❌ 文章生成失敗，退出碼: $($Process.ExitCode)"
    exit 1
}
Write-Log "✅ 文章生成完成"

# ============================================================
# 步驟 5：更新分類頁面與 Sitemap
# ============================================================
Write-Log "[5/6] 更新分類頁面與 Sitemap..."

python -c "from src.html_builder import generate_category_pages, generate_categories_page, create_default_index; generate_category_pages(); generate_categories_page(); create_default_index()" 2>&1 | Out-String | Write-Log

Write-Log "✅ 分類頁面與首頁已更新"

# ============================================================
# 步驟 6：部署到 Cloudflare
# ============================================================
Write-Log "[6/6] 部署到 Cloudflare Pages..."

$DeployResult = & npx wrangler pages deploy . --project-name=ahpal-pages 2>&1
Write-Log $DeployResult

if ($LASTEXITCODE -ne 0) {
    Write-Log "❌ 部署失敗，退出碼: $LASTEXITCODE"
    Write-Log "⚠️ 將在 10 分鐘後重試部署..."

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
Write-Log "✅ 歷史腦洞 20 篇 — 全自動產線執行完畢！"
Write-Log "📅 完成時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "📊 預期文章數: 20 篇"
Write-Log "📁 日誌位置: $LogFile"
Write-Log "============================================================"

# 寄送完成通知 (透過 Gmail)
Write-Log "📧 寄送完成通知..."

$SmtpUser = [Environment]::GetEnvironmentVariable("SMTP_USER")
$SmtpPass = [Environment]::GetEnvironmentVariable("SMTP_PASS")
$ToEmail = [Environment]::GetEnvironmentVariable("SMTP_TO")

if ($SmtpUser -and $SmtpPass -and $SmtpUser -ne "你的Gmail帳號@gmail.com") {
    $Subject = "🦞 歷史腦洞 20 篇 — 自動產線完成通知"
    $Body = @"
歷史腦洞 20 篇全自動產線已於 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') 完成！

📊 執行摘要：
   - 文章數量：20 篇
   - 日誌位置：$LogFile
   - 部署狀態：✅ 已完成

請至 https://www.ahpal.com/history/ 查看最新文章。

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