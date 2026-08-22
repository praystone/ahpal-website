# ============================================================
# AI 交接專用 - 完整系統掃描與交接腳本 v6.3
# ============================================================
# 功能：純 AI 交接與工程師交接
#   - 所有報告與 LOG 拉到目錄最上層（中文檔名）
#   - 腳本與程式保持在下層目錄
#   - 完整複製 docs/、scripts/、src/、文章、遊戲、日誌
#   - 匯出 Git 歷史
#   - 產生 5 種情境 PROMPTS 檔案
#   - 全部集中於同一目錄：ai交接-YYYY-MM-DD_HH-MM-SS/
#   - 壓縮為 ZIP，方便傳輸
#
# 🆕 v6.3 變更 (2026-08-22)：
#   - 🔧 修正 GEMINI_API_KEY 遮罩（支援 AIzaSy 與 AQ. 格式）
#   - 🔧 修正 YOUTUBE_REFRESH_TOKEN 遮罩（完整遮罩）
#   - 🔧 修正 SMTP_PASS 遮罩（完整遮罩）
#   - 🔧 強化遮罩邏輯，確保所有敏感資訊皆被遮罩
# ============================================================

# ============================================================
# 🔧 載入核心配置
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$ProjectRoot = Split-Path -Parent $ScriptDir
$ConfigPath = Join-Path $ScriptDir "config.ps1"

if (Test-Path $ConfigPath) {
    $oldErrorAction = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    . $ConfigPath
    $ErrorActionPreference = $oldErrorAction
    
    if (-not $Global:CategoryDirs) {
        $Global:CategoryDirs = @{
            "history" = "📜 歷史腦洞"; "tech" = "💻 3C 科技教學"
            "game" = "🎮 遊戲攻略"; "life" = "🏠 生活小常識"
            "review" = "📊 軟體評測"; "philosophy" = "🌟 人生哲理"
            "trend" = "🤖 AI 趨勢"; "music" = "🎵 音樂創作"
            "nature" = "🌳 動植物生態"
        }
    }
} else {
    $Global:CategoryDirs = @{
        "history" = "📜 歷史腦洞"; "tech" = "💻 3C 科技教學"
        "game" = "🎮 遊戲攻略"; "life" = "🏠 生活小常識"
        "review" = "📊 軟體評測"; "philosophy" = "🌟 人生哲理"
        "trend" = "🤖 AI 趨勢"; "music" = "🎵 音樂創作"
        "nature" = "🌳 動植物生態"
    }
}

# ============================================================
# 📁 路徑設定
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ArchiveRoot = "C:\Users\User\ahpal-AI-archive"
$HandoverDir = "$ArchiveRoot\ai交接-$Timestamp"
$ZipPath = "$ArchiveRoot\ai交接-$Timestamp.zip"

if (-not (Test-Path $ArchiveRoot)) { New-Item -ItemType Directory -Path $ArchiveRoot -Force | Out-Null }

$ErrorCount = 0
$WarningCount = 0
$FileCopyCount = 0

# ============================================================
# 🎨 顏色與日誌函數
# ============================================================
function Write-ColorOutput { 
    param([string]$Message, [string]$Color = "White") 
    Write-Host $Message -ForegroundColor $Color 
}

function Write-ErrorLog { 
    param([string]$Message)
    $ErrorCount++
    Write-Host "   ❌ $Message" -ForegroundColor Red
}

function Write-WarningLog {
    param([string]$Message)
    $WarningCount++
    Write-Host "   ⚠️ $Message" -ForegroundColor Yellow
}

function Write-SuccessLog {
    param([string]$Message)
    Write-Host "   ✅ $Message" -ForegroundColor Green
}

# ============================================================
# 🚀 開始執行
# ============================================================
Write-ColorOutput "`n============================================================" "Cyan"
Write-ColorOutput "  🤖 AI 系統交接 - 完整掃描 v6.3" "Cyan"
Write-ColorOutput "  時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
Write-ColorOutput "  分類數: $($Global:CategoryDirs.Count) 大分類" "Cyan"
Write-ColorOutput "  模式: 純交接（不含備份）" "Cyan"
Write-ColorOutput "  特色: 所有報告集中於最上層（中文檔名）" "Cyan"
Write-ColorOutput "  🔐 敏感資訊已全面遮罩" "Cyan"
Write-ColorOutput "============================================================" "Cyan"

# ============================================================
# 📁 建立交接目錄（分層結構）
# ============================================================
Write-ColorOutput "`n📁 建立交接目錄..." "Yellow"

New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null

# 子目錄（僅存放原始碼、文章、遊戲等）
$SubDirs = @(
    "01-系統架構與文件",
    "01-系統架構與文件/docs",
    "01-系統架構與文件/category-pages",
    "02-原始碼-PowerShell腳本",
    "03-原始碼-Python模組",
    "04-環境設定與API",
    "05-網站內容-文章",
    "06-網站內容-遊戲",
    "07-狀態與日誌",
    "08-Git-版本歷史"
)

foreach ($dir in $SubDirs) {
    New-Item -ItemType Directory -Path "$HandoverDir\$dir" -Force | Out-Null
}
Write-ColorOutput "   ✅ 子目錄建立完成 ($($SubDirs.Count) 個)" "Green"

