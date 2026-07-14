# Campus Auto Login - sanitized version
# 凭据从 config.ps1 加载，请勿直接修改此文件中的凭据

$PortalHost = '202.113.48.21'
$LogFile    = "$env:USERPROFILE\Desktop\campus_auth_log.txt"

# 加载个人配置
$ConfigPath = Join-Path $PSScriptRoot 'config.ps1'
if (Test-Path $ConfigPath) {
    . $ConfigPath
} else {
    Write-Host "[ERROR] 未找到 config.ps1，请复制 config.example.ps1 并填写凭据"
    exit 1
}

Add-Type -AssemblyName System.Web
$Service = [System.Web.HttpUtility]::UrlEncode([System.Web.HttpUtility]::UrlEncode('校园网'))
$PasswordEnc = [System.Web.HttpUtility]::UrlEncode([System.Web.HttpUtility]::UrlEncode($Password))

function Write-Log {
    param([string]$Msg)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts - $Msg" | Out-File $LogFile -Append -Encoding UTF8
    Write-Host "$ts - $Msg"
}

function Show-Popup {
    param([string]$Text, [string]$Title, [string]$Type)
    try {
        $pop = New-Object -ComObject Wscript.Shell
        $btn = if ($Type -eq 'info') { 0 + 64 } elseif ($Type -eq 'error') { 0 + 16 } else { 0 + 48 }
        $pop.Popup($Text, 0, $Title, $btn)
    } catch {}
}

Write-Log '===== Campus Auto Login ====='
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
[System.Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Start-Sleep -Seconds 8

function Get-QueryString {
    $req = [System.Net.WebRequest]::Create('http://www.baidu.com')
    $req.Timeout = 10000
    $req.AllowAutoRedirect = $false
    $resp = $req.GetResponse()
    $code = [int]$resp.StatusCode
    if ($code -ne 200) { $resp.Close(); return $null }
    $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
    $body = $reader.ReadToEnd(); $reader.Close(); $resp.Close()
    if ($body -match 'baidu\.com') { return 'ONLINE' }
    $idx = $body.IndexOf("location.href='")
    if ($idx -lt 0) { return $null }
    $url = $body.Substring($idx + 15, $body.IndexOf("'", $idx + 15) - $idx - 15)
    $qIdx = $url.IndexOf('?')
    if ($qIdx -lt 0) { return $null }
    return $url.Substring($qIdx + 1)
}

$qs = ''
try { $qs = Get-QueryString } catch { Write-Log "Error: $($_.Exception.Message)" }
if ($qs -eq 'ONLINE') { Write-Log 'Already online'; Show-Popup '校园网已连接' 'Campus Auto Login' 'info'; exit 0 }
if (-not $qs) { Write-Log 'No queryString'; Show-Popup '无法获取网络信息' 'Campus Auto Login' 'error'; exit 1 }

$qsEncoded = [System.Web.HttpUtility]::UrlEncode($qs)
Write-Log "Got queryString, length: $($qs.Length)"

# pageInfo
try {
    $r = Invoke-WebRequest -Uri "http://${PortalHost}/eportal/InterFace.do?method=pageInfo" -Method Post -Body "queryString=$qsEncoded" -UseBasicParsing -TimeoutSec 15 -ContentType 'application/x-www-form-urlencoded; charset=UTF-8'
    Write-Log 'pageInfo OK'
} catch { Write-Log "pageInfo: $($_.Exception.Message)" }

# getServices
try {
    $r = Invoke-WebRequest -Uri "http://${PortalHost}/eportal/InterFace.do?method=getServices&queryString=$qsEncoded" -Method Post -Body '' -UseBasicParsing -TimeoutSec 15
    Write-Log 'getServices OK'
} catch { Write-Log "getServices: $($_.Exception.Message)" }

# Login
try {
    $loginBody = "userId=$Username&password=$PasswordEnc&service=$Service&queryString=$qsEncoded&operatorPwd=&operatorUserId=&validcode=&passwordEncrypt=false"
    Write-Log 'Submitting login...'
    $resp = Invoke-WebRequest -Uri "http://${PortalHost}/eportal/InterFace.do?method=login" -Method Post -Body $loginBody -UseBasicParsing -TimeoutSec 15 -ContentType 'application/x-www-form-urlencoded; charset=UTF-8'
    $content = $resp.Content
    Write-Log "Response: $content"
    if ($content -match '"result":"success"') { $ok = $true; Write-Log 'LOGIN SUCCESS!' }
    else { $ok = $false; Show-Popup "登录失败：$($content -replace '.*"message":"([^"]*)".*','$1')" 'Campus Auto Login' 'error' }
} catch { Write-Log "Login error: $($_.Exception.Message)"; $ok = $false; Show-Popup "登录请求失败：$($_.Exception.Message)" 'Campus Auto Login' 'error' }

if ($ok) {
    Start-Sleep -Seconds 5
    for ($i=0; $i -lt 5; $i++) {
        try { $check = Get-QueryString; if ($check -eq 'ONLINE') { Write-Log 'NETWORK CONNECTED!'; Show-Popup '校园网已自动登录成功!' 'Campus Auto Login' 'info'; exit 0 } } catch {}
        Start-Sleep -Seconds 3
    }
    Write-Log 'Auth sent, waiting'
} else { Write-Log 'Login failed'; Show-Popup '校园网登录已发送，请手动检查网络' 'Campus Auto Login' 'warning' }

Write-Log '===== End ====='