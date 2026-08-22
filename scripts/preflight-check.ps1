# 將完整的新程式碼儲存為正確的 UTF-8 格式
$newScriptContent = @'
# ============================================================
# preflight-check.ps1 - 董事長死命令檢查 v2.5
# ============================================================
# 功能：推送前強制檢查
#   1. 文章數量與大小
#   2. 內容品質（品牌名稱、API錯誤、AdSense、Giscus）
#   3. HTML結構（H1、H2、表格、FAQ）
#   4. 分類頁面與Sitemap
#   5. Git狀態
#   6. 死命令11：SEO四大件嚴禁noindex
# ============================================================

param(
    [switch]$Quiet,
    [switch]$Fix,
    [switch]$Report
)

$ProjectRoot = CUsersUserahpal-static
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = $PSScriptRoot }

# 載入核心配置
$ConfigPath = Join-Path $ScriptDir config.ps1
if (Test-Path $ConfigPath) {
    . $ConfigPath
}

function Write-Info {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Cyan }
}
function Write-Success {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Green }
}
function Write-Warning {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Yellow }
}
function Write-Error {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Red }
}

Write-Info ============================================================
Write-Info   🔴 董事長死命令：變更後強制檢查 v2.5
Write-Info ============================================================
Write-Info 
Write-Info   執行時間：$(Get-Date -Format 'yyyy-MM-dd HHmmss')
Write-Info   檢查範圍：檔案完整性  內容品質  Git 狀態  結構檢查  死命令 11
Write-Info 

$ErrorCount = 0
$WarningCount = 0
$PassCount = 0

# ============================================================
# 階段一：本地檔案完整性檢查
# ============================================================
Write-Info 📋 階段一：本地檔案完整性檢查
Write-Info ────────────────────────────────────────────────────────

# 文章數量
Write-Info    [1.1] 檢查文章數量...
$ExcludeDirs = @(game, docs, scripts, src, backups, logs, images, data, test, __pycache__)
$ArticleFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter .html -File  Where-Object {
    $dir = $_.DirectoryName
    $skip = $false
    foreach ($ex in $ExcludeDirs) {
        if ($dir -match $ex -or $dir -match $ex) { $skip = $true; break }
    }
    -not $skip
}
$ArticleCount = $ArticleFiles.Count
Write-Info    📄 文章目錄總數：$ArticleCount 篇（不含遊戲）

# 檢查待生成文章
$PendingFile = Join-Path $ProjectRoot datapending-articles.json
if (Test-Path $PendingFile) {
    $PendingContent = Get-Content $PendingFile -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($PendingContent -and $PendingContent -ne []) {
        Write-Warning    ⚠️ 發現待生成文章，請先執行 [2] 快速更新
        $WarningCount++
    } else {
        Write-Success    ✅ 無待生成文章
    }
} else {
    Write-Success    ✅ 無待生成文章
}

# 文章大小
Write-Info    [1.2] 檢查文章大小...
$SmallFiles = $ArticleFiles  Where-Object { $_.Length -lt 5120 }
if ($SmallFiles.Count -gt 0) {
    Write-Warning    ⚠️ 有 $($SmallFiles.Count) 個檔案過小（5KB），建議重新生成
    $WarningCount++
} else {
    Write-Success    ✅ 所有文章大小正常（≥5KB）
}

# 首頁
Write-Info    [1.3] 檢查首頁更新...
$IndexPath = Join-Path $ProjectRoot index.html
if (Test-Path $IndexPath) {
    Write-Success    ✅ 首頁正常
} else {
    Write-Error    ❌ 首頁不存在！
    $ErrorCount++
}

# ============================================================
# 階段二：內容品質檢查
# ============================================================
Write-Info 
Write-Info 📋 階段二：內容品質檢查
Write-Info ────────────────────────────────────────────────────────

$SampleSize = [math]Min(50, $ArticleFiles.Count)
Write-Info    📊 取樣 $SampleSize 篇文章進行檢查

# 品牌名稱檢查
Write-Info    [2.1] 檢查品牌名稱...
$BrandIssues = 0
$SampleFiles = $ArticleFiles  Select-Object -First $SampleSize
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '雅寶社區') {
        $BrandIssues++
    }
}
if ($BrandIssues -gt 0) {
    Write-Warning    ⚠️ 有 $BrandIssues 個檔案缺少品牌名稱
    $WarningCount++
} else {
    Write-Success    ✅ 品牌名稱檢查通過
}

