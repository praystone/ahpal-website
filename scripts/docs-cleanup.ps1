# ============================================================
# docs-cleanup.ps1 - docs/ 目錄清理與整理腳本 v1.0
# ============================================================
# 功能：
#   1. 歸檔舊版本文件至 _archive/
#   2. 重新命名檔名含空格的檔案
#   3. 刪除臨時測試檔案
#   4. 整理後輸出目錄結構
# ============================================================

$DocsDir = "C:\Users\User\ahpal-static\docs"
$ArchiveDir = Join-Path $DocsDir "_archive"

Set-Location $DocsDir

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 docs/ 目錄清理與整理工具 v1.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 工作目錄：$DocsDir" -ForegroundColor Yellow
Write-Host "📁 歸檔目錄：$ArchiveDir" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# 1. 建立歸檔目錄 (如不存在)
# ============================================================
Write-Host "[1/5] 準備歸檔目錄..." -ForegroundColor Yellow
if (-not (Test-Path $ArchiveDir)) {
    New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    Write-Host "   ✅ 已建立歸檔目錄" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ 歸檔目錄已存在" -ForegroundColor Gray
}
Write-Host ""

# ============================================================
# 2. 歸檔舊版本文件
# ============================================================
Write-Host "[2/5] 歸檔舊版本文件..." -ForegroundColor Yellow

$OldFiles = @(
    "AHPAL-交接手冊-v4.2.html",
    "AHPAL-交接手冊-v4.3.html",
    "AHPAL 喚醒定時器測試 SOP 標竿 v1.0.html",
    "AHPAL 災難備忘錄 v3.0 .html"
)

$MovedCount = 0
foreach ($file in $OldFiles) {
    $src = Join-Path $DocsDir $file
    if (Test-Path $src) {
        $dest = Join-Path $ArchiveDir $file
        Move-Item -Path $src -Destination $dest -Force
        Write-Host "   ✅ 已歸檔：$file" -ForegroundColor Green
        $MovedCount++
    } else {
        Write-Host "   ⚠️ 找不到：$file" -ForegroundColor Yellow
    }
}
Write-Host "   📊 共歸檔 $MovedCount 個檔案" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 3. 刪除臨時測試檔案
# ============================================================
Write-Host "[3/5] 刪除臨時測試檔案..." -ForegroundColor Yellow

$TempFiles = @(
    "新增 文字文件.txt"
)

$DeletedCount = 0
foreach ($file in $TempFiles) {
    $src = Join-Path $DocsDir $file
    if (Test-Path $src) {
        Remove-Item -Path $src -Force
        Write-Host "   🗑️ 已刪除：$file" -ForegroundColor Red
        $DeletedCount++
    } else {
        Write-Host "   ⚠️ 找不到：$file" -ForegroundColor Yellow
    }
}
Write-Host "   📊 共刪除 $DeletedCount 個檔案" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 4. 重新命名 (移除空格)
# ============================================================
Write-Host "[4/5] 重新命名檔案 (移除空格)..." -ForegroundColor Yellow

# 檢查災難備忘錄 v3.0 是否有空格
$ProblematicFile = "AHPAL 災難備忘錄 v3.0 .html"
$FixedFile = "AHPAL-災難備忘錄-v3.0.html"

# 先檢查是否在歸檔目錄中 (因為上一步已歸檔)
$srcArchive = Join-Path $ArchiveDir $ProblematicFile
if (Test-Path $srcArchive) {
    $destArchive = Join-Path $ArchiveDir $FixedFile
    Rename-Item -Path $srcArchive -NewName $FixedFile -Force
    Write-Host "   ✅ 已重新命名 (歸檔中)：$ProblematicFile → $FixedFile" -ForegroundColor Green
} else {
    # 檢查是否仍在主目錄
    $srcMain = Join-Path $DocsDir $ProblematicFile
    if (Test-Path $srcMain) {
        $destMain = Join-Path $DocsDir $FixedFile
        Rename-Item -Path $srcMain -NewName $FixedFile -Force
        Write-Host "   ✅ 已重新命名：$ProblematicFile → $FixedFile" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️ 找不到：$ProblematicFile (可能已被歸檔或刪除)" -ForegroundColor Yellow
    }
}
Write-Host ""

# ============================================================
# 5. 顯示清理後目錄結構
# ============================================================
Write-Host "[5/5] 清理完成！顯示目錄結構..." -ForegroundColor Yellow
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  📊 清理後 docs/ 目錄結構" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📁 docs/" -ForegroundColor Cyan

# 顯示根目錄檔案
Get-ChildItem -Path $DocsDir -File | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 1)
    $color = if ($_.Name -match "紅皮書|技術白皮書|創作憲章|交接手冊") { "Green" } elseif ($_.Name -match "四大件|索引") { "Yellow" } else { "Gray" }
    Write-Host "   ├─ $($_.Name) ($sizeKB KB)" -ForegroundColor $color
}

# 顯示子目錄
Get-ChildItem -Path $DocsDir -Directory | ForEach-Object {
    $count = (Get-ChildItem -Path $_.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
    Write-Host "   📁 $($_.Name)/ ($count 個檔案)" -ForegroundColor DarkCyan
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 清理完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 摘要：" -ForegroundColor Yellow
Write-Host "   ├─ 歸檔舊版本：$MovedCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 刪除臨時檔：$DeletedCount 個" -ForegroundColor Cyan
Write-Host "   └─ 重新命名：1 個 (移除空格)" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 下一步：更新四大件索引，確認版本對照表正確" -ForegroundColor Gray
Write-Host ""

Read-Host "按 Enter 結束"