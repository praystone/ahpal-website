# ============================================================
# 🎬 AHPAL MP3 合併 + MP4 生成腳本 v2.0
# 功能：合併多個 MP3 + 封面圖片 → 輸出 MP4 影片
# 位置：C:\Users\User\ahpal-static\scripts\merge-to-mp4.ps1
# 使用：.\scripts\merge-to-mp4.ps1
# ============================================================

param(
    [string]$MusicDir = "C:\Users\User\ahpal-static\music",
    [string]$OutputName = "合併影片",
    [switch]$AutoSelect,
    [switch]$CleanTemp
)

# ============================================================
# 顏色函數
# ============================================================
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Section { Write-Host "`n$('='*60)" -ForegroundColor Cyan; Write-Host $args -ForegroundColor Cyan; Write-Host "$('='*60)" -ForegroundColor Cyan }

# ============================================================
# 檢查 FFmpeg
# ============================================================
function Test-FFmpeg {
    try {
        $version = ffmpeg -version 2>&1 | Select-Object -First 1
        Write-Host "✅ FFmpeg 已安裝：$version" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "❌ FFmpeg 未安裝或不在 PATH 中"
        Write-Host "請下載 FFmpeg：https://ffmpeg.org/download.html" -ForegroundColor Yellow
        return $false
    }
}

# ============================================================
# 🆕 掃描音樂檔案（強化版）
# ============================================================
function Scan-MusicFiles {
    param([string]$Dir)
    
    # 排除已合併的檔案、暫存檔、過小檔案
    $excludePatterns = @("*合併版*", "*合併完整版*", "*單一檔案*", "*.wm.*", "*.tmp*", "merge-list*")
    
    $mp3Files = Get-ChildItem -Path $Dir -Filter "*.mp3" -File | Where-Object {
        $exclude = $false
        foreach ($pattern in $excludePatterns) {
            if ($_.Name -like $pattern) { $exclude = $true; break }
        }
        -not $exclude -and $_.Length -gt 500KB  # 至少 500KB
    } | Sort-Object LastWriteTime
    
    if ($mp3Files.Count -eq 0) {
        Write-Error "❌ 找不到 MP3 檔案：$Dir"
        return $null
    }
    
    Write-Host "`n📋 找到 $($mp3Files.Count) 個 MP3 檔案：" -ForegroundColor Yellow
    for ($i = 0; $i -lt $mp3Files.Count; $i++) {
        $size = [math]::Round($mp3Files[$i].Length / 1MB, 2)
        Write-Host "  [$($i+1)] $($mp3Files[$i].Name) ($size MB)" -ForegroundColor Gray
    }
    
    # 🆕 尋找封面圖片（強化版）
    $coverImages = Get-ChildItem -Path $Dir -File | Where-Object {
        $_.Extension -match "\.(jpg|jpeg|png)$" -and 
        $_.Length -gt 10KB -and
        $_.Name -notlike "*.wm.*" -and
        $_.Name -notlike "*.tmp*"
    } | Sort-Object LastWriteTime -Descending
    
    $coverPath = $null
    if ($coverImages.Count -gt 0) {
        $coverPath = $coverImages[0].FullName
        Write-Host "`n🖼️ 封面圖片：$($coverImages[0].Name)" -ForegroundColor Green
        if ($coverImages.Count -gt 1) {
            Write-Host "   （共有 $($coverImages.Count) 張圖片，使用最新的一張）" -ForegroundColor Gray
        }
    } else {
        Write-Warning "⚠️ 找不到封面圖片，將使用純黑背景"
        # 嘗試找任何圖片
        $anyImage = Get-ChildItem -Path $Dir -File | Where-Object { $_.Extension -match "\.(jpg|jpeg|png|gif|bmp)$" } | Select-Object -First 1
        if ($anyImage) {
            $coverPath = $anyImage.FullName
            Write-Host "`n🖼️ 使用替代圖片：$($anyImage.Name)" -ForegroundColor Yellow
        }
    }
    
    return @{
        Mp3Files = $mp3Files
        CoverPath = $coverPath
    }
}

