# ============================================================
# 雅寶社區 · 頂客論壇 - 系統備份腳本 v2.1
# ============================================================
# 功能：
#   1. 備份所有 PowerShell / Python 腳本
#   2. 備份網站完整靜態檔案 (ahpal-static)
#   3. 備份遊戲檔案與分類頁面
#   4. 產生文章清單 (article-manifest.txt)
#   5. 自動壓縮為 ZIP (可選)
# ============================================================
# 使用方法：.\backup-system.ps1
# 參數：.\backup-system.ps1 -Compress (自動壓縮備份)
# ============================================================

param(
    [switch]$Compress  # 加入此參數可自動壓縮備份為 ZIP
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "📦 雅寶社區 · 頂客論壇 - 系統備份工具 v2.1" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# ============================================================
# 1. 路徑設定
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

# 主要輸出目錄 (新位置)
$MainOutputDir = "C:\Users\User\ahpal-static"

# 備援輸出目錄 (舊位置)
$FallbackOutputDir = "C:\ahpal-static"

# 自動偵測實際使用的輸出目錄
if (Test-Path $MainOutputDir) {
    $ActualOutputDir = $MainOutputDir
    Write-Host "📁 偵測到主要輸出目錄：$ActualOutputDir" -ForegroundColor Cyan
} elseif (Test-Path $FallbackOutputDir) {
    $ActualOutputDir = $FallbackOutputDir
    Write-Host "📁 偵測到備援輸出目錄：$ActualOutputDir" -ForegroundColor Yellow
} else {
    Write-Host "❌ 找不到任何輸出目錄！" -ForegroundColor Red
    Write-Host "   請確認網站檔案是否存在於以下位置：" -ForegroundColor Yellow
    Write-Host "   - $MainOutputDir" -ForegroundColor Gray
    Write-Host "   - $FallbackOutputDir" -ForegroundColor Gray
    exit 1
}

$BackupRoot = "C:\Users\User\ahpal-backup"
$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BackupDir = Join-Path $BackupRoot $Timestamp

# ============================================================
# 2. 建立備份目錄
# ============================================================
Write-Host ""
Write-Host "📁 建立備份目錄：$BackupDir" -ForegroundColor Yellow
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

# ============================================================
# 3. 備份腳本檔案
# ============================================================
Write-Host ""
Write-Host "📄 備份腳本檔案..." -ForegroundColor Yellow

$ScriptFiles = @(
    "ahpal-static.ps1",
    "add_articles.ps1",
    "ahpal_generator.py",
    "backup-system.ps1"
)

$ScriptBackupDir = Join-Path $BackupDir "scripts"
New-Item -ItemType Directory -Path $ScriptBackupDir -Force | Out-Null

$ScriptsBackupCount = 0
foreach ($file in $ScriptFiles) {
    $src = Join-Path $ScriptDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $ScriptBackupDir -Force
        Write-Host "   ✅ 已備份：$file" -ForegroundColor Green
        $ScriptsBackupCount++
    } else {
        Write-Host "   ⚠️ 找不到：$file" -ForegroundColor Yellow
    }
}

# ============================================================
# 4. 備份完整網站檔案
# ============================================================
Write-Host ""
Write-Host "📄 備份完整網站檔案 (這可能需要一些時間)..." -ForegroundColor Yellow

$WebBackupDir = Join-Path $BackupDir "website-full"
New-Item -ItemType Directory -Path $WebBackupDir -Force | Out-Null

