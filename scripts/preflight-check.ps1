# ============================================================
# preflight-check.ps1 - 紅皮書死命令強制檢查腳本 v2.1
# ============================================================
# 用途：推送前強制檢查，確保文章品質與完整性
# 違反死命令者視同違反營運紀律
# ============================================================
# 修正 v2.1：
#   - 排除 game/ 目錄（遊戲檔案不適用文章檢查）
#   - 只檢查 tech/ life/ review/ philosophy/ trend/ 目錄
# ============================================================

param(
    [switch]$Fix,           # 自動修復可修復的問題
    [switch]$ReportOnly,    # 僅產生報告，不顯示詳細輸出
    [switch]$Quiet,         # 安靜模式（僅顯示摘要）
    [switch]$SkipGit        # 跳過 Git 檢查（排程用）
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$OutputDir = $ProjectRoot
$ErrorCount = 0
$WarningCount = 0
$FixCount = 0
$PassCount = 0
$CheckResults = @()

# ============================================================
# 文章目錄（排除 game/）
# ============================================================
$ArticleDirs = @("tech", "life", "review", "philosophy", "trend")

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "  🔴 董事長死命令：變更後強制檢查 v2.1" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  執行時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "  檢查範圍：檔案完整性 | 內容品質 | Git 狀態 | 結構檢查"
Write-Host "  排除目錄：game/（遊戲檔案）"
Write-Host ""

cd $ProjectRoot

# ============================================================
# 輔助函數：記錄結果
# ============================================================
function Add-CheckResult {
    param($Category, $Name, $Status, $Message, $Icon = "•")
    $CheckResults += [PSCustomObject]@{
        Category = $Category
        Name = $Name
        Status = $Status
        Message = $Message
        Icon = $Icon
    }
    if ($Status -eq "PASS") { $PassCount++ }
    elseif ($Status -eq "WARN") { $WarningCount++ }
    elseif ($Status -eq "FAIL") { $ErrorCount++ }
}

# ============================================================
# 取得文章檔案（排除 game/ 目錄）
# ============================================================
function Get-ArticleFiles {
    param([int]$MaxCount = 20)
    $Files = @()
    foreach ($dir in $ArticleDirs) {
        $path = Join-Path $OutputDir $dir
        if (Test-Path $path) {
            $Files += Get-ChildItem -Path $path -Filter "*.html" -ErrorAction SilentlyContinue
        }
    }
    if ($MaxCount -gt 0) {
        return $Files | Select-Object -First $MaxCount
    }
    return $Files
}

function GetAllArticleFiles {
    $Files = @()
    foreach ($dir in $ArticleDirs) {
        $path = Join-Path $OutputDir $dir
        if (Test-Path $path) {
            $Files += Get-ChildItem -Path $path -Filter "*.html" -ErrorAction SilentlyContinue
        }
    }
    return $Files
}

# ============================================================
# 階段一：本地檔案完整性檢查
# ============================================================
if (-not $Quiet) {
    Write-Host "📋 階段一：本地檔案完整性檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

# 1.1 檢查文章數量（只檢查文章目錄）
Write-Host "   [1.1] 檢查文章數量..." -ForegroundColor Gray
$ArticleCount = (GetAllArticleFiles).Count
Write-Host "   📄 文章目錄總數：$ArticleCount 篇（不含遊戲）" -ForegroundColor Cyan

# 檢查是否有待生成（從 manifest 或 main.py）
$DryRunOutput = python src/main.py --dry-run 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ⚠️ 無法檢查待生成狀態（可能 main.py 有問題）" -ForegroundColor Yellow
    Add-CheckResult -Category "完整性" -Name "文章數量" -Status "WARN" -Message "無法檢查待生成狀態"
    $WarningCount++
} else {
    $PendingMatch = [regex]::Match($DryRunOutput, '待生成文章：(\d+) 篇')
    if ($PendingMatch.Success) {
        $PendingCount = $PendingMatch.Groups[1].Value
        if ($PendingCount -eq "0") {
            Write-Host "   ✅ 文章數量檢查通過（0 篇待生成）" -ForegroundColor Green
            Add-CheckResult -Category "完整性" -Name "文章數量" -Status "PASS" -Message "0 篇待生成"
        } else {
            Write-Host "   ⚠️ 有 $PendingCount 篇文章待生成" -ForegroundColor Yellow
            Add-CheckResult -Category "完整性" -Name "文章數量" -Status "WARN" -Message "$PendingCount 篇待生成"
            $WarningCount++
        }
    }
}

# 1.2 檢查檔案大小（只檢查文章目錄，排除 game/）
Write-Host "   [1.2] 檢查文章大小..." -ForegroundColor Gray
$SmallFiles = @()
foreach ($dir in $ArticleDirs) {
    $path = Join-Path $OutputDir $dir
    if (Test-Path $path) {
        $SmallFiles += Get-ChildItem -Path $path -Filter "*.html" -ErrorAction SilentlyContinue | Where-Object { $_.Length -lt 5120 }
    }
}
$SmallCount = ($SmallFiles | Measure-Object).Count
if ($SmallCount -gt 0) {
    Write-Host "   ⚠️ 發現 $SmallCount 個檔案小於 5KB（文章目錄）" -ForegroundColor Yellow
    if ($Fix) {
        foreach ($f in $SmallFiles) {
            Write-Host "      🔧 標記待重新生成：$($f.Name)" -ForegroundColor Gray
            Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
            $FixCount++
        }
        Write-Host "   ✅ 已刪除 $FixCount 個過小檔案" -ForegroundColor Green
        Add-CheckResult -Category "完整性" -Name "文章大小" -Status "PASS" -Message "已刪除 $FixCount 個過小檔案" -Icon "🔧"
    } else {
        Add-CheckResult -Category "完整性" -Name "文章大小" -Status "WARN" -Message "$SmallCount 個檔案 < 5KB"
        $WarningCount++
    }
} else {
    Write-Host "   ✅ 所有文章大小正常（≥5KB）" -ForegroundColor Green
    Add-CheckResult -Category "完整性" -Name "文章大小" -Status "PASS" -Message "所有文章 ≥ 5KB"
}

# 1.3 檢查首頁
Write-Host "   [1.3] 檢查首頁更新..." -ForegroundColor Gray
$IndexPath = Join-Path $OutputDir "index.html"
if (Test-Path $IndexPath) {
    $IndexContent = Get-Content $IndexPath -Raw
    if ($IndexContent -match '<ul id="article-list">') {
        Write-Host "   ✅ 首頁正常" -ForegroundColor Green
        Add-CheckResult -Category "完整性" -Name "首頁" -Status "PASS" -Message "正常"
    } else {
        Write-Host "   ⚠️ 首頁可能未更新" -ForegroundColor Yellow
        Add-CheckResult -Category "完整性" -Name "首頁" -Status "WARN" -Message "可能未更新"
        $WarningCount++
    }
} else {
    Write-Host "   ❌ 首頁不存在" -ForegroundColor Red
    Add-CheckResult -Category "完整性" -Name "首頁" -Status "FAIL" -Message "index.html 不存在"
    $ErrorCount++
}

# ============================================================
# 階段二：內容品質檢查（只檢查文章目錄，排除 game/）
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "📋 階段二：內容品質檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

$ArticleFiles = Get-ArticleFiles -MaxCount 30

# 2.1 檢查品牌名稱
Write-Host "   [2.1] 檢查品牌名稱..." -ForegroundColor Gray
$BrandIssues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch "雅寶社區") {
        $BrandIssues++
    }
}
if ($BrandIssues -eq 0) {
    Write-Host "   ✅ 品牌名稱檢查通過" -ForegroundColor Green
    Add-CheckResult -Category "品質" -Name "品牌名稱" -Status "PASS" -Message "所有樣本皆包含品牌"
} else {
    Write-Host "   ⚠️ 有 $BrandIssues 個檔案缺少品牌名稱" -ForegroundColor Yellow
    Add-CheckResult -Category "品質" -Name "品牌名稱" -Status "WARN" -Message "$BrandIssues 個檔案缺少品牌"
    $WarningCount++
}

