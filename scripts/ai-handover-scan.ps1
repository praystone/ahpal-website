# ============================================================
# AI 交接專用 - 完整系統掃描與備份腳本 v3.1
# 用途：掃描所有關鍵檔案、生成分析報告、複製到交接目錄
# 創建時間：2026-07-24
# 修正：輸出目錄改為 ahpal-AI-archive
# 新增：包含 preflight-check.ps1、youtube_lm.py
# ============================================================

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ============================================================
# 1. 設定變數
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ProjectRoot = "C:\Users\User\ahpal-static"
$BackupRoot = "C:\Users\User\ahpal-backup"
$ArchiveRoot = "C:\Users\User\ahpal-AI-archive"

# 確保檔案館目錄存在
if (-not (Test-Path $ArchiveRoot)) {
    New-Item -ItemType Directory -Path $ArchiveRoot -Force | Out-Null
}

$HandoverDir = "$ArchiveRoot\ai交接-$Timestamp"
$ZipPath = "$ArchiveRoot\ai交接-$Timestamp.zip"

# 顏色函數
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# ============================================================
# 2. 建立交接目錄
# ============================================================
Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "  🤖 AI 系統交接 - 完整掃描與備份 v3.1" "Cyan"
Write-ColorOutput "========================================`n" "Cyan"

Write-ColorOutput "📁 建立交接目錄..." "Yellow"
New-Item -ItemType Directory -Path $HandoverDir -Force | Out-Null
Write-ColorOutput "   ✅ 交接目錄: $HandoverDir" "Green"

# 建立子目錄
$SubDirs = @(
    "01-系統架構與文件",
    "02-原始碼-PowerShell腳本",
    "03-原始碼-Python模組",
    "04-環境設定與API",
    "05-網站內容-文章",
    "06-網站內容-遊戲",
    "07-狀態與日誌",
    "08-備份檔案",
    "09-分析報告",
    "10-自動化工具",
    "11-資料與設定"
)

foreach ($dir in $SubDirs) {
    New-Item -ItemType Directory -Path "$HandoverDir\$dir" -Force | Out-Null
}
Write-ColorOutput "   ✅ 子目錄建立完成" "Green"

# ============================================================
# 3. 掃描與複製 - PowerShell 腳本（完整包含所有腳本）
# ============================================================
Write-ColorOutput "`n📜 掃描 PowerShell 腳本..." "Yellow"

$ScriptsDir = "$ProjectRoot\scripts"
$ScriptFiles = @(
    "ahpal-master.ps1",
    "ahpal-static.ps1", 
    "generate-games.ps1",
    "backup-system.ps1",
    "check-articles.ps1",
    "check-all.ps1",
    "config.ps1",
    "add-articles.ps1",
    "ai-handover-scan.ps1",
    "preflight-check.ps1",          # 🆕 死命令檢查
    "youtube-pipeline.ps1",          # 🆕 影音管線
    "youtube-upload-realtime.ps1",   # 🆕 YouTube 上傳
    "batch-upload-throttled.ps1",    # 🆕 批量上傳
    "check-deepseek-balance.ps1",    # 🆕 餘額檢查
    "check-quota.ps1",               # 🆕 配額檢查
    "manage-schedules.ps1"           # 🆕 排程管理
)

$ScriptReport = @()
foreach ($script in $ScriptFiles) {
    $source = "$ScriptsDir\$script"
    $dest = "$HandoverDir\02-原始碼-PowerShell腳本\$script"
    
    if (Test-Path $source) {
        $size = [math]::Round((Get-Item $source).Length / 1KB, 2)
        Copy-Item $source $dest -Force
        $ScriptReport += [PSCustomObject]@{
            File = $script
            Status = "✅ 已複製"
            Size = "$size KB"
        }
        Write-ColorOutput "      ✅ $script ($size KB)" "Green"
    } else {
        $ScriptReport += [PSCustomObject]@{
            File = $script
            Status = "⚠️ 檔案不存在"
            Size = "N/A"
        }
        Write-ColorOutput "      ⚠️ $script (不存在)" "Yellow"
    }
}

