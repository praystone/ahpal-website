# ============================================================
# AHPAL 排程任務管理程序 v1.0
# 功能：管理所有 AHPAL 相關排程任務（停用/啟用/刪除/查詢）
# 用法：.\manage-schedules.ps1
# ============================================================

# 定義所有 AHPAL 相關任務名稱
$TaskNames = @(
    "AHPAL_BatchUpload",
    "DeepSeek_Balance_Check",
    "AHPAL_AutoDeploy"
)

# ============================================================
# 1. 顯示目前狀態
# ============================================================
function Show-CurrentStatus {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "📊 AHPAL 排程任務狀態總覽" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    $Found = $false
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task) {
            $Found = $true
            $state = $task.State
            $color = if ($state -eq "Ready") { "Green" } elseif ($state -eq "Disabled") { "Yellow" } else { "Gray" }
            Write-Host "   $name : $state" -ForegroundColor $color
        } else {
            Write-Host "   $name : 不存在" -ForegroundColor Gray
        }
    }
    
    if (-not $Found) {
        Write-Host "   ⚠️ 沒有找到任何 AHPAL 相關排程任務" -ForegroundColor Yellow
    }
    Write-Host "========================================" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================
# 2. 停用所有任務
# ============================================================
function Disable-AllTasks {
    Write-Host ""
    Write-Host "🛑 停用所有 AHPAL 排程任務..." -ForegroundColor Yellow
    
    $Count = 0
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task -and $task.State -ne "Disabled") {
            Disable-ScheduledTask -TaskName $name
            Write-Host "   ✅ $name 已停用" -ForegroundColor Green
            $Count++
        } elseif ($task -and $task.State -eq "Disabled") {
            Write-Host "   ⏸️ $name 已經是停用狀態" -ForegroundColor Yellow
        } else {
            Write-Host "   ⚠️ $name 不存在" -ForegroundColor Gray
        }
    }
    Write-Host "   📊 共停用 $Count 個任務" -ForegroundColor Cyan
}

# ============================================================
# 3. 啟用所有任務
# ============================================================
function Enable-AllTasks {
    Write-Host ""
    Write-Host "▶️ 啟用所有 AHPAL 排程任務..." -ForegroundColor Yellow
    
    $Count = 0
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task -and $task.State -eq "Disabled") {
            Enable-ScheduledTask -TaskName $name
            Write-Host "   ✅ $name 已啟用" -ForegroundColor Green
            $Count++
        } elseif ($task -and $task.State -eq "Ready") {
            Write-Host "   ▶️ $name 已經是啟用狀態" -ForegroundColor Yellow
        } else {
            Write-Host "   ⚠️ $name 不存在" -ForegroundColor Gray
        }
    }
    Write-Host "   📊 共啟用 $Count 個任務" -ForegroundColor Cyan
}

# ============================================================
# 4. 刪除所有任務
# ============================================================
function Delete-AllTasks {
    Write-Host ""
    Write-Host "⚠️ 警告：即將刪除所有 AHPAL 排程任務！" -ForegroundColor Red
    Write-Host "   此操作無法復原，需重新註冊才能使用。" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "請輸入 'YES' 確認刪除 (輸入其他任何內容取消)"
    if ($confirm -ne "YES") {
        Write-Host "   ❌ 已取消刪除操作" -ForegroundColor Yellow
        return
    }
    
    Write-Host ""
    Write-Host "🗑️ 刪除所有 AHPAL 排程任務..." -ForegroundColor Yellow
    
    $Count = 0
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $name -Confirm:$false
            Write-Host "   ✅ $name 已刪除" -ForegroundColor Green
            $Count++
        } else {
            Write-Host "   ⚠️ $name 不存在" -ForegroundColor Gray
        }
    }
    Write-Host "   📊 共刪除 $Count 個任務" -ForegroundColor Cyan
}

