# ============================================================
# ensure-utf8-nobom.ps1 - UTF-8 無 BOM 編碼驗證與修復 v1.0
# ============================================================
# 功能：
#   1. 驗證 JSON 檔案是否為 UTF-8 無 BOM
#   2. 自動修復有 BOM 或非 UTF-8 的檔案
#   3. 可作為 add-articles.ps1 的前置檢查
# ============================================================

param(
    [string]$FilePath = "data/pending-articles.json",
    [switch]$Fix,
    [switch]$Quiet
)

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

$ProjectRoot = "C:\Users\User\ahpal-static"
$FullPath = Join-Path $ProjectRoot $FilePath

Write-Info "============================================================"
Write-Info "  🔍 UTF-8 無 BOM 編碼驗證與修復工具 v1.0"
Write-Info "============================================================"
Write-Info ""

# 1. 檢查檔案是否存在
if (-not (Test-Path $FullPath)) {
    Write-Error "❌ 檔案不存在：$FullPath"
    exit 1
}
Write-Info "📄 檔案：$FilePath"

# 2. 讀取檔案位元組
$bytes = [System.IO.File]::ReadAllBytes($FullPath)
$fileSize = $bytes.Length
Write-Info "📦 檔案大小：$fileSize bytes"

# 3. 檢查 BOM
$hasBom = $false
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $hasBom = $true
    Write-Warning "⚠️ 發現 BOM (UTF-8 with BOM)"
} else {
    Write-Success "✅ 無 BOM (UTF-8 without BOM)"
}

# 4. 檢查是否為有效 JSON
$isValidJson = $false
$jsonContent = ""
try {
    $jsonContent = Get-Content $FullPath -Raw -Encoding UTF8
    $null = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    $isValidJson = $true
    Write-Success "✅ JSON 格式有效"
} catch {
    Write-Error "❌ JSON 格式無效：$_"
    exit 1
}

# 5. 檢查是否包含中文 (判斷是否為 UTF-8)
$hasChinese = [regex]::IsMatch($jsonContent, '[\u4e00-\u9fa5]')
if ($hasChinese) {
    Write-Info "📝 檔案包含中文字元"
} else {
    Write-Info "📝 檔案為純 ASCII (無中文)"
}

# 6. 判斷是否需要修復
$needsFix = $hasBom

if (-not $needsFix) {
    Write-Success ""
    Write-Success "✅ 編碼正確：UTF-8 無 BOM"
    Write-Info "============================================================"
    exit 0
}

# 7. 執行修復
if ($needsFix) {
    Write-Warning ""
    Write-Warning "⚠️ 需要修復編碼！"
    
    if (-not $Fix) {
        Write-Warning ""
        Write-Warning "📌 請使用 -Fix 參數執行修復："
        Write-Warning "   .\scripts\ensure-utf8-nobom.ps1 -Fix"
        Write-Info "============================================================"
        exit 2
    }
    
    Write-Info ""
    Write-Info "🔧 正在修復編碼為 UTF-8 無 BOM..."
    
    try {
        # 使用 .NET 寫入 UTF-8 無 BOM
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        
        # 如果是 JSON，重新格式化 (保持可讀性)
        if ($isValidJson) {
            $jsonObject = $jsonContent | ConvertFrom-Json
            $reformatted = $jsonObject | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllText($FullPath, $reformatted, $utf8NoBom)
            Write-Success "   ✅ 已修復為 UTF-8 無 BOM (JSON 已重新格式化)"
        } else {
            [System.IO.File]::WriteAllText($FullPath, $jsonContent, $utf8NoBom)
            Write-Success "   ✅ 已修復為 UTF-8 無 BOM"
        }
        
        # 驗證修復結果
        $verifyBytes = [System.IO.File]::ReadAllBytes($FullPath)
        if ($verifyBytes.Length -ge 3 -and $verifyBytes[0] -eq 0xEF -and $verifyBytes[1] -eq 0xBB -and $verifyBytes[2] -eq 0xBF) {
            Write-Error "   ❌ 修復後仍有 BOM，請手動檢查"
            exit 3
        } else {
            Write-Success "   ✅ 修復驗證通過"
        }
        
    } catch {
        Write-Error "   ❌ 修復失敗：$_"
        exit 4
    }
}

Write-Success ""
Write-Success "✅ 編碼修復完成！"
Write-Info "============================================================"
exit 0