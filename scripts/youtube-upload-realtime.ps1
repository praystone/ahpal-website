param(
    [Parameter(Mandatory=$true)]
    [string]$VideoFile,
    [Parameter(Mandatory=$true)]
    [string]$Title,
    [string]$Description = "",
    [string[]]$Tags = @()
)

Write-Host "🦞 YouTube 純二進位串流上傳模式" -ForegroundColor Cyan

# 解析絕對路徑
$ResolvedVideoPath = (Resolve-Path $VideoFile -ErrorAction Stop).Path
Write-Host "📄 影片檔案：$ResolvedVideoPath" -ForegroundColor Gray

if (-not (Test-Path $ResolvedVideoPath)) {
    Write-Host "❌ 影片檔案不存在" -ForegroundColor Red
    exit 1
}

# 讀取影片二進位資料
$VideoBytes = [System.IO.File]::ReadAllBytes($ResolvedVideoPath)
Write-Host "✅ 已讀取 $($VideoBytes.Length) 位元組 ($([math]::Round($VideoBytes.Length / 1MB, 2)) MB)" -ForegroundColor Green

# 載入 Refresh Token
$envContent = Get-Content ".env" -Raw
if ($envContent -match "YOUTUBE_REFRESH_TOKEN=(.+)") {
    [Environment]::SetEnvironmentVariable("YOUTUBE_REFRESH_TOKEN", $Matches[1].Trim(), "Process")
}
$RefreshToken = [Environment]::GetEnvironmentVariable("YOUTUBE_REFRESH_TOKEN")

# 讀取 client_secret.json
$ClientSecret = Get-Content "data\client_secret.json" -Raw | ConvertFrom-Json
$Creds = if ($ClientSecret.installed) { $ClientSecret.installed } else { $ClientSecret.web }

# 交換 Access Token
$TokenBody = @{
    client_id = $Creds.client_id
    client_secret = $Creds.client_secret
    refresh_token = $RefreshToken
    grant_type = "refresh_token"
} | ConvertTo-Json

try {
    $TokenResponse = Invoke-RestMethod -Uri "https://oauth2.googleapis.com/token" -Method Post -ContentType "application/json" -Body $TokenBody
    $AccessToken = $TokenResponse.access_token
    Write-Host "✅ Access Token 取得成功" -ForegroundColor Green
} catch {
    Write-Host "❌ Access Token 交換失敗：$_" -ForegroundColor Red
    exit 1
}

# 建立 Multipart 內容 (純位元組拼接)
$Boundary = "ahpal_boundary_" + (Get-Date -Format "yyyyMMddHHmmss")

# 中繼資料 (JSON)
$Metadata = @{
    snippet = @{
        title = $Title
        description = $Description
        tags = $Tags
        categoryId = "22"
    }
    status = @{
        privacyStatus = "public"
        selfDeclaredMadeForKids = $false
    }
} | ConvertTo-Json -Depth 10 -Compress

$Enc = [System.Text.Encoding]::UTF8
$FileName = Split-Path $ResolvedVideoPath -Leaf

# 組裝 Multipart 字串部分
$HeaderPart = "--$Boundary`r`n" +
              "Content-Disposition: form-data; name=`"snippet`"`r`n" +
              "Content-Type: application/json; charset=UTF-8`r`n`r`n" +
              "$Metadata`r`n" +
              "--$Boundary`r`n" +
              "Content-Disposition: form-data; name=`"media`"; filename=`"$FileName`"`r`n" +
              "Content-Type: video/mp4`r`n`r`n"

$FooterPart = "`r`n--$Boundary--"

$HeaderBytes = $Enc.GetBytes($HeaderPart)
$FooterBytes = $Enc.GetBytes($FooterPart)

# 純位元組拼接 (這是關鍵修正)
$MultipartContent = New-Object byte[] ($HeaderBytes.Length + $VideoBytes.Length + $FooterBytes.Length)
[System.Buffer]::BlockCopy($HeaderBytes, 0, $MultipartContent, 0, $HeaderBytes.Length)
[System.Buffer]::BlockCopy($VideoBytes, 0, $MultipartContent, $HeaderBytes.Length, $VideoBytes.Length)
[System.Buffer]::BlockCopy($FooterBytes, 0, $MultipartContent, $HeaderBytes.Length + $VideoBytes.Length, $FooterBytes.Length)

Write-Host "📡 正在發送上傳請求至 YouTube API..." -ForegroundColor Yellow

$UploadUrl = "https://www.googleapis.com/upload/youtube/v3/videos?part=snippet,status"
$Headers = @{
    "Authorization" = "Bearer $AccessToken"
}

try {
    $UploadResponse = Invoke-RestMethod -Uri $UploadUrl -Method Post -Headers $Headers -Body $MultipartContent -ContentType "multipart/related; boundary=$Boundary"
    Write-Host "✅ 上傳成功！影片 ID：$($UploadResponse.id)" -ForegroundColor Green
    Write-Host "🔗 影片連結：https://youtu.be/$($UploadResponse.id)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ 上傳失敗：$_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $ErrorDetail = $reader.ReadToEnd()
        Write-Host "錯誤詳情：$ErrorDetail" -ForegroundColor Red
    }
}