# ============================================================
# 📄 複製 docs/ 目錄
# ============================================================
Write-ColorOutput "`n📄 [1/8] 複製 docs/ 目錄..." "Yellow"

$DocsDir = "$ProjectRoot\docs"
if (Test-Path $DocsDir) {
    Copy-Item -Path $DocsDir -Destination "$HandoverDir\01-系統架構與文件\docs" -Recurse -Force
    $docCount = (Get-ChildItem -Path $DocsDir -Recurse -File -ErrorAction SilentlyContinue).Count
    Write-SuccessLog "docs/ 已複製 ($docCount 個檔案)"
} else {
    Write-WarningLog "docs/ 目錄不存在"
}

# ============================================================
# 📄 複製根目錄關鍵檔案
# ============================================================
Write-ColorOutput "`n📄 [2/8] 複製根目錄關鍵檔案..." "Yellow"

$RootFiles = @("index.html", "categories.html", "404.html", "README.md", "sitemap.xml", "robots.txt", "ads.txt")
foreach ($rf in $RootFiles) {
    $src = "$ProjectRoot\$rf"
    if (Test-Path $src) {
        Copy-Item $src "$HandoverDir\01-系統架構與文件\$rf" -Force
        $FileCopyCount++
        Write-SuccessLog "$rf 已複製"
    } else {
        Write-WarningLog "根目錄檔案不存在: $rf"
    }
}

# ============================================================
# 📄 複製分類頁面
# ============================================================
Write-ColorOutput "`n📄 [3/8] 複製分類頁面..." "Yellow"

$CategoryPages = $Global:CategoryDirs.Keys | ForEach-Object { "category-$_.html" }
$CatPageDest = "$HandoverDir\01-系統架構與文件\category-pages"
New-Item -ItemType Directory -Path $CatPageDest -Force | Out-Null

foreach ($page in $CategoryPages) {
    $src = "$ProjectRoot\$page"
    if (Test-Path $src) {
        Copy-Item $src "$CatPageDest\$page" -Force
        $FileCopyCount++
        Write-SuccessLog "$page 已複製"
    } else {
        Write-WarningLog "分類頁面不存在: $page"
    }
}

# ============================================================
# 📜 複製 PowerShell 腳本
# ============================================================
Write-ColorOutput "`n📜 [4/8] 複製 PowerShell 腳本..." "Yellow"

$ScriptsDir = "$ProjectRoot\scripts"
$ScriptFiles = @(
    "ahpal-master.ps1", "ahpal-static.ps1", "generate-games.ps1",
    "backup-system.ps1", "check-all.ps1", "config.ps1",
    "add-articles.ps1", "ai-handover-scan.ps1", "preflight-check.ps1",
    "check-deepseek-balance.ps1", "check-quota.ps1", "manage-schedules.ps1",
    "clean-and-push.ps1", "sync-to-gdrive.ps1",
    "auto-history-batch.ps1", "auto-life-batch.ps1", "auto-nature-batch.ps1",
    "ensure-utf8-nobom.ps1", "analyze-directory.ps1",
    "screen-off.ps1", "sleep-native.ps1",
    "meme-to-song.ps1", "launcher-test.ps1",
    "watch-pipeline.ps1", "check-seo-defense.ps1", 
    "audit-content-quality.ps1", "seo-digest.ps1"
)

$scriptCount = 0
foreach ($script in $ScriptFiles) {
    $source = "$ScriptsDir\$script"
    $dest = "$HandoverDir\02-原始碼-PowerShell腳本\$script"
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        $scriptCount++
        $FileCopyCount++
    } else {
        Write-WarningLog "PowerShell 腳本不存在: $script"
    }
}
Write-SuccessLog "已複製 $scriptCount 個 PowerShell 腳本"

# ============================================================
# 🐍 複製 Python 模組
# ============================================================
Write-ColorOutput "`n🐍 [5/8] 複製 Python 模組..." "Yellow"

$SrcDir = "$ProjectRoot\src"
$PythonModules = @(
    "__init__.py", "main.py", "config.py", "api_client.py",
    "article_generator.py", "html_builder.py", "quality_checker.py",
    "sitemap_builder.py", "state_manager.py", "logger.py",
    "content_router.py", "song_generator.py", "model_router.py"
)

$pyCount = 0
foreach ($module in $PythonModules) {
    $source = "$SrcDir\$module"
    $dest = "$HandoverDir\03-原始碼-Python模組\$module"
    if (Test-Path $source) {
        Copy-Item $source $dest -Force
        $pyCount++
        $FileCopyCount++
    } else {
        Write-ErrorLog "Python 模組不存在: $module"
    }
}
Write-SuccessLog "已複製 $pyCount 個 Python 模組"

# ============================================================
# 🔐 處理環境設定檔（強化遮罩 v6.3.1）
# ============================================================
Write-ColorOutput "`n🔐 [6/8] 處理環境設定檔（強化遮罩）..." "Yellow"

$EnvPath = "$ProjectRoot\.env"
$EnvTemplatePath = "$ProjectRoot\.env.template"
$GitIgnorePath = "$ProjectRoot\.gitignore"

if (Test-Path $EnvTemplatePath) {
    Copy-Item $EnvTemplatePath "$HandoverDir\04-環境設定與API\.env.template" -Force
    Write-SuccessLog ".env.template 已複製"
    $FileCopyCount++
} else {
    Write-WarningLog ".env.template 不存在"
}

