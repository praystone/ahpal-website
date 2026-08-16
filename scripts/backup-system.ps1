# ============================================================
# 雅寶社區 · 頂客論壇 - 系統備份腳本 v3.3 (完整版)
# ============================================================
# 功能：
#   1. 一般備份（不壓縮）
#   2. 備份 + 壓縮
#   3. 黃金備份（壓縮 + 複製到 AI 檔案館）
#   4. 清理過舊備份
# ============================================================
# 🆕 v3.3 變更 (2026-08-17)：
#   - 🔧 統一使用 config.ps1 核心配置 (9 大分類)
#   - 🔧 移除所有硬編碼分類定義
#   - 🔧 動態讀取分類統計
#   - 🔧 備份保留數量統一為 5 個
#   - 🔧 使用 $env:USERPROFILE 取代硬編碼路徑
# ============================================================

param(
    [switch]$Compress,
    [switch]$Golden,
    [switch]$Cleanup
)

# ============================================================
# 載入核心配置
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

$ConfigPath = Join-Path $ScriptDir "config.ps1"
if (Test-Path $ConfigPath) {
    . $ConfigPath
}

# ============================================================
# 防止雙擊後自動關閉
# ============================================================
$script:isDoubleClicked = $false
if ($Host.Name -eq "ConsoleHost" -and $MyInvocation.InvocationName -ne ".") {
    if ($Host.Name -ne "Windows PowerShell ISE Host") {
        $script:isDoubleClicked = $true
    }
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
# 核心備份函數
# ============================================================
function Invoke-Backup {
    param(
        [switch]$Compress,
        [switch]$Golden
    )
    
    Write-Section "📦 執行備份"
    if ($Golden) { Write-Info "⭐ 黃金備份模式：完整壓縮 + 同步至 AI 檔案館" }
    
    # 路徑設定
    $MainOutputDir = $Global:ProjectRoot
    $BackupRoot = "C:\Users\User\ahpal-backup"
    $GoldenArchiveRoot = "C:\Users\User\ahpal-AI-archive\優良備份"
    
    if (-not (Test-Path $MainOutputDir)) {
        Write-Error "❌ 找不到輸出目錄：$MainOutputDir"
        return
    }
    Write-Info "📁 輸出目錄：$MainOutputDir"
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupDir = Join-Path $BackupRoot $Timestamp
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Info "📁 備份目錄：$BackupDir"
    
    # 備份腳本
    Write-Info "`n📄 備份腳本檔案..."
    $ScriptBackupDir = Join-Path $BackupDir "scripts"
    New-Item -ItemType Directory -Path $ScriptBackupDir -Force | Out-Null
    
    $ScriptFiles = @(
        "ahpal-master.ps1", "ahpal-static.ps1", "generate-games.ps1",
        "backup-system.ps1", "add-articles.ps1", "check-all.ps1",
        "preflight-check.ps1", "sync-to-gdrive.ps1", "config.ps1"
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
    
    # 備份 Python
    Write-Info "`n🐍 備份 Python 原始碼..."
    $SrcDir = Join-Path $MainOutputDir "src"
    if (Test-Path $SrcDir) {
        $SrcBackupDir = Join-Path $BackupDir "src"
        New-Item -ItemType Directory -Path $SrcBackupDir -Force | Out-Null
        Copy-Item -Path "$SrcDir\*" -Destination $SrcBackupDir -Recurse -Force
        $SrcCount = (Get-ChildItem -Path $SrcBackupDir -Recurse -File).Count
        Write-Success "   ✅ 已備份 $SrcCount 個檔案"
    } else {
        Write-Warning "   ⚠️ 找不到 src/ 目錄"
    }
    
    # 備份完整網站 (使用動態分類)
    Write-Info "`n📄 備份完整網站..."
    $WebBackupDir = Join-Path $BackupDir "website-full"
    New-Item -ItemType Directory -Path $WebBackupDir -Force | Out-Null
    
    try {
        Copy-Item -Path "$MainOutputDir\*" -Destination $WebBackupDir -Recurse -Force
        $WebCount = (Get-ChildItem -Path $WebBackupDir -Recurse -File).Count
        $WebSize = [math]::Round((Get-ChildItem -Path $WebBackupDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
        Write-Success "   ✅ 已備份完整網站 ($WebCount 個檔案，${WebSize} MB)"
    } catch {
        Write-Error "   ❌ 備份網站失敗：$_"
        return
    }
    
    # 備份關鍵頁面 (含所有分類頁面)
    Write-Info "`n📄 備份關鍵頁面..."
    $LightBackupDir = Join-Path $BackupDir "website-light"
    New-Item -ItemType Directory -Path $LightBackupDir -Force | Out-Null
    
    $KeyFiles = @("index.html", "categories.html", "sitemap.xml", "404.html", "memorial.html", "royal_dragon_karma.html", "ads.txt", "robots.txt")
    foreach ($file in $KeyFiles) {
        $src = Join-Path $MainOutputDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $LightBackupDir -Force
            Write-Success "   ✅ $file"
        }
    }
    
    # 🆕 動態備份所有分類頁面
    foreach ($page in $Global:CategoryPages) {
        $src = Join-Path $MainOutputDir $page
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $LightBackupDir -Force
            Write-Success "   ✅ $page"
        }
    }
    
    # 遊戲
    $GameSrc = Join-Path $MainOutputDir "game"
    if (Test-Path $GameSrc) {
        $GameDest = Join-Path $LightBackupDir "game"
        New-Item -ItemType Directory -Path $GameDest -Force | Out-Null
        Copy-Item -Path "$GameSrc\*" -Destination $GameDest -Recurse -Force
        $GameCount = (Get-ChildItem -Path $GameDest -Filter "*.html").Count
        Write-Success "   ✅ 已備份遊戲 ($GameCount 款)"
    }
    
    # 產生文章清單 (動態)
    Write-Info "`n📋 產生文章清單..."
    $ManifestPath = Join-Path $BackupDir "article-manifest.txt"
    $AllArticles = @()
    
    foreach ($key in $Global:CategoryDirs.Keys) {
        $dirPath = Join-Path $MainOutputDir $key
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
                    Category = $Global:CategoryDirs[$key]
                    Title = $title
                    Filename = "$key/$($f.Name)"
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
輸出目錄：$MainOutputDir
============================================================

📊 總文章數：$($AllArticles.Count) 篇
📦 總大小：$([math]::Round(($AllArticles | Measure-Object -Property Size -Sum).Sum / 1MB, 2)) MB

"@
    
    foreach ($key in $Global:CategoryDirs.Keys) {
        $catName = $Global:CategoryDirs[$key]
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
    
    # 壓縮
    $ZipPath = $null
    if ($Compress -or $Golden) {
        Write-Info "`n🗜️ 壓縮備份..."
        $ZipPath = "$BackupDir.zip"
        try {
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
    
    # 黃金備份
    if ($Golden) {
        Write-Info "`n⭐ 複製黃金備份到 AI 檔案館..."
        New-Item -ItemType Directory -Path $GoldenArchiveRoot -Force | Out-Null
        
        if ($ZipPath -and (Test-Path $ZipPath)) {
            $GoldenDest = Join-Path $GoldenArchiveRoot "ahpal-golden-$Timestamp.zip"
            try {
                Copy-Item -Path $ZipPath -Destination $GoldenDest -Force
                Write-Success "   ✅ 已複製黃金備份：$GoldenDest"
                
                $OldGoldens = Get-ChildItem -Path $GoldenArchiveRoot -Filter "ahpal-golden-*.zip" |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -Skip $Global:GoldenBackupKeepCount
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
    
    # 顯示摘要
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
# 清理過舊備份
# ============================================================
function Invoke-Cleanup {
    Write-Section "🧹 清理過舊備份"
    $BackupRoot = "C:\Users\User\ahpal-backup"
    $KeepCount = $Global:BackupKeepCount
    
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
# 互動選單
# ============================================================
function Show-Menu {
    Clear-Host
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  📦 雅寶社區 · 頂客論壇 - 系統備份工具 v3.3" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] 一般備份 (不壓縮)"
    Write-Host "  [2] 備份 + 壓縮"
    Write-Host "  [3] ⭐ 黃金備份 (壓縮 + 複製到 AI 檔案館)"
    Write-Host "  [4] 🧹 清理過舊備份 (保留最近 $($Global:BackupKeepCount) 個)"
    Write-Host "  [0] 退出"
    Write-Host ""
}

# ============================================================
# 主程式
# ============================================================
if ($Cleanup) {
    Invoke-Cleanup
} elseif ($Golden -or $Compress) {
    Invoke-Backup -Compress:$Compress -Golden:$Golden
} else {
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

if ($script:isDoubleClicked) {
    Write-Host ""
    Write-Host "按 Enter 鍵結束..." -ForegroundColor Gray
    Read-Host
}