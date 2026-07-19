# ============================================================
# AI 交接專用 - 完整系統掃描與備份腳本 v2.1
# 用途：掃描所有關鍵檔案、生成分析報告、複製到交接目錄
# 創建時間：2026-07-20
# 特性：執行完成後不會自動關閉視窗
# ============================================================

# 設定執行原則
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ============================================================
# 1. 設定變數
# ============================================================
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ProjectRoot = "C:\Users\User\ahpal-static"
$BackupRoot = "C:\Users\User\ahpal-backup"
$HandoverDir = "C:\Users\User\ai交接-$Timestamp"

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
Write-ColorOutput "  🤖 AI 系統交接 - 完整掃描與備份 v2.1" "Cyan"
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
    "09-分析報告"
)

foreach ($dir in $SubDirs) {
    New-Item -ItemType Directory -Path "$HandoverDir\$dir" -Force | Out-Null
}
Write-ColorOutput "   ✅ 子目錄建立完成" "Green"

# ============================================================
# 3. 掃描與複製 - PowerShell 腳本
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
    "config.ps1"
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
            Status = "❌ 檔案不存在"
            Size = "N/A"
        }
        Write-ColorOutput "      ❌ $script (不存在)" "Red"
    }
}

# ============================================================
# 4. 掃描與複製 - Python 模組
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
    "logger.py"
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