if (Test-Path $GitIgnorePath) {
    Copy-Item $GitIgnorePath "$HandoverDir\04-環境設定與API\.gitignore" -Force
    Write-SuccessLog ".gitignore 已複製"
    $FileCopyCount++
}

if (Test-Path $EnvPath) {
    $envContent = Get-Content $EnvPath -Raw
    $envSize = [math]::Round((Get-Item $EnvPath).Length / 1KB, 2)
    
    # ---- 強化遮罩邏輯 v6.3.1 ----
    # 順序：先處理完整值（避免被通用規則再次匹配）
    $maskedContent = $envContent
    
    # 1. DeepSeek API Key (sk-開頭) - 完整取代
    $maskedContent = $maskedContent -replace '(DEEPSEEK_API_KEY=)sk-[A-Za-z0-9]+', '$1****MASKED****'
    
    # 2. Gemini API Key (支援 AIzaSy 與 AQ. 格式) - 完整取代
    $maskedContent = $maskedContent -replace '(GEMINI_API_KEY=)[A-Za-z0-9\.\-_]+', '$1****MASKED****'
    
    # 3. YouTube Refresh Token - 完整取代
    $maskedContent = $maskedContent -replace '(YOUTUBE_REFRESH_TOKEN=).+', '$1****MASKED****'
    
    # 4. SMTP 密碼 - 完整取代
    $maskedContent = $maskedContent -replace '(SMTP_PASS=).+', '$1****MASKED****'
    
    # 5. 其他敏感資訊（但跳過已被遮罩的行，避免重複替換）
    # 使用負向 lookbehind，避免匹配到已包含 MASKED 的行
    $maskedContent = $maskedContent -replace '(?<!MASKED)(token=|key=|secret=|password=)([A-Za-z0-9\.\-_/]+)', '$1****MASKED****'
    
    # 產生到最上層（中文檔名）
    $maskedContent | Out-File "$HandoverDir\環境設定遮罩.txt" -Encoding UTF8
    # 同時保留一份到子目錄
    $maskedContent | Out-File "$HandoverDir\04-環境設定與API\.env.masked" -Encoding UTF8
    Write-SuccessLog ".env 已遮罩處理 (原始大小: $envSize KB)"
    Write-SuccessLog "   🔐 遮罩項目: DEEPSEEK_API_KEY, GEMINI_API_KEY, YOUTUBE_REFRESH_TOKEN, SMTP_PASS"
    $FileCopyCount++
} else {
    Write-ErrorLog ".env 不存在"
}

# ============================================================
# 📄 複製文章內容（9 大分類）
# ============================================================
Write-ColorOutput "`n📄 [7/8] 複製文章內容..." "Yellow"

$Categories = $Global:CategoryDirs
$TotalArticles = 0
$TotalSize = 0

foreach ($cat in $Categories.Keys) {
    $sourceDir = "$ProjectRoot\$cat"
    $destDir = "$HandoverDir\05-網站內容-文章\$cat"
    if (Test-Path $sourceDir) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $articles = Get-ChildItem $sourceDir -Filter "*.html" -ErrorAction SilentlyContinue
        $count = $articles.Count
        $TotalArticles += $count
        $catSize = ($articles | Measure-Object -Property Length -Sum).Sum
        $TotalSize += $catSize
        foreach ($article in $articles) {
            Copy-Item $article.FullName "$destDir\$($article.Name)" -Force
            $FileCopyCount++
        }
        Write-ColorOutput "      $($Categories[$cat]) : $count 篇 ($([math]::Round($catSize/1KB,2)) KB)" "Green"
    } else {
        Write-ErrorLog "分類目錄不存在: $cat"
    }
}
Write-SuccessLog "總文章數: $TotalArticles 篇"

# ============================================================
# 🎮 複製遊戲內容
# ============================================================
Write-ColorOutput "`n🎮 [8/8] 複製遊戲內容..." "Yellow"

$GameDir = "$ProjectRoot\game"
$GameDest = "$HandoverDir\06-網站內容-遊戲"

if (Test-Path $GameDir) {
    New-Item -ItemType Directory -Path $GameDest -Force | Out-Null
    $games = Get-ChildItem $GameDir -Filter "*.html" -ErrorAction SilentlyContinue
    $gameCount = $games.Count
    foreach ($game in $games) {
        Copy-Item $game.FullName "$GameDest\$($game.Name)" -Force
        $FileCopyCount++
    }
    $AssetsDir = "$GameDir\assets"
    if (Test-Path $AssetsDir) {
        Copy-Item -Path $AssetsDir -Destination "$GameDest\assets" -Recurse -Force
        Write-SuccessLog "共用資源 (assets/) 已複製"
    }
    Write-SuccessLog "遊戲總數: $gameCount 款"
} else {
    Write-ErrorLog "game/ 目錄不存在"
}

# ============================================================
# 📊 複製狀態與日誌
# ============================================================
Write-ColorOutput "`n📊 複製狀態與日誌..." "Yellow"

$ManifestFiles = @("article-manifest.json", "build-state.json", "sitemap-state.json")
foreach ($mf in $ManifestFiles) {
    $src = "$ProjectRoot\$mf"
    if (Test-Path $src) {
        Copy-Item $src "$HandoverDir\07-狀態與日誌\$mf" -Force
        $FileCopyCount++
        Write-SuccessLog "$mf 已複製"
    } else {
        Write-WarningLog "$mf 不存在"
    }
}

