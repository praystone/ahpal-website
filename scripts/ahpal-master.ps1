# ============================================================
# 雅寶社區 · 頂客論壇 - 萬能總指揮 v8.1
# ============================================================
# 功能：備份、處理待新增文章、生成遊戲、生成文章、Git 提交、
#       Cloudflare 部署、SEO 驗證、系統工具整合、餘額檢查
# ============================================================
# 🆕 v8.0 變更：
#   - 整合系統工具整合器 (system-toolkit.ps1)
#   - 新增完整 SEO 檢查 (含 master-articles.json)
#   - 新增執行前餘額檢查
#   - 新增執行前 .env 載入檢查
#   - 新增執行前死命令檢查 (可選)
#   - 強化錯誤處理
#   - 版本號升級至 v8.0
#
# 🆕 v8.1 變更：
#   - 🆕 $categories 新增 "nature": "🌳 動植物生態"
# ============================================================

param(
    [ValidateSet("full", "quick", "games", "articles", "backup", "deploy", "check", "status", "seo", "toolkit")]
    [string]$Action,
    [ValidateSet("gemini", "deepseek", "auto")]
    [string]$ForceApi,
    [switch]$Master,
    [switch]$SkipPreflight,
    [switch]$SkipBalance
)

# 防止雙擊執行後自動關閉
if ($Host.Name -eq "ConsoleHost" -and $MyInvocation.InvocationName -ne ".") {
    if ($Host.Name -ne "Windows PowerShell ISE Host") {
        $script:isDoubleClicked = $true
    }
}

# ============================================================
# 載入環境設定
# ============================================================
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
    Write-Host "✅ 已載入 .env 環境變數" -ForegroundColor Green
} else {
    Write-Host "⚠️ .env 檔案不存在，請先執行 .\scripts\ahpal-static.ps1" -ForegroundColor Yellow
}

# ============================================================
# 顏色函數
# ============================================================
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Section { Write-Host "`n$('='*60)" -ForegroundColor Cyan; Write-Host $args -ForegroundColor Cyan; Write-Host "$('='*60)" -ForegroundColor Cyan }

# ============================================================
# 輔助函數：檢查並處理待新增文章
# ============================================================
function Invoke-ProcessPending {
    param([string]$StepName = "檢查待新增文章")
    
    $PendingFile = Join-Path $ProjectRoot "data\pending-articles.json"
    
    if (-not (Test-Path $PendingFile)) {
        Write-Host "   ℹ️ 沒有待新增文章檔案" -ForegroundColor Gray
        return $false
    }
    
    $Content = Get-Content $PendingFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($Content) -or $Content -eq "[]") {
        Write-Host "   ℹ️ 待新增文章清單為空" -ForegroundColor Gray
        return $false
    }
    
    try {
        $Pending = $Content | ConvertFrom-Json
        $count = $Pending.Count
        if ($count -eq 0) {
            Write-Host "   ℹ️ 待新增文章清單為空" -ForegroundColor Gray
            return $false
        }
        Write-Host "   📋 發現 $count 篇待新增文章，執行 add-articles.ps1..." -ForegroundColor Yellow
        & "$ScriptDir\add-articles.ps1"
        return $true
    } catch {
        Write-Host "   ⚠️ pending-articles.json 格式有誤，跳過處理" -ForegroundColor Yellow
        return $false
    }
}

# ============================================================
# 🆕 輔助函數：檢查 DeepSeek 餘額
# ============================================================
function Invoke-BalanceCheck {
    Write-Host ""
    Write-Host "💰 檢查 DeepSeek 餘額..." -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    $BalanceScript = "$ScriptDir\check-deepseek-balance.ps1"
    if (Test-Path $BalanceScript) {
        & $BalanceScript
        if ($LASTEXITCODE -eq 1) {
            Write-Host "   ❌ 餘額不足，請儲值後再執行" -ForegroundColor Red
            return $false
        } elseif ($LASTEXITCODE -eq 2) {
            Write-Host "   ⚠️ 餘額查詢失敗，繼續執行..." -ForegroundColor Yellow
            return $true
        }
        return $true
    } else {
        Write-Host "   ⚠️ 找不到 check-deepseek-balance.ps1，跳過餘額檢查" -ForegroundColor Yellow
        return $true
    }
}

