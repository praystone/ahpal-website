# scripts\deploy.ps1
param(
    [string]$CommitMessage = "更新文章 $(Get-Date -Format 'yyyy-MM-dd HH:mm')",
    [switch]$SkipGit
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🚀 AHPAL 自動部署工具" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 切換到專案根目錄
Set-Location C:\Users\User\ahpal-static

# 1. Git 提交（除非跳過）
if (-not $SkipGit) {
    Write-Host "`n📦 檢查 Git 變更..." -ForegroundColor Yellow
    
    $hasChanges = git status --porcelain | Measure-Object | Select-Object -ExpandProperty Count
    
    if ($hasChanges -gt 0) {
        Write-Host "📝 發現 $hasChanges 個檔案變更，準備提交..." -ForegroundColor Yellow
        git add .
        git commit -m $CommitMessage
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Git 提交成功！" -ForegroundColor Green
            Write-Host "`n📜 最近提交記錄：" -ForegroundColor Cyan
            git log --oneline -3
        } else {
            Write-Host "❌ Git 提交失敗！" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "✅ 沒有變更需要提交" -ForegroundColor Green
    }
}

# 2. 部署到 Cloudflare Pages
Write-Host "`n☁️ 部署到 Cloudflare Pages..." -ForegroundColor Cyan
npx wrangler pages deploy . --project-name=ahpal-pages --commit-dirty=true

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "✅ 部署成功！" -ForegroundColor Green
    Write-Host "📍 網站網址：https://ad0426f7.ahpal-pages.pages.dev" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Green
} else {
    Write-Host "❌ 部署失敗！" -ForegroundColor Red
    exit 1
}
