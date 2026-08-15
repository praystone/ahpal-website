# ============================================================
# 📊 AHPAL 目錄分析工具 v1.4 (analyze-directory.ps1)
# ============================================================

# 1. param 必須放在最最頂端！
param(
    [switch]$HtmlOnly,
    [switch]$TxtOnly,
    [switch]$OpenReport,
    [switch]$Json
)

# 2. 編碼與環境宣告
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$null = chcp 65001

# ============================================================
# 設定路徑
# ============================================================
$ProjectRoot = "C:\Users\User\ahpal-static"
$ReportDir = "C:\Users\User\ahpal-AI-archive\system-tools\system-reports"
$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$TxtReport = "$ReportDir\directory-analysis-$Timestamp.txt"
$HtmlReport = "$ReportDir\directory-analysis-$Timestamp.html"
$JsonReport = "$ReportDir\directory-analysis-$Timestamp.json"

New-Item -ItemType Directory -Path $ReportDir -Force | Out-Null
$StartTime = Get-Date

# ============================================================
# 顏色與輸出輔助函數
# ============================================================
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }
function Write-Section { 
    Write-Host "`n$('='*60)" -ForegroundColor Cyan
    Write-Host $args -ForegroundColor Cyan
    Write-Host "$('='*60)" -ForegroundColor Cyan 
}

# ============================================================
# 掃描函數
# ============================================================
function Get-DirectoryStats {
    param([string]$Path)
    
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        return $null
    }
    
    try {
        $items = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
        $dirs = Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue
        
        $extensions = @{}
        $totalSize = 0
        $fileCount = 0
        
        foreach ($item in $items) {
            $fileCount++
            $totalSize += $item.Length
            $ext = $item.Extension.ToLower()
            if (-not $ext) { $ext = "(無副檔名)" }
            if ($extensions.ContainsKey($ext)) {
                $extensions[$ext]++
            } else {
                $extensions[$ext] = 1
            }
        }
        
        return @{
            Path = $Path
            FileCount = $fileCount
            DirectoryCount = $dirs.Count
            TotalSize = $totalSize
            TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
            Extensions = $extensions
            Items = $items
        }
    } catch {
        Write-Error "    ❌ 掃描失敗: $Path - $($_.Exception.Message)"
        return $null
    }
}

function Get-CategoryStats {
    param([string]$BasePath)
    
    # 確保 BasePath 不是空字串
    if ([string]::IsNullOrWhiteSpace($BasePath)) {
        $BasePath = "C:\Users\User\ahpal-static"
    }

    $catNames = @("history", "tech", "game", "life", "review", "philosophy", "trend", "music")
    
    $catDisplayNames = @{
        "history"    = "📜 歷史腦洞"
        "tech"       = "💻 3C 科技教學"
        "game"       = "🎮 遊戲攻略"
        "life"       = "🏠 生活小常識"
        "review"     = "📊 軟體評測"
        "philosophy" = "🌟 人生哲理"
        "trend"      = "🤖 AI 趨勢"
        "music"      = "🎵 音樂創作"
    }
    
    $result = @{}
    $totalArticles = 0
    
    foreach ($cat in $catNames) {
        if ([string]::IsNullOrWhiteSpace($cat)) { continue }
        
        $dirPath = Join-Path $BasePath $cat
        $displayName = $catDisplayNames[$cat]
        
        if (Test-Path $dirPath) {
            $htmlFiles = Get-ChildItem -Path "$dirPath\*.html" -File -ErrorAction SilentlyContinue
            $count = $htmlFiles.Count
            $size = ($htmlFiles | Measure-Object -Property Length -Sum).Sum
            
            Write-Info "    📂 $displayName : $count 篇"
            
            $result[$cat] = @{
                Name = $displayName
                Count = $count
                SizeMB = if ($size) { [math]::Round($size / 1MB, 2) } else { 0 }
                Files = $htmlFiles
            }
            $totalArticles += $count
        } else {
            Write-Warning "    📂 $displayName : 目錄不存在"
            $result[$cat] = @{
                Name = $displayName
                Count = 0
                SizeMB = 0
                Files = @()
            }
        }
    }
    
    return @{
        Categories = $result
        TotalArticles = $totalArticles
    }
}

# ============================================================
# 主程式執行
# ============================================================
Write-Section "📊 AHPAL 目錄分析工具 v1.4"
Write-Info "📅 分析時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "📁 專案路徑：$ProjectRoot"
Write-Host ""

# 1. 掃描專案根目錄
Write-Info "🔍 [1/4] 掃描專案根目錄..."
$rootStats = Get-DirectoryStats -Path $ProjectRoot

# 2. 掃描各分類目錄
Write-Info "🔍 [2/4] 掃描分類目錄..."
$categoryStats = Get-CategoryStats -BasePath $ProjectRoot

# 3. 掃描 scripts 目錄
Write-Info "🔍 [3/4] 掃描 scripts 目錄..."
$scriptsStats = Get-DirectoryStats -Path (Join-Path $ProjectRoot "scripts")
if (-not $scriptsStats) { $scriptsStats = @{ FileCount = 0; TotalSizeMB = 0 } }

# 4. 掃描 src 目錄
Write-Info "🔍 [4/4] 掃描 src 目錄..."
$srcStats = Get-DirectoryStats -Path (Join-Path $ProjectRoot "src")
if (-not $srcStats) { $srcStats = @{ FileCount = 0; TotalSizeMB = 0 } }