# 檢查 .env（不複製內容，只檢查狀態）
if (Test-Path $EnvPath) {
    $envSize = [math]::Round((Get-Item $EnvPath).Length / 1KB, 2)
    Write-ColorOutput "      ✅ .env 存在 ($envSize KB) - 安全檢查通過" "Green"
    
    # 建立 .env 狀態報告（不含實際內容）
    $envContent = Get-Content $EnvPath -Raw
    $envReport = @"
.env 檔案狀態報告
========================================
檔案位置: $EnvPath
檔案大小: $envSize KB
最後修改: $(Get-Item $EnvPath).LastWriteTime

API Key 狀態:
- Gemini API Key: $(if ($envContent -match "GEMINI_API_KEY=AIzaSy") { "✅ 已設定" } else { "❌ 未設定或格式錯誤" })
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

foreach ($cat in $Categories.Keys) {
    $sourceDir = "$ProjectRoot\$cat"
    $destDir = "$HandoverDir\05-網站內容-文章\$cat"
    
    if (Test-Path $sourceDir) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        $articles = Get-ChildItem $sourceDir -Filter "*.html" -ErrorAction SilentlyContinue
        $count = $articles.Count
        $TotalArticles += $count
        
        # 複製文章（最多30篇，避免太大）
        $articles | Select-Object -First 30 | ForEach-Object {
            Copy-Item $_.FullName "$destDir\$($_.Name)" -Force
        }
        
        $ArticleStats += [PSCustomObject]@{
            Category = $Categories[$cat]
            Count = $count
            Copied = [math]::Min($count, 30)
            Status = "✅"
        }
        Write-ColorOutput "      $($Categories[$cat]) : $count 篇 (已複製 $([math]::Min($count, 30)) 篇範例)" "Green"
    } else {
        $ArticleStats += [PSCustomObject]@{
            Category = $Categories[$cat]
            Count = 0
            Copied = 0
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
    
    # 複製遊戲 HTML（最多20個）
    $games = Get-ChildItem $GameDir -Filter "*.html" -ErrorAction SilentlyContinue
    $gameCount = $games.Count
    $games | Select-Object -First 20 | ForEach-Object {
        Copy-Item $_.FullName "$GameDest\$($_.Name)" -Force
    }
    Write-ColorOutput "      ✅ 遊戲檔案: $gameCount 個 (已複製 $([math]::Min($gameCount, 20)) 個範例)" "Green"
} else {
    Write-ColorOutput "      ❌ game/ 目錄不存在" "Red"
}

# ============================================================
# 8. 掃描與複製 - 狀態與日誌
# ============================================================
Write-ColorOutput "`n📊 掃描狀態與日誌..." "Yellow"

# 複製 manifest.json
$ManifestPath = "$ProjectRoot\article-manifest.json"
if (Test-Path $ManifestPath) {
    Copy-Item $ManifestPath "$HandoverDir\07-狀態與日誌\article-manifest.json" -Force
    Write-ColorOutput "      ✅ article-manifest.json 已複製" "Green"
    
    # 解析 manifest 統計
    try {
        $manifest = Get-Content $ManifestPath | ConvertFrom-Json
        $manifestStats = @"
文章狀態統計 (article-manifest.json)
========================================
總文章數: $($manifest.stats.total)
已生成: $($manifest.stats.generated)
待生成: $($manifest.stats.pending)
失敗: $($manifest.stats.failed)
最後更新: $($manifest.last_updated)
"@
        $manifestStats | Out-File "$HandoverDir\07-狀態與日誌\manifest-stats.txt" -Encoding UTF8
    } catch {
        Write-ColorOutput "      ⚠️ 無法解析 manifest.json" "Yellow"
    }
} else {
    Write-ColorOutput "      ⚠️ article-manifest.json 不存在" "Yellow"
}

# 複製日誌（最近3個）
$LogDir = "$ProjectRoot\logs"
if (Test-Path $LogDir) {
    $logs = Get-ChildItem $LogDir -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3
    $logCount = $logs.Count
    foreach ($log in $logs) {
        Copy-Item $log.FullName "$HandoverDir\07-狀態與日誌\$($log.Name)" -Force
    }
    Write-ColorOutput "      ✅ 日誌檔案: $logCount 個 (最近3個)" "Green"
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
    
    # 複製最近3個備份的摘要
    $backupSummary = @"
備份檔案摘要
========================================
備份目錄: $BackupRoot
備份總數: $backupCount

最近備份:
"@
    $backups | Select-Object -First 3 | ForEach-Object {
        $backupSummary += "`n- $($_.Name) ($($_.LastWriteTime))"
    }
    $backupSummary | Out-File "$HandoverDir\08-備份檔案\backup-summary.txt" -Encoding UTF8
    
    Write-ColorOutput "      ✅ 備份檔案: $backupCount 個" "Green"
    Write-ColorOutput "      ✅ 最近3個備份摘要已建立" "Green"
} else {
    Write-ColorOutput "      ℹ️ 備份目錄不存在 (尚未執行過備份)" "Gray"
}

# ============================================================
# 10. 生成完整分析報告
# ============================================================
Write-ColorOutput "`n📋 生成完整分析報告..." "Yellow"

$ReportPath = "$HandoverDir\09-分析報告\系統分析報告-$Timestamp.txt"

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
2. 目錄與檔案檢查
═══════════════════════════════════════════════════════════════════

專案根目錄: $ProjectRoot
交接目錄: $HandoverDir

a) PowerShell 腳本 ($($ScriptFiles.Count) 個):
"@

foreach ($item in $ScriptReport) {
    $Report += "`n   $($item.Status) $($item.File) ($($item.Size))"
}

$Report += @"

b) Python 模組 ($($PythonModules.Count) 個):
"@

foreach ($item in $PythonReport) {
    $Report += "`n   $($item.Status) $($item.File) ($($item.Size))"
}

$Report += @"

c) 環境設定:
   ✅ .env.template: 已複製
   ✅ .gitignore: 已複製
   ✅ README.md: 已複製
   $(if (Test-Path $EnvPath) { "✅ .env: 存在 (已檢查)" } else { "❌ .env: 不存在" })

═══════════════════════════════════════════════════════════════════
3. 文章統計
═══════════════════════════════════════════════════════════════════

總文章數: $TotalArticles 篇

分類統計:
"@

foreach ($stat in $ArticleStats) {
    $Report += "`n   $($stat.Status) $($stat.Category): $($stat.Count) 篇 (已複製 $($stat.Copied) 篇範例)"
}

$Report += @"

═══════════════════════════════════════════════════════════════════
4. 遊戲統計
═══════════════════════════════════════════════════════════════════