# 2.2 檢查 API 錯誤標記
Write-Host "   [2.2] 檢查 API 錯誤標記..." -ForegroundColor Gray
$ApiErrorIssues = 0
$ErrorKeywords = @("429", "503", "RESOURCE_EXHAUSTED", "unavailable", "暫時無法", "配額已用盡")
foreach ($f in $ArticleFiles) {
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
if ($ApiErrorIssues -eq 0) {
    Write-Host "   ✅ 無 API 錯誤標記" -ForegroundColor Green
    Add-CheckResult -Category "品質" -Name "API 錯誤" -Status "PASS" -Message "無錯誤標記"
} else {
    Write-Host "   ⚠️ 有 $ApiErrorIssues 個檔案含 API 錯誤標記" -ForegroundColor Yellow
    Add-CheckResult -Category "品質" -Name "API 錯誤" -Status "WARN" -Message "$ApiErrorIssues 個檔案含錯誤標記"
    $WarningCount++
}

# 2.3 檢查 AdSense 程式碼
Write-Host "   [2.3] 檢查 AdSense 程式碼..." -ForegroundColor Gray
$AdsenseIssues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch "adsbygoogle") {
        $AdsenseIssues++
    }
}
if ($AdsenseIssues -eq 0) {
    Write-Host "   ✅ AdSense 程式碼檢查通過" -ForegroundColor Green
    Add-CheckResult -Category "品質" -Name "AdSense" -Status "PASS" -Message "所有樣本皆包含"
} else {
    Write-Host "   ⚠️ 有 $AdsenseIssues 個檔案缺少 AdSense 程式碼" -ForegroundColor Yellow
    Add-CheckResult -Category "品質" -Name "AdSense" -Status "WARN" -Message "$AdsenseIssues 個檔案缺少"
    $WarningCount++
}

