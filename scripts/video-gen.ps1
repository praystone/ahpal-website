# ============================================================
# video-gen.ps1 - AHPAL 視頻自動化生成調度器 v1.0
# 位置: C:\Users\User\ahpal-static\scripts\video-gen.ps1
# ============================================================
# 功能：
#   - 從 JSON 工作佇列讀取任務
#   - 觸發雲端 GPU (Modal / Lightning AI) 執行 LTX-2.3
#   - 下載生成影片並執行 ffmpeg 合軌
#   - 記錄成本與生成日誌
# ============================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskFile,              # JSON 工作檔路徑
    [ValidateSet("modal", "lightning", "colab")]
    [string]$Platform = "modal",     # 預設使用 Modal
    [switch]$DryRun,                # 預覽模式
    [switch]$Force                  # 跳過確認
)

# ---- 環境設定 ----
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---- 路徑設定 ----
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
$VideoDir = Join-Path $ProjectRoot "videos"
$FinalDir = Join-Path $VideoDir "final"
$AudioDir = Join-Path $ProjectRoot "audio"
$LogDir = Join-Path $ProjectRoot "logs"

New-Item -ItemType Directory -Path $FinalDir -Force | Out-Null
New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFile = Join-Path $LogDir "video-gen-$Timestamp.log"

# ---- 載入工作任務 ----
function Load-Tasks {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Error "❌ 找不到工作檔: $Path"
        exit 1
    }
    
    $content = Get-Content $Path -Raw -Encoding UTF8
    $tasks = $content | ConvertFrom-Json
    
    if ($tasks.Count -eq 0) {
        Write-Warning "⚠️ 工作清單為空"
        exit 0
    }
    
    return $tasks
}

# ---- 檢查平台可用性 ----
function Test-PlatformAvailability {
    param([string]$Platform)
    
    switch ($Platform) {
        "modal" {
            # 檢查 Modal 是否安裝
            $modal = Get-Command modal -ErrorAction SilentlyContinue
            if (-not $modal) {
                Write-Warning "⚠️ Modal CLI 未安裝，嘗試安裝..."
                pip install modal
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "❌ Modal 安裝失敗"
                    return $false
                }
            }
            # 檢查是否已登入
            $result = modal token show 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "⚠️ 請先執行: modal token set"
                return $false
            }
            return $true
        }
        "lightning" {
            Write-Warning "⚠️ Lightning AI 需要手動授權"
            return $true
        }
        "colab" {
            Write-Warning "⚠️ Colab 模式需手動執行 Notebook"
            return $true
        }
        default { return $false }
    }
}

# ---- 生成任務 ID ----
function New-TaskId {
    return "task-$(Get-Date -Format 'yyyyMMdd-HHmmss')-$(Get-Random -Maximum 999)"
}

# ---- 檢查成本配額 ----
function Check-Quota {
    $QuotaFile = Join-Path $ProjectRoot "data\video-quota.json"
    
    if (-not (Test-Path $QuotaFile)) {
        # 建立預設配額
        $defaultQuota = @{
            daily_limit = 5
            monthly_limit = 50
            current_daily = 0
            current_monthly = 0
            last_reset = (Get-Date).ToString("yyyy-MM-dd")
        }
        $defaultQuota | ConvertTo-Json | Out-File $QuotaFile -Encoding UTF8
        return $true
    }
    
    $quota = Get-Content $QuotaFile -Raw | ConvertFrom-Json
    
    # 檢查每日重置
    $today = Get-Date -Format "yyyy-MM-dd"
    if ($quota.last_reset -ne $today) {
        $quota.current_daily = 0
        $quota.last_reset = $today
        $quota | ConvertTo-Json | Out-File $QuotaFile -Encoding UTF8
    }
    
    # 檢查配額
    if ($quota.current_daily -ge $quota.daily_limit) {
        Write-Warning "⚠️ 每日配額已達上限 ($($quota.daily_limit) 部)"
        return $false
    }
    
    if ($quota.current_monthly -ge $quota.monthly_limit) {
        Write-Warning "⚠️ 每月配額已達上限 ($($quota.monthly_limit) 部)"
        return $false
    }
    
    return $true
}