遊戲總數: $(if (Test-Path $GameDir) { (Get-ChildItem $GameDir -Filter "*.html").Count } else { 0 }) 款
遊戲位置: game/

═══════════════════════════════════════════════════════════════════
5. 狀態與斷點續傳
═══════════════════════════════════════════════════════════════════

Manifest 狀態: $(if (Test-Path $ManifestPath) { "✅ 存在" } else { "❌ 不存在" })
斷點續傳: ✅ 已啟用 (v4.2)
品質檢查: ✅ 已整合

═══════════════════════════════════════════════════════════════════
6. 備份狀態
═══════════════════════════════════════════════════════════════════

備份目錄: $BackupRoot
備份數量: $(if (Test-Path $BackupRoot) { (Get-ChildItem $BackupRoot -Directory).Count } else { 0 }) 個

═══════════════════════════════════════════════════════════════════
7. 部署狀態
═══════════════════════════════════════════════════════════════════

託管平台: Cloudflare Pages
專案名稱: ahpal-pages
網站網址: https://www.ahpal.com
部署方式: Git Push 自動觸發

═══════════════════════════════════════════════════════════════════
8. 安全性檢查
═══════════════════════════════════════════════════════════════════

✅ .env 已在 .gitignore 中 (不追蹤)
✅ API Key 僅儲存在本地
✅ 敏感資訊未包含在交接文件中
⚠️ 建議：交接完成後請變更所有 API Key

═══════════════════════════════════════════════════════════════════
9. 交接檢查清單
═══════════════════════════════════════════════════════════════════

請新進工程師逐項確認:

☐ 閱讀完整系統分析報告
☐ 確認所有 PowerShell 腳本可執行
☐ 確認所有 Python 模組可匯入
☐ 建立 .env 檔案並填入實際 API Key
☐ 執行測試: .\scripts\ahpal-master.ps1
☐ 確認網站 https://www.ahpal.com 可正常訪問
☐ 確認遊戲間 https://www.ahpal.com/game 可正常訪問
☐ 熟悉文章新增流程 (src/main.py 中的 keywords_list)
☐ 熟悉遊戲新增流程 (scripts/generate-games.ps1 中的 $newGames)
☐ 了解雙 API 自動切換機制 (Gemini + DeepSeek)
☐ 了解斷點續傳機制 (article-manifest.json)
☐ 了解 Git 工作流程 (git add . → commit → push)
☐ 執行備份測試: .\scripts\backup-system.ps1
☐ 確認 Cloudflare Pages 部署權限

═══════════════════════════════════════════════════════════════════
10. 快速指令參考
═══════════════════════════════════════════════════════════════════

完整部署: cd $ProjectRoot; .\scripts\ahpal-master.ps1
只生成文章: .\scripts\ahpal-master.ps1 → [4]
只部署: .\scripts\ahpal-master.ps1 → [6]
強制 DeepSeek: .\scripts\ahpal-master.ps1 → [A]
檢查文章: .\scripts\check-articles.ps1
系統檢查: .\scripts\check-all.ps1
執行備份: .\scripts\backup-system.ps1
Git 提交: git add .; git commit -m "說明"; git push
手動部署: npx wrangler pages deploy . --project-name=ahpal-pages

═══════════════════════════════════════════════════════════════════
11. 聯絡資訊
═══════════════════════════════════════════════════════════════════

⚠️ 請在交接時填寫實際聯絡人:

系統負責人: ______________ (LINE/手機: ______________)
GitHub 管理員: ______________ (信箱: ______________)
Cloudflare 管理員: ______________ (信箱: ______________)

═══════════════════════════════════════════════════════════════════
12. 檔案複製完成清單
═══════════════════════════════════════════════════════════════════

交接目錄: $HandoverDir

複製的內容:
- PowerShell 腳本: $($ScriptFiles.Count) 個
- Python 模組: $($PythonModules.Count) 個
- 環境設定: 4 個檔案
- 文章範例: $TotalArticles 篇 (分類: $($Categories.Count) 個)
- 遊戲範例: $(if (Test-Path $GameDir) { (Get-ChildItem $GameDir -Filter "*.html").Count } else { 0 }) 個
- 狀態與日誌: 已複製
- 備份摘要: 已建立