# ============================================================
# 選擇要合併的檔案
# ============================================================
function Select-Mp3Files {
    param([array]$Mp3Files)
    
    if ($AutoSelect) {
        Write-Host "`n🔄 自動模式：使用全部 $($Mp3Files.Count) 個檔案" -ForegroundColor Yellow
        return $Mp3Files
    }
    
    Write-Host "`n📝 請輸入要合併的檔案編號（用逗號分隔，例如：1,2,3）" -ForegroundColor Yellow
    Write-Host "   輸入 'all' 選擇全部，或按 Enter 選擇全部" -ForegroundColor Gray
    $input = Read-Host "你的選擇"
    
    if ($input -eq "" -or $input -eq "all") {
        return $Mp3Files
    }
    
    $selected = @()
    $numbers = $input -split ',' | ForEach-Object { $_.Trim() }
    foreach ($num in $numbers) {
        $index = [int]$num - 1
        if ($index -ge 0 -and $index -lt $Mp3Files.Count) {
            $selected += $Mp3Files[$index]
        } else {
            Write-Warning "⚠️ 無效編號：$num，已跳過"
        }
    }
    
    if ($selected.Count -eq 0) {
        Write-Warning "⚠️ 未選擇任何檔案，將使用全部檔案"
        return $Mp3Files
    }
    
    return $selected
}

# ============================================================
# 🆕 合併 MP3（強化中文檔名處理）
# ============================================================
function Merge-Mp3Files {
    param(
        [array]$SelectedFiles,
        [string]$OutputDir
    )
    
    if ($SelectedFiles.Count -eq 0) {
        Write-Error "❌ 沒有選擇任何檔案"
        return $null
    }
    
    if ($SelectedFiles.Count -eq 1) {
        Write-Host "`n📌 只有 1 個檔案，無需合併" -ForegroundColor Yellow
        return $SelectedFiles[0].FullName
    }
    
    Write-Host "`n🔄 合併 $($SelectedFiles.Count) 個 MP3 檔案..." -ForegroundColor Yellow
    
    # 🆕 使用 FFmpeg 的 concat 協議（直接合併，不需清單檔案）
    $filePaths = $SelectedFiles | ForEach-Object { "`"$($_.FullName)`"" }
    $concatString = $filePaths -join "|"
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputPath = Join-Path $OutputDir "合併版_$timestamp.mp3"
    
    Write-Host "   📌 執行 FFmpeg 合併..." -ForegroundColor Gray
    
    # 使用更穩健的合併方式
    $ffmpegCmd = "ffmpeg -i `"concat:$concatString`" -c copy `"$outputPath`""
    Write-Host "   🔧 $ffmpegCmd" -ForegroundColor DarkGray
    
    $result = Invoke-Expression $ffmpegCmd 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
        $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
        Write-Success "   ✅ 合併完成：$outputPath ($size MB)"
        return $outputPath
    } else {
        Write-Error "   ❌ 合併失敗，嘗試使用 concat 檔案方式..."
        
        # 🆕 備案：使用清單檔案
        $listFile = Join-Path $OutputDir "merge-list-$timestamp.txt"
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $listContent = ""
        foreach ($file in $SelectedFiles) {
            $listContent += "file '$($file.FullName)'`n"
        }
        [System.IO.File]::WriteAllText($listFile, $listContent, $utf8NoBom)
        
        $result2 = ffmpeg -f concat -safe 0 -i $listFile -c copy $outputPath 2>&1
        
        if ($LASTEXITCODE -eq 0 -and (Test-Path $outputPath)) {
            $size = [math]::Round((Get-Item $outputPath).Length / 1MB, 2)
            Write-Success "   ✅ 合併完成：$outputPath ($size MB)"
            Remove-Item $listFile -Force -ErrorAction SilentlyContinue
            return $outputPath
        } else {
            Write-Error "   ❌ 合併失敗"
            Write-Host $result2 -ForegroundColor Red
            return $null
        }
    }
}

