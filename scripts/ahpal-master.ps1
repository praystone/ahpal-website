# ============================================================
# 雅寶社區 · 頂客論壇 - 萬能總指揮腳本 v7.0 (語法修正版)
# ============================================================
# 功能：載入環境 → 備份 → 遊戲生成 → 文章生成 → Git → 部署
# 新增：命令列參數支援 (Mode/Action)，適合排程自動執行
# 修改：選項 [A] 強制使用 Gemini（尖峰時段也適用）
# 修正：所有路徑問題、Git upstream、API 參數、PowerShell 語法
# ============================================================

param(
    [string]$Mode = "auto",      # auto, gemini, deepseek
    [string]$Action = "menu"     # menu, full, quick, generate, deploy, backup, check
)

# ============================================================
# 0. 排程模式檢查
# ============================================================
$IsScheduled = ($Action -ne "menu")

if ($IsScheduled) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "🦞 排程自動執行模式" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "   📌 動作：$Action" -ForegroundColor Gray
    Write-Host "   📌 模型：$Mode" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# 1. 環境設定
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

Write-Host "📍 腳本目錄：$ScriptDir" -ForegroundColor Gray

# 專案根目錄（ahpal-static 目錄）
$ProjectRoot = Split-Path -Parent $ScriptDir
Write-Host "📍 專案根目錄：$ProjectRoot" -ForegroundColor Gray

# 載入環境設定（可能在 scripts 目錄或根目錄）
$EnvScriptCandidates = @()
$EnvScriptCandidates += Join-Path $ScriptDir "ahpal-static.ps1"
$EnvScriptCandidates += Join-Path $ProjectRoot "ahpal-static.ps1"

$EnvScript = $null
foreach ($candidate in $EnvScriptCandidates) {
    if (Test-Path $candidate) {
        $EnvScript = $candidate
        break
    }
}

if ($EnvScript) {
    Write-Host "🔧 載入環境設定：$EnvScript" -ForegroundColor Cyan
    & $EnvScript
} else {
    Write-Host "❌ 找不到 ahpal-static.ps1" -ForegroundColor Red
    Write-Host "   📍 搜尋位置：" -ForegroundColor Yellow
    foreach ($candidate in $EnvScriptCandidates) {
        Write-Host "      - $candidate" -ForegroundColor Gray
    }
    exit 1
}

if (-not $env:GEMINI_API_KEY -and -not $env:DEEPSEEK_API_KEY) {
    Write-Host "❌ 未設定任何 API Key！" -ForegroundColor Red
    exit 1
}

if (-not $env:AHPAL_OUTPUT_DIR) {
    Write-Host "❌ 輸出目錄未設定！" -ForegroundColor Red
    exit 1
}

$OutputDir = $env:AHPAL_OUTPUT_DIR
$BackupRoot = "C:\Users\User\ahpal-backup"

# ============================================================
# 腳本路徑
# ============================================================
# main.py 可能在根目錄或 src 目錄
$PythonScriptCandidates = @()
$PythonScriptCandidates += Join-Path $ProjectRoot "main.py"
$PythonScriptCandidates += Join-Path $ProjectRoot "src\main.py"

$PythonScript = $null
foreach ($candidate in $PythonScriptCandidates) {
    if (Test-Path $candidate) {
        $PythonScript = $candidate
        break
    }
}

if (-not $PythonScript) {
    Write-Host "❌ 找不到 main.py" -ForegroundColor Red
    Write-Host "   📍 搜尋位置：" -ForegroundColor Yellow
    foreach ($candidate in $PythonScriptCandidates) {
        Write-Host "      - $candidate" -ForegroundColor Gray
    }
    exit 1
}

Write-Host "📄 main.py 路徑：$PythonScript" -ForegroundColor Gray

