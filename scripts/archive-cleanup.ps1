# ============================================================
# archive-cleanup.ps1 - ahpal-AI-archive 目錄清理與整理腳本 v1.0
# ============================================================
# 功能：
#   1. 刪除舊的交接目錄與 ZIP (保留最近 3 個)
#   2. 刪除舊的用量數據目錄 (保留最新 1 個)
#   3. 歸檔根目錄歷史文件至 archive/
#   4. 整理後輸出目錄結構
# ============================================================

$ArchiveRoot = "C:\Users\User\ahpal-AI-archive"
$ArchiveDir = Join-Path $ArchiveRoot "archive"
$HistoryDir = Join-Path $ArchiveRoot "歷史文件"

Set-Location $ArchiveRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 ahpal-AI-archive 目錄清理與整理工具 v1.0" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📁 工作目錄：$ArchiveRoot" -ForegroundColor Yellow
Write-Host ""

# ============================================================
# 1. 建立歸檔目錄
# ============================================================
Write-Host "[1/6] 準備歸檔目錄..." -ForegroundColor Yellow

$DirsToCreate = @($ArchiveDir, $HistoryDir)
foreach ($dir in $DirsToCreate) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "   ✅ 已建立：$(Split-Path $dir -Leaf)" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️ 已存在：$(Split-Path $dir -Leaf)" -ForegroundColor Gray
    }
}
Write-Host ""

# ============================================================
# 2. 計算目前空間使用
# ============================================================
Write-Host "[2/6] 計算目前空間使用..." -ForegroundColor Yellow

