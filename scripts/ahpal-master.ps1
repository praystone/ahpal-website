# ============================================================
# 雅寶社區 · 頂客論壇 - 萬能總指揮腳本 v6.3 (重構版)
# ============================================================
# 功能：載入環境 → 備份 → 遊戲生成 → 文章生成 → Git → 部署
# 新增：選項 [A] 臨時強制使用 DeepSeek（尖峰時段也適用）
#       選項 [B] 恢復自動切換模式
#       已更新為重構版 v4.0（使用 src/main.py）
#       修正：$PythonScript 路徑指向專案根目錄
# ============================================================
# 在 ahpal-master.ps1 的開頭加入

# ============================================================
# DeepSeek 餘額檢查（每日首次執行時自動檢查）
# ============================================================

$BalanceCheckFile = "C:\Users\User\ahpal-static\logs\last-balance-check.txt"
$Today = Get-Date -Format "yyyy-MM-dd"
$LastCheck = ""

if (Test-Path $BalanceCheckFile) {
    $LastCheck = Get-Content $BalanceCheckFile -Raw
}

if ($LastCheck -ne $Today) {
    Write-Host "📊 執行每日餘額檢查..." -ForegroundColor Yellow
    
    $CheckResult = .\scripts\check-deepseek-balance.ps1 -SendAlert
    
    if ($CheckResult -eq 1) {
        Write-Host "⚠️ 餘額過低，請注意！" -ForegroundColor Red
        # 可以選擇停止執行或繼續
        # exit 1  # 若要強制停止，取消註解
    } elseif ($CheckResult -eq 2) {
        Write-Host "⚠️ 餘額檢查失敗，請手動確認" -ForegroundColor Yellow
    }
    
    # 記錄今日已檢查
    $Today | Out-File -FilePath $BalanceCheckFile -Encoding utf8
}
# ============================================================
# 1. 環境設定（先載入 ahpal-static.ps1）
# ============================================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = Get-Location
}

# ✅ 載入環境設定（API Key + 輸出目錄）
$EnvScript = Join-Path $ScriptDir "ahpal-static.ps1"
if (Test-Path $EnvScript) {
    Write-Host "🔧 載入環境設定..." -ForegroundColor Cyan
    & $EnvScript
} else {
    Write-Host "❌ 找不到 ahpal-static.ps1" -ForegroundColor Red
    Write-Host "   請確認檔案位於：$EnvScript" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 1
}

# 確認環境變數已載入
if (-not $env:GEMINI_API_KEY -and -not $env:DEEPSEEK_API_KEY) {
    Write-Host "❌ 未設定任何 API Key！" -ForegroundColor Red
    Write-Host "   請檢查 ahpal-static.ps1 中的 API Key" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 1
}

if (-not $env:AHPAL_OUTPUT_DIR) {
    Write-Host "❌ 輸出目錄未設定！" -ForegroundColor Red
    Write-Host "   請檢查 ahpal-static.ps1 中的輸出目錄" -ForegroundColor Yellow
    Read-Host "按 Enter 鍵結束"
    exit 1
}

$OutputDir = $env:AHPAL_OUTPUT_DIR
$BackupRoot = "C:\Users\User\ahpal-backup"

# ============================================================
# 腳本路徑（重構版）- 已修正
# ============================================================
$ProjectRoot = Split-Path -Parent $ScriptDir  # scripts/ 的上一層 = 專案根目錄
$PythonScript = Join-Path $ProjectRoot "src\main.py"
$GameGeneratorScript = Join-Path $ScriptDir "generate-games.ps1"
$BackupScript = Join-Path $ScriptDir "backup-system.ps1"
$CheckScript = Join-Path $ScriptDir "check-articles.ps1"

# ============================================================
# 2. 強制 API 模式控制
# ============================================================
$Global:ForceAPI = $null  # $null=自動, "deepseek", "gemini"

function Set-ForceAPI {
    param([string]$Mode)
    $Global:ForceAPI = $Mode
    if ($Mode) {
        $env:FORCE_API = $Mode
        Write-Host ""
        Write-Host "✅ 已強制使用：$Mode" -ForegroundColor Green
        Write-Host "   （將覆蓋自動時段切換）" -ForegroundColor Gray
    } else {
        Remove-Item Env:FORCE_API -ErrorAction SilentlyContinue
        Write-Host ""
        Write-Host "✅ 已恢復自動切換模式" -ForegroundColor Green
    }
    Write-Host ""
}