$GameGeneratorScript = Join-Path $ScriptDir "generate-games.ps1"
$BackupScript = Join-Path $ScriptDir "backup-system.ps1"
$CheckScript = Join-Path $ScriptDir "check-articles.ps1"
$BalanceCheckScript = Join-Path $ScriptDir "check-deepseek-balance.ps1"

# ============================================================
# DeepSeek 餘額檢查（每日首次執行時自動檢查）
# ============================================================
$BalanceCheckFile = "C:\Users\User\ahpal-static\logs\last-balance-check.txt"
$Today = Get-Date -Format "yyyy-MM-dd"
$LastCheck = ""

if (Test-Path $BalanceCheckFile) {
    $LastCheck = Get-Content $BalanceCheckFile -Raw
}

if ($LastCheck -ne $Today -and (Test-Path $BalanceCheckScript)) {
    Write-Host "📊 執行每日餘額檢查..." -ForegroundColor Yellow
    
    try {
        $CheckResult = & $BalanceCheckScript -SendAlert
        
        if ($CheckResult -eq 1) {
            Write-Host "⚠️ 餘額過低，請注意！" -ForegroundColor Red
        } elseif ($CheckResult -eq 2) {
            Write-Host "⚠️ 餘額檢查失敗，請手動確認" -ForegroundColor Yellow
        }
        
        $Today | Out-File -FilePath $BalanceCheckFile -Encoding utf8
    } catch {
        Write-Host "⚠️ 餘額檢查失敗：$($_.Exception.Message)" -ForegroundColor Yellow
    }
} elseif ($LastCheck -ne $Today) {
    Write-Host "⚠️ 找不到餘額檢查腳本：$BalanceCheckScript" -ForegroundColor Yellow
}

# ============================================================
# 2. 模型選擇邏輯（支援排程模式）
# ============================================================
$Global:ForceAPI = $null

function Set-ForceAPI {
    param([string]$Mode)
    $Global:ForceAPI = $Mode
    if ($Mode) {
        $env:FORCE_API = $Mode
        Write-Host "✅ 已強制使用：$Mode" -ForegroundColor Green
    } else {
        Remove-Item Env:FORCE_API -ErrorAction SilentlyContinue
        Write-Host "✅ 已恢復自動切換模式" -ForegroundColor Green
    }
}

# 排程模式：根據參數設定模型
if ($IsScheduled) {
    if ($Mode -eq "gemini") {
        Set-ForceAPI -Mode "gemini"
    } elseif ($Mode -eq "deepseek") {
        Set-ForceAPI -Mode "deepseek"
    } else {
        Set-ForceAPI -Mode $null
        Write-Host "🔄 自動切換模式（尖峰 Gemini / 離峰 DeepSeek）" -ForegroundColor Cyan
    }
}

function Show-ForceAPIStatus {
    if ($Global:ForceAPI) {
        Write-Host "   🔧 強制模式：$Global:ForceAPI" -ForegroundColor Yellow
    } else {
        $currentHour = (Get-Date).Hour
        if ($currentHour -ge 9 -and $currentHour -lt 18) {
            Write-Host "   🔄 自動模式：Gemini（尖峰時段）" -ForegroundColor Cyan
        } else {
            Write-Host "   🔄 自動模式：DeepSeek（離峰時段）" -ForegroundColor Cyan
        }
    }
}

