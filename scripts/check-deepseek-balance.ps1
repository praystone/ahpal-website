param(
    [string]$ApiKey = $env:DEEPSEEK_API_KEY,
    [float]$Threshold = 1.0,
    [switch]$SendAlert
)

$LogDir = "C:\Users\User\ahpal-static\logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir "balance-history.txt"
$Today = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🦞 DeepSeek 餘額監控" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if (-not $ApiKey) {
    Write-Host "❌ 錯誤：DEEPSEEK_API_KEY 未設定" -ForegroundColor Red
    Write-Host "💡 請先執行：.\scripts\ahpal-static.ps1" -ForegroundColor Yellow
    exit 1
}

try {
    $Headers = @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }

    Write-Host "📡 正在查詢 DeepSeek 餘額..." -ForegroundColor Gray
    $Response = Invoke-RestMethod -Uri "https://api.deepseek.com/user/balance" -Headers $Headers -Method Get -ErrorAction Stop

    # ============================================================
    # 修正餘額解析邏輯：支援多種 API 回應格式
    # ============================================================
    $TotalBalance = 0
    
    # 方式 1：檢查 total_balance
    if ($Response.total_balance -ne $null -and $Response.total_balance -gt 0) {
        $TotalBalance = $Response.total_balance
    }
    # 方式 2：檢查 balance_infos 陣列
    elseif ($Response.balance_infos -and $Response.balance_infos.Count -gt 0) {
        foreach ($info in $Response.balance_infos) {
            if ($info.currency -eq "CNY" -and $info.total_balance -gt 0) {
                $TotalBalance = $info.total_balance
                break
            }
        }
        # 如果沒找到 CNY，取第一個
        if ($TotalBalance -eq 0) {
            $TotalBalance = $Response.balance_infos[0].total_balance
        }
    }
    # 方式 3：檢查 balance 欄位
    elseif ($Response.balance -ne $null) {
        $TotalBalance = $Response.balance
    }
    
    # 如果還是 0，嘗試從授權資訊中獲取
    if ($TotalBalance -eq 0 -and $Response.authorized -eq $true) {
        Write-Host "   ⚠️ 帳戶已授權，但餘額資訊可能需從其他欄位讀取" -ForegroundColor Yellow
    }

    $Currency = if ($Response.currency) { $Response.currency } else { "CNY" }

    $LogEntry = "$Today | 餘額: ¥$TotalBalance | 幣別: $Currency | 原始回應: $($Response | ConvertTo-Json -Compress)"
    Add-Content -Path $LogFile -Value $LogEntry -Encoding utf8

    Write-Host ""
    Write-Host "📊 目前餘額：¥$TotalBalance" -ForegroundColor Green
    Write-Host "📌 幣別：$Currency" -ForegroundColor Gray
    Write-Host "📌 檢查時間：$Today" -ForegroundColor Gray
    Write-Host ""

    if ($TotalBalance -lt $Threshold) {
        Write-Host "⚠️ 警告：餘額低於門檻值 ¥$Threshold！" -ForegroundColor Red
        Write-Host "💰 剩餘餘額：¥$TotalBalance" -ForegroundColor Yellow

        if ($SendAlert) {
            $SmtpServer = if ($env:SMTP_SERVER) { $env:SMTP_SERVER } else { "smtp.gmail.com" }
            $SmtpPort = if ($env:SMTP_PORT) { [int]$env:SMTP_PORT } else { 587 }
            $SmtpUser = $env:SMTP_USER
            $SmtpPass = $env:SMTP_PASS
            $ToEmail = if ($env:SMTP_TO) { $env:SMTP_TO } else { $env:SMTP_USER }
            $FromEmail = if ($env:SMTP_FROM) { $env:SMTP_FROM } else { $env:SMTP_USER }

            if ($SmtpUser -and $SmtpPass -and $SmtpUser -ne "你的Gmail帳號@gmail.com") {
                $Subject = "🦞 DeepSeek 餘額告警 - 僅剩 ¥$TotalBalance"
                $Body = @"
DeepSeek API 餘額告警

時間：$Today
目前餘額：¥$TotalBalance
門檻值：¥$Threshold
建議：請立即儲值，避免 API 服務中斷！

儲值連結：https://platform.deepseek.com/
"@

                try {
                    $SmtpClient = New-Object System.Net.Mail.SmtpClient($SmtpServer, $SmtpPort)
                    $SmtpClient.EnableSsl = $true
                    $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPass)
                    
                    $MailMessage = New-Object System.Net.Mail.MailMessage($FromEmail, $ToEmail, $Subject, $Body)
                    $MailMessage.BodyEncoding = [System.Text.Encoding]::UTF8
                    
                    $SmtpClient.Send($MailMessage)
                    Write-Host "   ✅ 郵件已成功發送至 $ToEmail" -ForegroundColor Green
                } catch {
                    Write-Host "   ❌ 郵件發送失敗：$($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "   ⚠️ SMTP 設定不完整，請檢查 .env 檔案" -ForegroundColor Yellow
            }
        }

        Write-Host "💡 請立即儲值，避免 API 服務中斷！" -ForegroundColor Yellow
        Write-Host "🔗 儲值連結：https://platform.deepseek.com/" -ForegroundColor Cyan
        exit 1
    } else {
        Write-Host "✅ 餘額充足（¥$TotalBalance ≥ ¥$Threshold）" -ForegroundColor Green
        exit 0
    }
} catch {
    Write-Host "❌ 查詢失敗：$($_.Exception.Message)" -ForegroundColor Red
    $ErrorLog = "$Today | ERROR: $($_.Exception.Message)"
    Add-Content -Path $LogFile -Value $ErrorLog -Encoding utf8
    exit 2
}
