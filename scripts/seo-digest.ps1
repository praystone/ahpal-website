# ============================================================
# seo-digest.ps1 - SEO 數據自動化彙整 v1.1
# ============================================================
# 功能：
#   1. 讀取 Google Search Console / GA4 郵件摘要或 CSV
#   2. 對比過去 7 天流量變化
#   3. 自動分析熱門頁面與關鍵字
#   4. 輸出 SEO 數據日報並支援郵件發送
# ============================================================

param(
    [string]$GSCReportPath,
    [switch]$SendReport,
    [switch]$Quiet
)

$ProjectRoot = "C:\Users\User\ahpal-static"
$ReportDir = "C:\Users\User\ahpal-AI-archive\system-tools\system-reports\05-SEO數據"

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

Write-Info "============================================================"
Write-Info "  📊 SEO 數據自動化彙整 v1.1"
Write-Info "============================================================"
Write-Info ""

$ReportData = @()
if ($GSCReportPath -and (Test-Path $GSCReportPath)) {
    Write-Info "📂 讀取外部 GSC 報告：$GSCReportPath"
    $ReportData = Import-Csv -Path $GSCReportPath -Encoding UTF8
} else {
    Write-Warning "⚠️ 未提供外部 GSC CSV，將從 master-articles.json 進行結構分析..."
    $MasterPath = Join-Path $ProjectRoot "data\master-articles.json"
    if (Test-Path $MasterPath) {
        $Articles = Get-Content $MasterPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $ReportData = $Articles | Select-Object -First 20 | ForEach-Object {
            [PSCustomObject]@{
                頁面 = $_.filename
                標題 = $_.keyword
                分類 = $_.category
            }
        }
    }
}

$AllHtmlFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter '*.html' -File | Where-Object { 
    $_.DirectoryName -notmatch 'game|docs|scripts|src|backups|logs|node_modules' 
}
$TotalArticlesCount = $AllHtmlFiles.Count
$TotalSizeMB = [math]::Round(($AllHtmlFiles | Measure-Object -Property Length -Sum).Sum / 1MB, 2)

$Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$DigestFile = Join-Path $ReportDir "seo-digest-$Timestamp.txt"

$Digest = @()
$Digest += "============================================================"
$Digest += "  📊 AHPAL SEO 數據日報"
$Digest += "  報告時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$Digest += "============================================================"
$Digest += ""
$Digest += "📈 產線整體數據概覽："
$Digest += "   - 總文章數量：$TotalArticlesCount 篇"
$Digest += "   - HTML 總容量：$TotalSizeMB MB"
$Digest += ""
$Digest += "📌 核心推算焦點頁面 Top 10："
$ReportData | Select-Object -First 10 | ForEach-Object {
    $Digest += "   - [$($_.分類)] $($_.標題) → $($_.頁面)"
}
$Digest += ""
$Digest += "📂 各分類數量統計："
$CategoryDirs = @{
    "history"    = "📜 歷史腦洞"
    "tech"       = "💻 3C 科技教學"
    "game"       = "🎮 遊戲攻略"
    "life"       = "🏠 生活小常識"
    "review"     = "📊 軟體評測"
    "philosophy" = "🌟 人生哲理"
    "trend"      = "🤖 AI 趨勢"
    "music"      = "🎵 音樂創作"
    "nature"     = "🌳 動植物生態"
}

foreach ($key in $CategoryDirs.Keys) {
    $dir = Join-Path $ProjectRoot $key
    if (Test-Path $dir) {
        $count = (Get-ChildItem -Path $dir -Filter "*.html").Count
        $Digest += "   - $($CategoryDirs[$key])：$count 篇"
    }
}

$Digest += ""
$Digest += "============================================================"
$Digest += "  ✅ 報告產生完成"
$Digest += "============================================================"

$Digest | Out-File -FilePath $DigestFile -Encoding UTF8

Write-Success "✅ SEO 摘要已儲存：$DigestFile"
Write-Info ""
Write-Info "📌 建議後續維護動作："
Write-Info "   1. 將 GSC / GA4 數據匯入此目錄以獲得實際點擊率與 CTR 變化"
Write-Info "   2. 定期執行 watch-pipeline.ps1 監控 API 與產線健康度"
Write-Info "   3. 執行 audit-content-quality.ps1 確保文章結構品質"
Write-Info ""

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
        $Body = $Digest -join "`n"
        try {
            $SmtpClient = New-Object System.Net.Mail.SmtpClient("smtp.gmail.com", 587)
            $SmtpClient.EnableSsl = $true
            $SmtpClient.Credentials = New-Object System.Net.NetworkCredential($SmtpUser, $SmtpPass)
            $Mail = New-Object System.Net.Mail.MailMessage($SmtpUser, $ToEmail, "📊 AHPAL SEO 數據日報", $Body)
            $Mail.BodyEncoding = [System.Text.Encoding]::UTF8
            $SmtpClient.Send($Mail)
            Write-Success "   ✅ 郵件已發送"
        } catch {
            Write-Warning "   ⚠️ 郵件發送失敗：$_"
        }
    } else {
        Write-Warning "   ⚠️ 未找到完整 SMTP 設定，跳過郵件發送"
    }
}

Write-Info "✅ SEO 數據彙整完成！"