# ============================================================
# 階段三：HTML 結構檢查（只檢查文章目錄）
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "📋 階段三：HTML 結構檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

# 3.1 檢查 H1 標題
Write-Host "   [3.1] 檢查 H1 標題..." -ForegroundColor Gray
$H1Issues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '<h1[^>]*>') {
        $H1Issues++
    }
}
if ($H1Issues -eq 0) {
    Write-Host "   ✅ H1 標題檢查通過" -ForegroundColor Green
    Add-CheckResult -Category "結構" -Name "H1 標題" -Status "PASS" -Message "所有樣本皆有 H1"
} else {
    Write-Host "   ⚠️ 有 $H1Issues 個檔案缺少 H1 標題" -ForegroundColor Yellow
    Add-CheckResult -Category "結構" -Name "H1 標題" -Status "WARN" -Message "$H1Issues 個檔案缺少 H1"
    $WarningCount++
}

# 3.2 檢查 H2 標題
Write-Host "   [3.2] 檢查 H2 標題..." -ForegroundColor Gray
$H2Issues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content) {
        $h2Count = ([regex]::Matches($Content, '<h2[^>]*>')).Count
        if ($h2Count -lt 2) {
            $H2Issues++
        }
    }
}
if ($H2Issues -eq 0) {
    Write-Host "   ✅ H2 標題檢查通過 (≥2個)" -ForegroundColor Green
    Add-CheckResult -Category "結構" -Name "H2 標題" -Status "PASS" -Message "所有樣本皆有 ≥2 個 H2"
} else {
    Write-Host "   ⚠️ 有 $H2Issues 個檔案 H2 標題不足" -ForegroundColor Yellow
    Add-CheckResult -Category "結構" -Name "H2 標題" -Status "WARN" -Message "$H2Issues 個檔案 H2 < 2"
    $WarningCount++
}

# 3.3 檢查表格
Write-Host "   [3.3] 檢查表格..." -ForegroundColor Gray
$TableIssues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '<table[^>]*>') {
        $TableIssues++
    }
}
if ($TableIssues -eq 0) {
    Write-Host "   ✅ 表格檢查通過" -ForegroundColor Green
    Add-CheckResult -Category "結構" -Name "表格" -Status "PASS" -Message "所有樣本皆有表格"
} else {
    Write-Host "   ⚠️ 有 $TableIssues 個檔案缺少表格" -ForegroundColor Yellow
    Add-CheckResult -Category "結構" -Name "表格" -Status "WARN" -Message "$TableIssues 個檔案缺少表格"
    $WarningCount++
}

# 3.4 檢查 FAQ
Write-Host "   [3.4] 檢查 FAQ..." -ForegroundColor Gray
$FaqIssues = 0
foreach ($f in $ArticleFiles) {
    $Content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
    if ($Content -and $Content -notmatch '(FAQ|常見問題|Q：|問：|Q&A)') {
        $FaqIssues++
    }
}
if ($FaqIssues -eq 0) {
    Write-Host "   ✅ FAQ 檢查通過" -ForegroundColor Green
    Add-CheckResult -Category "結構" -Name "FAQ" -Status "PASS" -Message "所有樣本皆有 FAQ"
} else {
    Write-Host "   ⚠️ 有 $FaqIssues 個檔案缺少 FAQ" -ForegroundColor Yellow
    Add-CheckResult -Category "結構" -Name "FAQ" -Status "WARN" -Message "$FaqIssues 個檔案缺少 FAQ"
    $WarningCount++
}