# 複製整個 ahpal-static (保留目錄結構)
if (Test-Path $ActualOutputDir) {
    Copy-Item -Path "$ActualOutputDir\*" -Destination $WebBackupDir -Recurse -Force
    $WebFileCount = (Get-ChildItem -Path $WebBackupDir -Recurse -File).Count
    $WebSize = [math]::Round((Get-ChildItem -Path $WebBackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
    Write-Host "   ✅ 已備份完整網站 ($WebFileCount 個檔案，${WebSize} MB)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️ 找不到網站目錄，跳過完整備份" -ForegroundColor Yellow
}

# ============================================================
# 5. 備份關鍵頁面 (精簡版，僅備份重要檔案)
# ============================================================
Write-Host ""
Write-Host "📄 備份關鍵頁面 (精簡版)..." -ForegroundColor Yellow

$WebLightBackupDir = Join-Path $BackupDir "website-light"
New-Item -ItemType Directory -Path $WebLightBackupDir -Force | Out-Null

# 根目錄關鍵檔案
$KeyFiles = @(
    "index.html",
    "categories.html",
    "sitemap.xml",
    "404.html",
    "memorial.html",
    "royal_dragon_karma.html"
)

foreach ($file in $KeyFiles) {
    $src = Join-Path $ActualOutputDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $WebLightBackupDir -Force
        Write-Host "   ✅ 已備份：$file" -ForegroundColor Green
    }
}

# 分類頁面
$CategoryFiles = @(
    "category-tech.html",
    "category-game.html",
    "category-life.html",
    "category-review.html",
    "category-philosophy.html",
    "category-trend.html"
)

foreach ($file in $CategoryFiles) {
    $src = Join-Path $ActualOutputDir $file
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $WebLightBackupDir -Force
        Write-Host "   ✅ 已備份：$file" -ForegroundColor Green
    }
}

# 遊戲目錄 (完整)
$GameSrcDir = Join-Path $ActualOutputDir "game"
if (Test-Path $GameSrcDir) {
    $GameDestDir = Join-Path $WebLightBackupDir "game"
    New-Item -ItemType Directory -Path $GameDestDir -Force | Out-Null
    Copy-Item -Path "$GameSrcDir\*" -Destination $GameDestDir -Recurse -Force
    $GameCount = (Get-ChildItem -Path $GameDestDir -Filter "*.html").Count
    Write-Host "   ✅ 已備份遊戲目錄 ($GameCount 款遊戲)" -ForegroundColor Green
}

# ============================================================
# 6. 產生文章清單
# ============================================================
Write-Host ""
Write-Host "📋 產生文章清單..." -ForegroundColor Yellow

$ManifestPath = Join-Path $BackupDir "article-manifest.txt"

# 掃描所有文章目錄
$AllArticles = @()
$CategoryDirs = @{
    "tech" = "💻 3C 科技教學"
    "game" = "🎮 遊戲攻略"
    "life" = "🏠 生活小常識"
    "review" = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend" = "🤖 AI 趨勢"
}

foreach ($dirName in $CategoryDirs.Keys) {
    $dirPath = Join-Path $ActualOutputDir $dirName
    if (Test-Path $dirPath) {
        $files = Get-ChildItem -Path $dirPath -Filter "*.html"
        foreach ($f in $files) {
            try {
                $content = Get-Content -Path $f.FullName -Encoding UTF8 -Raw -ErrorAction SilentlyContinue
                $titleMatch = [regex]::Match($content, '<title>(.*?)</title>')
                $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value } else { $f.BaseName }
            } catch {
                $title = $f.BaseName
            }
            $AllArticles += [PSCustomObject]@{
                Category = $CategoryDirs[$dirName]
                Title = $title
                Filename = "$dirName/$($f.Name)"
                Size = $f.Length
            }
        }
    }
}

# 產生清單內容
$ManifestContent = @"
============================================================
雅寶社區 · 頂客論壇 - 文章備份清單
備份時間：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
備份目錄：$BackupDir
輸出目錄：$ActualOutputDir
============================================================

📊 總文章數：$($AllArticles.Count) 篇
📦 總大小：$([math]::Round(($AllArticles | Measure-Object -Property Size -Sum).Sum / 1MB, 2)) MB

"@

foreach ($cat in $CategoryDirs.Keys) {
    $catName = $CategoryDirs[$cat]
    $catArticles = $AllArticles | Where-Object { $_.Category -eq $catName }
    $ManifestContent += "【$catName】($($catArticles.Count) 篇)`n"
    foreach ($article in $catArticles) {
        $sizeKB = [math]::Round($article.Size / 1KB, 2)
        $ManifestContent += "  - $($article.Title) ($sizeKB KB)`n"
        $ManifestContent += "    檔案：$($article.Filename)`n"
    }
    $ManifestContent += "`n"
}