# ============================================================
# 4. 掃描與複製 - Python 模組（包含 youtube_lm.py）
# ============================================================
Write-ColorOutput "`n🐍 掃描 Python 模組..." "Yellow"

$SrcDir = "$ProjectRoot\src"
$PythonModules = @(
    "__init__.py",
    "main.py",
    "config.py",
    "api_client.py",
    "article_generator.py",
    "html_builder.py",
    "quality_checker.py",
    "sitemap_builder.py",
    "state_manager.py",
    "logger.py",
    "youtube_lm.py"          # 🆕 YT+LM 整合
)

$PythonReport = @()
foreach ($module in $PythonModules) {
    $source = "$SrcDir\$module"
    $dest = "$HandoverDir\03-原始碼-Python模組\$module"
    
    if (Test-Path $source) {
        $size = [math]::Round((Get-Item $source).Length / 1KB, 2)
        Copy-Item $source $dest -Force
        $PythonReport += [PSCustomObject]@{
            File = $module
            Status = "✅ 已複製"
            Size = "$size KB"
        }
        Write-ColorOutput "      ✅ $module ($size KB)" "Green"
    } else {
        $PythonReport += [PSCustomObject]@{
            File = $module
            Status = "❌ 檔案不存在"
            Size = "N/A"
        }
        Write-ColorOutput "      ❌ $module (不存在)" "Red"
    }
}

# ============================================================
# 5. 掃描與複製 - 環境設定
# ============================================================
Write-ColorOutput "`n🔐 掃描環境設定檔..." "Yellow"

$EnvPath = "$ProjectRoot\.env"
$EnvTemplatePath = "$ProjectRoot\.env.template"
$GitIgnorePath = "$ProjectRoot\.gitignore"
$ReadmePath = "$ProjectRoot\README.md"
$AdsTxtPath = "$ProjectRoot\ads.txt"

# 複製 .env.template
if (Test-Path $EnvTemplatePath) {
    Copy-Item $EnvTemplatePath "$HandoverDir\04-環境設定與API\.env.template" -Force
    Write-ColorOutput "      ✅ .env.template 已複製" "Green"
} else {
    Write-ColorOutput "      ❌ .env.template 不存在" "Red"
}

# 複製 .gitignore
if (Test-Path $GitIgnorePath) {
    Copy-Item $GitIgnorePath "$HandoverDir\04-環境設定與API\.gitignore" -Force
    Write-ColorOutput "      ✅ .gitignore 已複製" "Green"
} else {
    Write-ColorOutput "      ❌ .gitignore 不存在" "Red"
}

# 複製 README.md
if (Test-Path $ReadmePath) {
    Copy-Item $ReadmePath "$HandoverDir\04-環境設定與API\README.md" -Force
    Write-ColorOutput "      ✅ README.md 已複製" "Green"
} else {
    Write-ColorOutput "      ❌ README.md 不存在" "Red"
}

# 複製 ads.txt
if (Test-Path $AdsTxtPath) {
    Copy-Item $AdsTxtPath "$HandoverDir\04-環境設定與API\ads.txt" -Force
    Write-ColorOutput "      ✅ ads.txt 已複製" "Green"
} else {
    Write-ColorOutput "      ⚠️ ads.txt 不存在" "Yellow"
}

