# ============================================================
# 雅寶社區 · 頂客論壇 - 萬能總指揮 v7.1
# ============================================================
# 功能：備份、生成遊戲、生成文章、Git 提交、Cloudflare 部署、SEO 驗證
# 支援命令列參數：.\ahpal-master.ps1 -Action full|quick|games|articles|backup|deploy|check|status|seo
# 支援強制 API：.\ahpal-master.ps1 -ForceApi gemini|deepseek|auto
# ============================================================

param(
    [ValidateSet("full", "quick", "games", "articles", "backup", "deploy", "check", "status", "seo")]
    [string]$Action,
    [ValidateSet("gemini", "deepseek", "auto")]
    [string]$ForceApi,
    [switch]$Master
)

# 防止雙擊執行後自動關閉
if ($Host.Name -eq "ConsoleHost" -and $MyInvocation.InvocationName -ne ".") {
    if ($Host.Name -ne "Windows PowerShell ISE Host") {
        $script:isDoubleClicked = $true
    }
}

# 載入環境設定
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

# 載入 .env
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

# ============================================================
# 1. 驗證 SEO 基礎檔案（獨立函數）v2.1
# ============================================================
function Invoke-SeoValidation {
    param([switch]$Master)
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  🔍 SEO 基礎檔案驗證 v2.1" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $allPass = $true

    # --- robots.txt ---
    Write-Host "📄 1. robots.txt" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

    if (Test-Path "robots.txt") {
        $robots = Get-Content "robots.txt" -Raw -Encoding UTF8
        $file = Get-ChildItem "robots.txt"
        Write-Host "   ✅ 檔案存在" -ForegroundColor Green
        Write-Host "   📦 大小：$([math]::Round($file.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "   🕐 修改時間：$($file.LastWriteTime)" -ForegroundColor Gray

        if ($robots -match "Sitemap: https://www.ahpal.com/sitemap.xml") {
            Write-Host "   ✅ Sitemap 宣告：正確" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ Sitemap 宣告：遺失" -ForegroundColor Yellow
            $allPass = $false
        }

        # 🔧 優化：檢查 Cloudflare Managed 區塊（自動添加）或本地手動添加的 AI 爬蟲規則
        if ($robots -match "Cloudflare Managed|GPTBot|ClaudeBot") {
            Write-Host "   ✅ AI 爬蟲封鎖：已設定 (Cloudflare 自動管理)" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ AI 爬蟲封鎖：未設定（Cloudflare 部署後會自動添加）" -ForegroundColor Yellow
            # 不將此項設為失敗，因為 Cloudflare 會自動添加
        }

        try {
            $r = Invoke-WebRequest -Uri "https://www.ahpal.com/robots.txt" -UseBasicParsing -ErrorAction Stop
            Write-Host "   🌐 正式網站：✅ 狀態碼 $($r.StatusCode)" -ForegroundColor Green
        } catch {
            Write-Host "   🌐 正式網站：⚠️ 無法訪問 (可能尚未部署)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
        $allPass = $false
    }

    # --- ads.txt ---
    Write-Host ""
    Write-Host "📄 2. ads.txt" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

    if (Test-Path "ads.txt") {
        $ads = Get-Content "ads.txt" -Raw -Encoding UTF8
        $file = Get-ChildItem "ads.txt"
        Write-Host "   ✅ 檔案存在" -ForegroundColor Green
        Write-Host "   📦 大小：$([math]::Round($file.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "   🕐 修改時間：$($file.LastWriteTime)" -ForegroundColor Gray

        if ($ads -match "pub-8637791667872348") {
            Write-Host "   ✅ AdSense PUB-ID：正確" -ForegroundColor Green
        } else {
            Write-Host "   ❌ AdSense PUB-ID：遺失" -ForegroundColor Red
            $allPass = $false
        }

        $lines = $ads -split "`n" | Where-Object { $_.Trim() -ne "" }
        if ($lines.Count -eq 1) {
            Write-Host "   ✅ 格式：僅含 AdSense 宣告" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ 格式：包含其他內容" -ForegroundColor Yellow
        }

        try {
            $a = Invoke-WebRequest -Uri "https://www.ahpal.com/ads.txt" -UseBasicParsing -ErrorAction Stop
            Write-Host "   🌐 正式網站：✅ 狀態碼 $($a.StatusCode)" -ForegroundColor Green
        } catch {
            Write-Host "   🌐 正式網站：⚠️ 無法訪問 (可能尚未部署)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
        $allPass = $false
    }

    # --- sitemap.xml ---
    Write-Host ""
    Write-Host "📄 3. sitemap.xml" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

    if (Test-Path "sitemap.xml") {
        $sitemap = Get-Content "sitemap.xml" -Raw -Encoding UTF8
        $file = Get-ChildItem "sitemap.xml"
        Write-Host "   ✅ 檔案存在" -ForegroundColor Green
        Write-Host "   📦 大小：$([math]::Round($file.Length / 1KB, 2)) KB" -ForegroundColor Gray
        Write-Host "   🕐 修改時間：$($file.LastWriteTime)" -ForegroundColor Gray

        if ($sitemap -match "<\?xml.*encoding=""UTF-8""\?>") {
            Write-Host "   ✅ XML 格式：正確" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ XML 格式：無法確認" -ForegroundColor Yellow
        }

        $urlCount = ([regex]::Matches($sitemap, "<loc>")).Count
        if ($urlCount -ge 50) {
            Write-Host "   ✅ URL 數量：$urlCount 個" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ URL 數量：$urlCount 個 (偏低)" -ForegroundColor Yellow
        }

        if ($sitemap -match "<loc>https://www.ahpal.com/</loc>") {
            Write-Host "   ✅ 首頁已包含" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ 首頁未包含" -ForegroundColor Yellow
        }

        try {
            $s = Invoke-WebRequest -Uri "https://www.ahpal.com/sitemap.xml" -UseBasicParsing -ErrorAction Stop
            Write-Host "   🌐 正式網站：✅ 狀態碼 $($s.StatusCode)" -ForegroundColor Green
        } catch {
            Write-Host "   🌐 正式網站：⚠️ 無法訪問 (可能尚未部署)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ 檔案不存在" -ForegroundColor Red
        $allPass = $false
    }

    # --- Master 模式 ---
    if ($Master) {
        Write-Host ""
        Write-Host "📋 Master 模式資訊" -ForegroundColor Yellow
        Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

        $gitBranch = git branch --show-current 2>$null
        $gitCommit = git log --oneline -1 2>$null
        Write-Host "   🌿 Git 分支：$gitBranch" -ForegroundColor Cyan
        Write-Host "   📝 最新提交：$gitCommit" -ForegroundColor Cyan

        $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories|dashboard|about|contact|privacy|terms" } | Measure-Object).Count
        Write-Host "   📊 文章總數：$articleCount 篇" -ForegroundColor Cyan
    }

    # --- 總結 ---
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  ✅ SEO 驗證完成！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""

    if ($allPass) {
        Write-Host "📋 狀態：所有基礎檔案正常 ✅" -ForegroundColor Green
    } else {
        Write-Host "📋 狀態：部分項目需注意 ⚠️" -ForegroundColor Yellow
        Write-Host "   💡 robots.txt AI 爬蟲封鎖由 Cloudflare 自動管理" -ForegroundColor Gray
    }
    Write-Host ""

    return $allPass
}

# ============================================================
# 2. 核心功能函數（直接實作，避免遞迴呼叫）
# ============================================================
function Invoke-FullPipeline {
    Write-Host ""
    Write-Host "▶️ 執行完整流程 (備份 + 生成 + Git + 部署)..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 1. 備份
    Write-Host "   [1/4] 執行備份..." -ForegroundColor Yellow
    & "$ScriptDir\backup-system.ps1" -Compress
    
    # 2. 生成文章
    Write-Host "   [2/4] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    # 3. Git 提交
    Write-Host "   [3/4] Git 提交..." -ForegroundColor Yellow
    git add .
    $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories" } | Measure-Object).Count
    git commit -m "🔄 完整更新 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    
    # 4. 部署
    Write-Host "   [4/4] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Host "✅ 完整流程執行完畢！" -ForegroundColor Green
}

function Invoke-QuickUpdate {
    Write-Host ""
    Write-Host "▶️ 執行快速更新 (跳過備份)..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 1. 生成文章
    Write-Host "   [1/3] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    # 2. Git 提交
    Write-Host "   [2/3] Git 提交..." -ForegroundColor Yellow
    git add .
    $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories" } | Measure-Object).Count
    git commit -m "🔄 快速更新 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    
    # 3. 部署
    Write-Host "   [3/3] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Host "✅ 快速更新執行完畢！" -ForegroundColor Green
}

function Invoke-GenerateGames {
    Write-Host ""
    Write-Host "▶️ 生成遊戲..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    & "$ScriptDir\generate-games.ps1"
}

function Invoke-GenerateArticles {
    Write-Host ""
    Write-Host "▶️ 生成文章 (遊戲 + 文章，不部署)..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 1. 生成遊戲
    Write-Host "   [1/2] 生成遊戲..." -ForegroundColor Yellow
    & "$ScriptDir\generate-games.ps1"
    
    # 2. 生成文章
    Write-Host "   [2/2] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    Write-Host "✅ 文章生成完畢！請手動執行部署" -ForegroundColor Green
}

function Invoke-Backup {
    Write-Host ""
    Write-Host "▶️ 執行備份..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    & "$ScriptDir\backup-system.ps1" -Compress
}

function Invoke-GitAndDeploy {
    Write-Host ""
    Write-Host "▶️ 執行 Git + 部署..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 1. 檢查變更
    $hasChanges = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($hasChanges -gt 0) {
        Write-Host "   [1/3] 發現 $hasChanges 個檔案變更，提交中..." -ForegroundColor Yellow
        git add .
        $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories" } | Measure-Object).Count
        git commit -m "🔄 更新文章 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    } else {
        Write-Host "   [1/3] 無變更，跳過提交" -ForegroundColor Yellow
    }
    
    # 2. 推送
    Write-Host "   [2/3] 推送到 GitHub..." -ForegroundColor Yellow
    git push origin main
    
    # 3. 部署
    Write-Host "   [3/3] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Host "✅ Git + 部署執行完畢！" -ForegroundColor Green
}

# 改為：
function Invoke-CheckArticles {
    Write-Host ""
    Write-Host "▶️ 檢查文章狀態..." -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    & "$ScriptDir\check-all.ps1" -Report
}
# (名稱相同，但 check-all.ps1 已包含所有功能)


function Invoke-SystemStatus {
    Write-Host ""
    Write-Host "📊 系統狀態" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 文章統計
    $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories|dashboard|about|contact|privacy|terms" } | Measure-Object).Count
    Write-Host "   📝 文章總數：$articleCount 篇" -ForegroundColor Cyan
    
    # 遊戲統計
    $gameCount = (Get-ChildItem game -Filter "*.html" -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "   🎮 遊戲總數：$gameCount 款" -ForegroundColor Cyan
    
    # Git 狀態
    $gitBranch = git branch --show-current 2>$null
    $gitCommit = git log --oneline -1 2>$null
    Write-Host "   🌿 Git 分支：$gitBranch" -ForegroundColor Cyan
    Write-Host "   📝 最新提交：$gitCommit" -ForegroundColor Cyan
    
    # 分類統計
    Write-Host ""
    Write-Host "📂 分類統計：" -ForegroundColor Yellow
    $categories = @{
        "tech" = "💻 3C 科技教學"
        "life" = "🏠 生活小常識"
        "review" = "📊 軟體評測"
        "philosophy" = "🌟 人生哲理"
        "trend" = "🤖 AI 趨勢"
    }
    foreach ($cat in $categories.Keys) {
        if (Test-Path $cat) {
            $c = (Get-ChildItem -Path $cat -Filter "*.html" -ErrorAction SilentlyContinue).Count
            Write-Host "   $($categories[$cat])：$c 篇" -ForegroundColor Gray
        }
    }
    Write-Host "   🎮 遊戲攻略：$gameCount 款" -ForegroundColor Gray
}

function Set-ForceApi {
    param([string]$mode)
    Write-Host ""
    Write-Host "🔧 設定強制 API：$mode" -ForegroundColor Cyan
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    # 寫入臨時標記
    $flagFile = Join-Path $ProjectRoot ".force-api"
    if ($mode -eq "auto") {
        if (Test-Path $flagFile) { Remove-Item $flagFile -Force }
        Write-Host "   ✅ 已恢復自動切換模式" -ForegroundColor Green
    } else {
        $mode | Out-File $flagFile -Encoding UTF8
        Write-Host "   ✅ 已強制使用 $mode" -ForegroundColor Green
    }
}

# ============================================================
# 3. 主選單（僅在無命令列參數時顯示）
# ============================================================
function Show-MainMenu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  雅寶社區 · 頂客論壇 - 萬能總指揮 v7.1" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 系統狀態：" -ForegroundColor Yellow
    
    $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { $_.DirectoryName -notmatch "game" -and $_.Name -notmatch "index|categories|dashboard|about|contact|privacy|terms" } | Measure-Object).Count
    $gameCount = (Get-ChildItem game -Filter "*.html" -ErrorAction SilentlyContinue | Measure-Object).Count
    
    Write-Host "   📝 文章總數：$articleCount 篇" -ForegroundColor Cyan
    Write-Host "   🎮 遊戲數量：$gameCount 款" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [1] 完整流程 (備份 + 生成 + Git + 部署)"
    Write-Host "   [2] 快速更新 (跳過備份)"
    Write-Host "   [3] 只生成遊戲 (不耗 API，快速)"
    Write-Host "   [4] 只生成文章 (遊戲 + 文章，不部署)"
    Write-Host "   [5] 只做備份 (不生成、不部署)"
    Write-Host "   [6] 只做 Git + 部署 (不生成)"
    Write-Host "   [7] 檢查文章狀態"
    Write-Host "   [8] 查看系統狀態"
    Write-Host "   [S] 🔍 SEO 驗證 (robots.txt / ads.txt / sitemap.xml)"
    Write-Host ""
    Write-Host "   [A] 🔧 強制使用 Gemini (尖峰時段也適用)"
    Write-Host "   [D] 🔧 強制使用 DeepSeek"
    Write-Host "   [B] 🔄 恢復自動切換模式"
    Write-Host ""
    Write-Host "   [0] 退出腳本"
    Write-Host ""
    $choice = Read-Host "請輸入選項 (0-9 或 A/B/D/S)"

    switch ($choice) {
        "1" { Invoke-FullPipeline }
        "2" { Invoke-QuickUpdate }
        "3" { Invoke-GenerateGames }
        "4" { Invoke-GenerateArticles }
        "5" { Invoke-Backup }
        "6" { Invoke-GitAndDeploy }
        "7" { Invoke-CheckArticles }
        "8" { Invoke-SystemStatus }
        "S" { Invoke-SeoValidation -Master }
        "s" { Invoke-SeoValidation -Master }
        "A" { Set-ForceApi "gemini" }
        "D" { Set-ForceApi "deepseek" }
        "B" { Set-ForceApi "auto" }
        "0" { exit }
        default { Write-Host "❌ 無效選項，請重新選擇" -ForegroundColor Red; Start-Sleep 2; Show-MainMenu }
    }
}

# ============================================================
# 4. 啟動（判斷是否有命令列參數）
# ============================================================
if ($Action) {
    # 命令列模式
    Write-Host "🦞 AHPAL 萬能總指揮 v7.1 (命令列模式)" -ForegroundColor Cyan
    Write-Host "   Action: $Action" -ForegroundColor Gray
    
    switch ($Action) {
        "full" { Invoke-FullPipeline }
        "quick" { Invoke-QuickUpdate }
        "games" { Invoke-GenerateGames }
        "articles" { Invoke-GenerateArticles }
        "backup" { Invoke-Backup }
        "deploy" { Invoke-GitAndDeploy }
        "check" { Invoke-CheckArticles }
        "status" { Invoke-SystemStatus }
        "seo" { Invoke-SeoValidation -Master }
        default { Write-Host "❌ 未知 Action: $Action" -ForegroundColor Red }
    }
} elseif ($ForceApi) {
    # 強制 API 模式
    Set-ForceApi $ForceApi
} else {
    # 互動式選單模式
    Show-MainMenu
}

# 防止雙擊後自動關閉
if ($script:isDoubleClicked) {
    Write-Host ""
    Write-Host "按 Enter 鍵結束..." -ForegroundColor Gray
    Read-Host
}