$ManifestContent += "============================================================`n"
$ManifestContent += "備份完成時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"

Set-Content -Path $ManifestPath -Value $ManifestContent -Encoding UTF8
Write-Host "   ✅ 已產生文章清單（$($AllArticles.Count) 篇）" -ForegroundColor Green

# ============================================================
# 7. 產生備份摘要 (metadata.txt)
# ============================================================
$MetadataPath = Join-Path $BackupDir "backup-metadata.txt"
$Metadata = @"
============================================================
雅寶社區 · 頂客論壇 - 備份摘要
============================================================

備份時間：$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
備份工具版本：v2.1
執行者：$env:USERNAME
電腦名稱：$env:COMPUTERNAME

備份目錄：$BackupDir
輸出目錄：$ActualOutputDir

📊 備份統計：
   - 腳本檔案：$ScriptsBackupCount 個
   - 完整網站備份：$WebFileCount 個檔案 (${WebSize} MB)
   - 關鍵頁面：$(Get-ChildItem -Path $WebLightBackupDir -File -Filter "*.html" | Measure-Object).Count 個
   - 總文章數：$($AllArticles.Count) 篇
   - 文章總大小：$([math]::Round(($AllArticles | Measure-Object -Property Size -Sum).Sum / 1MB, 2)) MB

📁 備份內容：
   - scripts/              # 所有腳本
   - website-full/         # 完整網站檔案
   - website-light/        # 關鍵頁面 + 遊戲
   - article-manifest.txt  # 文章清單

============================================================
"@
Set-Content -Path $MetadataPath -Value $Metadata -Encoding UTF8

# ============================================================
# 8. 自動壓縮 (如果啟用)
# ============================================================
if ($Compress) {
    Write-Host ""
    Write-Host "🗜️ 正在壓縮備份為 ZIP 檔案..." -ForegroundColor Yellow
    
    # 檢查是否有 7-Zip 或 PowerShell 壓縮支援
    $ZipPath = "$BackupDir.zip"
    
    # 使用 PowerShell 內建 Compress-Archive (Windows 10/11 內建)
    try {
        Compress-Archive -Path $BackupDir -DestinationPath $ZipPath -Force
        Write-Host "   ✅ 已壓縮備份：$ZipPath" -ForegroundColor Green
        
        $ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
        Write-Host "   📦 壓縮檔案大小：${ZipSize} MB" -ForegroundColor Cyan
    } catch {
        Write-Host "   ⚠️ 壓縮失敗，請確認系統支援 Compress-Archive" -ForegroundColor Yellow
        Write-Host "   手動壓縮方式：右鍵點擊備份資料夾 → 傳送到 → 壓縮 (zipped) 資料夾" -ForegroundColor Gray
    }
}

# ============================================================
# 9. 備份完成摘要
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ 備份完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📁 備份位置：$BackupDir" -ForegroundColor Cyan
Write-Host "📄 文章清單：$ManifestPath" -ForegroundColor Cyan
if ($Compress -and (Test-Path $ZipPath)) {
    Write-Host "🗜️ 壓縮檔案：$ZipPath" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "📊 備份統計：" -ForegroundColor Yellow
Write-Host "   ├─ 腳本檔案：$ScriptsBackupCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 完整網站：$WebFileCount 個檔案 (${WebSize} MB)" -ForegroundColor Cyan
Write-Host "   ├─ 關鍵頁面：$(Get-ChildItem -Path $WebLightBackupDir -File -Filter "*.html" | Measure-Object).Count 個" -ForegroundColor Cyan
Write-Host "   └─ 總文章數：$($AllArticles.Count) 篇" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 若要還原，請將 website-full/ 或 website-light/ 的內容複製回 $ActualOutputDir" -ForegroundColor Yellow
Write-Host ""

Read-Host "按 Enter 鍵結束"