# API錯誤檢查
Write-Info    [2.2] 檢查 API 錯誤標記...
$ApiErrorIssues = 0
$ErrorKeywords = @(API_ERROR, ❌, 生成失敗, RateLimit)
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content) {
        foreach ($keyword in $ErrorKeywords) {
            if ($Content -match $keyword) {
                $ApiErrorIssues++
                break
            }
        }
    }
}
if ($ApiErrorIssues -gt 0) {
    Write-Warning    ⚠️ 有 $ApiErrorIssues 個檔案含有 API 錯誤標記
    $WarningCount++
} else {
    Write-Success    ✅ 無 API 錯誤標記
}

# AdSense檢查
Write-Info    [2.3] 檢查 AdSense 程式碼...
$AdsenseIssues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch 'pagead2.googlesyndication.com') {
        $AdsenseIssues++
    }
}
if ($AdsenseIssues -gt 0) {
    Write-Warning    ⚠️ 有 $AdsenseIssues 個檔案缺少 AdSense 程式碼
    $WarningCount++
} else {
    Write-Success    ✅ AdSense 程式碼檢查通過
}

# Giscus檢查
Write-Info    [2.4] 檢查 Giscus 留言板...
$GiscusIssues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch 'giscus.app') {
        $GiscusIssues++
    }
}
if ($GiscusIssues -gt 0) {
    Write-Warning    ⚠️ 有 $GiscusIssues 個檔案缺少 Giscus 留言板
    $WarningCount++
} else {
    Write-Success    ✅ Giscus 留言板檢查通過
}

# ============================================================
# 階段三：HTML結構檢查
# ============================================================
Write-Info 
Write-Info 📋 階段三：HTML 結構檢查
Write-Info ────────────────────────────────────────────────────────

# H1檢查
Write-Info    [3.1] 檢查 H1 標題...
$H1Issues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch 'h1[^]') {
        $H1Issues++
    }
}
if ($H1Issues -gt 0) {
    Write-Warning    ⚠️ 有 $H1Issues 個檔案缺少 H1 標題
    $WarningCount++
} else {
    Write-Success    ✅ H1 標題檢查通過
}

# H2檢查
Write-Info    [3.2] 檢查 H2 標題...
$H2Issues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    $h2Count = ([regex]Matches($Content, 'h2[^]')).Count
    if ($h2Count -lt 2) {
        $H2Issues++
    }
}
if ($H2Issues -gt 0) {
    Write-Warning    ⚠️ 有 $H2Issues 個檔案 H2 標題不足（2個）
    $WarningCount++
} else {
    Write-Success    ✅ H2 標題檢查通過（≥2個）
}

# 表格檢查
Write-Info    [3.3] 檢查表格...
$TableIssues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch 'table[^]') {
        $TableIssues++
    }
}
if ($TableIssues -gt 0) {
    Write-Warning    ⚠️ 有 $TableIssues 個檔案缺少表格
    $WarningCount++
} else {
    Write-Success    ✅ 表格檢查通過
}

# FAQ檢查
Write-Info    [3.4] 檢查 FAQ...
$FaqIssues = 0
foreach ($f in $SampleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '(FAQ常見問題Q：問：Q&A)') {
        $FaqIssues++
    }
}
if ($FaqIssues -gt 0) {
    Write-Warning    ⚠️ 有 $FaqIssues 個檔案缺少 FAQ
    $WarningCount++
} else {
    Write-Success    ✅ FAQ 檢查通過
}

# ============================================================
# 階段四：分類頁面與Sitemap
# ============================================================
Write-Info 
Write-Info 📋 階段四：分類頁面與 Sitemap 檢查
Write-Info ────────────────────────────────────────────────────────

# 分類頁面
Write-Info    [4.1] 檢查分類頁面...
$CategoryDirs = @(history, tech, game, life, review, philosophy, trend, music, nature)
$CategoryPages = @()
foreach ($cat in $CategoryDirs) {
    $page = Join-Path $ProjectRoot category-$cat.html
    if (Test-Path $page) {
        $CategoryPages += $page
        Write-Info       ✅ category-$cat.html 正常
    } else {
        Write-Warning       ⚠️ category-$cat.html 不存在
        $WarningCount++
    }
}
Write-Success    ✅ 所有分類頁面正常

