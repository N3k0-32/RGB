param(
    [Parameter(Position=0)]
    [string]$ipAddress = $(if ($args.Length -gt 0) { $args[0] } else { Read-Host -Prompt "請輸入目標 IP 地址" }),
    
    [Alias("i")]
    [int]$interval = 1000,   # 初始間隔時間
    
    [Alias("min")]
    [int]$minInterval = 10,  # 最小間隔時間
    
    [Alias("max")]
    [int]$maxInterval = 1000, # 最大間隔時間
    
    [Alias("d")]
    [ValidateSet("down","up")]
    [string]$direction = "down",  # 初始方向
    
    [Alias("w")]
    [int]$waitTime = 1000    # 達到極值後等待時間
)

if ($ipAddress -eq '--help' -or $args -contains '--help') {
    Write-Host "RGB 腳本說明:" -ForegroundColor Green
    Write-Host "用法: .\rgb.ps1 <目標 IP 位址> <參數>"
    Write-Host ""
    Write-Host "參數:"
    Write-Host "  -i       初始間隔時間，預設為 1000 ms"
    Write-Host "  -min     最小間隔時間，預設為 10 ms"
    Write-Host "  -max     最大間隔時間，預設為 1000 ms"
    Write-Host "  -d       初始方向，可選值 'down' 或 'up'，預設為 down"
    Write-Host "  -w       達到極值時的等待時間，預設為 1000 ms"
    Write-Host ""
    Write-Host "範例:"
    Write-Host "  .\rgb.ps1 192.168.1.1 -i 500 -min 50 -max 1000 -d up -w 2000"
    exit
}

# 定義要請求的 URL 列表
$urls = @(
    "http://$ipAddress/L0",
    "http://$ipAddress/L1",
    "http://$ipAddress/L2"
)

# 輸出 ASCII Art
$asciiArt = @"

██████╗  ██████╗ ██████╗ 
██╔══██╗██╔════╝ ██╔══██╗
██████╔╝██║  ███╗██████╔╝
██╔══██╗██║   ██║██╔══██╗
██║  ██║╚██████╔╝██████╔╝
╚═╝  ╚═╝ ╚═════╝ ╚═════╝ 

"@
Write-Host $asciiArt -ForegroundColor Green

# 顯示開始信息
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "開始對" -ForegroundColor Cyan -NoNewline; Write-Host " $ipAddress " -ForegroundColor Yellow -NoNewline; Write-Host "進行 RGB 攻擊" -ForegroundColor Cyan
Write-Host "初始間隔：" -ForegroundColor Cyan -NoNewline; Write-Host "$interval ms" -ForegroundColor Yellow
Write-Host "最小間隔："-ForegroundColor Cyan -NoNewline; Write-Host "$minInterval ms" -ForegroundColor Yellow
Write-Host "最大間隔：" -ForegroundColor Cyan -NoNewline; Write-Host "$maxInterval ms" -ForegroundColor Yellow
Write-Host "達到極值時將持續請求" -ForegroundColor Cyan -NoNewline; Write-Host " $($waitTime / 1000) 秒" -ForegroundColor Yellow -NoNewline; Write-Host "，然後改變方向" -ForegroundColor Cyan
Write-Host "按" -ForegroundColor Cyan -NoNewline; Write-Host " Ctrl+C " -ForegroundColor Yellow -NoNewline; Write-Host "停止腳本" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

# 定義發送請求的函數
function Send-Request {
    param (
        [string]$url,
        [int]$currentInterval,
        [string]$currentDirection
    )
    
    $directionArrow = if ($currentDirection -eq "down") { "↓" } else { "↑" }
    
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing
        if ($response.StatusCode -ne 200) {
            Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - 請求 $url - 狀態碼: $($response.StatusCode) - 間隔: $currentInterval ms $directionArrow"
        }
    }
    catch {
        Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - 請求 $url - 錯誤: $($_.Exception.Message) - 間隔: $currentInterval ms $directionArrow" -ForegroundColor Red
    }
}

# 無限循環執行
while ($true) {
    foreach ($url in $urls) {
        # 發送請求
        Send-Request -url $url -currentInterval $interval -currentDirection $direction
        
        # 暫停指定的間隔時間
        Start-Sleep -Milliseconds $interval
        
        # 根據當前方向調整間隔時間
        if ($direction -eq "down") {
            # 縮短間隔時間
            $interval = [math]::Max($minInterval, $interval * 0.9)
            
            # 檢查是否達到最小值
            if ($interval -eq $minInterval) {
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - 達到最小間隔 $minInterval ms，$($waitTime / 1000) 秒後開始增加間隔..." -ForegroundColor Yellow
                
                # 在等待期間繼續發送請求
                $startTime = Get-Date
                while ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalMilliseconds -lt $waitTime) {
                    foreach ($waitUrl in $urls) {
                        Send-Request -url $waitUrl -currentInterval $interval -currentDirection $direction
                        Start-Sleep -Milliseconds $interval
                    }
                }
                
                $direction = "up"
            }
        }
        else {
            # 增加間隔時間
            $interval = [math]::Min($maxInterval, $interval / 0.9)
            
            # 檢查是否達到最大值
            if ($interval -eq $maxInterval) {
                Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') - 達到最大間隔 $maxInterval ms，$($waitTime / 1000) 秒後開始減少間隔..." -ForegroundColor Yellow
                
                # 在等待期間繼續發送請求
                $startTime = Get-Date
                while ((New-TimeSpan -Start $startTime -End (Get-Date)).TotalMilliseconds -lt $waitTime) {
                    foreach ($waitUrl in $urls) {
                        Send-Request -url $waitUrl -currentInterval $interval -currentDirection $direction
                        Start-Sleep -Milliseconds $interval
                    }
                }
                
                $direction = "down"
            }
        }
    }
}