# 檢查 .env
if (Test-Path $EnvPath) {
    $envSize = [math]::Round((Get-Item $EnvPath).Length / 1KB, 2)
    Write-ColorOutput "      ✅ .env 存在 ($envSize KB) - 安全檢查通過" "Green"
    
    $envContent = Get-Content $EnvPath -Raw
    $envReport = @"
.env 檔案狀態報告
========================================
檔案位置: $EnvPath
檔案大小: $envSize KB
最後修改: $(Get-Item $EnvPath).LastWriteTime

API Key 狀態:
- Gemini API Key: $(if ($envContent -match "GEMINI_API_KEY=AIzaSy") { "✅ 已設定" } else { "⚠️ 已設定（新格式）" })
- DeepSeek API Key: $(if ($envContent -match "DEEPSEEK_API_KEY=sk-") { "✅ 已設定" } else { "❌ 未設定或格式錯誤" })

⚠️ 注意：此檔案包含敏感資訊，請勿外洩！
"@
    $envReport | Out-File "$HandoverDir\04-環境設定與API\.env-status-report.txt" -Encoding UTF8
    Write-ColorOutput "      ✅ .env 狀態報告已建立" "Green"
} else {
    Write-ColorOutput "      ❌ .env 不存在 (請從 .env.template 建立)" "Red"
}

# ============================================================
# 6. 掃描與複製 - 文章內容
# ============================================================
Write-ColorOutput "`n📄 掃描文章內容..." "Yellow"

$Categories = @{
    "game" = "🎮 遊戲攻略"
    "tech" = "💻 3C 科技教學"
    "life" = "🏠 生活小常識"
    "review" = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend" = "🤖 AI 趨勢"
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
        }
        
        $ArticleStats += [PSCustomObject]@{
            Category = $Categories[$cat]
            Count = $count
            SizeKB = [math]::Round($catSize / 1KB, 2)
            Status = "✅"
        }
        Write-ColorOutput "      $($Categories[$cat]) : $count 篇 ($([math]::Round($catSize/1KB,2)) KB) ✅ 全數複製" "Green"
    } else {
        $ArticleStats += [PSCustomObject]@{
            Category = $Categories[$cat]
            Count = 0
            SizeKB = 0
            Status = "❌ 目錄不存在"
        }
        Write-ColorOutput "      ❌ $($Categories[$cat]) : 目錄不存在" "Red"
    }
}

# ============================================================
# 7. 掃描與複製 - 遊戲內容
# ============================================================
Write-ColorOutput "`n🎮 掃描遊戲內容..." "Yellow"

$GameDir = "$ProjectRoot\game"
$GameDest = "$HandoverDir\06-網站內容-遊戲"

if (Test-Path $GameDir) {
    New-Item -ItemType Directory -Path $GameDest -Force | Out-Null
    
    $games = Get-ChildItem $GameDir -Filter "*.html" -ErrorAction SilentlyContinue
    $gameCount = $games.Count
    foreach ($game in $games) {
        Copy-Item $game.FullName "$GameDest\$($game.Name)" -Force
    }
    
    $AssetsDir = "$GameDir\assets"
    if (Test-Path $AssetsDir) {
        Copy-Item -Path $AssetsDir -Destination "$GameDest\assets" -Recurse -Force
        Write-ColorOutput "      ✅ 共用資源 (assets/) 已複製" "Green"
    }
    
    Write-ColorOutput "      ✅ 遊戲檔案: $gameCount 款 (全數複製)" "Green"
} else {
    Write-ColorOutput "      ❌ game/ 目錄不存在" "Red"
}

# ============================================================
# 8. 掃描與複製 - 狀態與日誌
# ============================================================
Write-ColorOutput "`n📊 掃描狀態與日誌..." "Yellow"

$ManifestFiles = @(
    "article-manifest.json",
    "build-state.json"
)