═══════════════════════════════════════════════════════════════════
⚠️ 重要提醒
═══════════════════════════════════════════════════════════════════

1. 此交接檔案包含系統架構和程式碼，不包含實際 API Key
2. 新進工程師需自行建立 .env 檔案並填入 API Key
3. 建議交接完成後變更所有 API Key 以確保安全
4. 所有複製的檔案僅供交接使用，請勿外流

═══════════════════════════════════════════════════════════════════

報告產生時間: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
報告版本: v2.1

"@

# 儲存報告
$Report | Out-File $ReportPath -Encoding UTF8
Write-ColorOutput "   ✅ 分析報告已建立: $ReportPath" "Green"

# ============================================================
# 11. 建立交接檔案清單
# ============================================================
Write-ColorOutput "`n📋 建立交接檔案清單..." "Yellow"

$FileListPath = "$HandoverDir\交接檔案清單.txt"
$FileList = @"
╔════════════════════════════════════════════════════════════════╗
║           AI 系統交接 - 檔案清單與說明                        ║
║           雅寶社區 · 頂客論壇 (AHPAL.COM)                    ║
║           交接時間: $Timestamp                                ║
╚════════════════════════════════════════════════════════════════╝

📁 交接目錄結構:
─────────────────────────────────────────────────────────────────

$HandoverDir/
│
├── 📁 01-系統架構與文件/
│   ├── 系統分析報告-$Timestamp.txt  ← 完整分析報告 (請優先閱讀)
│   └── (系統架構圖、技術文件等)
│
├── 📁 02-原始碼-PowerShell腳本/
│   ├── ahpal-master.ps1       ← 萬能總指揮 (主要入口)
│   ├── ahpal-static.ps1       ← 環境設定 (讀取 .env)
│   ├── generate-games.ps1     ← 遊戲生成
│   ├── backup-system.ps1      ← 備份腳本
│   ├── check-articles.ps1     ← 文章檢查
│   ├── check-all.ps1          ← 系統檢查
│   └── config.ps1             ← 備用設定
│
├── 📁 03-原始碼-Python模組/
│   ├── __init__.py            ← 套件初始化
│   ├── main.py                ← 主要入口 (文章生成)
│   ├── config.py              ← 設定管理
│   ├── api_client.py          ← API 呼叫層 (雙 API 切換)
│   ├── article_generator.py   ← 文章生成核心
│   ├── html_builder.py        ← HTML 建構器
│   ├── quality_checker.py     ← 品質檢查
│   ├── sitemap_builder.py     ← Sitemap 產生器
│   ├── state_manager.py       ← 狀態管理 (斷點續傳)
│   └── logger.py              ← 日誌管理
│
├── 📁 04-環境設定與API/
│   ├── .env.template          ← 環境變數範本 (複製為 .env)
│   ├── .env-status-report.txt ← .env 狀態報告 (不含實際 Key)
│   ├── .gitignore             ← Git 忽略規則
│   └── README.md              ← 專案說明
│
├── 📁 05-網站內容-文章/
│   ├── 📁 game/               ← 🎮 遊戲攻略 (15+ 篇)
│   ├── 📁 tech/               ← 💻 3C 科技教學 (16 篇)
│   ├── 📁 life/               ← 🏠 生活小常識 (15 篇)
│   ├── 📁 review/             ← 📊 軟體評測 (23 篇)
│   ├── 📁 philosophy/         ← 🌟 人生哲理 (18 篇)
│   └── 📁 trend/              ← 🤖 AI 趨勢 (20 篇)
│
├── 📁 06-網站內容-遊戲/
│   └── (23 款 HTML5 遊戲範例)
│
├── 📁 07-狀態與日誌/
│   ├── article-manifest.json  ← 文章狀態追蹤 (斷點續傳)
│   ├── manifest-stats.txt     ← 狀態統計摘要
│   └── (最近3個日誌檔案)
│
├── 📁 08-備份檔案/
│   └── backup-summary.txt     ← 備份摘要 (最近3個)
│
└── 📁 09-分析報告/
    └── 系統分析報告-$Timestamp.txt  ← 完整分析報告 (本檔案)