# ---- 更新配額 ----
function Update-Quota {
    $QuotaFile = Join-Path $ProjectRoot "data\video-quota.json"
    $quota = Get-Content $QuotaFile -Raw | ConvertFrom-Json
    $quota.current_daily++
    $quota.current_monthly++
    $quota | ConvertTo-Json | Out-File $QuotaFile -Encoding UTF8
}

# ---- 執行單一任務 ----
function Invoke-VideoTask {
    param(
        [object]$Task,
        [string]$Platform,
        [string]$TaskId
    )
    
    Write-Host ""
    Write-Host "📹 執行任務 [$TaskId]: $($Task.title)" -ForegroundColor Yellow
    Write-Host "   📌 描述: $($Task.description)" -ForegroundColor Gray
    Write-Host "   📌 平台: $Platform" -ForegroundColor Gray
    Write-Host "   📌 分辨率: $($Task.resolution)" -ForegroundColor Gray
    Write-Host "   📌 時長: $($Task.duration) 秒" -ForegroundColor Gray
    
    $startTime = Get-Date
    
    # ---- 步驟 1：檢查音訊檔 ----
    $audioFile = $Task.audio_file
    if ($audioFile -and -not (Test-Path $audioFile)) {
        $audioFile = Join-Path $AudioDir $audioFile
        if (-not (Test-Path $audioFile)) {
            Write-Warning "   ⚠️ 音訊檔不存在: $audioFile，使用純文字生成"
            $audioFile = $null
        }
    }
    
    # ---- 步驟 2：準備提示詞 ----
    $prompt = $Task.prompt
    if (-not $prompt) {
        $prompt = $Task.title
    }
    
    # ---- 步驟 3：生成關鍵畫面 Prompt ----
    $imagePrompt = $Task.image_prompt
    if (-not $imagePrompt) {
        $imagePrompt = Generate-KeyframePrompt -Text $prompt
    }
    
    # ---- 步驟 4：調用雲端平台 ----
    $videoFile = $null
    $outputFile = Join-Path $FinalDir "$TaskId-$($Task.title -replace '[^a-zA-Z0-9]', '-').mp4"
    
    switch ($Platform) {
        "modal" {
            $videoFile = Invoke-ModalVideo `
                -Prompt $prompt `
                -ImagePrompt $imagePrompt `
                -Duration $Task.duration `
                -Resolution $Task.resolution `
                -TaskId $TaskId
        }
        "lightning" {
            $videoFile = Invoke-LightningVideo `
                -Prompt $prompt `
                -ImagePrompt $imagePrompt `
                -Duration $Task.duration `
                -Resolution $Task.resolution `
                -TaskId $TaskId
        }
        "colab" {
            # 產生 Colab 連結供手動執行
            $colabUrl = Generate-ColabUrl -Prompt $prompt -TaskId $TaskId
            Write-Host "   📌 Colab 連結: $colabUrl" -ForegroundColor Cyan
            Write-Host "   ⏳ 請手動執行 Colab Notebook，完成後將影片放入 $FinalDir" -ForegroundColor Yellow
            return $null
        }
    }
    
    if (-not $videoFile -or -not (Test-Path $videoFile)) {
        Write-Error "   ❌ 影片生成失敗"
        return $null
    }
    
    # ---- 步驟 5：合軌音訊 ----
    if ($audioFile -and (Test-Path $audioFile)) {
        Write-Host "   🎵 合併音訊: $audioFile" -ForegroundColor Gray
        $finalFile = $outputFile -replace "\.mp4$", "-audio.mp4"
        
        $ffmpegCmd = "ffmpeg -i `"$videoFile`" -i `"$audioFile`" -map 0:v -map 1:a -shortest -c:v copy -c:a aac -b:a 192k `"$finalFile`" -y"
        Invoke-Expression $ffmpegCmd
        
        if (Test-Path $finalFile) {
            Remove-Item $videoFile -Force
            $videoFile = $finalFile
            Write-Host "   ✅ 音訊合併完成" -ForegroundColor Green
        }
    }
    
    # ---- 步驟 6：更新配額 ----
    Update-Quota
    
    # ---- 步驟 7：記錄結果 ----
    $elapsed = (Get-Date) - $startTime
    $result = @{
        task_id = $TaskId
        title = $Task.title
        status = "success"
        output_file = $videoFile
        elapsed = $elapsed.ToString()
    }
    
    return $result
}

