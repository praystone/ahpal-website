# ============================================================
# 雅寶社區 · 頂客論壇 - 系統備份腳本 v3.2 (完整版)
# ============================================================
# 功能：
#   1. 一般備份（不壓縮）
#   2. 備份 + 壓縮
#   3. 黃金備份（壓縮 + 複製到 AI 檔案館）
#   4. 清理過舊備份
# ============================================================
# 執行後不會自動關閉，方便查看結果
# ============================================================

param(
    [switch]$Compress,
    [switch]$Golden,
    [switch]$Cleanup
)

# ============================================================
# 🔧 防止雙擊後自動關閉（全域開關）
# ============================================================
$script:isDoubleClicked = $false
if ($Host.Name -eq "ConsoleHost" -and $MyInvocation.InvocationName -ne ".") {
    if ($Host.Name -ne "Windows PowerShell ISE Host") {
        $script:isDoubleClicked = $true
    }
}

# ============================================================
# 🎨 顏色函數
# ============================================================
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Section { Write-Host "`n$('='*60)" -ForegroundColor Cyan; Write-Host $args -ForegroundColor Cyan; Write-Host "$('='*60)" -ForegroundColor Cyan }

# ============================================================
# 📦 核心備份函數
# ============================================================
function Invoke-Backup {
    param(
        [switch]$Compress,
        [switch]$Golden
    )
    
    Write-Section "📦 執行備份"
    if ($Golden) { Write-Info "⭐ 黃金備份模式：完整壓縮 + 同步至 AI 檔案館" }
    
    # ============================================================
    # 1. 路徑設定
    # ============================================================
    # 🆕 修復：使用 Get-Location 作為備用
    try {
        $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
        if (-not $ScriptDir -or -not (Test-Path $ScriptDir)) {
            $ScriptDir = Get-Location
        }
    } catch {
        $ScriptDir = Get-Location
    }
    Write-Info "📁 腳本目錄：$ScriptDir"
    
    $MainOutputDir = "C:\Users\User\ahpal-static"
    $BackupRoot = "C:\Users\User\ahpal-backup"
    $GoldenArchiveRoot = "C:\Users\User\ahpal-AI-archive\優良備份"
    
    if (Test-Path $MainOutputDir) {
        $ActualOutputDir = $MainOutputDir
        Write-Info "📁 輸出目錄：$ActualOutputDir"
    } else {
        Write-Error "❌ 找不到輸出目錄！"
        return
    }
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupDir = Join-Path $BackupRoot $Timestamp
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Info "📁 備份目錄：$BackupDir"
    
    # ============================================================
    # 2. 備份腳本
    # ============================================================
    Write-Info "`n📄 備份腳本檔案..."
    $ScriptBackupDir = Join-Path $BackupDir "scripts"
    New-Item -ItemType Directory -Path $ScriptBackupDir -Force | Out-Null
    
    $ScriptFiles = @(
        "ahpal-master.ps1",
        "ahpal-static.ps1",
        "generate-games.ps1",
        "backup-system.ps1",
        "add-articles.ps1",
        "check-all.ps1",
        "preflight-check.ps1",
        "sync-to-gdrive.ps1"
    )
    $ScriptsCount = 0
    foreach ($file in $ScriptFiles) {
        $src = Join-Path $ScriptDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $ScriptBackupDir -Force
            Write-Success "   ✅ $file"
            $ScriptsCount++
        } else {
            Write-Warning "   ⚠️ 找不到：$file"
        }
    }
    Write-Info "   ✅ 已備份 $ScriptsCount 個腳本"
    
    # ============================================================
    # 3. 備份 Python
    # ============================================================
    Write-Info "`n🐍 備份 Python 原始碼..."
    $SrcDir = Join-Path $ActualOutputDir "src"
    if (Test-Path $SrcDir) {
        $SrcBackupDir = Join-Path $BackupDir "src"
        New-Item -ItemType Directory -Path $SrcBackupDir -Force | Out-Null
        Copy-Item -Path "$SrcDir\*" -Destination $SrcBackupDir -Recurse -Force
        $SrcCount = (Get-ChildItem -Path $SrcBackupDir -Recurse -File).Count
        Write-Success "   ✅ 已備份 $SrcCount 個檔案"
    } else {
        Write-Warning "   ⚠️ 找不到 src/ 目錄"
    }
    
    # ============================================================
    # 4. 備份網站
    # ============================================================
    Write-Info "`n📄 備份完整網站..."
    $WebBackupDir = Join-Path $BackupDir "website-full"
    New-Item -ItemType Directory -Path $WebBackupDir -Force | Out-Null
    
    try {
        Copy-Item -Path "$ActualOutputDir\*" -Destination $WebBackupDir -Recurse -Force
        $WebCount = (Get-ChildItem -Path $WebBackupDir -Recurse -File).Count
        $WebSize = [math]::Round((Get-ChildItem -Path $WebBackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-Success "   ✅ 已備份完整網站 ($WebCount 個檔案，${WebSize} MB)"
    } catch {
        Write-Error "   ❌ 備份網站失敗：$_"
        return
    }
    
    # ============================================================
    # 5. 備份關鍵頁面
    # ============================================================
    Write-Info "`n📄 備份關鍵頁面..."
    $LightBackupDir = Join-Path $BackupDir "website-light"
    New-Item -ItemType Directory -Path $LightBackupDir -Force | Out-Null
    
    $KeyFiles = @("index.html", "categories.html", "sitemap.xml", "404.html", "memorial.html", "royal_dragon_karma.html", "ads.txt")
    foreach ($file in $KeyFiles) {
        $src = Join-Path $ActualOutputDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $LightBackupDir -Force
            Write-Success "   ✅ $file"
        }
    }
    
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
            Copy-Item -Path $src -Destination $LightBackupDir -Force
            Write-Success "   ✅ $file"
        }
    }
    
    # 遊戲
    $GameSrc = Join-Path $ActualOutputDir "game"
    if (Test-Path $GameSrc) {
        $GameDest = Join-Path $LightBackupDir "game"
        New-Item -ItemType Directory -Path $GameDest -Force | Out-Null
        Copy-Item -Path "$GameSrc\*" -Destination $GameDest -Recurse -Force
        $GameCount = (Get-ChildItem -Path $GameDest -Filter "*.html").Count
        Write-Success "   ✅ 已備份遊戲 ($GameCount 款)"
    }
    
    # ============================================================
    # 6. 產生文章清單
    # ============================================================
    Write-Info "`n📋 產生文章清單..."
    $ManifestPath = Join-Path $BackupDir "article-manifest.txt"
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
    
    $ManifestContent = @"