# ============================================================
# 階段四：分類頁面與 Sitemap 檢查
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "📋 階段四：分類頁面與 Sitemap 檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

# 4.1 檢查分類頁面
Write-Host "   [4.1] 檢查分類頁面..." -ForegroundColor Gray
$Categories = @("tech", "game", "life", "review", "philosophy", "trend")
$CatIssues = 0
foreach ($cat in $Categories) {
    $CatPath = Join-Path $OutputDir "category-$cat.html"
    if (Test-Path $CatPath) {
        $CatContent = Get-Content $CatPath -Raw
        if ($CatContent -match '<ul class="article-list">') {
            # 正常
        } else {
            $CatIssues++
            Write-Host "      ⚠️ category-$cat.html 結構異常" -ForegroundColor Yellow
        }
    } else {
        $CatIssues++
        Write-Host "      ❌ category-$cat.html 不存在" -ForegroundColor Red
    }
}
if ($CatIssues -eq 0) {
    Write-Host "   ✅ 所有分類頁面正常" -ForegroundColor Green
    Add-CheckResult -Category "完整性" -Name "分類頁面" -Status "PASS" -Message "6 個分類頁面皆正常"
} else {
    Write-Host "   ⚠️ 有 $CatIssues 個分類頁面有問題" -ForegroundColor Yellow
    Add-CheckResult -Category "完整性" -Name "分類頁面" -Status "WARN" -Message "$CatIssues 個分類頁面異常"
    $WarningCount++
}

# 4.2 檢查 Sitemap
Write-Host "   [4.2] 檢查 Sitemap..." -ForegroundColor Gray
$SitemapPath = Join-Path $OutputDir "sitemap.xml"
if (Test-Path $SitemapPath) {
    $SitemapContent = Get-Content $SitemapPath -Raw
    if ($SitemapContent -match '<urlset') {
        Write-Host "   ✅ Sitemap 正常" -ForegroundColor Green
        Add-CheckResult -Category "完整性" -Name "Sitemap" -Status "PASS" -Message "正常"
    } else {
        Write-Host "   ⚠️ Sitemap 可能損壞" -ForegroundColor Yellow
        Add-CheckResult -Category "完整性" -Name "Sitemap" -Status "WARN" -Message "可能損壞"
        $WarningCount++
    }
} else {
    Write-Host "   ❌ Sitemap 不存在" -ForegroundColor Red
    Add-CheckResult -Category "完整性" -Name "Sitemap" -Status "FAIL" -Message "sitemap.xml 不存在"
    $ErrorCount++
}

# ============================================================
# 階段五：遊戲檢查（僅統計，不評分）
# ============================================================
if (-not $Quiet) {
    Write-Host ""
    Write-Host "📋 階段五：遊戲檢查" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
}

Write-Host "   [5.1] 檢查遊戲檔案..." -ForegroundColor Gray
$GamePath = Join-Path $OutputDir "game"
if (Test-Path $GamePath) {
    $GameFiles = Get-ChildItem -Path $GamePath -Filter "*.html" -ErrorAction SilentlyContinue
    $GameCount = $GameFiles.Count
    $GameIndexPath = Join-Path $GamePath "index.html"
    $GameIndexExists = Test-Path $GameIndexPath
    
    Write-Host "   🎮 遊戲總數：$GameCount 款（僅統計，不檢查品質）" -ForegroundColor Cyan
    Write-Host "   📄 遊戲索引：$(if ($GameIndexExists) {'✅ 存在'} else {'❌ 不存在'})" -ForegroundColor $(if ($GameIndexExists) {'Green'} else {'Red'})
    
    Add-CheckResult -Category "遊戲" -Name "遊戲數量" -Status "PASS" -Message "$GameCount 款遊戲"
    if (-not $GameIndexExists) {
        Add-CheckResult -Category "遊戲" -Name "遊戲索引" -Status "WARN" -Message "game/index.html 不存在"
        $WarningCount++
    }
} else {
    Write-Host "   ❌ 找不到遊戲目錄" -ForegroundColor Red
    Add-CheckResult -Category "遊戲" -Name "遊戲目錄" -Status "FAIL" -Message "game/ 目錄不存在"
    $ErrorCount++
}