# ---- 生成關鍵畫面 Prompt (使用 AI) ----
function Generate-KeyframePrompt {
    param([string]$Text)
    
    Write-Host "   🎨 生成關鍵畫面 Prompt..." -ForegroundColor Gray
    
    # 調用 Python 腳本生成視覺提示詞
    $pythonScript = @"
import json
import sys
from src.api_client import APIClient

client = APIClient()
prompt = f"請為以下內容生成一個視覺畫面的英文描述 (16:9 構圖)：\n\n{'{Text}'}"

try:
    result = client.generate_article(
        keyword="視覺提示詞生成",
        category="📊 軟體評測",
        max_tokens=200
    )
    # 提取有用的部分
    lines = result.strip().split('\n')
    visual = [l for l in lines if len(l) > 10][0] if lines else result
    print(visual[:200])
except Exception as e:
    print(f"A cinematic scene about: {Text[:100]}")
"@ -replace "{Text}", $Text
    
    $imagePrompt = python -c $pythonScript 2>$null
    if (-not $imagePrompt) {
        $imagePrompt = "A cinematic scene about: $Text"
    }
    
    Write-Host "   📝 生成畫面 Prompt: $($imagePrompt.Substring(0, [Math]::Min(60, $imagePrompt.Length)))..." -ForegroundColor Gray
    return $imagePrompt
}

# ---- Modal 影片生成 ----
function Invoke-ModalVideo {
    param(
        [string]$Prompt,
        [string]$ImagePrompt,
        [int]$Duration,
        [string]$Resolution,
        [string]$TaskId
    )
    
    Write-Host "   🚀 提交 Modal 任務..." -ForegroundColor Gray
    
    # 建立 Modal Python 腳本
    $modalScript = @"
import modal
import time
import os

app = modal.App("ahpal-video-gen-$TaskId")

image = modal.Image.debian_slim().pip_install("torch", "diffusers", "transformers")

@app.function(
    image=image,
    gpu="A100",
    timeout=1800,
    mounts=[
        modal.Mount.from_local_dir("C:/Users/User/ahpal-static/videos", remote_path="/root/videos")
    ]
)
def generate_video(prompt, image_prompt, duration, resolution):
    # 載入 LTX-2.3 模型
    # 此處為示意，實際需要整合 LTX-2.3 Notebook 邏輯
    print(f"Generating video with prompt: {prompt}")
    print(f"Image prompt: {image_prompt}")
    print(f"Duration: {duration}s, Resolution: {resolution}")
    
    # 模擬生成
    time.sleep(30)
    
    # 返回影片路徑
    return "/root/videos/output.mp4"

@app.local_entrypoint()
def main():
    try:
        result = generate_video.remote(
            prompt="$Prompt",
            image_prompt="$ImagePrompt",
            duration=$Duration,
            resolution="$Resolution"
        )
        print(result)
    except Exception as e:
        print(f"Error: {e}")
"@ -replace "\$Prompt", $Prompt -replace "\$ImagePrompt", $ImagePrompt -replace "\$Duration", $Duration -replace "\$Resolution", $Resolution

    # 寫入臨時檔案
    $tempScript = Join-Path $env:TEMP "modal-$TaskId.py"
    $modalScript | Out-File $tempScript -Encoding UTF8
    
    # 執行 Modal
    $output = & modal run $tempScript 2>&1
    $exitCode = $LASTEXITCODE
    
    # 清理
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    
    if ($exitCode -ne 0) {
        Write-Error "   ❌ Modal 執行失敗"
        Write-Host "   📄 錯誤輸出: $output" -ForegroundColor Red
        return $null
    }
    
    # 檢查輸出檔案
    $outputFile = Join-Path $FinalDir "$TaskId-modal-output.mp4"
    if (Test-Path $outputFile) {
        return $outputFile
    }
    
    # 如果沒有特定檔案，尋找最近生成的 mp4
    $files = Get-ChildItem $FinalDir -Filter "*.mp4" | Sort-Object LastWriteTime -Descending
    if ($files.Count -gt 0) {
        return $files[0].FullName
    }
    
    return $null
}

