# ============================================================
# 📤 AHPAL 定时同步到 ahpalke_drive (排程专用)
# ============================================================
# 用途：每日自动同步優良備份到 ahpalke@gmail.com
# 用法：powershell -ExecutionPolicy Bypass -File "C:\Users\User\ahpal-static\scripts\sync-ahpalke-scheduled.ps1"
# ============================================================

# 设定日志
$LogDir = "C:\Users\User\ahpal-static\logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

$LogFile = Join-Path $LogDir "sync-ahpalke.log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 写入日志函数
function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $LogEntry = "[$Timestamp] $Message"
    Add-Content -Path $LogFile -Value $LogEntry -Encoding UTF8
    Write-Host $LogEntry -ForegroundColor $Color
}

Write-Log "========================================" "Cyan"
Write-Log "📤 AHPAL 定时同步启动" "Cyan"
Write-Log "========================================" "Cyan"

# 检查 Rclone
$RclonePath = "C:\MyCloudBackup\rclone.exe"
if (-not (Test-Path $RclonePath)) {
    Write-Log "❌ Rclone 不存在，跳过同步" "Red"
    exit 1
}

# 检查来源目录
$SourceDir = "C:\Users\User\ahpal-AI-archive\優良備份"
if (-not (Test-Path $SourceDir)) {
    Write-Log "❌ 来源目录不存在：$SourceDir" "Red"
    exit 1
}

# 检查档案数量
$FileCount = (Get-ChildItem -Path $SourceDir -Recurse -File -ErrorAction SilentlyContinue).Count
Write-Log "📊 来源档案数：$FileCount 个" "Yellow"

if ($FileCount -eq 0) {
    Write-Log "⚠️ 来源目录为空，跳过同步" "Yellow"
    exit 0
}

# 执行 Rclone sync
Write-Log "☁️ 正在同步到 ahpalke_drive:/優良備份..." "Cyan"

cd C:\MyCloudBackup

# 使用 --progress 输出到日志，但保留最后状态
$SyncResult = & $RclonePath sync "C:\Users\User\ahpal-AI-archive\優良備份" "ahpalke_drive:/優良備份" --transfers 4 --verbose 2>&1

# 检查结果
if ($LASTEXITCODE -eq 0) {
    Write-Log "✅ 同步完成！" "Green"
} else {
    Write-Log "⚠️ 同步可能不完全 (退出码: $LASTEXITCODE)" "Yellow"
}

# 显示最后几行输出
Write-Log "📋 最后输出：" "Gray"
$SyncResult | Select-Object -Last 5 | ForEach-Object { Write-Log "   $_" "Gray" }

Write-Log "========================================" "Cyan"
Write-Log "✅ 定时同步结束" "Green"
Write-Log "========================================" "Cyan"