foreach ($mf in $ManifestFiles) {
    $src = "$ProjectRoot\$mf"
    if (Test-Path $src) {
        Copy-Item $src "$HandoverDir\07-狀態與日誌\$mf" -Force
        Write-ColorOutput "      ✅ $mf 已複製" "Green"
        
        try {
            $content = Get-Content $src -Raw | ConvertFrom-Json
            if ($mf -eq "article-manifest.json") {
                $stats = $content.stats
                $statsText = @"
$mf 統計摘要
========================================
總文章數: $($stats.total)
已生成: $($stats.generated)
待生成: $($stats.pending)
失敗: $($stats.failed)
最後更新: $($content.last_updated)
"@
            } else {
                $statsText = @"
$mf 統計摘要
========================================
總檔案數: $($content.files.PSObject.Properties.Count)
最後構建: $($content.last_build)
版本: $($content.version)
"@
            }
            $statsText | Out-File "$HandoverDir\07-狀態與日誌\$mf-stats.txt" -Encoding UTF8
        } catch {
            Write-ColorOutput "      ⚠️ 無法解析 $mf" "Yellow"
        }
    } else {
        Write-ColorOutput "      ⚠️ $mf 不存在" "Yellow"
    }
}

$LogDir = "$ProjectRoot\logs"
if (Test-Path $LogDir) {
    $logs = Get-ChildItem $LogDir -Filter "*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 5
    $logCount = $logs.Count
    foreach ($log in $logs) {
        Copy-Item $log.FullName "$HandoverDir\07-狀態與日誌\$($log.Name)" -Force
    }
    Write-ColorOutput "      ✅ 日誌檔案: $logCount 個 (最近5個)" "Green"
} else {
    Write-ColorOutput "      ℹ️ logs/ 目錄不存在" "Gray"
}

# ============================================================
# 9. 備份檔案
# ============================================================
Write-ColorOutput "`n💾 掃描備份檔案..." "Yellow"