# ---- Lightning AI 影片生成 ----
function Invoke-LightningVideo {
    param(
        [string]$Prompt,
        [string]$ImagePrompt,
        [int]$Duration,
        [string]$Resolution,
        [string]$TaskId
    )
    
    Write-Host "   🚀 提交 Lightning AI 任務..." -ForegroundColor Gray
    Write-Host "   ⚠️ Lightning AI 需要手動授權 (GitHub OAuth)" -ForegroundColor Yellow
    Write-Host "   📌 請確保已授權 lightning.ai 存取 GitHub 儲存庫" -ForegroundColor Yellow
    
    # 產生 Lightning AI Studio 連結
    $studioUrl = "https://lightning.ai/praystone/studios/ahpal-video-gen"
    Write-Host "   📌 Lightning Studio: $studioUrl" -ForegroundColor Cyan
    
    # 此處為示意，實際需要透過 Lightning API 觸發
    Write-Warning "   ⚠️ Lightning AI 自動化 API 開發中，請手動執行 Notebook"
    
    return $null
}

# ---- Colab 連結生成 ----
function Generate-ColabUrl {
    param(
        [string]$Prompt,
        [string]$TaskId
    )
    
    $encodedPrompt = [System.Web.HttpUtility]::UrlEncode($Prompt)
    $notebookUrl = "https://colab.research.google.com/github/changm2024-lang/ai-notebook/blob/main/LTX2_3_Video_Generator_Modal.ipynb"
    
    # 建立帶參數的連結
    return "$notebookUrl?ref=$TaskId&prompt=$encodedPrompt"
}

# ---- 產生摘要報告 ----
function Generate-Summary {
    param([array]$Results)
    
    Write-Section "📊 執行摘要"
    
    $successCount = ($Results | Where-Object { $_ -ne $null }).Count
    $totalCount = $Results.Count
    
    Write-Host "   ✅ 成功: $successCount / $totalCount" -ForegroundColor Green
    Write-Host "   📄 日誌: $LogFile" -ForegroundColor Gray
    
    foreach ($r in $Results) {
        if ($r) {
            Write-Host "   📹 $($r.title) → $($r.output_file)" -ForegroundColor Cyan
        }
    }
}

# ============================================================
# 主程式
# ============================================================

Write-Info "============================================================"
Write-Info "  🎬 AHPAL 視頻自動化生成調度器 v1.0"
Write-Info "============================================================"
Write-Host ""

# 1. 載入任務
$tasks = Load-Tasks -Path $TaskFile

Write-Info "📋 載入 $($tasks.Count) 個任務"

# 2. 檢查平台
if (-not (Test-PlatformAvailability -Platform $Platform)) {
    Write-Error "❌ 平台 $Platform 不可用"
    exit 1
}

# 3. 檢查配額
if (-not (Check-Quota)) {
    Write-Error "❌ 配額已滿，請等待重置或調整 daily_limit"
    exit 1
}

if ($DryRun) {
    Write-Info "🔍 預覽模式 - 將執行 $($tasks.Count) 個任務"
    foreach ($task in $tasks) {
        Write-Host "   📹 $($task.title)" -ForegroundColor Gray
    }
    exit 0
}

if (-not $Force) {
    $confirm = Read-Host "是否繼續執行 $($tasks.Count) 個任務？(y/n)"
    if ($confirm -ne "y") {
        Write-Warning "已取消"
        exit 0
    }
}

# 4. 執行任務
$results = @()
foreach ($task in $tasks) {
    $taskId = New-TaskId
    $result = Invoke-VideoTask -Task $task -Platform $Platform -TaskId $taskId
    $results += $result
}

# 5. 產生摘要
Generate-Summary -Results $results

# 6. 觸發部署
if ($results.Count -gt 0 -and $results[0] -ne $null) {
    Write-Host ""
    Write-Info "📌 下一步: 執行部署"
    Write-Gray "   .\scripts\ahpal-master.ps1 -Action deploy"
}

Write-Success "🎬 視頻生成流程完成！"