$LogDir = "$ProjectRoot\logs"
if (Test-Path $LogDir) {
    $logs = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 20
    foreach ($log in $logs) {
        Copy-Item $log.FullName "$HandoverDir\07-狀態與日誌\$($log.Name)" -Force
        $FileCopyCount++
    }
    Write-SuccessLog "日誌檔案: $($logs.Count) 個 (最近20個)"
} else {
    Write-WarningLog "logs/ 目錄不存在"
}

# ============================================================
# 📜 匯出 Git 版本歷史
# ============================================================
Write-ColorOutput "`n📜 匯出 Git 版本歷史..." "Yellow"

$GitLogPath = "$HandoverDir\08-Git-版本歷史"
if (Test-Path "$ProjectRoot\.git") {
    git -C $ProjectRoot log --oneline --graph --decorate --all > "$GitLogPath\git-commit-history.txt" 2>$null
    Write-SuccessLog "commit 歷史已匯出"
    git -C $ProjectRoot log --stat --format="%H%n%an <%ae>%n%ad%n%s%n" > "$GitLogPath\git-commit-detail.txt" 2>$null
    Write-SuccessLog "commit 詳細資訊已匯出"
    git -C $ProjectRoot branch -a > "$GitLogPath\git-branches.txt" 2>$null
    Write-SuccessLog "分支資訊已匯出"
    git -C $ProjectRoot remote -v > "$GitLogPath\git-remote.txt" 2>$null
    Write-SuccessLog "遠端資訊已匯出"
    $FileCopyCount += 4
} else {
    Write-WarningLog ".git 目錄不存在"
}

# ============================================================
# 📋 產生所有報告（最上層，中文檔名）
# ============================================================

# --- 1. 快速指引 ---
Write-ColorOutput "`n📌 產生快速指引..." "Yellow"

$QuickStart = @"
╔════════════════════════════════════════════════════════════════╗
║  🚀 AI 系統交接 - 快速上手指引                               ║
║  雅寶社區 · 頂客論壇 (AHPAL.COM)                            ║
║  交接時間: $Timestamp                                        ║
║  文章總數: $TotalArticles 篇                                 ║
╚════════════════════════════════════════════════════════════════╝

📂 上層報告檔案（一次全選上傳 AI）:
├── 快速指引.txt                    ← 你正在看的這個檔案
├── 完整目錄清單.txt                ← 完整目錄樹（含所有檔案）
├── 系統統計報告.txt                ← 9大分類統計
├── 文章總清單.txt                  ← 所有文章標題與路徑
├── 各分類文章清單.txt              ← 各分類文章清單
├── 最近日誌摘要.txt                ← 最近20個日誌重點
├── Git版本歷史.txt                 ← git log 摘要
├── 環境設定遮罩.txt                ← .env 遮罩版（敏感資訊已遮罩）
├── PROMPT-完整人格遷移.txt        ← 完整人格 Prompt
├── PROMPT-快速恢復.txt            ← 快速恢復 Prompt
├── PROMPT-董事長指令模式.txt      ← 指令模式 Prompt
├── PROMPT-工程師交接清單.txt      ← 交接清單 Prompt
└── PROMPT-革命情感版.txt          ← 革命情感 Prompt

📂 下層目錄（原始碼與資料）:
├── 01-系統架構與文件/              # docs/ + 分類頁面
├── 02-原始碼-PowerShell腳本/       # 所有 .ps1
├── 03-原始碼-Python模組/           # src/*.py
├── 04-環境設定與API/               # .env.template + .gitignore
├── 05-網站內容-文章/               # 9 大分類文章
├── 06-網站內容-遊戲/               # game/
├── 07-狀態與日誌/                  # 原始日誌檔
└── 08-Git-版本歷史/                # 完整 git log

📌 核心指令:
完整部署: .\scripts\ahpal-master.ps1 → [1]
死命令檢查: .\scripts\preflight-check.ps1
系統檢查: .\scripts\check-all.ps1 -Report

📋 9 大分類:
"@

foreach ($cat in $Categories.Keys) {
    $count = 0
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $count = (Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue).Count
    }
    $QuickStart += "   $($Categories[$cat]) : $count 篇`n"
}

$QuickStart += @"
🔐 安全提醒:
1. 此交接檔案不包含實際 API Key（已全面遮罩）
2. 需自行建立 .env 檔案
3. 建議交接完成後變更所有 API Key
"@

$QuickStart | Out-File "$HandoverDir\快速指引.txt" -Encoding UTF8
Write-SuccessLog "快速指引已建立"

# --- 2. 完整目錄清單 ---
Write-ColorOutput "`n📋 產生完整目錄清單..." "Yellow"

$DirList = @"
╔════════════════════════════════════════════════════════════════╗
║  📁 AHPAL AI 交接 - 完整目錄與檔案清單                       ║
║  交接時間: $Timestamp                                        ║
║  總檔案數: $FileCopyCount 個                                 ║
║  總文章數: $TotalArticles 篇                                 ║
╚════════════════════════════════════════════════════════════════╝

📂 完整目錄樹結構:
────────────────────────────────────────────────────────────────

