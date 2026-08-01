# scripts\clean-and-push.ps1 - 清理 Git 歷史並重新推送
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  🧹 AHPAL Git 歷史清理工具" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 備份
Write-Host "`n📦 備份重要檔案..." -ForegroundColor Yellow
$backupDir = "C:\Users\User\ahpal-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item .env $backupDir\ -ErrorAction SilentlyContinue
Copy-Item data\client_secret.json $backupDir\ -ErrorAction SilentlyContinue
Write-Host "✅ 備份到：$backupDir"

# 清理 Git
Write-Host "`n🧹 清理 Git 歷史..." -ForegroundColor Yellow
cd C:\Users\User
Copy-Item ahpal-static ahpal-static-clean -Recurse -Force
cd ahpal-static-clean

# 重新初始化
Remove-Item .git -Recurse -Force -ErrorAction SilentlyContinue
git init
git add .
git commit -m "重新初始化：AHPAL 文章系統（無敏感檔案）"

# 設定遠端
git remote add origin https://github.com/praystone/ahpal-website.git

# 推送
Write-Host "`n☁️ 推送到 GitHub..." -ForegroundColor Yellow
git push -u origin main --force

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "✅ 清理完成！" -ForegroundColor Green
Write-Host "📍 新倉庫位置：C:\Users\User\ahpal-static-clean" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Green
