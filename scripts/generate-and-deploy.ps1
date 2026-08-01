# scripts\generate-and-deploy.ps1
param(
    [string]$ForceAPI = "deepseek",
    [string]$CommitMessage = "自動更新文章 $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🦞 AHPAL 文章生成 + 自動部署" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Set-Location C:\Users\User\ahpal-static

# 1. 生成文章
Write-Host "`n📝 開始生成文章..." -ForegroundColor Cyan
python src/main.py --force $ForceAPI

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ 文章生成失敗！" -ForegroundColor Red
    exit 1
}

# 2. 部署
Write-Host "`n🚀 開始部署..." -ForegroundColor Cyan
.\scripts\deploy.ps1 -CommitMessage $CommitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "✅ 全部完成！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
}