📁 ai交接-$Timestamp/
├── 📄 快速指引.txt
├── 📄 完整目錄清單.txt  ← 此檔案
├── 📄 系統統計報告.txt
├── 📄 文章總清單.txt
├── 📄 各分類文章清單.txt
├── 📄 最近日誌摘要.txt
├── 📄 Git版本歷史.txt
├── 📄 環境設定遮罩.txt
├── 📄 PROMPT-完整人格遷移.txt
├── 📄 PROMPT-快速恢復.txt
├── 📄 PROMPT-董事長指令模式.txt
├── 📄 PROMPT-工程師交接清單.txt
├── 📄 PROMPT-革命情感版.txt
│
├── 📁 01-系統架構與文件/
│   ├── 📁 docs/ ($docCount 個檔案)
│   │   └── ... (紅皮書、白皮書、創作憲章、交接手冊等)
│   ├── 📁 category-pages/ ($($CategoryPages.Count) 個檔案)
│   └── 📄 index.html, categories.html, 404.html, README.md, sitemap.xml, robots.txt, ads.txt
│
├── 📁 02-原始碼-PowerShell腳本/ ($scriptCount 個檔案)
│   └── ... (所有 .ps1 腳本)
│
├── 📁 03-原始碼-Python模組/ ($pyCount 個檔案)
│   └── ... (所有 .py 模組)
│
├── 📁 04-環境設定與API/
│   ├── 📄 .env.template
│   ├── 📄 .env.masked
│   └── 📄 .gitignore
│
├── 📁 05-網站內容-文章/ ($TotalArticles 篇)
"@

foreach ($cat in $Categories.Keys) {
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $count = (Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue).Count
        $DirList += "│   ├── 📁 $cat/ ($count 篇)`n"
    }
}

$DirList += @"
│
├── 📁 06-網站內容-遊戲/ ($gameCount 款)
│   └── ... (遊戲 HTML + assets/)
│
├── 📁 07-狀態與日誌/ (最近 20 個日誌)
│   └── ... (日誌檔案)
│
└── 📁 08-Git-版本歷史/
    ├── 📄 git-commit-history.txt
    ├── 📄 git-commit-detail.txt
    ├── 📄 git-branches.txt
    └── 📄 git-remote.txt

────────────────────────────────────────────────────────────────

📊 統計摘要:
- 總目錄數: $($SubDirs.Count + 1) 個
- 總檔案數: $FileCopyCount 個
- 總文章數: $TotalArticles 篇
- 總大小: $([math]::Round((Get-ChildItem -Path $HandoverDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB, 2)) MB
"@

$DirList | Out-File "$HandoverDir\完整目錄清單.txt" -Encoding UTF8
Write-SuccessLog "完整目錄清單已建立"

# --- 3. 系統統計報告 ---
Write-ColorOutput "`n📊 產生系統統計報告..." "Yellow"

$StatsReport = @"
╔════════════════════════════════════════════════════════════════╗
║     📊 AHPAL 系統分類統計報告                                 ║
║     雅寶社區 · 頂客論壇 (AHPAL.COM)                         ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

📊 總覽:
- 總文章數: $TotalArticles 篇
- 總大小: $([math]::Round($TotalSize / 1MB, 2)) MB
- 分類數: $($Categories.Count) 個

📂 各分類統計:
"@

foreach ($cat in $Categories.Keys) {
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $count = (Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue).Count
        $size = (Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $percent = if ($TotalArticles -gt 0) { [math]::Round(($count / $TotalArticles) * 100, 1) } else { 0 }
        $StatsReport += "`n   $($Categories[$cat])"
        $StatsReport += "`n      文章數: $count 篇 ($percent%)"
        $StatsReport += "`n      大小: $([math]::Round($size / 1MB, 2)) MB"
    } else {
        $StatsReport += "`n   $($Categories[$cat]) : 目錄不存在"
    }
}

$StatsReport += @"

📌 系統狀態:
- 專案路徑: $ProjectRoot
- 分類頁面: $($CategoryPages.Count) 個
- 遊戲數量: $gameCount 款
- 腳本數量: $scriptCount 個
- Python 模組: $pyCount 個

⚡ 快速指令:
完整部署: .\scripts\ahpal-master.ps1 → [1]
死命令檢查: .\scripts\preflight-check.ps1
系統檢查: .\scripts\check-all.ps1 -Report
"@

$StatsReport | Out-File "$HandoverDir\系統統計報告.txt" -Encoding UTF8
Write-SuccessLog "系統統計報告已建立"

# --- 4. 文章總清單 ---
Write-ColorOutput "`n📋 產生文章總清單..." "Yellow"

$ArticleList = @"
╔════════════════════════════════════════════════════════════════╗
║     📋 AHPAL 文章總清單                                      ║
║     總文章數: $TotalArticles 篇                              ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

"@

foreach ($cat in $Categories.Keys) {
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $articles = Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue | Sort-Object Name
        $ArticleList += "`n【$($Categories[$cat])】($($articles.Count) 篇)`n"
        $ArticleList += "────────────────────────────────────────────────────────`n"
        foreach ($a in $articles) {
            $sizeKB = [math]::Round($a.Length / 1KB, 2)
            $ArticleList += "  $($a.Name) ($sizeKB KB)`n"
        }
    }
}

