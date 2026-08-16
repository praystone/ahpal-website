# ============================================================
# 🦞 關閉螢幕 (保持系統運作)
# ============================================================
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 關閉螢幕 (系統保持運作)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  螢幕將於 3 秒後關閉..." -ForegroundColor Yellow
Write-Host "  系統將持續運作，排程任務將準時執行。" -ForegroundColor Yellow
Write-Host "  5分鐘後將彈出 PowerShell 視窗！" -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 3

$code = @"
using System;
using System.Runtime.InteropServices;
public class Screen {
    [DllImport("user32.dll")]
    public static extern int SendMessage(int hWnd, int hMsg, int wParam, int lParam);
}
"@
Add-Type -TypeDefinition $code
[Screen]::SendMessage(0xffff, 0x0112, 0xF170, 2)

Write-Host "✅ 螢幕已關閉，系統持續運作中..." -ForegroundColor Green
Write-Host "⏰ 排程將於指定時間執行並彈出視窗" -ForegroundColor Yellow