# ============================================================
# 🆕 輔助函數：執行死命令檢查
# ============================================================
function Invoke-PreflightCheck {
    Write-Host ""
    Write-Host "🔴 執行死命令檢查..." -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    $PreflightScript = "$ScriptDir\preflight-check.ps1"
    if (Test-Path $PreflightScript) {
        & $PreflightScript -Quiet
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 2) {
            Write-Host "   ❌ 死命令檢查失敗，請修正後再執行" -ForegroundColor Red
            return $false
        } elseif ($exitCode -eq 1) {
            Write-Host "   ⚠️ 有警告但無錯誤，繼續執行..." -ForegroundColor Yellow
            return $true
        }
        return $true
    } else {
        Write-Host "   ⚠️ 找不到 preflight-check.ps1，跳過死命令檢查" -ForegroundColor Yellow
        return $true
    }
}

# ============================================================
# 🆕 輔助函數：系統工具整合器
# ============================================================
function Invoke-SystemToolkit {
    Write-Section "🛠️ 系統工具整合器"
    
    $ToolkitPath = "C:\Users\User\ahpal-AI-archive\system-tools\system-toolkit.ps1"
    
    if (Test-Path $ToolkitPath) {
        Write-Success "  ✅ 找到系統工具整合器，啟動中..."
        & $ToolkitPath
    } else {
        Write-Error "  ❌ 找不到 system-toolkit.ps1"
        Write-Info "  📌 請確認路徑：$ToolkitPath"
        Write-Host ""
        Write-Info "  📌 你可以手動建立該檔案，或直接執行："
        Write-Gray "     C:\Users\User\ahpal-AI-archive\system-tools\system-toolkit.ps1"
        Read-Host "`n按 Enter 返回"
    }
}