# ============================================================
# 階段六：Git 狀態檢查
# ============================================================
if (-not $SkipGit) {
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "📋 階段六：Git 狀態檢查" -ForegroundColor Yellow
        Write-Host "────────────────────────────────────────────────────────" -ForegroundColor Gray
    }

    # 6.1 檢查 Git 狀態
    Write-Host "   [6.1] 檢查 Git 狀態..." -ForegroundColor Gray
    $GitStatus = git status --porcelain 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   ❌ Git 狀態檢查失敗" -ForegroundColor Red
        Add-CheckResult -Category "Git" -Name "Git 狀態" -Status "FAIL" -Message "Git 檢查失敗"
        $ErrorCount++
    } else {
        if ($GitStatus) {
            Write-Host "   ⚠️ 有未提交的變更：" -ForegroundColor Yellow
            $GitStatus | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
            Add-CheckResult -Category "Git" -Name "Git 狀態" -Status "WARN" -Message "有未提交變更"
            $WarningCount++
        } else {
            Write-Host "   ✅ 工作目錄乾淨" -ForegroundColor Green
            Add-CheckResult -Category "Git" -Name "Git 狀態" -Status "PASS" -Message "工作目錄乾淨"
        }
    }

    # 6.2 檢查機密檔案
    Write-Host "   [6.2] 檢查機密檔案..." -ForegroundColor Gray
    $EnvPath = Join-Path $ProjectRoot ".env"
    if (Test-Path $EnvPath) {
        $EnvTracked = git ls-files ".env" 2>$null
        if ($EnvTracked) {
            Write-Host "   ❌ .env 被 Git 追蹤！不安全！" -ForegroundColor Red
            Add-CheckResult -Category "Git" -Name ".env 追蹤" -Status "FAIL" -Message ".env 被 Git 追蹤！"
            $ErrorCount++
        } else {
            Write-Host "   ✅ .env 未被 Git 追蹤（安全）" -ForegroundColor Green
            Add-CheckResult -Category "Git" -Name ".env 追蹤" -Status "PASS" -Message ".env 未被追蹤"
        }
    } else {
        Write-Host "   ⚠️ .env 檔案不存在" -ForegroundColor Yellow
        Add-CheckResult -Category "Git" -Name ".env 存在" -Status "WARN" -Message ".env 不存在"
        $WarningCount++
    }
}

# ============================================================
# 階段七：總結報告
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📊 檢查報告" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# 顯示統計
Write-Host "   ✅ 通過：$PassCount 項" -ForegroundColor Green
Write-Host "   ⚠️ 警告：$WarningCount 項" -ForegroundColor Yellow
Write-Host "   ❌ 錯誤：$ErrorCount 項" -ForegroundColor Red
if ($Fix) {
    Write-Host "   🔧 自動修復：$FixCount 項" -ForegroundColor Cyan
}

Write-Host ""

# 顯示詳細結果
if ($CheckResults.Count -gt 0) {
    Write-Host "   📋 詳細結果：" -ForegroundColor Gray
    $CheckResults | ForEach-Object {
        $color = switch ($_.Status) {
            "PASS" { "Green" }
            "WARN" { "Yellow" }
            "FAIL" { "Red" }
            default { "Gray" }
        }
        $icon = switch ($_.Status) {
            "PASS" { "✅" }
            "WARN" { "⚠️" }
            "FAIL" { "❌" }
            default { "•" }
        }
        Write-Host "      $icon [$($_.Category)] $($_.Name) : $($_.Message)" -ForegroundColor $color
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "  ✅ 所有檢查通過！可以推送！" -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "  ⚠️ 有警告但無錯誤，建議修復後再推送" -ForegroundColor Yellow
    if (-not $Fix) {
        Write-Host "  💡 使用 -Fix 參數可自動修復部分問題" -ForegroundColor Gray
    }
    exit 1
} else {
    Write-Host "  ❌ 有錯誤，請修正後再推送！" -ForegroundColor Red
    Write-Host ""
    Write-Host "  📌 快速修復指令：" -ForegroundColor Yellow
    if ($Fix) {
        Write-Host "     .\scripts\preflight-check.ps1 -Fix" -ForegroundColor Gray
    }
    Write-Host "     python src/main.py --force deepseek" -ForegroundColor Gray
    Write-Host "     .\scripts\ahpal-master.ps1 → [4]" -ForegroundColor Gray
    Write-Host "     .\scripts\check-all.ps1 -Fix -Report" -ForegroundColor Gray
    exit 2
}