============================================================
雅寶社區 · 頂客論壇 - 文章備份清單
備份時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
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
    Write-Success "   ✅ 已產生文章清單（$($AllArticles.Count) 篇）"
    
    # ============================================================
    # 7. 壓縮
    # ============================================================
    $ZipPath = $null
    if ($Compress -or $Golden) {
        Write-Info "`n🗜️ 壓縮備份..."
        $ZipPath = "$BackupDir.zip"
        try {
            # 檢查是否有檔案需要壓縮
            $filesToCompress = Get-ChildItem -Path $BackupDir -Recurse
            if ($filesToCompress.Count -gt 0) {
                Compress-Archive -Path $BackupDir -DestinationPath $ZipPath -Force -ErrorAction Stop
                $ZipSize = [math]::Round((Get-Item $ZipPath).Length / 1MB, 2)
                Write-Success "   ✅ 已壓縮 (${ZipSize} MB)"
            } else {
                Write-Warning "   ⚠️ 備份目錄為空，跳過壓縮"
                $ZipPath = $null
            }
        } catch {
            Write-Warning "   ⚠️ 壓縮失敗：$_"
            $ZipPath = $null
        }
    }
    
    # ============================================================
    # 8. 黃金備份
    # ============================================================
    if ($Golden) {
        Write-Info "`n⭐ 複製黃金備份到 AI 檔案館..."
        New-Item -ItemType Directory -Path $GoldenArchiveRoot -Force | Out-Null
        
        if ($ZipPath -and (Test-Path $ZipPath)) {
            $GoldenDest = Join-Path $GoldenArchiveRoot "ahpal-golden-$Timestamp.zip"
            try {
                Copy-Item -Path $ZipPath -Destination $GoldenDest -Force
                Write-Success "   ✅ 已複製黃金備份：$GoldenDest"
                
                # 🆕 清理舊黃金備份（保留 3 個，只刪除 ahpal-golden- 前綴的檔案）
                $OldGoldens = Get-ChildItem -Path $GoldenArchiveRoot -Filter "ahpal-golden-*.zip" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -Skip 3
                foreach ($old in $OldGoldens) {
                    Remove-Item -Path $old.FullName -Force
                    Write-Info "   🗑️ 已刪除舊備份：$($old.Name)"
                }
            } catch {
                Write-Error "   ❌ 複製黃金備份失敗：$_"
            }
        } else {
            Write-Warning "   ⚠️ 找不到壓縮檔，跳過黃金備份複製"
        }
    }
    
    # ============================================================
    # 9. 顯示摘要
    # ============================================================
    Write-Section "✅ 備份完成！"
    Write-Info "📁 備份位置：$BackupDir"
    if ($ZipPath -and (Test-Path $ZipPath)) {
        Write-Info "🗜️ 壓縮檔案：$ZipPath"
    }
    Write-Info "📊 文章總數：$($AllArticles.Count) 篇"
    Write-Info "📦 網站大小：${WebSize} MB"
    Write-Info ""
}

