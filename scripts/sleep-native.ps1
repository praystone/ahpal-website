# ============================================================
# 🦞 關閉螢幕並觸發睡眠 (C# 原生 API)
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 關閉螢幕並觸發睡眠 (C# 原生 API)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  系統將於 3 秒後進入睡眠..." -ForegroundColor Yellow
Write-Host "  喚醒時間: $WakeTime" -ForegroundColor Yellow
Write-Host ""
Start-Sleep -Seconds 3

# C# 原生 API 睡眠
$code = @"
using System;
using System.Runtime.InteropServices;
public class Power {
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
    [DllImport("Powrprof.dll", SetLastError = true)]
    public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
}
"@
Add-Type -TypeDefinition $code

# 關閉螢幕
[Power]::SendMessage(0xffff, 0x0112, 0xF170, 2)

# 觸發睡眠 (不強制關閉，不禁用喚醒事件)
[Power]::SetSuspendState($false, $false, $false)

Write-Host "✅ 已進入睡眠模式" -ForegroundColor Green
