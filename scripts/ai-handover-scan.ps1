# ============================================================
# AI 交接專用 - 完整系統掃描與備份腳本 v5.0
# 修復：Write-Host 語法錯誤
# 優化：
#   - 🆕 完整支援 9 大分類 (history, tech, game, life, review, philosophy, trend, music, nature)
#   - 🆕 新增 12 個自動化腳本
#   - 🆕 統計總文章數時包含所有分類
#   - 🆕 自動偵測並複製分類頁面 (category-*.html)
#   - 🆕 優化日誌輸出格式
#   - 🆕 加入進度顯示
# ============================================================

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ProjectRoot = "C:\Users\User\ahpal-static"
$BackupRoot = "C:\Users\User\ahpal-backup"
$ArchiveRoot = "C:\Users\User\ahpal-AI-archive"

if (-not (Test-Path $ArchiveRoot)) { New-Item -ItemType Directory -Path $ArchiveRoot -Force | Out-Null }

$HandoverDir = "$ArchiveRoot\ai交接-$Timestamp"
$ZipPath = "$ArchiveRoot\ai交接-$Timestamp.zip"

$ErrorCount = 0
$WarningCount = 0
$FileCopyCount = 0

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-ErrorLog {
    param([string]$Message)
    $ErrorCount++
    Write-Host "   ❌ $Message" -ForegroundColor Red
    Add-Content -Path "$HandoverDir\error-log.txt" -Value "[ERROR] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

function Write-WarningLog {
    param([string]$Message)
    $WarningCount++
    Write-Host "   ⚠️ $Message" -ForegroundColor Yellow
    Add-Content -Path "$HandoverDir\warning-log.txt" -Value "[WARNING] $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

Write-ColorOutput "`n============================================================" "Cyan"
Write-ColorOutput "  🤖 AI 系統交接 - 完整掃描與備份 v5.0" "Cyan"
Write-ColorOutput "  時間: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "Cyan"
Write-ColorOutput "============================================================" "Cyan"

Write-ColorOutput "`n📁 建立交接目錄..." "Yellow"
New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null
Write-ColorOutput "   ✅ 交接目錄: $HandoverDir" "Green"

$SubDirs = @(
    "01-系統架構與文件", "02-原始碼-PowerShell腳本", "03-原始碼-Python模組",
    "04-環境設定與API", "05-網站內容-文章", "06-網站內容-遊戲",
    "07-狀態與日誌", "08-備份檔案", "09-分析報告",
    "10-自動化工具", "11-資料與設定", "12-Git-版本歷史", "13-圖片資源"
)

foreach ($dir in $SubDirs) {
    New-Item -ItemType Directory -Path "$HandoverDir\$dir" -Force | Out-Null
}
Write-ColorOutput "   ✅ 子目錄建立完成 ($($SubDirs.Count) 個)" "Green"

# ============================================================
# 3. PowerShell 腳本 (完整清單 v5.0)
# ============================================================
Write-ColorOutput "`n📜 [1/13] 掃描 PowerShell 腳本..." "Yellow"

$ScriptsDir = "$ProjectRoot\scripts"
$ScriptFiles = @(
    # 核心腳本
    "ahpal-master.ps1", "ahpal-static.ps1", "generate-games.ps1",
    "backup-system.ps1", "check-all.ps1", "config.ps1",
    "add-articles.ps1", "ai-handover-scan.ps1", "preflight-check.ps1",
    # YouTube 相關
    "youtube-pipeline.ps1", "youtube-upload-realtime.ps1",
    "batch-upload-throttled.ps1", "check-deepseek-balance.ps1",
    "check-quota.ps1", "manage-schedules.ps1",
    "clean-and-push.ps1", "sync-to-gdrive.ps1",
    # 🆕 批次生成腳本
    "auto-history-batch.ps1", "auto-life-batch.ps1", "auto-nature-batch.ps1",
    # 🆕 編碼與分析工具
    "ensure-utf8-nobom.ps1", "analyze-directory.ps1",
    # 🆕 電源管理
    "screen-off.ps1", "sleep-native.ps1",
    # 🆕 影音工具
    "video-gen.ps1", "video-finalize.ps1",
    # 🆕 迷因工具
    "meme-to-song.ps1", "launcher-test.ps1"
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
Write-ColorOutput "   ✅ 已複製 $scriptCount 個 PowerShell 腳本" "Green"

# ============================================================
# 4. Python 模組 (完整清單 v5.0)
# ============================================================
Write-ColorOutput "`n🐍 [2/13] 掃描 Python 模組..." "Yellow"

$SrcDir = "$ProjectRoot\src"
$PythonModules = @(
    "__init__.py", "main.py", "config.py", "api_client.py",
    "article_generator.py", "html_builder.py", "quality_checker.py",
    "sitemap_builder.py", "state_manager.py", "logger.py",
    "youtube_lm.py", "content_router.py", "song_generator.py",
    "model_router.py"
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
Write-ColorOutput "   ✅ 已複製 $pyCount 個 Python 模組" "Green"

# ============================================================
# 5. 環境設定
# ============================================================
Write-ColorOutput "`n🔐 [3/13] 處理環境設定檔..." "Yellow"

$EnvPath = "$ProjectRoot\.env"
$EnvTemplatePath = "$ProjectRoot\.env.template"
$GitIgnorePath = "$ProjectRoot\.gitignore"

if (Test-Path $EnvTemplatePath) {
    Copy-Item $EnvTemplatePath "$HandoverDir\04-環境設定與API\.env.template" -Force
    Write-ColorOutput "      ✅ .env.template 已複製" "Green"
    $FileCopyCount++
} else {
    Write-WarningLog ".env.template 不存在"
}

if (Test-Path $GitIgnorePath) {
    Copy-Item $GitIgnorePath "$HandoverDir\04-環境設定與API\.gitignore" -Force
    Write-ColorOutput "      ✅ .gitignore 已複製" "Green"
    $FileCopyCount++
}

if (Test-Path $EnvPath) {
    $envContent = Get-Content $EnvPath -Raw
    $envSize = [math]::Round((Get-Item $EnvPath).Length / 1KB, 2)
    
    $maskedContent = $envContent
    $maskedContent = $maskedContent -replace '(DEEPSEEK_API_KEY=)(sk-[A-Za-z0-9]+)', '$1sk-****MASKED****'
    $maskedContent = $maskedContent -replace '(GEMINI_API_KEY=)(AIzaSy[A-Za-z0-9]+)', '$1AIza****MASKED****'
    $maskedContent = $maskedContent -replace '(POLLINATIONS_API_KEY=)([A-Za-z0-9]+)', '$1****MASKED****'
    
    $maskedContent | Out-File "$HandoverDir\04-環境設定與API\.env.masked" -Encoding UTF8
    Write-ColorOutput "      ✅ .env 已遮罩處理 (原始大小: $envSize KB)" "Green"
    $FileCopyCount++
} else {
    Write-ErrorLog ".env 不存在"
}

# ============================================================
# 6. 文章內容 — 🆕 完整 9 大分類
# ============================================================
Write-ColorOutput "`n📄 [4/13] 掃描文章內容..." "Yellow"

$Categories = @{
    "history"    = "📜 歷史腦洞"
    "tech"       = "💻 3C 科技教學"
    "game"       = "🎮 遊戲攻略"
    "life"       = "🏠 生活小常識"
    "review"     = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend"      = "🤖 AI 趨勢"
    "music"      = "🎵 音樂創作"
    "nature"     = "🌳 動植物生態"
}

$ArticleStats = @()
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
Write-ColorOutput "   ✅ 總文章數: $TotalArticles 篇" "Green"

# ============================================================
# 7. 遊戲內容
# ============================================================
Write-ColorOutput "`n🎮 [5/13] 掃描遊戲內容..." "Yellow"

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
        Write-ColorOutput "      ✅ 共用資源 (assets/) 已複製" "Green"
    }
    Write-ColorOutput "   ✅ 遊戲總數: $gameCount 款" "Green"
} else {
    Write-ErrorLog "game/ 目錄不存在"
}

# ============================================================
# 8. 圖片資源
# ============================================================
Write-ColorOutput "`n🖼️ [6/13] 掃描圖片資源..." "Yellow"

$ImageDir = "$ProjectRoot\images"
$ImageDest = "$HandoverDir\13-圖片資源"

if (Test-Path $ImageDir) {
    New-Item -ItemType Directory -Path $ImageDest -Force | Out-Null
    $images = Get-ChildItem $ImageDir -File -ErrorAction SilentlyContinue
    $imageCount = $images.Count
    $imageSize = [math]::Round(($images | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    foreach ($img in $images) {
        Copy-Item $img.FullName "$ImageDest\$($img.Name)" -Force
        $FileCopyCount++
    }
    Write-ColorOutput "   ✅ 圖片總數: $imageCount 個 ($imageSize MB)" "Green"
} else {
    Write-WarningLog "images/ 目錄不存在"
}

# ============================================================
# 9. 狀態與日誌
# ============================================================
Write-ColorOutput "`n📊 [7/13] 掃描狀態與日誌..." "Yellow"

$ManifestFiles = @("article-manifest.json", "build-state.json", "sitemap-state.json")
foreach ($mf in $ManifestFiles) {
    $src = "$ProjectRoot\$mf"
    if (Test-Path $src) {
        Copy-Item $src "$HandoverDir\07-狀態與日誌\$mf" -Force
        $FileCopyCount++
        Write-ColorOutput "      ✅ $mf 已複製" "Green"
    } else {
        Write-WarningLog "$mf 不存在"
    }
}

$LogDir = "$ProjectRoot\logs"
if (Test-Path $LogDir) {
    $logs = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 15
    foreach ($log in $logs) {
        Copy-Item $log.FullName "$HandoverDir\07-狀態與日誌\$($log.Name)" -Force
        $FileCopyCount++
    }
    Write-ColorOutput "      ✅ 日誌檔案: $($logs.Count) 個 (最近15個)" "Green"
} else {
    Write-WarningLog "logs/ 目錄不存在"
}

# ============================================================
# 10. 分類頁面 — 🆕 完整 9 大分類
# ============================================================
Write-ColorOutput "`n📄 [7.5/13] 掃描分類頁面..." "Yellow"

$CategoryPages = @(
    "category-history.html", "category-tech.html", "category-game.html",
    "category-life.html", "category-review.html", "category-philosophy.html",
    "category-trend.html", "category-music.html", "category-nature.html"
)

$CatPageDest = "$HandoverDir\01-系統架構與文件\category-pages"
New-Item -ItemType Directory -Path $CatPageDest -Force | Out-Null

foreach ($page in $CategoryPages) {
    $src = "$ProjectRoot\$page"
    if (Test-Path $src) {
        Copy-Item $src "$CatPageDest\$page" -Force
        $FileCopyCount++
        Write-ColorOutput "      ✅ $page 已複製" "Green"
    } else {
        Write-WarningLog "分類頁面不存在: $page"
    }
}

# ============================================================
# 11. Git 版本歷史
# ============================================================
Write-ColorOutput "`n📜 [8/13] 匯出 Git 版本歷史..." "Yellow"

$GitLogPath = "$HandoverDir\12-Git-版本歷史"
if (Test-Path "$ProjectRoot\.git") {
    git -C $ProjectRoot log --oneline --graph --decorate --all > "$GitLogPath\git-commit-history.txt"
    Write-ColorOutput "      ✅ commit 歷史已匯出" "Green"
    git -C $ProjectRoot log --stat --format="%H%n%an <%ae>%n%ad%n%s%n" > "$GitLogPath\git-commit-detail.txt"
    Write-ColorOutput "      ✅ commit 詳細資訊已匯出" "Green"
    git -C $ProjectRoot branch -a > "$GitLogPath\git-branches.txt"
    Write-ColorOutput "      ✅ 分支資訊已匯出" "Green"
    git -C $ProjectRoot remote -v > "$GitLogPath\git-remote.txt"
    Write-ColorOutput "      ✅ 遠端資訊已匯出" "Green"
    $FileCopyCount += 4
} else {
    Write-WarningLog ".git 目錄不存在"
}

# ============================================================
# 12. 備份檔案
# ============================================================
Write-ColorOutput "`n💾 [9/13] 掃描備份檔案..." "Yellow"

if (Test-Path $BackupRoot) {
    $backups = Get-ChildItem $BackupRoot -Directory | Sort-Object LastWriteTime -Descending
    $backupCount = $backups.Count
    $recentBackups = $backups | Select-Object -First 3
    $i = 0
    foreach ($b in $recentBackups) {
        $i++
        $backupDest = "$HandoverDir\08-備份檔案\backup-$i-$($b.Name)"
        Copy-Item -Path $b.FullName -Destination $backupDest -Recurse -Force
        $size = [math]::Round((Get-ChildItem $b.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-ColorOutput "      ✅ $($b.Name) ($size MB)" "Green"
        $FileCopyCount++
    }
    Write-ColorOutput "   ✅ 備份摘要已建立 ($backupCount 個備份)" "Green"
} else {
    Write-WarningLog "備份目錄不存在: $BackupRoot"
}

# ============================================================
# 13. 自動化工具
# ============================================================
Write-ColorOutput "`n⚡ [10/13] 掃描自動化工具..." "Yellow"

$DataDir = "$ProjectRoot\data"
if (Test-Path $DataDir) {
    Copy-Item -Path $DataDir -Destination "$HandoverDir\10-自動化工具\data" -Recurse -Force
    Write-ColorOutput "      ✅ data/ 目錄已複製" "Green"
    $FileCopyCount++
} else {
    Write-WarningLog "data/ 目錄不存在"
}

$BackupsDir = "$ProjectRoot\backups"
if (Test-Path $BackupsDir) {
    $recentBackups = Get-ChildItem $BackupsDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    foreach ($b in $recentBackups) {
        Copy-Item -Path $b.FullName -Destination "$HandoverDir\10-自動化工具\backups\$($b.Name)" -Recurse -Force
        $FileCopyCount++
    }
    Write-ColorOutput "      ✅ backups/ 目錄 (最近3個) 已複製" "Green"
} else {
    Write-WarningLog "backups/ 目錄不存在"
}

# ============================================================
# 14. 文件庫
# ============================================================
Write-ColorOutput "`n📚 [11/13] 掃描文件庫..." "Yellow"

$DocsDir = "$ProjectRoot\docs"
if (Test-Path $DocsDir) {
    Copy-Item -Path $DocsDir -Destination "$HandoverDir\01-系統架構與文件\docs" -Recurse -Force
    Write-ColorOutput "      ✅ docs/ 目錄已複製" "Green"
    $FileCopyCount++
} else {
    Write-WarningLog "docs/ 目錄不存在"
}

$RootFiles = @("index.html", "categories.html", "404.html", "README.md", "sitemap.xml", "robots.txt", "ads.txt")
foreach ($rf in $RootFiles) {
    $src = "$ProjectRoot\$rf"
    if (Test-Path $src) {
        Copy-Item $src "$HandoverDir\01-系統架構與文件\$rf" -Force
        $FileCopyCount++
        Write-ColorOutput "      ✅ $rf 已複製" "Green"
    } else {
        Write-WarningLog "根目錄檔案不存在: $rf"
    }
}

# ============================================================
# 15. START-HERE.txt
# ============================================================
Write-ColorOutput "`n📌 [12/13] 建立快速上手指引..." "Yellow"

$QuickStart = @"
╔════════════════════════════════════════════════════════════════╗
║  🚀 新 AI 工程師 / 系統接手者，請先讀我！                   ║
║  雅寶社區 · 頂客論壇 (AHPAL.COM)                            ║
║  交接時間: $Timestamp                                        ║
║  系統版本: v5.0 (9 大分類 · 批次自動化)                     ║
╚════════════════════════════════════════════════════════════════╝

📌 你必須知道的最重要工具

【1️⃣ 新增文章（批次自動化）】
   📁 data/pending-articles.json  ← 在這裡定義新文章（JSON 格式）
   ⚡ scripts/add-articles.ps1    ← 執行這個腳本

【2️⃣ 生成文章】
   ⚡ python src/main.py --force deepseek

【3️⃣ 完整部署】
   ⚡ .\scripts\ahpal-master.ps1 → [1]

【4️⃣ 死命令與品質檢查】
   ⚡ .\scripts\preflight-check.ps1  ← 推送前強制檢查
   ⚡ .\scripts\check-all.ps1       ← 全系統診斷

【5️⃣ 批次生成 (三大自動化腳本)】
   ⚡ .\scripts\auto-history-batch.ps1  ← 歷史腦洞
   ⚡ .\scripts\auto-life-batch.ps1     ← 生活小常識
   ⚡ .\scripts\auto-nature-batch.ps1   ← 動植物生態

【6️⃣ 系統交接】
   ⚡ .\scripts\ai-handover-scan.ps1    ← 生成完整交接報告

📋 JSON 格式範例：
[
    {"keyword": "2026 年最新 AI 工具推薦", "category": "🤖 AI 趨勢"},
    {"keyword": "居家收納終極指南", "category": "🏠 生活小常識"}
]

🔐 安全提醒：此交接檔案不包含實際 API Key，需自行建立 .env
"@
$QuickStart | Out-File "$HandoverDir\START-HERE.txt" -Encoding UTF8
Write-ColorOutput "   ✅ 快速上手指引已建立" "Green"

# ============================================================
# 16. 驗證清單
# ============================================================
Write-ColorOutput "`n✅ [13/13] 建立交接驗證清單..." "Yellow"

$Checklist = @"
AI 系統交接 - 驗證清單 v5.0
交接時間: $Timestamp

【環境設定】
☐ Git 已安裝並設定
☐ Python 3 已安裝
☐ .env 檔案已建立
☐ SSH 金鑰已新增至 GitHub

【系統驗證】
☐ 執行 check-all.ps1 -Report
☐ 執行 preflight-check.ps1
☐ 執行 git status

【文章操作】
☐ 了解 pending-articles.json 格式
☐ 測試新增文章

【部署驗證】
☐ 執行 ahpal-master.ps1 → [1]
☐ 確認 Cloudflare 部署成功

【分類檢查】
☐ 9 大分類皆正常顯示 (history, tech, game, life, review, philosophy, trend, music, nature)
☐ categories.html 包含所有分類
☐ 各分類頁面 (category-*.html) 可正常瀏覽

簽署人: ____________________
日期: ____________________
"@
$Checklist | Out-File "$HandoverDir\交接驗證清單.txt" -Encoding UTF8
Write-ColorOutput "   ✅ 交接驗證清單已建立" "Green"

# ============================================================
# 17. 分析報告
# ============================================================
Write-ColorOutput "`n📋 生成完整分析報告..." "Yellow"

$Report = @"
╔════════════════════════════════════════════════════════════════╗
║     🤖 AI 系統交接 - 完整系統分析報告 v5.0                  ║
║     雅寶社區 · 頂客論壇 (AHPAL.COM)                         ║
║     報告時間: $Timestamp                                     ║
╚════════════════════════════════════════════════════════════════╝

📊 統計總覽:
- 總文章數: $TotalArticles 篇
- 總檔案複製: $FileCopyCount 個
- 錯誤數: $ErrorCount 個
- 警告數: $WarningCount 個

📂 9 大分類分布:
"@

foreach ($cat in $Categories.Keys) {
    $dir = "$ProjectRoot\$cat"
    if (Test-Path $dir) {
        $count = (Get-ChildItem $dir -Filter "*.html" -ErrorAction SilentlyContinue).Count
        $Report += "   - $($Categories[$cat]) : $count 篇`n"
    } else {
        $Report += "   - $($Categories[$cat]) : 目錄不存在`n"
    }
}

$Report += @"

⚡ 快速指令參考:
完整部署: .\scripts\ahpal-master.ps1 → [1]
新增文章: 編輯 data/pending-articles.json → .\scripts\add-articles.ps1
死命令檢查: .\scripts\preflight-check.ps1
系統檢查: .\scripts\check-all.ps1 -Report
批次生成(歷史): .\scripts\auto-history-batch.ps1
批次生成(生活): .\scripts\auto-life-batch.ps1
批次生成(生態): .\scripts\auto-nature-batch.ps1

⚠️ 重要提醒:
1. 此交接檔案不包含實際 API Key
2. 需自行建立 .env 檔案
3. 建議交接完成後變更所有 API Key
4. 請確實執行驗證清單中的所有項目
"@
$Report | Out-File "$HandoverDir\09-分析報告\系統分析報告-$Timestamp.txt" -Encoding UTF8
Write-ColorOutput "   ✅ 分析報告已建立" "Green"

# ============================================================
# 18. 壓縮
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
# 19. 完成
# ============================================================
Write-ColorOutput "`n============================================================" "Cyan"
Write-ColorOutput "  ✅ 掃描與備份完成！" "Green"
Write-ColorOutput "============================================================" "Cyan"

Write-ColorOutput "`n📊 系統快照:" "Yellow"
Write-ColorOutput "   📝 文章總數: $TotalArticles 篇" "Cyan"
Write-ColorOutput "   📁 複製檔案: $FileCopyCount 個" "Cyan"
Write-ColorOutput "   📦 交接大小: $(if (Test-Path $ZipPath) { "$([math]::Round((Get-Item $ZipPath).Length / 1MB, 2)) MB" } else { '未知' })" "Cyan"

Write-ColorOutput "`n📋 交接檔案位置:" "Yellow"
Write-ColorOutput "   📁 $HandoverDir" "White"
Write-ColorOutput "   📦 $ZipPath" "White"

Write-ColorOutput "`n🔐 安全提醒:" "Red"
Write-ColorOutput "   ⚠️ API Key 已遮罩處理" "Red"
Write-ColorOutput "   ⚠️ 建議交接完成後變更所有 API Key" "Red"

Write-ColorOutput "`n🦞 交接掃描完成！" "Cyan"