# ============================================================
# 🆕 轉換為 MP4（強化版）
# ============================================================
function Convert-ToMp4 {
    param(
        [string]$Mp3Path,
        [string]$CoverPath,
        [string]$OutputDir,
        [string]$OutputName
    )
    
    if (-not $Mp3Path -or -not (Test-Path $Mp3Path)) {
        Write-Error "❌ MP3 檔案不存在：$Mp3Path"
        return $null
    }
    
    Write-Host "`n🎬 轉換為 MP4..." -ForegroundColor Yellow
    
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputFile = Join-Path $OutputDir "$OutputName-$timestamp.mp4"
    
    # 🆕 確保輸出目錄存在
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    
    if ($CoverPath -and (Test-Path $CoverPath)) {
        Write-Host "   🖼️ 使用封面圖片：$(Split-Path $CoverPath -Leaf)" -ForegroundColor Gray
        $ffmpegCmd = "ffmpeg -loop 1 -i `"$CoverPath`" -i `"$Mp3Path`" -c:v libx264 -tune stillimage -c:a aac -b:a 192k -shortest -pix_fmt yuv420p `"$outputFile`""
    } else {
        Write-Host "   ⚠️ 無封面圖片，使用純黑背景 + 文字標題" -ForegroundColor Yellow
        $ffmpegCmd = "ffmpeg -f lavfi -i color=c=black:s=1280x720:d=5 -i `"$Mp3Path`" -c:v libx264 -c:a aac -b:a 192k -shortest -pix_fmt yuv420p `"$outputFile`""
    }
    
    Write-Host "   🔧 $ffmpegCmd" -ForegroundColor DarkGray
    $result = Invoke-Expression $ffmpegCmd 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {
        $size = [math]::Round((Get-Item $outputFile).Length / 1MB, 2)
        Write-Success "   ✅ MP4 生成完成：$outputFile ($size MB)"
        return $outputFile
    } else {
        Write-Error "   ❌ MP4 轉換失敗"
        Write-Host $result -ForegroundColor Red
        return $null
    }
}

# ============================================================
# 🆕 清理暫存檔案
# ============================================================
function Clean-TempFiles {
    param([string]$Dir)
    
    Write-Host "`n🧹 清理暫存檔案..." -ForegroundColor Yellow
    
    $patterns = @("merge-list-*.txt", "*.tmp", "*.temp")
    $count = 0
    foreach ($pattern in $patterns) {
        $files = Get-ChildItem -Path $Dir -Filter $pattern -File -ErrorAction SilentlyContinue
        foreach ($f in $files) {
            Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
            $count++
        }
    }
    Write-Success "   ✅ 已清理 $count 個暫存檔案"
}

# ============================================================
# 主程式
# ============================================================
Write-Section "🎬 AHPAL MP3 合併 + MP4 生成工具 v2.0"

# 1. 檢查 FFmpeg
if (-not (Test-FFmpeg)) {
    Read-Host "按 Enter 結束"
    exit 1
}

# 2. 切換到音樂目錄
if (-not (Test-Path $MusicDir)) {
    Write-Error "❌ 目錄不存在：$MusicDir"
    Read-Host "按 Enter 結束"
    exit 1
}
Set-Location $MusicDir
Write-Info "📁 工作目錄：$MusicDir"

# 3. 掃描檔案
$scanResult = Scan-MusicFiles -Dir $MusicDir
if (-not $scanResult) {
    Read-Host "按 Enter 結束"
    exit 1
}

$mp3Files = $scanResult.Mp3Files
$coverPath = $scanResult.CoverPath

# 4. 選擇要合併的檔案
$selectedFiles = Select-Mp3Files -Mp3Files $mp3Files

# 5. 合併 MP3
$mergedMp3 = Merge-Mp3Files -SelectedFiles $selectedFiles -OutputDir $MusicDir
if (-not $mergedMp3) {
    Read-Host "按 Enter 結束"
    exit 1
}

# 6. 轉換為 MP4
$mp4File = Convert-ToMp4 -Mp3Path $mergedMp3 -CoverPath $coverPath -OutputDir $MusicDir -OutputName $OutputName

# 7. 清理暫存
if ($CleanTemp) {
    Clean-TempFiles -Dir $MusicDir
}

# 8. 結果總結
Write-Section "✅ 處理完成"

if ($mp4File) {
    Write-Success "📁 MP4 檔案：$mp4File"
    Write-Host ""
    Write-Host "📋 下一步：" -ForegroundColor Yellow
    Write-Host "   1. 上傳到 YouTube" -ForegroundColor Gray
    Write-Host "   2. 複製影片 ID" -ForegroundColor Gray
    Write-Host "   3. 填入 data/pending-articles.json 的 video_id 欄位" -ForegroundColor Gray
    Write-Host "   4. 執行 python src/main.py --force deepseek" -ForegroundColor Gray
    Write-Host ""
    Write-Host "🎬 播放測試：Start-Process `"$mp4File`"" -ForegroundColor Cyan
} else {
    Write-Error "❌ 處理失敗，請檢查錯誤訊息"
}

Read-Host "`n按 Enter 結束"