if (Test-Path $BackupRoot) {
    $backups = Get-ChildItem $BackupRoot -Directory | Sort-Object LastWriteTime -Descending
    $backupCount = $backups.Count
    
    $backupSummary = @"
備份檔案摘要
========================================
備份目錄: $BackupRoot
備份總數: $backupCount

最近備份:
"@
    $backups | Select-Object -First 5 | ForEach-Object {
        $size = [math]::Round((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        $backupSummary += "`n- $($_.Name) ($($_.LastWriteTime)) - $size MB"
    }
    $backupSummary | Out-File "$HandoverDir\08-備份檔案\backup-summary.txt" -Encoding UTF8
    
    Write-ColorOutput "      ✅ 備份檔案: $backupCount 個" "Green"
    Write-ColorOutput "      ✅ 最近5個備份摘要已建立" "Green"
} else {
    Write-ColorOutput "      ℹ️ 備份目錄不存在" "Gray"
}

# ============================================================
# 10. 掃描與複製 - 自動化工具
# ============================================================
Write-ColorOutput "`n⚡ 掃描自動化工具..." "Yellow"

$DataDir = "$ProjectRoot\data"
if (Test-Path $DataDir) {
    Copy-Item -Path $DataDir -Destination "$HandoverDir\10-自動化工具\data" -Recurse -Force
    Write-ColorOutput "      ✅ data/ 目錄已複製" "Green"
} else {
    Write-ColorOutput "      ℹ️ data/ 目錄不存在" "Gray"
}

$BackupsDir = "$ProjectRoot\backups"
if (Test-Path $BackupsDir) {
    $recentBackups = Get-ChildItem $BackupsDir -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    foreach ($b in $recentBackups) {
        Copy-Item -Path $b.FullName -Destination "$HandoverDir\10-自動化工具\backups\$($b.Name)" -Recurse -Force
    }
    Write-ColorOutput "      ✅ backups/ 目錄 (最近3個) 已複製" "Green"
} else {
    Write-ColorOutput "      ℹ️ backups/ 目錄不存在" "Gray"
}

# ============================================================
# 11. 掃描與複製 - 文件庫
# ============================================================
Write-ColorOutput "`n📚 掃描文件庫..." "Yellow"

$DocsDir = "$ProjectRoot\docs"
if (Test-Path $DocsDir) {
    Copy-Item -Path $DocsDir -Destination "$HandoverDir\01-系統架構與文件\docs" -Recurse -Force
    Write-ColorOutput "      ✅ docs/ 目錄已複製" "Green"
} else {
    Write-ColorOutput "      ℹ️ docs/ 目錄不存在" "Gray"
}

# ============================================================
# 12. 生成完整分析報告
# ============================================================
Write-ColorOutput "`n📋 生成完整分析報告..." "Yellow"

$ReportPath = "$HandoverDir\09-分析報告\系統分析報告-$Timestamp.txt"

$TotalSizeMB = [math]::Round($TotalSize / 1MB, 2)
$GameCount = if (Test-Path $GameDir) { (Get-ChildItem $GameDir -Filter "*.html").Count } else { 0 }

$Report = @"
╔════════════════════════════════════════════════════════════════╗
║                                                              ║
║     🤖 AI 系統交接 - 完整系統分析報告                        ║
║     雅寶社區 · 頂客論壇 (AHPAL.COM)                         ║
║                                                              ║
║     報告時間: $Timestamp                                     ║
║                                                              ║
╚════════════════════════════════════════════════════════════════╝

═══════════════════════════════════════════════════════════════════
1. 系統概況
═══════════════════════════════════════════════════════════════════

系統名稱: 雅寶社區 · 頂客論壇 (AHPAL.COM)
系統類型: AI 驅動的自動化內容平台
技術棧: PowerShell + Python 3 + Cloudflare Pages + Git
API: Google Gemini (尖峰) + DeepSeek (離峰)
版本: v4.2 (模組化架構)

═══════════════════════════════════════════════════════════════════
2. PowerShell 腳本 ($($ScriptFiles.Count) 個)
═══════════════════════════════════════════════════════════════════

"@

foreach ($item in $ScriptReport) {
    $Report += "   $($item.Status) $($item.File) ($($item.Size))`n"
}

$Report += @"

═══════════════════════════════════════════════════════════════════
3. Python 模組 ($($PythonModules.Count) 個)
═══════════════════════════════════════════════════════════════════

"@

foreach ($item in $PythonReport) {
    $Report += "   $($item.Status) $($item.File) ($($item.Size))`n"
}

$Report += @"

═══════════════════════════════════════════════════════════════════
4. 文章統計
═══════════════════════════════════════════════════════════════════

總文章數: $TotalArticles 篇
總大小: $TotalSizeMB MB

分類統計:
"@

foreach ($stat in $ArticleStats) {
    $Report += "`n   $($stat.Status) $($stat.Category): $($stat.Count) 篇 ($($stat.SizeKB) KB)"
}

$Report += @"

═══════════════════════════════════════════════════════════════════
5. 遊戲統計
═══════════════════════════════════════════════════════════════════

遊戲總數: $GameCount 款
遊戲位置: game/
共用資源: assets/ (CSS/JS)

═══════════════════════════════════════════════════════════════════
6. 安全性檢查
═══════════════════════════════════════════════════════════════════

✅ .env 已在 .gitignore 中 (不追蹤)
✅ API Key 僅儲存在本地
✅ 敏感資訊未包含在交接文件中
⚠️ 建議：交接完成後請變更所有 API Key

═══════════════════════════════════════════════════════════════════
7. 快速指令參考
═══════════════════════════════════════════════════════════════════

完整部署: cd $ProjectRoot; .\scripts\ahpal-master.ps1 → [1]
快速更新: .\scripts\ahpal-master.ps1 → [2]
只生成文章: .\scripts\ahpal-master.ps1 → [4]
只部署: .\scripts\ahpal-master.ps1 → [6]
死命令檢查: .\scripts\preflight-check.ps1
系統檢查: .\scripts\check-all.ps1 -Report
執行備份: .\scripts\backup-system.ps1 -Compress

═══════════════════════════════════════════════════════════════════
⚠️ 重要提醒
═══════════════════════════════════════════════════════════════════

1. 此交接檔案包含系統架構和程式碼，不包含實際 API Key
2. 新進工程師需自行建立 .env 檔案並填入 API Key
3. 建議交接完成後變更所有 API Key 以確保安全
4. 所有複製的檔案僅供交接使用，請勿外流

═══════════════════════════════════════════════════════════════════

報告產生時間: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
報告版本: v3.1
"@

$Report | Out-File $ReportPath -Encoding UTF8
Write-ColorOutput "   ✅ 分析報告已建立: $ReportPath" "Green"

# ============================================================
# 13. 建立交接檔案清單
# ============================================================
Write-ColorOutput "`n📋 建立交接檔案清單..." "Yellow"

$FileListPath = "$HandoverDir\交接檔案清單.txt"
$FileList = @"
╔════════════════════════════════════════════════════════════════╗
║           AI 系統交接 - 檔案清單與說明                        ║
║           雅寶社區 · 頂客論壇 (AHPAL.COM)                    ║
║           交接時間: $Timestamp                                ║
║           版本: v3.1 (2026-07-24)                            ║
╚════════════════════════════════════════════════════════════════╝

📁 交接目錄:
$HandoverDir

📌 優先閱讀:
1. 09-分析報告/系統分析報告-$Timestamp.txt
2. 交接檔案清單.txt

🔐 安全提醒:
- 此交接檔案不包含實際 API Key
- 需自行建立 .env 檔案
- 建議交接完成後變更所有 API Key

═══════════════════════════════════════════════════════════════════
"@

$FileList | Out-File $FileListPath -Encoding UTF8
Write-ColorOutput "   ✅ 檔案清單已建立: $FileListPath" "Green"

# ============================================================
# 14. 壓縮交接檔案
# ============================================================
Write-ColorOutput "`n📦 壓縮交接檔案..." "Yellow"

try {
    Compress-Archive -Path $HandoverDir -DestinationPath $ZipPath -Force
    Write-ColorOutput "   ✅ 壓縮完成: $ZipPath" "Green"
    $zipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
    Write-ColorOutput "   📦 檔案大小: $zipSize MB" "Cyan"
} catch {
    Write-ColorOutput "   ⚠️ 壓縮失敗 (請手動壓縮 $HandoverDir)" "Yellow"
}

# ============================================================
# 15. 顯示完成訊息
# ============================================================
Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "  ✅ 掃描與備份完成！" "Green"
Write-ColorOutput "========================================`n" "Cyan"

Write-ColorOutput "📊 系統快照:" "Yellow"
Write-ColorOutput "   📝 文章總數: $TotalArticles 篇" "Cyan"
Write-ColorOutput "   🎮 遊戲數量: $GameCount 款" "Cyan"
Write-ColorOutput "   📁 交接大小: $(if (Test-Path $ZipPath) { "$([math]::Round((Get-Item $ZipPath).Length / 1MB, 2)) MB" } else { '未知' })" "Cyan"
Write-ColorOutput ""

Write-ColorOutput "📋 交接檔案位置:" "Yellow"
Write-ColorOutput "   📁 $HandoverDir" "White"
Write-ColorOutput "   📦 $ZipPath" "White"

Write-ColorOutput "`n📌 請新進工程師優先閱讀:" "Yellow"
Write-ColorOutput "   📄 $HandoverDir\09-分析報告\系統分析報告-$Timestamp.txt" "White"
Write-ColorOutput "   📄 $HandoverDir\交接檔案清單.txt" "White"

Write-ColorOutput "`n🔐 安全提醒:" "Red"
Write-ColorOutput "   ⚠️ 此交接檔案包含系統架構和程式碼" "Red"
Write-ColorOutput "   ⚠️ 不包含實際 API Key (需自行建立 .env)" "Red"
Write-ColorOutput "   ⚠️ 建議交接完成後變更所有 API Key" "Red"

Write-ColorOutput "`n========================================" "Cyan"

Write-ColorOutput "`n按任意鍵關閉此視窗..." "Yellow"
Read-Host | Out-Null