# ============================================================
# 🆕 輔助函數：完整 SEO 檢查（含文章狀態）v3.1 (修正版)
# ============================================================
function Invoke-SeoFullCheck {
    Write-Section "🔍 完整 SEO 檢查 v3.1"

    # 1. 基礎檔案檢查 (呼叫原有函數)
    Invoke-SeoValidation -Master

    # 2. master-articles.json 文章狀態
    Write-Host ""
    Write-Host "📊 master-articles.json 文章狀態" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

    # 🆕 修正：使用 Python 的 json 模組，避免轉義問題
    python -c "
import json
import os

try:
    with open('data/master-articles.json', 'r', encoding='utf-8') as f:
        articles = json.load(f)
except Exception as e:
    print(f'❌ 讀取失敗：{e}')
    exit(1)

total = len(articles)
with_category = sum(1 for a in articles if a.get('category'))
with_filename = sum(1 for a in articles if a.get('filename'))
with_responses = sum(1 for a in articles if a.get('use_responses_api', False))
with_reasoning = sum(1 for a in articles if a.get('enable_reasoning', False))
with_search = sum(1 for a in articles if a.get('enable_search', False))

# 檢查分類分布
categories = {}
for a in articles:
    cat = a.get('category', '未分類')
    categories[cat] = categories.get(cat, 0) + 1

print(f'📊 文章總數：{total} 篇')
print()
print(f'📋 欄位覆蓋率：')
print(f'   ├─ 有分類：{with_category}/{total} ({with_category/total*100:.1f}%)')
print(f'   ├─ 有檔名：{with_filename}/{total} ({with_filename/total*100:.1f}%)')
print(f'   ├─ 使用 Responses API：{with_responses}/{total} ({with_responses/total*100:.1f}%)')
print(f'   ├─ 啟用 Reasoning：{with_reasoning}/{total} ({with_reasoning/total*100:.1f}%)')
print(f'   └─ 啟用 Search：{with_search}/{total} ({with_search/total*100:.1f}%)')
print()
print(f'📂 分類分布：')
for cat, count in sorted(categories.items(), key=lambda x: -x[1]):
    print(f'   ├─ {cat}：{count} 篇')
"

    # 3. 檢查文章檔案存在性 (獨立執行，避免變數干擾)
    Write-Host ""
    Write-Host "📁 文章檔案存在性檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray

    # 🆕 修正：使用獨立的 Python 腳本區塊，避免引號衝突
    python -c "
import json
import os

try:
    with open('data/master-articles.json', 'r', encoding='utf-8') as f:
        articles = json.load(f)
except Exception as e:
    print(f'❌ 無法讀取 master-articles.json: {e}')
    exit(1)

missing = []
for a in articles:
    filename = a.get('filename', '')
    if filename and not os.path.exists(filename):
        missing.append(a)

if missing:
    print(f'⚠️ 待生成文章：{len(missing)} 篇')
    for a in missing[:10]:
        kw = a.get('keyword', '未知')[:40]
        fn = a.get('filename', '')
        print(f'   - {kw}... → {fn}')
    if len(missing) > 10:
        print(f'   ... 還有 {len(missing)-10} 篇')
else:
    print('✅ 所有文章檔案都存在！')
"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  ✅ 完整 SEO 檢查完成！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Read-Host "`n按 Enter 返回"
}

# ============================================================
# 1. 驗證 SEO 基礎檔案 v2.1
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

        $articleCount = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { 
            $_.DirectoryName -notmatch "game" -and 
            $_.Name -notmatch "index|categories|dashboard|about|contact|privacy|terms" 
        } | Measure-Object).Count
        Write-Host "   📊 文章總數：$articleCount 篇" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  ✅ SEO 驗證完成！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""

    if ($allPass) {
        Write-Host "📋 狀態：所有基礎檔案正常 ✅" -ForegroundColor Green
    } else {
        Write-Host "📋 狀態：部分項目需注意 ⚠️" -ForegroundColor Yellow
    }
    Write-Host ""

    return $allPass
}

# ============================================================
# 2. 核心功能函數
# ============================================================

function Get-ArticleCount {
    $count = (Get-ChildItem -Recurse -Filter "*.html" | Where-Object { 
        $_.DirectoryName -notmatch "game" -and 
        $_.Name -notmatch "index|categories|dashboard|about|contact|privacy|terms|404|memorial|royal"
    } | Measure-Object).Count
    return $count
}

function Invoke-FullPipeline {
    Write-Section "▶️ 執行完整流程 (備份 + 處理待新增 + 生成 + Git + 部署)"
    
    # 執行前檢查
    if (-not $SkipBalance) {
        if (-not (Invoke-BalanceCheck)) {
            Write-Error "❌ 餘額不足，停止執行"
            return
        }
    }
    
    if (-not $SkipPreflight) {
        if (-not (Invoke-PreflightCheck)) {
            Write-Error "❌ 死命令檢查失敗，停止執行"
            return
        }
    }
    
    # 1. 備份
    Write-Host "   [1/5] 執行備份..." -ForegroundColor Yellow
    & "$ScriptDir\backup-system.ps1" -Compress
    
    # 2. 處理待新增文章
    Write-Host "   [2/5] 處理待新增文章..." -ForegroundColor Yellow
    Invoke-ProcessPending
    
    # 3. 生成文章
    Write-Host "   [3/5] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    # 4. Git 提交
    Write-Host "   [4/5] Git 提交..." -ForegroundColor Yellow
    git add .
    $articleCount = Get-ArticleCount
    git commit -m "🔄 完整更新 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    
    # 5. 部署
    Write-Host "   [5/5] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Success "✅ 完整流程執行完畢！"
}

function Invoke-QuickUpdate {
    Write-Section "▶️ 執行快速更新 (跳過備份)"
    
    if (-not $SkipBalance) {
        if (-not (Invoke-BalanceCheck)) {
            Write-Error "❌ 餘額不足，停止執行"
            return
        }
    }
    
    # 1. 處理待新增文章
    Write-Host "   [1/4] 處理待新增文章..." -ForegroundColor Yellow
    Invoke-ProcessPending
    
    # 2. 生成文章
    Write-Host "   [2/4] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    # 3. Git 提交
    Write-Host "   [3/4] Git 提交..." -ForegroundColor Yellow
    git add .
    $articleCount = Get-ArticleCount
    git commit -m "🔄 快速更新 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    git push origin main
    
    # 4. 部署
    Write-Host "   [4/4] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Success "✅ 快速更新執行完畢！"
}

function Invoke-GenerateGames {
    Write-Section "▶️ 生成遊戲"
    & "$ScriptDir\generate-games.ps1"
}

function Invoke-GenerateArticles {
    Write-Section "▶️ 生成文章 (遊戲 + 文章，不部署)"
    
    # 1. 生成遊戲
    Write-Host "   [1/3] 生成遊戲..." -ForegroundColor Yellow
    & "$ScriptDir\generate-games.ps1"
    
    # 2. 處理待新增文章
    Write-Host "   [2/3] 處理待新增文章..." -ForegroundColor Yellow
    Invoke-ProcessPending
    
    # 3. 生成文章
    Write-Host "   [3/3] 生成文章..." -ForegroundColor Yellow
    python src/main.py --force deepseek
    
    Write-Success "✅ 文章生成完畢！請手動執行部署"
}

function Invoke-Backup {
    Write-Section "▶️ 執行備份"
    & "$ScriptDir\backup-system.ps1" -Compress
}

function Invoke-GitAndDeploy {
    Write-Section "▶️ 執行 Git + 部署"
    
    $hasChanges = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($hasChanges -gt 0) {
        Write-Host "   [1/3] 發現 $hasChanges 個檔案變更，提交中..." -ForegroundColor Yellow
        git add .
        $articleCount = Get-ArticleCount
        git commit -m "🔄 更新文章 (總數: $articleCount 篇) | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    } else {
        Write-Host "   [1/3] 無變更，跳過提交" -ForegroundColor Yellow
    }
    
    Write-Host "   [2/3] 推送到 GitHub..." -ForegroundColor Yellow
    git push origin main
    
    Write-Host "   [3/3] 部署到 Cloudflare..." -ForegroundColor Yellow
    npx wrangler pages deploy . --project-name=ahpal-pages
    
    Write-Success "✅ Git + 部署執行完畢！"
}

function Invoke-CheckArticles {
    Write-Section "▶️ 檢查文章狀態"
    & "$ScriptDir\check-all.ps1" -Report
}

function Invoke-SystemStatus {
    Write-Section "📊 系統狀態"
    
    $articleCount = Get-ArticleCount
    $gameCount = (Get-ChildItem game -Filter "*.html" -ErrorAction SilentlyContinue | Measure-Object).Count
    
    Write-Host "   📝 文章總數：$articleCount 篇" -ForegroundColor Cyan
    Write-Host "   🎮 遊戲總數：$gameCount 款" -ForegroundColor Cyan
    
    $gitBranch = git branch --show-current 2>$null
    $gitCommit = git log --oneline -1 2>$null
    Write-Host "   🌿 Git 分支：$gitBranch" -ForegroundColor Cyan
    Write-Host "   📝 最新提交：$gitCommit" -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "📂 分類統計：" -ForegroundColor Yellow
    $categories = @{
        "tech" = "💻 3C 科技教學"
        "life" = "🏠 生活小常識"
        "review" = "📊 軟體評測"
        "philosophy" = "🌟 人生哲理"
        "trend" = "🤖 AI 趨勢"
        "history" = "📜 歷史腦洞"
        "music" = "🎵 音樂創作"
        "nature" = "🌳 動植物生態"      # 🆕 新增
    }
    foreach ($cat in $categories.Keys) {
        if (Test-Path $cat) {
            $c = (Get-ChildItem -Path $cat -Filter "*.html" -ErrorAction SilentlyContinue).Count
            Write-Host "   $($categories[$cat])：$c 篇" -ForegroundColor Gray
        }
    }
    Write-Host "   🎮 遊戲攻略：$gameCount 款" -ForegroundColor Gray
    
    # 檢查 DeepSeek 餘額
    Write-Host ""
    Write-Host "💰 餘額狀態：" -ForegroundColor Yellow
    & "$ScriptDir\check-deepseek-balance.ps1" 2>$null
}

function Set-ForceApi {
    param([string]$mode)
    Write-Section "🔧 設定強制 API：$mode"
    
    $flagFile = Join-Path $ProjectRoot ".force-api"
    if ($mode -eq "auto") {
        if (Test-Path $flagFile) { Remove-Item $flagFile -Force }
        Write-Success "  ✅ 已恢復自動切換模式"
    } else {
        $mode | Out-File $flagFile -Encoding UTF8
        Write-Success "  ✅ 已強制使用 $mode"
    }
}

# ============================================================
# 3. 主選單
# ============================================================
function Show-MainMenu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  雅寶社區 · 頂客論壇 - 萬能總指揮 v8.1" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📊 系統狀態：" -ForegroundColor Yellow
    
    $articleCount = Get-ArticleCount
    $gameCount = (Get-ChildItem game -Filter "*.html" -ErrorAction SilentlyContinue | Measure-Object).Count
    
    Write-Host "   📝 文章總數：$articleCount 篇" -ForegroundColor Cyan
    Write-Host "   🎮 遊戲數量：$gameCount 款" -ForegroundColor Cyan
    
    $PendingFile = Join-Path $ProjectRoot "data\pending-articles.json"
    if (Test-Path $PendingFile) {
        try {
            $Content = Get-Content $PendingFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if (-not [string]::IsNullOrWhiteSpace($Content) -and $Content -ne "[]") {
                $Pending = $Content | ConvertFrom-Json -ErrorAction SilentlyContinue
                if ($Pending -and $Pending.Count -gt 0) {
                    Write-Host "   📋 待新增文章：$($Pending.Count) 篇 ⚠️" -ForegroundColor Yellow
                }
            }
        } catch {}
    }
    Write-Host ""
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [1] 完整流程 (備份 + 處理待新增 + 生成 + Git + 部署)"
    Write-Host "   [2] 快速更新 (處理待新增 + 生成 + Git + 部署)"
    Write-Host "   [3] 只生成遊戲 (不耗 API，快速)"
    Write-Host "   [4] 只生成文章 (遊戲 + 處理待新增 + 文章，不部署)"
    Write-Host "   [5] 只做備份 (不生成、不部署)"
    Write-Host "   [6] 只做 Git + 部署 (不生成)"
    Write-Host "   [7] 檢查文章狀態"
    Write-Host "   [8] 查看系統狀態 (含餘額)"
    Write-Host ""
    Write-Host "   [S] 🔍 SEO 基礎檔案驗證 (robots.txt / ads.txt / sitemap.xml)"
    Write-Host "   [E] 📊 完整 SEO 檢查 (含文章狀態與檔案存在性)"  # 🆕
    Write-Host "   [T] 🛠️ 系統工具與診斷 (開機優化/硬體報告/備份)"  # 🆕
    Write-Host ""
    Write-Host "   [A] 🔧 強制使用 Gemini (尖峰時段也適用)"
    Write-Host "   [D] 🔧 強制使用 DeepSeek"
    Write-Host "   [B] 🔄 恢復自動切換模式"
    Write-Host ""
    Write-Host "   [0] 退出腳本"
    Write-Host ""
    $choice = Read-Host "請輸入選項"

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
        "E" { Invoke-SeoFullCheck }
        "e" { Invoke-SeoFullCheck }
        "T" { Invoke-SystemToolkit }
        "t" { Invoke-SystemToolkit }
        "A" { Set-ForceApi "gemini" }
        "D" { Set-ForceApi "deepseek" }
        "B" { Set-ForceApi "auto" }
        "0" { exit }
        default { Write-Host "❌ 無效選項，請重新選擇" -ForegroundColor Red; Start-Sleep 2; Show-MainMenu }
    }
}

# ============================================================
# 4. 啟動
# ============================================================
if ($Action) {
    Write-Host "🦞 AHPAL 萬能總指揮 v8.1 (命令列模式)" -ForegroundColor Cyan
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
        "toolkit" { Invoke-SystemToolkit }
        default { Write-Host "❌ 未知 Action: $Action" -ForegroundColor Red }
    }
} elseif ($ForceApi) {
    Set-ForceApi $ForceApi
} else {
    Show-MainMenu
}

if ($script:isDoubleClicked) {
    Write-Host ""
    Write-Host "按 Enter 鍵結束..." -ForegroundColor Gray
    Read-Host
}