# ============================================================
# 3. 顯示系統狀態
# ============================================================
function Show-SystemStatus {
    Write-Host ""
    Write-Host "📊 系統狀態：" -ForegroundColor Yellow
    
    if ($env:GEMINI_API_KEY) {
        $masked = $env:GEMINI_API_KEY.Substring(0, [Math]::Min(6, $env:GEMINI_API_KEY.Length)) + "..." + $env:GEMINI_API_KEY.Substring([Math]::Max(0, $env:GEMINI_API_KEY.Length - 4))
        Write-Host "   🔑 Gemini：$masked" -ForegroundColor Cyan
    } else {
        Write-Host "   🔑 Gemini：未設定" -ForegroundColor Red
    }
    
    if ($env:DEEPSEEK_API_KEY) {
        $masked = $env:DEEPSEEK_API_KEY.Substring(0, [Math]::Min(6, $env:DEEPSEEK_API_KEY.Length)) + "..." + $env:DEEPSEEK_API_KEY.Substring([Math]::Max(0, $env:DEEPSEEK_API_KEY.Length - 4))
        Write-Host "   🔑 DeepSeek：$masked" -ForegroundColor Cyan
    } else {
        Write-Host "   🔑 DeepSeek：未設定" -ForegroundColor Red
    }
    
    Show-ForceAPIStatus
    Write-Host "   📁 輸出目錄：$OutputDir" -ForegroundColor Cyan
    
    $ArticleCount = 0
    $Dirs = @("tech", "game", "life", "review", "philosophy", "trend")
    foreach ($dir in $Dirs) {
        $path = Join-Path $OutputDir $dir
        $count = (Get-ChildItem -Path $path -Filter "*.html" -ErrorAction SilentlyContinue).Count
        $ArticleCount += $count
    }
    Write-Host "   📝 文章總數：$ArticleCount 篇" -ForegroundColor $(if ($ArticleCount -gt 0) {'Green'} else {'Red'})
    
    $GamePath = Join-Path $OutputDir "game"
    $GameCount = (Get-ChildItem -Path $GamePath -Filter "*.html" -ErrorAction SilentlyContinue).Count
    Write-Host "   🎮 遊戲數量：$GameCount 款" -ForegroundColor $(if ($GameCount -gt 0) {'Green'} else {'Red'})
    Write-Host ""
}