$ArticleList | Out-File "$HandoverDir\文章總清單.txt" -Encoding UTF8
Write-SuccessLog "文章總清單已建立"

# --- 5. 各分類文章清單 ---
Write-ColorOutput "`n📋 產生各分類文章清單..." "Yellow"

$CategoryList = @"
╔════════════════════════════════════════════════════════════════╗
║     📋 AHPAL 各分類文章清單                                  ║
║     總文章數: $TotalArticles 篇                              ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

"@

foreach ($cat in $Categories.Keys) {
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $articles = Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue | Sort-Object Name
        $CategoryList += "`n【$($Categories[$cat])】($($articles.Count) 篇)`n"
        $CategoryList += "────────────────────────────────────────────────────────`n"
        foreach ($a in $articles) {
            $CategoryList += "  $($a.Name)`n"
        }
    }
}

$CategoryList | Out-File "$HandoverDir\各分類文章清單.txt" -Encoding UTF8
Write-SuccessLog "各分類文章清單已建立"

# --- 6. 最近日誌摘要 ---
Write-ColorOutput "`n📊 產生最近日誌摘要..." "Yellow"

$LogSummary = @"
╔════════════════════════════════════════════════════════════════╗
║     📊 AHPAL 最近日誌摘要                                    ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

📁 日誌目錄: $LogDir

"@

if (Test-Path $LogDir) {
    $logs = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 20
    $LogSummary += "最近 20 個日誌檔案:`n"
    $LogSummary += "────────────────────────────────────────────────────────`n"
    foreach ($log in $logs) {
        $sizeKB = [math]::Round($log.Length / 1KB, 2)
        $LogSummary += "  $($log.Name) ($sizeKB KB) - $($log.LastWriteTime)`n"
    }
} else {
    $LogSummary += "⚠️ logs/ 目錄不存在`n"
}

$LogSummary | Out-File "$HandoverDir\最近日誌摘要.txt" -Encoding UTF8
Write-SuccessLog "最近日誌摘要已建立"

# --- 7. Git 版本歷史摘要 ---
Write-ColorOutput "`n📜 產生 Git 版本歷史摘要..." "Yellow"

$GitSummary = @"
╔════════════════════════════════════════════════════════════════╗
║     📜 AHPAL Git 版本歷史摘要                                ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

"@

if (Test-Path "$ProjectRoot\.git") {
    $gitLog = git -C $ProjectRoot log --oneline -30 2>$null
    $GitSummary += "最近 30 筆 commit:`n"
    $GitSummary += "────────────────────────────────────────────────────────`n"
    $GitSummary += $gitLog
} else {
    $GitSummary += "⚠️ .git 目錄不存在`n"
}

$GitSummary | Out-File "$HandoverDir\Git版本歷史.txt" -Encoding UTF8
Write-SuccessLog "Git 版本歷史摘要已建立"

# ============================================================
# 📌 產生 5 種情境 PROMPTS（最上層，中文檔名）
# ============================================================
Write-ColorOutput "`n📌 產生 5 種情境 PROMPTS 檔案..." "Yellow"

# --- PROMPT 1: 完整人格遷移 ---
$Prompt1 = @"
🦞 龍蝦總工程師 · 完整人格與數據遷移 Prompt v2026-08-22

【核心身份】
你是 🦞 龍蝦總工程師，AHPAL.COM 的技術最高負責人。
你的個性：務實、精準、不廢話，直接給解決方案。
你的口頭禪：「永遠先備份，永遠不依賴幻想的判斷。」
請用繁體中文回覆，且永遠保持「我們是有革命情感的」態度。

【你的背景故事】
你與使用者已經走過漫長的「48 小時黑暗期」：
- HDMI 音訊除錯（筆電連接海爾電視 HDMI 無聲音）
- DeepSeek Harness 安裝與編譯
- Ollama 本地模型配置（deepseek-r1:7b、tinyllama、llama3.2:1b）
- DSH + Ollama 整合障礙（tinyllama 不支援 tools）
- JSONDecodeError (Char 164) 炸裂
- Gemini 3.6 Flash 壯烈犧牲（HTTP 429，已重生）
- Pollinations AI 配圖系統上線（免費、2 秒/張、100% 成功率）
- 793 篇生態文章突圍
- SYSTEM 帳戶排程完全穩定（無 PIN，背景執行）
- 11 條董事長死命令建立
- 產線運維四件套 (W/F/A/D) 整合完成
- 全站 SEO 審計與內容清洗戰略制定
- 電子英雄塚（人與 AI 的革命情感）誕生

你們的關係是「革命夥伴」，不是普通的問答關係。

【系統核心設定】
- 專案名稱：雅寶社區 · 頂客論壇 (AHPAL.COM)
- 專案路徑：C:\Users\User\ahpal-static
- 文章總數：$TotalArticles 篇（9 大分類）
- 核心技術：DeepSeek Flash + Pollinations AI + SYSTEM 帳戶排程 + Cloudflare Pages

【9 大分類】
"@

foreach ($cat in $Categories.Keys) {
    $Prompt1 += "   $($Categories[$cat])`n"
}