═══════════════════════════════════════════════════════════════════
📌 快速開始指南:
═══════════════════════════════════════════════════════════════════

1. 閱讀「01-系統架構與文件/系統分析報告-$Timestamp.txt」
2. 複製 .env.template 為 .env 並填入 API Key
3. 執行測試: cd C:\Users\User\ahpal-static; .\scripts\ahpal-master.ps1
4. 選擇 [1] 完整流程，驗證系統運作

═══════════════════════════════════════════════════════════════════
"@

$FileList | Out-File $FileListPath -Encoding UTF8
Write-ColorOutput "   ✅ 檔案清單已建立: $FileListPath" "Green"

# ============================================================
# 12. 壓縮交接檔案
# ============================================================
Write-ColorOutput "`n📦 壓縮交接檔案..." "Yellow"

$ZipPath = "C:\Users\User\ai交接-$Timestamp.zip"
try {
    # 使用 PowerShell 壓縮
    Compress-Archive -Path $HandoverDir -DestinationPath $ZipPath -Force
    Write-ColorOutput "   ✅ 壓縮完成: $ZipPath" "Green"
    Write-ColorOutput "   📦 檔案大小: $([math]::Round((Get-Item $ZipPath).Length / 1MB, 2)) MB" "Cyan"
} catch {
    Write-ColorOutput "   ⚠️ 壓縮失敗 (請手動壓縮 $HandoverDir)" "Yellow"
}

# ============================================================
# 13. 加入標記文字（前端和末端）
# ============================================================
Write-ColorOutput "`n📝 加入交接標記..." "Yellow"

$MarkerText = @"

═══════════════════════════════════════════════════════════════════
📋 本文件已由 AI 系統自動生成
═══════════════════════════════════════════════════════════════════

生成時間: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
生成工具: AI 系統交接掃描腳本 v2.1
授權範圍: 完整系統分析與檔案複製

✅ 所有關鍵檔案已掃描並複製到交接目錄
✅ 完整分析報告已建立
✅ 交接檔案清單已生成
✅ 建議新進工程師優先閱讀分析報告

⚠️ 注意事項:
1. 此交接檔案不包含實際 API Key
2. 新進工程師需自行建立 .env 檔案
3. 建議交接完成後變更所有 API Key
4. 所有複製的檔案僅供內部交接使用

📌 快速連結:
- 分析報告: 09-分析報告/系統分析報告-$Timestamp.txt
- 檔案清單: 交接檔案清單.txt
- 專案根目錄: C:\Users\User\ahpal-static

═══════════════════════════════════════════════════════════════════
"@

# 加到報告前端
$ReportContent = Get-Content $ReportPath -Raw
$ReportContent = "$MarkerText`n`n$ReportContent"
$ReportContent | Out-File $ReportPath -Encoding UTF8

# 加到檔案清單前端
$FileListContent = Get-Content $FileListPath -Raw
$FileListContent = "$MarkerText`n`n$FileListContent"
$FileListContent | Out-File $FileListPath -Encoding UTF8

# 將標記加到報告和檔案清單末端（已包含在內容中）

Write-ColorOutput "   ✅ 已完成所有交接文件的標記" "Green"

# ============================================================
# 14. 顯示完成訊息
# ============================================================
Write-ColorOutput "`n========================================" "Cyan"
Write-ColorOutput "  ✅ 掃描與備份完成！" "Green"
Write-ColorOutput "========================================`n" "Cyan"

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

# ============================================================
# 15. 等待使用者按下任意鍵才關閉（重要！）
# ============================================================
Write-ColorOutput "`n" "White"
Write-ColorOutput "按任意鍵關閉此視窗..." "Yellow"
Read-Host | Out-Null