function Show-ForceAPIStatus {
    if ($Global:ForceAPI) {
        Write-Host "   🔧 強制模式：$Global:ForceAPI（覆蓋自動切換）" -ForegroundColor Yellow
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
# 3. 函數：顯示系統狀態
# ============================================================
function Show-SystemStatus {
    Write-Host ""
    Write-Host "📊 系統狀態：" -ForegroundColor Yellow
    
    # 顯示 API Key 狀態
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
    
    # 計算文章總數（包含所有分類，含 game/）
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
# 4. 函數：安全執行步驟
# ============================================================
function Invoke-SafeStep {
    param(
        [string]$StepName,
        [scriptblock]$ScriptBlock,
        [switch]$SkipOnError
    )
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "▶️ $StepName" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⏳ 執行中... (按 Ctrl+C 可中斷)" -ForegroundColor Gray
    Write-Host ""
    
    $ErrorOccurred = $false
    $ErrorMessage = ""
    
    try {
        & $ScriptBlock
        if ($LASTEXITCODE -ne 0) {
            $ErrorOccurred = $true
            $ErrorMessage = "執行完成但返回錯誤碼: $LASTEXITCODE"
        }
    } catch {
        $ErrorOccurred = $true
        $ErrorMessage = $_.Exception.Message
    }
    
    if ($ErrorOccurred) {
        Write-Host ""
        Write-Host "⚠️ $StepName 執行有問題" -ForegroundColor Yellow
        Write-Host "   錯誤訊息：$ErrorMessage" -ForegroundColor Red
        
        if ($SkipOnError) {
            Write-Host "⏩ 已設定跳過錯誤，繼續執行..." -ForegroundColor Yellow
            return $true
        }
        
        $ValidChoice = $false
        while (-not $ValidChoice) {
            Write-Host ""
            Write-Host "請選擇處理方式：" -ForegroundColor Cyan
            Write-Host "   [R] 重試此步驟" -ForegroundColor Gray
            Write-Host "   [S] 跳過此步驟 (繼續執行)" -ForegroundColor Gray
            Write-Host "   [A] 中止執行 (回到主選單)" -ForegroundColor Gray
            Write-Host "   [V] 查看錯誤詳情" -ForegroundColor Gray
            Write-Host ""
            $choice = Read-Host "請輸入選項 (R/S/A/V)"
            
            switch ($choice.ToUpper()) {
                "R" {
                    $ValidChoice = $true
                    return Invoke-SafeStep -StepName $StepName -ScriptBlock $ScriptBlock -SkipOnError:$SkipOnError
                }
                "S" {
                    $ValidChoice = $true
                    Write-Host ""
                    Write-Host "⏩ 已跳過 $StepName" -ForegroundColor Yellow
                    return $true
                }
                "A" {
                    $ValidChoice = $true
                    Write-Host ""
                    Write-Host "🛑 已中止執行，回到主選單" -ForegroundColor Yellow
                    return $false
                }
                "V" {
                    $ValidChoice = $true
                    Write-Host ""
                    Write-Host "📋 錯誤詳情：" -ForegroundColor Yellow
                    Write-Host "   $ErrorMessage" -ForegroundColor Red
                    Write-Host ""
                    Write-Host "💡 可能原因：" -ForegroundColor Cyan
                    Write-Host "   1. 檔案路徑不正確" -ForegroundColor Gray
                    Write-Host "   2. 權限不足" -ForegroundColor Gray
                    Write-Host "   3. 網路連線問題" -ForegroundColor Gray
                    Write-Host "   4. API Key 無效或已過期" -ForegroundColor Gray
                    Write-Host ""
                    Read-Host "按 Enter 繼續選擇"
                    $ValidChoice = $false
                }
                default {
                    Write-Host ""
                    Write-Host "⚠️ 無效的選項，請輸入 R、S、A 或 V" -ForegroundColor Yellow
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "✅ $StepName 完成！" -ForegroundColor Green
    return $true
}

# ============================================================
# 5. 暫停函數
# ============================================================
function Pause-Menu {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Gray
    Write-Host "按 Enter 鍵返回主選單" -ForegroundColor Cyan
    Read-Host
}

# ============================================================
# 6. 執行功能
# ============================================================

function Run-GenerateGamesOnly {
    Write-Host ""
    Write-Host "🎮 執行：只生成遊戲..." -ForegroundColor Cyan
    Write-Host "⏳ 約需 10-20 秒..." -ForegroundColor Gray
    Write-Host ""
    
    Invoke-SafeStep -StepName "生成遊戲" -ScriptBlock {
        if (Test-Path $GameGeneratorScript) {
            & $GameGeneratorScript
        } else {
            Write-Host "⚠️ 找不到 generate-games.ps1，跳過遊戲生成" -ForegroundColor Yellow
            Write-Host "   請確認檔案位於：$GameGeneratorScript" -ForegroundColor Gray
        }
    } -SkipOnError
    
    Write-Host ""
    Write-Host "✅ 遊戲生成完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 若要部署到網站，請選擇主選單 [1] 完整流程 或 [6] 只做部署" -ForegroundColor Cyan
}

function Run-FullProcess {
    param(
        [switch]$SkipBackup
    )
    
    if (-not $SkipBackup) {
        Invoke-SafeStep -StepName "步驟 0：備份" -ScriptBlock {
            if (Test-Path $BackupScript) {
                & $BackupScript
            } else {
                Write-Host "⚠️ 找不到 backup-system.ps1，跳過備份" -ForegroundColor Yellow
            }
        } -SkipOnError
    } else {
        Write-Host "⏩ 跳過備份" -ForegroundColor Yellow
    }
    
    Invoke-SafeStep -StepName "步驟 1：生成遊戲" -ScriptBlock {
        if (Test-Path $GameGeneratorScript) {
            & $GameGeneratorScript
        } else {
            Write-Host "⚠️ 找不到 generate-games.ps1，跳過遊戲生成" -ForegroundColor Yellow
        }
    } -SkipOnError
    
    Invoke-SafeStep -StepName "步驟 2：生成文章" -ScriptBlock {
        if (Test-Path $PythonScript) {
            Write-Host "🐍 執行 Python 腳本..." -ForegroundColor Cyan
            if ($Global:ForceAPI) {
                Write-Host "🔧 強制使用 API：$Global:ForceAPI" -ForegroundColor Yellow
            } else {
                $currentHour = (Get-Date).Hour
                if ($currentHour -ge 9 -and $currentHour -lt 18) {
                    Write-Host "📡 自動模式：Gemini（尖峰時段）" -ForegroundColor Cyan
                } else {
                    Write-Host "📡 自動模式：DeepSeek（離峰時段）" -ForegroundColor Cyan
                }
            }
            Write-Host "⏳ 此步驟約需 25-35 分鐘，請耐心等待..." -ForegroundColor Gray
            python $PythonScript
            if ($LASTEXITCODE -ne 0) {
                throw "文章生成失敗 (錯誤碼: $LASTEXITCODE)"
            }
        } else {
            throw "找不到 src/main.py"
        }
    }
    
    Invoke-SafeStep -StepName "步驟 3：Git 提交與推送" -ScriptBlock {
        cd $OutputDir
        $status = git status --porcelain
        if ($status) {
            git add .
            $CommitMsg = "自動提交：$(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            git commit -m $CommitMsg
            if ($LASTEXITCODE -eq 0) {
                git push
                Write-Host "✅ Git 提交與推送完成！" -ForegroundColor Green
                Write-Host "   📝 提交訊息：$CommitMsg" -ForegroundColor Gray
            } else {
                throw "Git 提交失敗"
            }
        } else {
            Write-Host "ℹ️ 沒有變更，跳過 Git 提交" -ForegroundColor Yellow
        }
    } -SkipOnError
    
    Invoke-SafeStep -StepName "步驟 4：部署到 Cloudflare" -ScriptBlock {
        Write-Host "🌐 正在部署到 ahpal-pages..." -ForegroundColor Cyan
        npx wrangler pages deploy "$OutputDir" --project-name=ahpal-pages
        if ($LASTEXITCODE -ne 0) {
            throw "部署失敗 (錯誤碼: $LASTEXITCODE)"
        }
        Write-Host "✅ 部署完成！" -ForegroundColor Green
        Write-Host "🌐 https://www.ahpal.com/" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "✅ 所有作業成功完成！" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "🌐 網站網址：https://www.ahpal.com/" -ForegroundColor Cyan
    Write-Host "🎮 遊戲入口：https://www.ahpal.com/game/" -ForegroundColor Cyan
    Write-Host ""
}

function Run-GenerateOnly {
    Write-Host ""
    Write-Host "📝 執行：只生成文章（遊戲 + 文章，不部署）..." -ForegroundColor Cyan
    if ($Global:ForceAPI) {
        Write-Host "🔧 強制使用 API：$Global:ForceAPI" -ForegroundColor Yellow
    }
    Write-Host "⏳ 約需 25-35 分鐘..." -ForegroundColor Gray
    Write-Host ""
    
    Invoke-SafeStep -StepName "步驟 1：生成遊戲" -ScriptBlock {
        if (Test-Path $GameGeneratorScript) {
            & $GameGeneratorScript
        } else {
            Write-Host "⚠️ 找不到 generate-games.ps1，跳過遊戲生成" -ForegroundColor Yellow
        }
    } -SkipOnError
    
    Invoke-SafeStep -StepName "步驟 2：生成文章" -ScriptBlock {
        if (Test-Path $PythonScript) {
            Write-Host "🐍 執行 Python 腳本..." -ForegroundColor Cyan
            if ($Global:ForceAPI) {
                Write-Host "🔧 強制使用 API：$Global:ForceAPI" -ForegroundColor Yellow
            }
            Write-Host "⏳ 此步驟約需 25-35 分鐘，請耐心等待..." -ForegroundColor Gray
            python $PythonScript
            if ($LASTEXITCODE -ne 0) {
                throw "文章生成失敗 (錯誤碼: $LASTEXITCODE)"
            }
        } else {
            throw "找不到 src/main.py"
        }
    }
    
    Write-Host ""
    Write-Host "✅ 文章生成完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 若要部署，請執行選單 [1] 完整流程 或 [6] 只做部署" -ForegroundColor Cyan
}

function Run-DeployOnly {
    Write-Host ""
    Write-Host "🚀 執行：只做備份 + Git + 部署（不生成文章）..." -ForegroundColor Cyan
    Write-Host ""
    
    Invoke-SafeStep -StepName "步驟 0：備份" -ScriptBlock {
        if (Test-Path $BackupScript) {
            & $BackupScript
        } else {
            Write-Host "⚠️ 找不到 backup-system.ps1，跳過備份" -ForegroundColor Yellow
        }
    } -SkipOnError
    
    Invoke-SafeStep -StepName "步驟 1：Git 提交與推送" -ScriptBlock {
        cd $OutputDir
        $status = git status --porcelain
        if ($status) {
            git add .
            $CommitMsg = "自動提交：$(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            git commit -m $CommitMsg
            if ($LASTEXITCODE -eq 0) {
                git push
                Write-Host "✅ Git 提交與推送完成！" -ForegroundColor Green
            } else {
                throw "Git 提交失敗"
            }
        } else {
            Write-Host "ℹ️ 沒有變更，跳過 Git 提交" -ForegroundColor Yellow
        }
    } -SkipOnError
    
    Invoke-SafeStep -StepName "步驟 2：部署到 Cloudflare" -ScriptBlock {
        Write-Host "🌐 正在部署到 ahpal-pages..." -ForegroundColor Cyan
        npx wrangler pages deploy "$OutputDir" --project-name=ahpal-pages
        if ($LASTEXITCODE -ne 0) {
            throw "部署失敗 (錯誤碼: $LASTEXITCODE)"
        }
        Write-Host "✅ 部署完成！" -ForegroundColor Green
        Write-Host "🌐 https://www.ahpal.com/" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "✅ 備份 + Git + 部署完成！" -ForegroundColor Green
}

function Run-CheckArticles {
    Write-Host ""
    Write-Host "📊 檢查文章狀態..." -ForegroundColor Cyan
    if (Test-Path $CheckScript) {
        & $CheckScript
    } else {
        Write-Host "⚠️ 找不到 check-articles.ps1" -ForegroundColor Yellow
    }
}

function Run-BackupOnly {
    Write-Host ""
    Write-Host "📦 執行：只做備份..." -ForegroundColor Cyan
    Write-Host ""
    
    Invoke-SafeStep -StepName "備份系統" -ScriptBlock {
        if (Test-Path $BackupScript) {
            & $BackupScript
        } else {
            throw "找不到 backup-system.ps1"
        }
    }
    
    Write-Host ""
    Write-Host "✅ 備份完成！" -ForegroundColor Green
}

# ============================================================
# 7. 主選單
# ============================================================
function Show-MainMenu {
    Clear-Host
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  雅寶社區 · 頂客論壇 - 萬能總指揮 v6.3 (重構版)" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Cyan
    
    Show-SystemStatus
    
    Write-Host "📋 請選擇要執行的操作：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   [1] 完整流程 (備份 + 生成 + Git + 部署)" -ForegroundColor White
    Write-Host "   [2] 快速更新 (跳過備份)" -ForegroundColor White
    Write-Host "   [3] 只生成遊戲 (不耗 API，快速)" -ForegroundColor White
    Write-Host "   [4] 只生成文章 (遊戲 + 文章，不部署)" -ForegroundColor White
    Write-Host "   [5] 只做備份 (不生成、不部署)" -ForegroundColor White
    Write-Host "   [6] 只做 Git + 部署 (不生成)" -ForegroundColor White
    Write-Host "   [7] 檢查文章狀態" -ForegroundColor White
    Write-Host "   [8] 查看系統狀態" -ForegroundColor White
    Write-Host "   [9] 查看完整說明" -ForegroundColor White
    Write-Host ""
    Write-Host "   [A] 🔧 強制使用 DeepSeek (尖峰時段也適用)" -ForegroundColor Yellow
    Write-Host "   [B] 🔄 恢復自動切換模式" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "   [0] 退出腳本" -ForegroundColor White
    Write-Host ""
    Write-Host "💡 按 Ctrl+C 可隨時中斷執行" -ForegroundColor Cyan
    Write-Host ""
    
    $choice = Read-Host "請輸入選項 (0-9 或 A/B)"
    
    switch ($choice.ToUpper()) {
        "1" {
            Write-Host ""
            Write-Host "▶️ 執行完整流程..." -ForegroundColor Cyan
            Run-FullProcess
            Pause-Menu
            Show-MainMenu
        }
        "2" {
            Write-Host ""
            Write-Host "▶️ 執行快速更新 (跳過備份)..." -ForegroundColor Cyan
            Run-FullProcess -SkipBackup
            Pause-Menu
            Show-MainMenu
        }
        "3" {
            Run-GenerateGamesOnly
            Pause-Menu
            Show-MainMenu
        }
        "4" {
            Run-GenerateOnly
            Pause-Menu
            Show-MainMenu
        }
        "5" {
            Run-BackupOnly
            Pause-Menu
            Show-MainMenu
        }
        "6" {
            Run-DeployOnly
            Pause-Menu
            Show-MainMenu
        }
        "7" {
            Run-CheckArticles
            Pause-Menu
            Show-MainMenu
        }
        "8" {
            Write-Host ""
            Show-SystemStatus
            Pause-Menu
            Show-MainMenu
        }
        "9" {
            Show-Help
            Pause-Menu
            Show-MainMenu
        }
        "A" {
            Set-ForceAPI -Mode "deepseek"
            Pause-Menu
            Show-MainMenu
        }
        "B" {
            Set-ForceAPI -Mode $null
            Pause-Menu
            Show-MainMenu
        }
        "0" {
            Write-Host ""
            Write-Host "⏹️ 退出腳本" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "按 Enter 鍵結束"
            exit 0
        }
        default {
            Write-Host ""
            Write-Host "⚠️ 無效選項，請輸入 0-9 或 A/B" -ForegroundColor Yellow
            Read-Host "按 Enter 重新選擇"
            Show-MainMenu
        }
    }
}

# ============================================================
# 8. 顯示說明
# ============================================================
function Show-Help {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "📋 使用說明" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "功能說明：" -ForegroundColor Cyan
    Write-Host "   [1] 完整流程：備份 → 生成遊戲 → 生成文章 → Git → 部署" -ForegroundColor Gray
    Write-Host "   [2] 快速更新：跳過備份，直接執行生成 → Git → 部署" -ForegroundColor Gray
    Write-Host "   [3] 只生成遊戲：不耗 API，約 10-20 秒完成" -ForegroundColor Gray
    Write-Host "   [4] 只生成文章：生成遊戲 + 文章，不提交 Git 也不部署" -ForegroundColor Gray
    Write-Host "   [5] 只做備份：備份所有檔案，不生成也不部署" -ForegroundColor Gray
    Write-Host "   [6] 只做部署：備份 + Git 提交 + 部署 (不生成文章)" -ForegroundColor Gray
    Write-Host "   [7] 檢查文章：檢查文章數量和異常檔案" -ForegroundColor Gray
    Write-Host "   [8] 系統狀態：顯示當前系統資訊" -ForegroundColor Gray
    Write-Host "   [9] 查看說明：顯示此說明" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   [A] 強制 DeepSeek：尖峰時段也強制使用 DeepSeek" -ForegroundColor Yellow
    Write-Host "   [B] 恢復自動：恢復尖峰 Gemini / 離峰 DeepSeek 自動切換" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📌 注意事項：" -ForegroundColor Yellow
    Write-Host "   - 按 Ctrl+C 可隨時中斷執行" -ForegroundColor Gray
    Write-Host "   - 步驟失敗時可選擇 [R] 重試 / [S] 跳過 / [A] 中止" -ForegroundColor Gray
    Write-Host "   - 強制 DeepSeek 模式會持續有效，直到重新啟動腳本或按 [B] 恢復" -ForegroundColor Gray
    Write-Host "   - 本版本已升級為重構版 v4.0，使用 src/main.py 作為文章生成入口" -ForegroundColor Gray
    Write-Host ""
}

# ============================================================
# 9. 啟動
# ============================================================
Show-MainMenu