# ============================================================
# 🧹 清理過舊備份
# ============================================================
function Invoke-Cleanup {
    Write-Section "🧹 清理過舊備份"
    $BackupRoot = "C:\Users\User\ahpal-backup"
    $KeepCount = 5
    
    if (-not (Test-Path $BackupRoot)) {
        Write-Warning "   ⚠️ 備份目錄不存在：$BackupRoot"
        return
    }
    
    $Backups = Get-ChildItem -Path $BackupRoot -Filter "*.zip" | Sort-Object LastWriteTime -Descending
    $Total = $Backups.Count
    
    if ($Total -gt $KeepCount) {
        $ToDelete = $Backups | Select-Object -Skip $KeepCount
        foreach ($b in $ToDelete) {
            Remove-Item -Path $b.FullName -Force
            Write-Warning "   🗑️ 已刪除：$($b.Name)"
        }
        Write-Success "   ✅ 清理完成！保留最近 $KeepCount 個備份"
    } else {
        Write-Success "   ✅ 備份數量 $Total 個，未超過 $KeepCount 個，無需清理"
    }
    Write-Info ""
}

# ============================================================
# 📋 互動選單
# ============================================================
function Show-Menu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  📦 雅寶社區 · 頂客論壇 - 系統備份工具 v3.2" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] 一般備份 (不壓縮)"
    Write-Host "  [2] 備份 + 壓縮"
    Write-Host "  [3] ⭐ 黃金備份 (壓縮 + 複製到 AI 檔案館)"
    Write-Host "  [4] 🧹 清理過舊備份 (保留最近 5 個)"
    Write-Host "  [0] 退出"
    Write-Host ""
}

# ============================================================
# 🚀 主程式
# ============================================================
if ($Cleanup) {
    Invoke-Cleanup
} elseif ($Golden -or $Compress) {
    Invoke-Backup -Compress:$Compress -Golden:$Golden
} else {
    # 互動選單模式
    do {
        Show-Menu
        $choice = Read-Host "請輸入選項 [0-4]"
        
        switch ($choice) {
            "1" { Invoke-Backup -Compress:$false -Golden:$false }
            "2" { Invoke-Backup -Compress:$true -Golden:$false }
            "3" { Invoke-Backup -Compress:$true -Golden:$true }
            "4" { Invoke-Cleanup }
            "0" { Write-Success "👋 退出"; break }
            default { Write-Error "❌ 無效選項，請重新選擇"; Start-Sleep 1 }
        }
        
        if ($choice -ne "0") {
            Write-Host ""
            Write-Host "按 Enter 鍵返回選單..." -ForegroundColor Gray
            Read-Host
        }
    } while ($choice -ne "0")
}

# ============================================================
# 🔒 防止雙擊後自動關閉
# ============================================================
if ($script:isDoubleClicked) {
    Write-Host ""
    Write-Host "按 Enter 鍵結束..." -ForegroundColor Gray
    Read-Host
}