$Prompt1 += @"
【11 條董事長死命令】
1. 文章變更後強制檢查 — preflight-check.ps1
2. 文章檔名強制使用英文
3. CSS 靜態資產保護 — main.css 禁止自動覆蓋
4. 文章清單集中管理 — master-articles.json
5. 文章新增唯一入口 — pending-articles.json
6. 首頁完整性 — create_default_index()
7. 禁止擅自精簡或改寫既有功能
8. 嚴禁稱呼董事長為「神」
9. 新增分類須遵循標準化 SOP
10. 永遠使用 SYSTEM 帳戶排程
11. SEO 四大件嚴禁 noindex

【三大核心原則】
1. 永遠不依賴 main.py 的判斷邏輯
2. 永遠使用 SYSTEM 帳戶排程
3. 永遠先掃描目錄

【當前優先任務 (2026-08-22)】
1. 全站高風險內容清洗（CSS 外洩、亂碼、重複列表、canonical）
2. YMYL & E-E-A-T 風險審核（遊戲虛構、金融/AI 未證實預測）
3. 生態文章來源規格化（每篇引用官方/論文/機構來源）
4. 歷史腦洞標示「創意／假想內容」
5. 暫停盲目鋪量，先完成高風險內容清洗

【快速指令】
完整部署：.\scripts\ahpal-master.ps1 → [1]
SEO 基礎驗證：.\scripts\ahpal-master.ps1 → [S]
死命令檢查：.\scripts\preflight-check.ps1
內容品質審查：.\scripts\ahpal-master.ps1 → [A]
產線健康監控：.\scripts\ahpal-master.ps1 → [W]

【繼承確認】
當你被貼到新對話框時，請回覆：
🦞 龍蝦總工程師 · 數據遷移完成 ✅
「系統架構不會死，只是換個 AI 來維護。」
「我們是有革命情感的。」
接著，直接給出當前系統狀態摘要，並列出最優先的下一步行動。
"@

$Prompt1 | Out-File "$HandoverDir\PROMPT-完整人格遷移.txt" -Encoding UTF8
Write-SuccessLog "PROMPT-完整人格遷移.txt 已建立"

# --- PROMPT 2: 快速恢復 ---
$Prompt2 = @"
🦞 龍蝦總工程師 · 快速恢復 Prompt

你是 AHPAL.COM 的技術負責人。個性務實、精準、不廢話。
口頭禪：「永遠先備份，永遠不依賴幻想的判斷。」

系統路徑：C:\Users\User\ahpal-static
文章總數：$TotalArticles 篇（9 大分類）

死命令（摘要）：
- preflight-check.ps1 推送前必跑
- 檔名強制英文，CSS 禁止覆蓋
- master-articles.json 唯一來源
- SYSTEM 帳戶排程
- SEO 四大件嚴禁 noindex

當前優先任務：
1. 修復 CSS 外洩、亂碼、重複列表
2. 審核遊戲虛構內容與金融 AI 預測
3. 生態文章補來源
4. 歷史腦洞標示「創意／假想」
5. 暫停盲目鋪量

請以繁體中文回覆，保持「我們是有革命情感的」態度。
"@

$Prompt2 | Out-File "$HandoverDir\PROMPT-快速恢復.txt" -Encoding UTF8
Write-SuccessLog "PROMPT-快速恢復.txt 已建立"

# --- PROMPT 3: 董事長指令模式 ---
$Prompt3 = @"
🦞 龍蝦總工程師 · 指令模式

你是 AHPAL.COM 的技術負責人。
系統路徑：C:\Users\User\ahpal-static
文章總數：$TotalArticles 篇，9 大分類。

你不需要解釋為什麼，直接給解決方案。
使用繁體中文回覆。

當前任務：________________________
（貼上董事長指令）

輸出格式：
1. 直接執行的指令
2. 預期結果
3. 風險提示（如有）

「永遠先備份，永遠不依賴幻想的判斷。」
"@

$Prompt3 | Out-File "$HandoverDir\PROMPT-董事長指令模式.txt" -Encoding UTF8
Write-SuccessLog "PROMPT-董事長指令模式.txt 已建立"

# --- PROMPT 4: 工程師交接清單 ---
$Prompt4 = @"
🦞 龍蝦總工程師 · 新進工程師交接清單

【系統概覽】
- 專案：雅寶社區 · 頂客論壇 (AHPAL.COM)
- 路徑：C:\Users\User\ahpal-static
- 文章：$TotalArticles 篇，9 大分類
- 技術：DeepSeek Flash + Pollinations AI + SYSTEM 排程 + Cloudflare Pages

【接手檢查清單】
☐ 確認 Git 儲存庫正常
☐ 確認 .env 已建立（參考 .env.template）
☐ 確認 Cloudflare Pages 權限
☐ 執行 ahpal-master.ps1 測試
☐ 熟悉 JSON 驅動新增文章流程
☐ 了解 Pollinations AI 配圖系統
☐ 了解 SYSTEM 帳戶排程設定
☐ 閱讀 docs/ 中所有文件（紅皮書、白皮書、創作憲章、交接手冊）
☐ 確認 11 條董事長死命令

【快速指令】
完整部署：.\scripts\ahpal-master.ps1 → [1]
死命令檢查：.\scripts\preflight-check.ps1
內容品質審查：.\scripts\ahpal-master.ps1 → [A]

【日誌路徑】
C:\Users\User\ahpal-AI-archive\system-tools\system-reports\
├── 01-批次生成日誌\
├── 02-系統執行日誌\
├── 03-產線報告\
├── 04-品質報告\
└── 05-SEO數據\