$Elapsed = (Get-Date) - $StartTime
$ElapsedSeconds = [math]::Round($Elapsed.TotalSeconds, 1)

# ============================================================
# 產生 TXT 報告
# ============================================================
if (-not $HtmlOnly) {
    Write-Info "📄 產生 TXT 報告..."
    $sortedCategories = $categoryStats.Categories.Keys | Sort-Object { $categoryStats.Categories[$_].Count } -Descending
    
    $txtContent = @"
============================================================
  📊 AHPAL 目錄分析報告
  分析時間：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
  執行耗時：$ElapsedSeconds 秒
  專案路徑：$ProjectRoot
============================================================

📁 1. 專案根目錄總覽
------------------------------------------------------------
  總檔案數：$($rootStats.FileCount) 個
  總目錄數：$($rootStats.DirectoryCount) 個
  總大小：$($rootStats.TotalSizeMB) MB

📂 2. 分類目錄統計 (共 $($categoryStats.TotalArticles) 篇文章)
------------------------------------------------------------
"@
    $totalArticles = $categoryStats.TotalArticles
    $totalSizeMB = 0
    
    foreach ($cat in $sortedCategories) {
        $data = $categoryStats.Categories[$cat]
        $totalSizeMB += $data.SizeMB
        $percent = if ($totalArticles -gt 0) { [math]::Round(($data.Count / $totalArticles) * 100, 1) } else { 0 }
        $txtContent += @"
  $($data.Name)
     文章數：$($data.Count) 篇 ($percent%)
     大小：$($data.SizeMB) MB

"@
    }
    
    $txtContent += @"
  總計：
     文章數：$totalArticles 篇
     總大小：$([math]::Round($totalSizeMB, 2)) MB

📜 3. scripts/ 目錄
------------------------------------------------------------
  檔案數：$($scriptsStats.FileCount) 個
  總大小：$($scriptsStats.TotalSizeMB) MB

🐍 4. src/ 目錄
------------------------------------------------------------
  檔案數：$($srcStats.FileCount) 個
  總大小：$($srcStats.TotalSizeMB) MB

============================================================
📁 報告位置：$TxtReport
============================================================
"@
    $txtContent | Out-File -FilePath $TxtReport -Encoding UTF8
    Write-Success "  ✅ TXT 報告已儲存：$TxtReport"
}

# ============================================================
# 產生 HTML 報告
# ============================================================
if (-not $TxtOnly) {
    Write-Info "📄 產生 HTML 報告..."
    $categoryRows = ""
    $sortedCategories = $categoryStats.Categories.Keys | Sort-Object { $categoryStats.Categories[$_].Count } -Descending
    $totalArticles = $categoryStats.TotalArticles
    $totalSizeMB = 0
    
    foreach ($cat in $sortedCategories) {
        $data = $categoryStats.Categories[$cat]
        $totalSizeMB += $data.SizeMB
        $percent = if ($totalArticles -gt 0) { [math]::Round(($data.Count / $totalArticles) * 100, 1) } else { 0 }
        $barColor = if ($percent -ge 50) { "#00A86B" } elseif ($percent -ge 20) { "#F1C40F" } else { "#005A9C" }
        
        $categoryRows += @"
            <tr>
                <td><strong>$($data.Name)</strong></td>
                <td>$($data.Count)</td>
                <td>$($data.SizeMB) MB</td>
                <td>
                    <div style="background:#E2E8F0;border-radius:4px;height:8px;width:100%;">
                        <div style="background:$barColor;border-radius:4px;height:8px;width:$percent%;"></div>
                    </div>
                    <span style="font-size:11px;color:#718096;">$percent%</span>
                </td>
            </tr>
"@
    }
    
    $htmlContent = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
    <meta charset="UTF-8">
    <title>AHPAL 目錄分析報告</title>
    <style>
        body { font-family: sans-serif; background: #F7F9FC; padding: 24px; color: #1A202C; }
        .container { max-width: 1000px; margin: 0 auto; }
        .card { background: #FFF; border-radius: 12px; padding: 24px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.05); }
        h1 { color: #005A9C; }
        table { width: 100%; border-collapse: collapse; margin-top: 12px; }
        th, td { padding: 10px; border: 1px solid #E2E8F0; text-align: left; }
        th { background: #005A9C; color: white; }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <h1>📊 AHPAL 目錄分析報告</h1>
            <p>專案路徑：$ProjectRoot | 耗時：$ElapsedSeconds 秒</p>
        </div>
        <div class="card">
            <h2>📂 分類目錄統計</h2>
            <table>
                <thead><tr><th>分類</th><th>文章數</th><th>大小</th><th>佔比</th></tr></thead>
                <tbody>
$categoryRows
                    <tr style="font-weight:700;background:#F0F4F8;">
                        <td>總計</td>
                        <td>$totalArticles 篇</td>
                        <td>$([math]::Round($totalSizeMB, 2)) MB</td>
                        <td>100%</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@
    $htmlContent | Out-File -FilePath $HtmlReport -Encoding UTF8
    Write-Success "  ✅ HTML 報告已儲存：$HtmlReport"
}

# ============================================================
# 完成
# ============================================================
Write-Section "✅ 目錄分析完成！"
Write-Host "📊 總檔案數：$($rootStats.FileCount) 個 | 文章總數：$($categoryStats.TotalArticles) 篇" -ForegroundColor Cyan

if ($OpenReport -and (-not $TxtOnly)) {
    Start-Process $HtmlReport
}