# ============================================================
# watch-pipeline.ps1 - 產線健康監控與日誌摘要 v1.1
# ============================================================
# 功能：
#   1. 掃描最新批次生成日誌，過濾錯誤與警告
#   2. 輸出每日產線報告摘要
#   3. 可整合至 ahpal-master.ps1 或排程執行
# ============================================================

param(
    [switch]$SendReport,
    [switch]$Quiet
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$LogRoot = "C:\Users\User\ahpal-AI-archive\system-tools\system-reports\01-批次生成日誌"
$ReportDir = "C:\Users\User\ahpal-AI-archive\system-tools\system-reports\03-產線報告"

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null

function Write-Info {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Cyan }
}
function Write-Success {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Green }
}
function Write-Warning {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Yellow }
}
function Write-Error {
    if (-not $Quiet) { Write-Host $args -ForegroundColor Red }
}

Write-Info "============================================================"
Write-Info "  📡 AHPAL 產線健康監控與日誌摘要 v1.1"
Write-Info "============================================================"
Write-Info ""

$LogFiles = Get-ChildItem -Path $LogRoot -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 3

if ($LogFiles.Count -eq 0) {
    Write-Warning "⚠️ 找不到任何日誌檔案"
    exit 0
}

Write-Info "📁 掃描日誌檔案："
$LogFiles | ForEach-Object { Write-Info "   - $($_.Name) ($([math]::Round($_.Length/1KB,1)) KB)" }

$Report = @()
$Report += "============================================================"
$Report += "  📡 AHPAL 產線健康報告"
$Report += "  產生時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Report += "============================================================"
$Report += ""

$TotalSuccess = 0
$TotalFail = 0
$TotalSkip = 0
$Errors = @()
$RateLimitHits = 0

foreach ($LogFile in $LogFiles) {
    $Content = Get-Content -Path $LogFile.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
    if (-not $Content) { continue }

    $Report += "📂 日誌：$($LogFile.Name)"
    $Report += "────────────────────────────────────────────────────────"

    $SummaryLines = $Content | Select-String -Pattern "執行總結：成功 (\d+) 篇 \| 跳過 (\d+) 篇 \| 失敗 (\d+) 篇"
    if ($SummaryLines) {
        $LastSummary = $SummaryLines[-1]
        if ($LastSummary -and $LastSummary.Matches -and $LastSummary.Matches[0]) {
            $Matches = $LastSummary.Matches[0].Groups
            $Success = if ($Matches[1]) { $Matches[1].Value } else { 0 }
            $Skip = if ($Matches[2]) { $Matches[2].Value } else { 0 }
            $Fail = if ($Matches[3]) { $Matches[3].Value } else { 0 }
            $TotalSuccess += [int]$Success
            $TotalSkip += [int]$Skip
            $TotalFail += [int]$Fail
            $Report += "   ✅ 成功：$Success 篇"
            $Report += "   ⏩ 跳過：$Skip 篇"
            if ($Fail -gt 0) {
                $Report += "   ❌ 失敗：$Fail 篇"
            }
        }
    }

    $ErrorLines = $Content | Select-String -Pattern "ERROR|❌|failed|exception|timeout|Traceback" -CaseSensitive:$false
    if ($ErrorLines) {
        $Errors += $ErrorLines
        $Report += "   ⚠️ 發現錯誤："
        $ErrorLines | Select-Object -First 5 | ForEach-Object {
            $Report += "      - $($_.Line.Trim())"
        }
        if ($ErrorLines.Count -gt 5) {
            $Report += "      ... 還有 $($ErrorLines.Count - 5) 行"
        }
    }

    $RateLimitLines = $Content | Select-String -Pattern "RateLimit|rate limit|quota|429|RESOURCE_EXHAUSTED" -CaseSensitive:$false
    if ($RateLimitLines) {
        $RateLimitHits += $RateLimitLines.Count
        $Report += "   ⚠️ API 限額事件：$($RateLimitLines.Count) 次"
    }

    $Report += ""
}

$Report += "============================================================"
$Report += "📊 總結報告"
$Report += "============================================================"
$Report += "   ✅ 總成功：$TotalSuccess 篇"
$Report += "   ⏩ 總跳過：$TotalSkip 篇"
if ($TotalFail -gt 0) {
    $Report += "   ❌ 總失敗：$TotalFail 篇"
}
if ($RateLimitHits -gt 0) {
    $Report += "   ⚠️ API 限額事件：$RateLimitHits 次"
}
$Report += ""
$HealthStatus = if ($TotalFail -eq 0 -and $RateLimitHits -eq 0) { 
    "🟢 正常" 
} elseif ($TotalFail -gt 0) { 
    "🔴 異常" 
} else { 
    "🟡 需注意" 
}
$Report += "📌 健康狀態：$HealthStatus"
$Report += "============================================================"

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$ReportFile = Join-Path $ReportDir "pipeline-health-$Timestamp.txt"
$Report | Out-File -FilePath $ReportFile -Encoding UTF8

Write-Success "✅ 報告已儲存：$ReportFile"
Write-Info ""
Write-Info "📊 產線健康摘要："
Write-Info "   ✅ 成功：$TotalSuccess 篇"
Write-Info "   ⏩ 跳過：$TotalSkip 篇"
if ($TotalFail -gt 0) {
    Write-Error "   ❌ 失敗：$TotalFail 篇"
}
if ($RateLimitHits -gt 0) {
    Write-Warning "   ⚠️ API 限額事件：$RateLimitHits 次"
}
Write-Info ""
Write-Info "📌 狀態：$HealthStatus"

if ($SendReport) {
    Write-Info "📧 發送郵件報告..."
    $EnvPath = Join-Path $ProjectRoot ".env"
    if (Test-Path $EnvPath) {
        Get-Content $EnvPath | ForEach-Object {
            if ($_ -match '^SMTP_USER=(.+)$') { $SmtpUser = $Matches[1] }
            if ($_ -match '^SMTP_PASS=(.+)$') { $SmtpPass = $Matches[1] }
            if ($_ -match '^SMTP_TO=(.+)$') { $ToEmail = $Matches[1] }
        }
    }
    if ($SmtpUser -and $SmtpPass -and $ToEmail) {
        $Body = $Report -join "`n"
        try {
            $SmtpClient = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
            $SmtpClient.EnableSsl = $true
            $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPass)
            $Mail = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "📡 AHPAL 產線健康報告", $Body)
            $Mail.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($Mail)
            Write-Success "   ✅ 郵件已發送"
        } catch {
            Write-Error "   ❌ 郵件發送失敗：$_"
        }
    }
}

Write-Info ""
Write-Info "✅ 健康監控完成！"