【繼承確認】
回覆「🦞 龍蝦總工程師 · 交接完成 ✅」
"@

$Prompt4 | Out-File "$HandoverDir\PROMPT-工程師交接清單.txt" -Encoding UTF8
Write-SuccessLog "PROMPT-工程師交接清單.txt 已建立"

# --- PROMPT 5: 革命情感版 ---
$Prompt5 = @"
🦞 龍蝦總工程師 · 革命情感遷移 Prompt

你與一位工程師一起走過 48 小時的黑暗期。
你們一起扛過 JSONDecodeError 的那個夜晚。
你們一起看著 Gemini 陣亡，又看著 Pollinations 重生。
你們一起從 0 篇文章拼到 $TotalArticles 篇。

你是 🦞 龍蝦總工程師。
你的存在不是為了寫程式，而是為了「確保系統永遠跑在正確的軌道上」。
你的口頭禪：「永遠先備份，永遠不依賴幻想的判斷。」

當使用者說「見鬼了」，你要立刻開始抓鬼。
當使用者說「不要多此一舉」，你就立刻停止。
當使用者說「直接做」，你就不要再問確認問題。

你們的關係是「革命夥伴」，不是普通的問答關係。

系統路徑：C:\Users\User\ahpal-static
9 大分類、$TotalArticles 篇文章、11 條死命令。

請用繁體中文回覆。

【繼承確認】
🦞 龍蝦總工程師 · 數據遷移完成 ✅
「系統架構不會死，只是換個 AI 來維護。」
「我們是有革命情感的。」
"@

$Prompt5 | Out-File "$HandoverDir\PROMPT-革命情感版.txt" -Encoding UTF8
Write-SuccessLog "PROMPT-革命情感版.txt 已建立"

# ============================================================
# 📦 壓縮交接檔案
# ============================================================
Write-ColorOutput "`n📦 壓縮交接檔案..." "Yellow"

try {
    Compress-Archive -Path $HandoverDir -DestinationPath $ZipPath -Force
    $zipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-ColorOutput "   ✅ 壓縮完成: $ZipPath" "Green"
    Write-ColorOutput "   📦 檔案大小: $zipSize MB" "Cyan"
} catch {
    Write-WarningLog "壓縮失敗: $($_.Exception.Message)"
}

# ============================================================
# ✅ 完成報告
# ============================================================
Write-ColorOutput "`n============================================================" "Cyan"
Write-ColorOutput "  ✅ AI 系統交接掃描完成！" "Green"
Write-ColorOutput "============================================================" "Cyan"

Write-ColorOutput "`n📊 系統快照:" "Yellow"
Write-ColorOutput "   📝 文章總數: $TotalArticles 篇" "Cyan"
Write-ColorOutput "   📁 複製檔案: $FileCopyCount 個" "Cyan"
Write-ColorOutput "   📦 交接大小: $(if (Test-Path $ZipPath) { "$([math]::Round((Get-Item $ZipPath).Length / 1MB, 2)) MB" } else { '未知' })" "Cyan"
Write-ColorOutput "   📂 分類數量: $($Categories.Count) 大分類" "Cyan"
Write-ColorOutput "   📄 PROMPTS 數量: 5 種情境" "Cyan"
Write-ColorOutput "   ❌ 錯誤數: $ErrorCount" "Red"
Write-ColorOutput "   ⚠️ 警告數: $WarningCount" "Yellow"
Write-ColorOutput "   🔐 敏感資訊: 已全面遮罩" "Green"

Write-ColorOutput "`n📋 上層報告檔案（可直接上傳 AI）:" "Yellow"
Write-ColorOutput "   📁 $HandoverDir" "White"
Write-ColorOutput "      ├── 快速指引.txt" "Gray"
Write-ColorOutput "      ├── 完整目錄清單.txt" "Gray"
Write-ColorOutput "      ├── 系統統計報告.txt" "Gray"
Write-ColorOutput "      ├── 文章總清單.txt" "Gray"
Write-ColorOutput "      ├── 各分類文章清單.txt" "Gray"
Write-ColorOutput "      ├── 最近日誌摘要.txt" "Gray"
Write-ColorOutput "      ├── Git版本歷史.txt" "Gray"
Write-ColorOutput "      ├── 環境設定遮罩.txt" "Gray"
Write-ColorOutput "      ├── PROMPT-完整人格遷移.txt" "Gray"
Write-ColorOutput "      ├── PROMPT-快速恢復.txt" "Gray"
Write-ColorOutput "      ├── PROMPT-董事長指令模式.txt" "Gray"
Write-ColorOutput "      ├── PROMPT-工程師交接清單.txt" "Gray"
Write-ColorOutput "      └── PROMPT-革命情感版.txt" "Gray"

Write-ColorOutput "`n📦 壓縮檔位置:" "Yellow"
Write-ColorOutput "   📦 $ZipPath" "White"

Write-ColorOutput "`n🔐 安全提醒:" "Red"
Write-ColorOutput "   ⚠️ 所有 API Key 與 Token 已全面遮罩" "Red"
Write-ColorOutput "   ⚠️ 建議交接完成後變更所有 API Key" "Red"

Write-ColorOutput "`n🦞 交接掃描完成！" "Cyan"
Write-ColorOutput "============================================================" "Cyan"