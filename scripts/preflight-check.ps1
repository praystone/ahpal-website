# ============================================================
# preflight-check.ps1 - 紅皮書死命令強制檢查腳本 v1.0
# ============================================================
# 用途：推送前強制檢查，確保文章品質與完整性
# 違反死命令者視同違反營運紀律
# ============================================================

param(
    [switch]$Fix,           # 自動修復可修復的問題
    [switch]$ReportOnly,    # 僅產生報告，不顯示詳細輸出
    [switch]$Quiet          # 安靜模式（僅顯示摘要）
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$OutputDir = $ProjectRoot
$ErrorCount = 0
$WarningCount = 0
$FixCount = 0

Write-Host ""
Write-Host "============================================================" -ForegroundColor Red
Write-Host "  🔴 董事長死命令：變更後強制檢查" -ForegroundColor Red
Write-Host "============================================================" -ForegroundColor Red
Write-Host ""
Write-Host "  執行時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

cd $ProjectRoot

# ============================================================
# 階段一：本地檔案完整性檢查
# ============================================================

if (-not $Quiet) {
    Write-Host "📋 階段一：本地檔案完整性檢查" -ForegroundColor Yellow
    Write-Host ""
}

# 1.1 檢查文章數量
Write-Host "   [1.1] 檢查文章數量..." -ForegroundColor Gray
$DryRunOutput = python src/main.py --dry-run 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ 文章數量檢查失敗" -ForegroundColor Red
    $ErrorCount++
} else {
    $PendingMatch = [regex]::Match($DryRunOutput, '待生成文章：(\d+) 篇')
    if ($PendingMatch.Success) {
        $PendingCount = $PendingMatch.Groups[1].Value
        if ($PendingCount -eq "0") {
            Write-Host "   ✅ 文章數量檢查通過（0 篇待生成）" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ 有 $PendingCount 篇文章待生成" -ForegroundColor Yellow
            $WarningCount++
        }
    }
}

# 1.2 檢查檔案大小（≥5KB）
Write-Host "   [1.2] 檢查文章大小..." -ForegroundColor Gray
$SmallFiles = Get-ChildItem -Path $OutputDir -Recurse -Filter "*.html" -ErrorAction SilentlyContinue | Where-Object { 
    $_.Length -lt 5120 -and 
    $_.Name -notin @("index.html", "categories.html", "404.html", "sitemap.xml")
}
$SmallCount = ($SmallFiles | Measure-Object).Count
if ($SmallCount -gt 0) {
    Write-Host "   ⚠️ 發現 $SmallCount 個檔案小於 5KB" -ForegroundColor Yellow
    if ($Fix) {
        foreach ($f in $SmallFiles) {
            Write-Host "      🔧 標記待重新生成：$($f.Name)" -ForegroundColor Gray
            Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
            $FixCount++
        }
        Write-Host "   ✅ 已刪除 $FixCount 個過小檔案" -ForegroundColor Green
    } else {
        $WarningCount++
    }
} else {
    Write-Host "   ✅ 所有文章大小正常（≥5KB）" -ForegroundColor Green
}

# 1.3 檢查首頁
Write-Host "   [1.3] 檢查首頁更新..." -ForegroundColor Gray
$IndexPath = Join-Path $OutputDir "index.html"
if (Test-Path $IndexPath) {
    $IndexContent = Get-Content $IndexPath -Raw
    if ($IndexContent -match '<ul id="article-list">') {
        Write-Host "   ✅ 首頁正常" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ 首頁可能未更新" -ForegroundColor Yellow
        $WarningCount++
    }
}

# ============================================================
# 階段二：Git 狀態檢查
# ============================================================

if (-not $Quiet) {
    Write-Host ""
    Write-Host "📋 階段二：Git 狀態檢查" -ForegroundColor Yellow
    Write-Host ""
}

# 2.1 檢查 Git 狀態
Write-Host "   [2.1] 檢查 Git 狀態..." -ForegroundColor Gray
$GitStatus = git status --porcelain 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "   ❌ Git 狀態檢查失敗" -ForegroundColor Red
    $ErrorCount++
} else {
    if ($GitStatus) {
        Write-Host "   ⚠️ 有未提交的變更：" -ForegroundColor Yellow
        $GitStatus | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
        $WarningCount++
    } else {
        Write-Host "   ✅ 工作目錄乾淨" -ForegroundColor Green
    }
}

# 2.2 檢查機密檔案
Write-Host "   [2.2] 檢查機密檔案..." -ForegroundColor Gray
$EnvPath = Join-Path $ProjectRoot ".env"
if (Test-Path $EnvPath) {
    $EnvTracked = git ls-files ".env" 2>$null
    if ($EnvTracked) {
        Write-Host "   ❌ .env 被 Git 追蹤！不安全！" -ForegroundColor Red
        Write-Host "      執行：git rm --cached .env" -ForegroundColor Yellow
        $ErrorCount++
    } else {
        Write-Host "   ✅ .env 未被 Git 追蹤（安全）" -ForegroundColor Green
    }
} else {
    Write-Host "   ⚠️ .env 檔案不存在" -ForegroundColor Yellow
    $WarningCount++
}

# ============================================================
# 總結報告
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📊 檢查報告" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   🔴 錯誤：$ErrorCount 個" -ForegroundColor $(if ($ErrorCount -gt 0) {'Red'} else {'Green'})
Write-Host "   🟡 警告：$WarningCount 個" -ForegroundColor $(if ($WarningCount -gt 0) {'Yellow'} else {'Green'})
if ($Fix) { Write-Host "   🔧 自動修復：$FixCount 個" -ForegroundColor Cyan }
Write-Host ""

if ($ErrorCount -eq 0 -and $WarningCount -eq 0) {
    Write-Host "   ✅ 所有檢查通過！可以推送！" -ForegroundColor Green
    exit 0
} elseif ($ErrorCount -eq 0) {
    Write-Host "   ⚠️ 有警告但無錯誤，建議修復後再推送" -ForegroundColor Yellow
    if (-not $Fix) {
        Write-Host "   💡 使用 -Fix 參數可自動修復部分問題" -ForegroundColor Gray
    }
    exit 1
} else {
    Write-Host "   ❌ 有錯誤，請修正後再推送！" -ForegroundColor Red
    Write-Host ""
    Write-Host "   📌 快速修復指令：" -ForegroundColor Yellow
    Write-Host "      .\scripts\preflight-check.ps1 -Fix" -ForegroundColor Gray
    Write-Host "      python src/main.py --force deepseek" -ForegroundColor Gray
    Write-Host "      .\scripts\ahpal-master.ps1 → [4]" -ForegroundColor Gray
    exit 2
}