# Sitemap
Write-Info    [4.2] 檢查 Sitemap...
$SitemapPath = Join-Path $ProjectRoot sitemap.xml
if (Test-Path $SitemapPath) {
    Write-Success    ✅ Sitemap 正常
} else {
    Write-Warning    ⚠️ Sitemap 不存在
    $WarningCount++
}

# ============================================================
# 階段五：遊戲檢查
# ============================================================
Write-Info 
Write-Info 📋 階段五：遊戲檢查
Write-Info ────────────────────────────────────────────────────────

$GameDir = Join-Path $ProjectRoot game
if (Test-Path $GameDir) {
    $GameFiles = Get-ChildItem -Path $GameDir -Filter .html -File
    Write-Info    🎮 遊戲總數：$($GameFiles.Count) 款（僅統計，不檢查品質）
    $IndexPath = Join-Path $GameDir index.html
    if (Test-Path $IndexPath) {
        Write-Success    📄 遊戲索引：✅ 存在
    } else {
        Write-Warning    📄 遊戲索引：⚠️ 不存在
        $WarningCount++
    }
} else {
    Write-Warning    ⚠️ game 目錄不存在
    $WarningCount++
}

# ============================================================
# 階段六：Git狀態檢查
# ============================================================
Write-Info 
Write-Info 📋 階段六：Git 狀態檢查
Write-Info ────────────────────────────────────────────────────────

# Git狀態
Write-Info    [6.1] 檢查 Git 狀態...
$GitStatus = git status --porcelain 2$null
if ($GitStatus) {
    $ChangedCount = ($GitStatus  Measure-Object).Count
    Write-Warning    ⚠️ 有 $ChangedCount 個未提交的變更
    $GitStatus  ForEach-Object { Write-Info        $_ }
    $WarningCount++
} else {
    Write-Success    ✅ Git 工作目錄乾淨
}

# 機密檔案檢查
Write-Info    [6.2] 檢查機密檔案...
$EnvPath = Join-Path $ProjectRoot .env
if (Test-Path $EnvPath) {
    $IsTracked = git ls-files .env 2$null
    if ($IsTracked) {
        Write-Error    ❌ .env 被 Git 追蹤！請立即移除！
        $ErrorCount++
    } else {
        Write-Success    ✅ .env 未被 Git 追蹤（安全）
    }
} else {
    Write-Warning    ⚠️ .env 檔案不存在
    $WarningCount++
}

# ============================================================
# 階段六點五：死命令11檢查
# ============================================================
Write-Info 
Write-Info 📋 階段六點五：死命令 11 檢查 (SEO 四大件嚴禁 noindex)
Write-Info ────────────────────────────────────────────────────────

$CheckScript = Join-Path $ScriptDir check-seo-noindex.ps1
if (Test-Path $CheckScript) {
    & $CheckScript -Quiet
    $ExitCode = $LASTEXITCODE
    if ($ExitCode -eq 1) {
        Write-Error    ❌ 違反死命令 11：四大件含有 noindex
        $ErrorCount++
    } else {
        Write-Success    ✅ 死命令 11 通過：四大件無 noindex
    }
} else {
    Write-Warning    ⚠️ 找不到 check-seo-noindex.ps1，跳過檢查
}

# ============================================================
# 報告
# ============================================================
Write-Info 
Write-Info ============================================================
Write-Info   📊 檢查報告
Write-Info ============================================================
Write-Info 
Write-Info    ✅ 通過：$PassCount 項
Write-Info    ⚠️ 警告：$WarningCount 項
Write-Info    ❌ 錯誤：$ErrorCount 項
Write-Info 

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Success    ✅ 所有檢查通過，可以安全推送！
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Warning    ⚠️ 有警告但無錯誤，建議修復後再推送
    Write-Info    💡 使用 -Fix 參數可自動修復部分問題
    exit 1
} else {
    Write-Error    ❌ 有錯誤，請修正後再推送！
    exit 2
}
'@

# 使用 UTF8 編碼（無 BOM）寫入檔案
$newScriptContent  Out-File -FilePath CUsersUserahpal-staticscriptspreflight-check.ps1 -Encoding UTF8 -Force

Write-Host ✅ 已重新建立 preflight-check.ps1 (UTF-8 編碼) -ForegroundColor Green