# ============================================================
# 5. 重新註冊任務（快速重建）
# ============================================================
function Recreate-Tasks {
    Write-Host ""
    Write-Host "🔄 重新註冊 AHPAL 排程任務..." -ForegroundColor Yellow
    Write-Host "   這將刪除現有任務並重新建立" -ForegroundColor Gray
    Write-Host ""
    
    $confirm = Read-Host "請輸入 'YES' 確認重建 (輸入其他任何內容取消)"
    if ($confirm -ne "YES") {
        Write-Host "   ❌ 已取消重建操作" -ForegroundColor Yellow
        return
    }
    
    # 先刪除
    foreach ($name in $TaskNames) {
        $task = Get-ScheduledTask -TaskName $name -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $name -Confirm:$false
            Write-Host "   🗑️ $name 已刪除" -ForegroundColor Gray
        }
    }
    
    Write-Host ""
    Write-Host "📌 重新註冊任務..." -ForegroundColor Yellow
    
    # 重新註冊 AHPAL_BatchUpload
    $Action1 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\Users\User\ahpal-static\scripts\batch-upload-throttled.ps1`" -WindowStyle Hidden"
    $Trigger1 = New-ScheduledTaskTrigger -Daily -At "18:10"
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:COMPUTERNAME\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    Register-ScheduledTask -TaskName "AHPAL_BatchUpload" -Action $Action1 -Trigger $Trigger1 -Principal $Principal -Force
    Write-Host "   ✅ AHPAL_BatchUpload 已註冊 (每日 18:10)" -ForegroundColor Green
    
    # 重新註冊 DeepSeek_Balance_Check
    $Action2 = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"C:\Users\User\ahpal-static\scripts\check-deepseek-balance.ps1`" -SendAlert -WindowStyle Hidden"
    $Trigger2 = New-ScheduledTaskTrigger -Daily -At "09:00"
    Register-ScheduledTask -TaskName "DeepSeek_Balance_Check" -Action $Action2 -Trigger $Trigger2 -Principal $Principal -Force
    Write-Host "   ✅ DeepSeek_Balance_Check 已註冊 (每日 09:00)" -ForegroundColor Green
    
    Write-Host "   ✅ 所有任務已重新註冊完成！" -ForegroundColor Green
}

# ============================================================
# 主選單
# ============================================================
function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "🦞 AHPAL 排程任務管理 v1.0" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    
    Show-CurrentStatus
    
    Write-Host "請選擇操作：" -ForegroundColor White
    Write-Host ""
    Write-Host "   [1] 停用所有任務（保留設定）" -ForegroundColor Yellow
    Write-Host "   [2] 啟用所有任務（恢復執行）" -ForegroundColor Green
    Write-Host "   [3] 刪除所有任務（完全移除）" -ForegroundColor Red
    Write-Host "   [4] 重新註冊所有任務（重建）" -ForegroundColor Cyan
    Write-Host "   [5] 查看任務狀態" -ForegroundColor Gray
    Write-Host "   [0] 退出" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "請輸入選項 (0-5)"
    
    switch ($choice) {
        "1" { 
            Disable-AllTasks
            Read-Host "`n按 Enter 返回"
            Show-Menu
        }
        "2" { 
            Enable-AllTasks
            Read-Host "`n按 Enter 返回"
            Show-Menu
        }
        "3" { 
            Delete-AllTasks
            Read-Host "`n按 Enter 返回"
            Show-Menu
        }
        "4" { 
            Recreate-Tasks
            Read-Host "`n按 Enter 返回"
            Show-Menu
        }
        "5" { 
            Show-CurrentStatus
            Read-Host "`n按 Enter 返回"
            Show-Menu
        }
        "0" { 
            Write-Host "`n👋 退出管理程序" -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "`n❌ 無效選項，請重新選擇" -ForegroundColor Red
            Read-Host "按 Enter 返回"
            Show-Menu
        }
    }
}

# ============================================================
# 啟動
# ============================================================
Show-Menu