# ============================================================
# 4. 安全執行步驟
# ============================================================
function Invoke-SafeStep {
    param(
        [string]$StepName,
        [scriptblock]$ScriptBlock,
        [switch]$SkipOnError,
        [switch]$IsScheduled
    )
    
    Write-Host ""
    Write-Host "▶️ $StepName" -ForegroundColor Yellow
    Write-Host "⏳ 執行中..." -ForegroundColor Gray
    
    try {
        & $ScriptBlock
        if ($LASTEXITCODE -ne 0) {
            if ($SkipOnError) {
                Write-Host "⏩ 跳過錯誤，繼續執行..." -ForegroundColor Yellow
                return $true
            }
            throw "執行失敗 (錯誤碼: $LASTEXITCODE)"
        }
    } catch {
        if ($IsScheduled) {
            Write-Host "❌ $StepName 失敗：$($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
        throw
    }
    
    Write-Host "✅ $StepName 完成！" -ForegroundColor Green
    return $true
}

# ============================================================
# 5. 執行功能
# ============================================================

function Run-FullProcess {
    param([switch]$SkipBackup)
    
    if (-not $SkipBackup) {
        Invoke-SafeStep -StepName "步驟 0：備份" -ScriptBlock {
            if (Test-Path $BackupScript) { & $BackupScript }
        } -SkipOnError -IsScheduled:$IsScheduled
    }
    
    Invoke-SafeStep -StepName "步驟 1：生成遊戲" -ScriptBlock {
        if (Test-Path $GameGeneratorScript) { & $GameGeneratorScript }
    } -SkipOnError -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "步驟 2：生成文章" -ScriptBlock {
        if (Test-Path $PythonScript) {
            Write-Host "🐍 執行 Python 腳本..." -ForegroundColor Cyan
            Write-Host "   📄 腳本路徑：$PythonScript" -ForegroundColor Gray
            
            # 構建命令參數
            $PythonArgs = @()
            if ($Global:ForceAPI) {
                $PythonArgs += "--force"
                $PythonArgs += $Global:ForceAPI
                Write-Host "   📌 強制使用 API：$Global:ForceAPI" -ForegroundColor Yellow
            } else {
                Write-Host "   📌 自動切換模式" -ForegroundColor Cyan
            }
            
            # 執行 Python
            & python $PythonScript @PythonArgs
            
            if ($LASTEXITCODE -ne 0) { 
                throw "文章生成失敗 (錯誤碼: $LASTEXITCODE)" 
            }
        } else {
            throw "找不到 main.py：$PythonScript"
        }
    } -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "步驟 3：Git 提交與推送" -ScriptBlock {
        cd $OutputDir
        $status = git status --porcelain
        if ($status) {
            git add .
            $CommitMsg = "自動提交：$(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            git commit -m $CommitMsg
            
            # 檢查是否有 upstream，如果沒有則設定
            $branch = git branch --show-current
            # 修正：使用引號包圍 @{upstream}
            $upstream = git rev-parse --abbrev-ref "@{upstream}" 2>$null
            if (-not $upstream) {
                Write-Host "   📌 設定 upstream 分支..." -ForegroundColor Yellow
                git push --set-upstream origin $branch
            } else {
                git push
            }
            Write-Host "✅ Git 提交與推送完成！" -ForegroundColor Green
        } else {
            Write-Host "ℹ️ 沒有變更，跳過 Git 提交" -ForegroundColor Yellow
        }
    } -SkipOnError -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "步驟 4：部署到 Cloudflare" -ScriptBlock {
        Write-Host "🌐 正在部署到 ahpal-pages..." -ForegroundColor Cyan
        npx wrangler pages deploy "$OutputDir" --project-name=ahpal-pages
        Write-Host "✅ 部署完成！" -ForegroundColor Green
        Write-Host "🌐 https://www.ahpal.com/" -ForegroundColor Cyan
    } -IsScheduled:$IsScheduled
    
    Write-Host ""
    Write-Host "✅ 所有作業成功完成！" -ForegroundColor Green
}

function Run-GenerateOnly {
    Write-Host "📝 執行：只生成文章..." -ForegroundColor Cyan
    
    Invoke-SafeStep -StepName "生成遊戲" -ScriptBlock {
        if (Test-Path $GameGeneratorScript) { & $GameGeneratorScript }
    } -SkipOnError -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "生成文章" -ScriptBlock {
        if (Test-Path $PythonScript) {
            Write-Host "🐍 執行 Python 腳本..." -ForegroundColor Cyan
            Write-Host "   📄 腳本路徑：$PythonScript" -ForegroundColor Gray
            
            $PythonArgs = @()
            if ($Global:ForceAPI) {
                $PythonArgs += "--force"
                $PythonArgs += $Global:ForceAPI
                Write-Host "   📌 強制使用 API：$Global:ForceAPI" -ForegroundColor Yellow
            }
            
            & python $PythonScript @PythonArgs
        }
    } -IsScheduled:$IsScheduled
    
    Write-Host "✅ 文章生成完成！" -ForegroundColor Green
}

function Run-DeployOnly {
    Write-Host "🚀 執行：只做部署..." -ForegroundColor Cyan
    
    Invoke-SafeStep -StepName "備份" -ScriptBlock {
        if (Test-Path $BackupScript) { & $BackupScript }
    } -SkipOnError -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "Git 提交與推送" -ScriptBlock {
        cd $OutputDir
        $status = git status --porcelain
        if ($status) {
            git add .
            git commit -m "自動提交：$(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            
            $branch = git branch --show-current
            # 修正：使用引號包圍 @{upstream}
            $upstream = git rev-parse --abbrev-ref "@{upstream}" 2>$null
            if (-not $upstream) {
                Write-Host "   📌 設定 upstream 分支..." -ForegroundColor Yellow
                git push --set-upstream origin $branch
            } else {
                git push
            }
        }
    } -SkipOnError -IsScheduled:$IsScheduled
    
    Invoke-SafeStep -StepName "部署到 Cloudflare" -ScriptBlock {
        npx wrangler pages deploy "$OutputDir" --project-name=ahpal-pages
    } -IsScheduled:$IsScheduled
    
    Write-Host "✅ 部署完成！" -ForegroundColor Green
}

function Run-BackupOnly {
    Write-Host "📦 執行：只做備份..." -ForegroundColor Cyan
    if (Test-Path $BackupScript) { & $BackupScript }
    Write-Host "✅ 備份完成！" -ForegroundColor Green
}

function Run-CheckArticles {
    Write-Host "📊 檢查文章狀態..." -ForegroundColor Cyan
    if (Test-Path $CheckScript) { & $CheckScript }
}

# ============================================================
# 6. 排程模式執行
# ============================================================
if ($IsScheduled) {
    Show-SystemStatus
    
    switch ($Action) {
        "full" { Run-FullProcess }
        "quick" { Run-FullProcess -SkipBackup }
        "generate" { Run-GenerateOnly }
        "deploy" { Run-DeployOnly }
        "backup" { Run-BackupOnly }
        "check" { Run-CheckArticles }
        default {
            Write-Host "❌ 未知動作：$Action" -ForegroundColor Red
            exit 1
        }
    }
    exit 0
}

# ============================================================
# 7. 互動模式主選單
# ============================================================
function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  雅寶社區 · 頂客論壇 - 萬能總指揮 v7.0" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Show-SystemStatus
    
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [1] 完整流程 (備份 + 生成 + Git + 部署)"
    Write-Host "   [2] 快速更新 (跳過備份)"
    Write-Host "   [3] 只生成遊戲 (不耗 API，快速)"
    Write-Host "   [4] 只生成文章 (遊戲 + 文章，不部署)"
    Write-Host "   [5] 只做備份 (不生成、不部署)"
    Write-Host "   [6] 只做 Git + 部署 (不生成)"
    Write-Host "   [7] 檢查文章狀態"
    Write-Host "   [8] 查看系統狀態"
    Write-Host ""
    Write-Host "   [A] 🔧 強制使用 Gemini (尖峰時段也適用)"
    Write-Host "   [D] 🔧 強制使用 DeepSeek"
    Write-Host "   [B] 🔄 恢復自動切換模式"
    Write-Host ""
    Write-Host "   [0] 退出腳本"
    Write-Host ""
    
    $choice = Read-Host "請輸入選項 (0-9 或 A/B/D)"
    
    switch ($choice.ToUpper()) {
        "1" { Run-FullProcess; Read-Host "按 Enter 返回"; Show-MainMenu }
        "2" { Run-FullProcess -SkipBackup; Read-Host "按 Enter 返回"; Show-MainMenu }
        "3" { Run-GenerateOnly; Read-Host "按 Enter 返回"; Show-MainMenu }
        "4" { Run-GenerateOnly; Read-Host "按 Enter 返回"; Show-MainMenu }
        "5" { Run-BackupOnly; Read-Host "按 Enter 返回"; Show-MainMenu }
        "6" { Run-DeployOnly; Read-Host "按 Enter 返回"; Show-MainMenu }
        "7" { Run-CheckArticles; Read-Host "按 Enter 返回"; Show-MainMenu }
        "8" { Show-SystemStatus; Read-Host "按 Enter 返回"; Show-MainMenu }
        "A" { Set-ForceAPI -Mode "gemini"; Read-Host "按 Enter 返回"; Show-MainMenu }
        "D" { Set-ForceAPI -Mode "deepseek"; Read-Host "按 Enter 返回"; Show-MainMenu }
        "B" { Set-ForceAPI -Mode $null; Read-Host "按 Enter 返回"; Show-MainMenu }
        "0" { Write-Host "⏹️ 退出腳本"; exit 0 }
        default { Write-Host "⚠️ 無效選項"; Read-Host "按 Enter 重新選擇"; Show-MainMenu }
    }
}

# ============================================================
# 8. 啟動
# ============================================================
Show-MainMenu