$totalSize = (Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$totalSizeGB = [math]::Round($totalSize / 1GB, 2)
Write-Host "   📊 目前使用空間：$totalSizeGB GB" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 3. 清理舊交接目錄與 ZIP (保留最近 3 個)
# ============================================================
Write-Host "[3/6] 清理舊交接目錄與 ZIP (保留最近 3 個)..." -ForegroundColor Yellow

$KeepCount = 3

# 取得所有 ai交接- 目錄 (按時間排序，最新的在前)
$HandoverDirs = Get-ChildItem -Path $ArchiveRoot -Directory -Filter "ai交接-*" | Sort-Object LastWriteTime -Descending
$HandoverZips = Get-ChildItem -Path $ArchiveRoot -File -Filter "ai交接-*.zip" | Sort-Object LastWriteTime -Descending

Write-Host "   📁 找到 $($HandoverDirs.Count) 個交接目錄" -ForegroundColor Gray
Write-Host "   📦 找到 $($HandoverZips.Count) 個交接 ZIP 檔" -ForegroundColor Gray

$DeletedDirCount = 0
$DeletedZipCount = 0
$FreedSize = 0

# 刪除舊目錄 (跳過前 $KeepCount 個)
if ($HandoverDirs.Count -gt $KeepCount) {
    $ToDeleteDirs = $HandoverDirs | Select-Object -Skip $KeepCount
    foreach ($dir in $ToDeleteDirs) {
        $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $dir.FullName -Recurse -Force
        Write-Host "   🗑️ 已刪除目錄：$($dir.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedDirCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 交接目錄 $($HandoverDirs.Count) 個，未超過 $KeepCount 個，無需刪除" -ForegroundColor Gray
}

# 刪除舊 ZIP (跳過前 $KeepCount 個)
if ($HandoverZips.Count -gt $KeepCount) {
    $ToDeleteZips = $HandoverZips | Select-Object -Skip $KeepCount
    foreach ($zip in $ToDeleteZips) {
        $size = $zip.Length
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $zip.FullName -Force
        Write-Host "   🗑️ 已刪除 ZIP：$($zip.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedZipCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 交接 ZIP $($HandoverZips.Count) 個，未超過 $KeepCount 個，無需刪除" -ForegroundColor Gray
}

Write-Host "   📊 刪除 $DeletedDirCount 個目錄，$DeletedZipCount 個 ZIP" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 4. 清理舊用量數據 (保留最新 1 個)
# ============================================================
Write-Host "[4/6] 清理舊用量數據 (保留最新 1 個)..." -ForegroundColor Yellow

$KeepUsageCount = 1

# 取得所有 usage_data_ 目錄 (按時間排序，最新的在前)
$UsageDirs = Get-ChildItem -Path $ArchiveRoot -Directory -Filter "usage_data_*" | Sort-Object LastWriteTime -Descending
$UsageZips = Get-ChildItem -Path $ArchiveRoot -File -Filter "usage_data_*.zip" | Sort-Object LastWriteTime -Descending

Write-Host "   📁 找到 $($UsageDirs.Count) 個用量數據目錄" -ForegroundColor Gray
Write-Host "   📦 找到 $($UsageZips.Count) 個用量數據 ZIP" -ForegroundColor Gray

$DeletedUsageDirCount = 0
$DeletedUsageZipCount = 0

# 刪除舊目錄 (跳過前 $KeepUsageCount 個)
if ($UsageDirs.Count -gt $KeepUsageCount) {
    $ToDeleteDirs = $UsageDirs | Select-Object -Skip $KeepUsageCount
    foreach ($dir in $ToDeleteDirs) {
        $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $dir.FullName -Recurse -Force
        Write-Host "   🗑️ 已刪除目錄：$($dir.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedUsageDirCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 用量目錄 $($UsageDirs.Count) 個，未超過 $KeepUsageCount 個，無需刪除" -ForegroundColor Gray
}

# 刪除舊 ZIP (跳過前 $KeepUsageCount 個)
if ($UsageZips.Count -gt $KeepUsageCount) {
    $ToDeleteZips = $UsageZips | Select-Object -Skip $KeepUsageCount
    foreach ($zip in $ToDeleteZips) {
        $size = $zip.Length
        $sizeMB = [math]::Round($size / 1MB, 2)
        Remove-Item -Path $zip.FullName -Force
        Write-Host "   🗑️ 已刪除 ZIP：$($zip.Name) ($sizeMB MB)" -ForegroundColor Red
        $DeletedUsageZipCount++
        $FreedSize += $size
    }
} else {
    Write-Host "   ℹ️ 用量 ZIP $($UsageZips.Count) 個，未超過 $KeepUsageCount 個，無需刪除" -ForegroundColor Gray
}

Write-Host "   📊 刪除 $DeletedUsageDirCount 個目錄，$DeletedUsageZipCount 個 ZIP" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 5. 歸檔根目錄歷史文件
# ============================================================
Write-Host "[5/6] 歸檔根目錄歷史文件..." -ForegroundColor Yellow

$FilesToArchive = @(
    "AHPAL-交接手冊-v3.0.html",
    "AHPAL-技術白皮書-v3.0.html",
    "AHPAL-紅皮書-v3.0.html",
    "AI交接提示詞-設定筆電可在夜間被自動喚醒.txt",
    "ANTIGRAVITY_HANDOVER.md",
    "HANDOVER.md",
    "PowerShell 開機診斷指令README.md",
    "打一份AI交接與新進工程師交接手冊.html",
    "歷史腦洞-創作典範.txt",
    "電子墓碑、JSONDecodeError 墓誌銘.html"
)

$MovedCount = 0
foreach ($file in $FilesToArchive) {
    $src = Join-Path $ArchiveRoot $file
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
# 6. 顯示清理後結果
# ============================================================
Write-Host "[6/6] 清理完成！顯示結果..." -ForegroundColor Yellow
Write-Host ""

# 計算清理後空間
$newTotalSize = (Get-ChildItem -Path $ArchiveRoot -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
$newTotalSizeGB = [math]::Round($newTotalSize / 1GB, 2)
$freedSizeGB = [math]::Round($FreedSize / 1GB, 2)

Write-Host "============================================================" -ForegroundColor Green
Write-Host "  📊 清理後 ahpal-AI-archive 目錄結構" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📁 ahpal-AI-archive/" -ForegroundColor Cyan

# 顯示根目錄檔案
$rootFiles = Get-ChildItem -Path $ArchiveRoot -File
if ($rootFiles) {
    foreach ($f in $rootFiles) {
        $sizeKB = [math]::Round($f.Length / 1KB, 1)
        Write-Host "   ├─ $($f.Name) ($sizeKB KB)" -ForegroundColor Gray
    }
}

# 顯示子目錄
$subDirs = Get-ChildItem -Path $ArchiveRoot -Directory | Sort-Object Name
foreach ($dir in $subDirs) {
    $count = (Get-ChildItem -Path $dir.FullName -File -Recurse -ErrorAction SilentlyContinue).Count
    $size = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($size / 1MB, 2)
    Write-Host "   📁 $($dir.Name)/ ($count 個檔案, $sizeMB MB)" -ForegroundColor DarkCyan
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ✅ 清理完成！" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 摘要：" -ForegroundColor Yellow
Write-Host "   ├─ 刪除交接目錄：$DeletedDirCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 刪除交接 ZIP：$DeletedZipCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 刪除用量目錄：$DeletedUsageDirCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 刪除用量 ZIP：$DeletedUsageZipCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 歸檔文件：$MovedCount 個" -ForegroundColor Cyan
Write-Host "   ├─ 釋放空間：$freedSizeGB GB" -ForegroundColor Green
Write-Host "   └─ 目前使用空間：$newTotalSizeGB GB" -ForegroundColor Cyan
Write-Host ""

Write-Host "📌 保留清單：" -ForegroundColor Yellow
Write-Host "   ├─ 最近 $KeepCount 個交接目錄 + ZIP" -ForegroundColor Gray
Write-Host "   ├─ 最新 1 個用量數據目錄 + ZIP" -ForegroundColor Gray
Write-Host "   └─ 根目錄：README.md, 備份記錄.txt, system-tools/, videos/, 優良備份/" -ForegroundColor Gray
Write-Host ""

Read-Host "按 Enter 結束"