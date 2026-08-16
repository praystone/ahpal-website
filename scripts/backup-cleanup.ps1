# ============================================================
# backup-cleanup.ps1 - ahpal-backup 目錄清理腳本 v1.0
# ============================================================

$BackupRoot = "C:\Users\User\ahpal-backup"
$KeepCount = 5  # 保留最近 5 個備份

Set-Location $BackupRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 ahpal-backup 目錄清理工具 v1.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 工作目錄：$BackupRoot" -ForegroundColor Yellow
Write-Host "📌 保留最近 $KeepCount 個備份" -ForegroundColor Yellow
Write-Host ""

# 1. 計算目前空間
$totalSize = (Get-ChildItem -Path $BackupRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$totalSizeGB = [math]::Round($totalSize / 1GB, 2)
Write-Host "[1/3] 目前使用空間：$totalSizeGB GB" -ForegroundColor Cyan
Write-Host ""

# 2. 取得所有備份目錄 (按時間排序，最新的在前)
$BackupDirs = Get-ChildItem -Path $BackupRoot -Directory -Filter "2026-*" | Sort-Object LastWriteTime -Descending
$BackupZips = Get-ChildItem -Path $BackupRoot -File -Filter "2026-*.zip" | Sort-Object LastWriteTime -Descending

Write-Host "[2/3] 找到 $($BackupDirs.Count) 個備份目錄，$($BackupZips.Count) 個 ZIP 檔" -ForegroundColor Yellow
Write-Host ""

# 3. 刪除舊備份目錄 (跳過前 $KeepCount 個)
$DeletedDirCount = 0
$DeletedZipCount = 0
$FreedSize = 0

if ($BackupDirs.Count -gt $KeepCount) {
    $ToDeleteDirs = $BackupDirs | Select-Object -Skip $KeepCount
    foreach ($dir in $ToDeleteDirs) {
        $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $dir.FullName -Recurse -Force
        Write-Host "   🗑️ 已刪除目錄：$($dir.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedDirCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 備份目錄 $($BackupDirs.Count) 個，未超過 $KeepCount 個，無需刪除" -ForegroundColor Gray
}

# 4. 刪除舊 ZIP (跳過前 $KeepCount 個)
if ($BackupZips.Count -gt $KeepCount) {
    $ToDeleteZips = $BackupZips | Select-Object -Skip $KeepCount
    foreach ($zip in $ToDeleteZips) {
        $size = $zip.Length
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $zip.FullName -Force
        Write-Host "   🗑️ 已刪除 ZIP：$($zip.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedZipCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 備份 ZIP $($BackupZips.Count) 個，未超過 $KeepCount 個，無需刪除" -ForegroundColor Gray
}

# 5. 檢查 extract-golden/ 目錄
Write-Host ""
Write-Host "[3/3] 檢查 extract-golden/ 目錄..." -ForegroundColor Yellow
$GoldenDir = Join-Path $BackupRoot "extract-golden"
if (Test-Path $GoldenDir) {
    $goldenSize = (Get-ChildItem -Path $GoldenDir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $goldenSizeMB = [math]::Round($goldenSize / 1MB, 2)
    Write-Host "   📁 extract-golden/ 大小：$goldenSizeMB MB" -ForegroundColor Gray
    $confirm = Read-Host "  是否刪除 extract-golden/？(y/n)"
    if ($confirm -eq "y") {
        Remove-Item -Path $GoldenDir -Recurse -Force
        Write-Host "   🗑️ 已刪除 extract-golden/" -ForegroundColor Red
        $FreedSize += $goldenSize
    }
}

# 6. 顯示結果
$newTotalSize = (Get-ChildItem -Path $BackupRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$newTotalSizeGB = [math]::Round($newTotalSize / 1GB, 2)
$freedSizeGB = [math]::Round($FreedSize / 1GB, 2)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 清理完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 摘要：" -ForegroundColor Yellow
Write-Host "   ├─ 刪除備份目錄：$DeletedDirCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 刪除備份 ZIP：$DeletedZipCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 釋放空間：$freedSizeGB GB" -ForegroundColor Green
Write-Host "   └─ 目前使用空間：$newTotalSizeGB GB" -ForegroundColor Cyan
Write-Host ""
Write-Host "📌 保留清單：" -ForegroundColor Yellow
$BackupDirs | Select-Object -First $KeepCount | ForEach-Object {
    Write-Host "   ├─ $($_.Name)" -ForegroundColor Gray
}
Write-Host ""

Read-Host "按 Enter 結束"