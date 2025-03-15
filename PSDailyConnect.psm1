# PSDailyConnect.psm1
# Module functions for interacting with the DailyConnect API

function New-DailyConnectSession {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Email,
        [Parameter(Mandatory = $true)]
        [string]$Password
    )
    $sessionObj = [PSCustomObject]@{
        Email     = $Email
        Password  = $Password
        Session   = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        srf_token = $null  # initialize property for the token
    }
    # Set a common user agent
    $sessionObj.Session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
    return $sessionObj
}

function Invoke-DailyConnectLogin {
    param(
        [Parameter(Mandatory = $true)]
        $DCSession
    )
    $body = "username=$([uri]::EscapeDataString($DCSession.Email))&password=$([uri]::EscapeDataString($DCSession.Password))"
    Write-Verbose "Logging in with $($DCSession.Email)..."
    $authResponse = Invoke-WebRequest -UseBasicParsing `
        -Uri "https://www.dailyconnect.com/Cmd?cmd=UserAuth" `
        -Method "POST" `
        -WebSession $DCSession.Session `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $body

    # Flatten the response content to ensure regex matching works
    $content = $authResponse.Content -replace "`r`n", " "
    if ($content -match "var\s+__srf_token__\s*=\s*'([^']+)'") {
         $DCSession.srf_token = $matches[1]
         Write-Verbose "Extracted token: $($DCSession.srf_token)"
    }
    else {
         Write-Error "Token not found in the authentication response."
         return $false
    }
    
    # Accept either 302 or 200 as success
    if ($authResponse.StatusCode -eq 302 -or $authResponse.StatusCode -eq 200) {
         Write-Verbose "Login successful (StatusCode: $($authResponse.StatusCode))"
         return $true
    }
    else {
         Write-Error "Login failed with status code: $($authResponse.StatusCode)"
         return $false
    }
}

function Get-DailyConnectUserInfo {
    param(
         [Parameter(Mandatory = $true)]
         $DCSession
    )
    Write-Verbose "Requesting user info..."
    $body = "__srf_token__=$($DCSession.srf_token)&cmd=UserInfoW"
    $response = Invoke-WebRequest -UseBasicParsing `
        -Uri "https://www.dailyconnect.com/CmdW?cmd=UserInfoW" `
        -Method "POST" `
        -WebSession $DCSession.Session `
        -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
        -Body $body
    if ($response.StatusCode -eq 200) {
         return $response.Content | ConvertFrom-Json
    }
    else {
         Write-Error "Error retrieving user info. Status code: $($response.StatusCode)"
         return $null
    }
}

function Get-DailyConnectKidSummaryByDay {
    param(
         [Parameter(Mandatory = $true)]
         $DCSession,
         [Parameter(Mandatory = $true)]
         $KidId,
         [Parameter(Mandatory = $true)]
         [datetime]$Date
    )
    $pdt = $Date.ToString("yyMMdd")  # format date as 'yymmdd'
    $body = "__srf_token__=$($DCSession.srf_token)&cmd=KidGetSummary&Kid=$KidId&pdt=$pdt"
    Write-Verbose "Requesting kid summary for KidId: $KidId on date: $pdt..."
    $response = Invoke-WebRequest -UseBasicParsing `
        -Uri "https://www.dailyconnect.com/CmdW" `
        -Method "POST" `
        -WebSession $DCSession.Session `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $body
    if ($response.StatusCode -eq 200) {
         return $response.Content | ConvertFrom-Json
    }
    else {
         Write-Error "Error retrieving kid summary. Status code: $($response.StatusCode)"
         return $null
    }
}

function Get-DailyConnectKidSummary {
    param(
         [Parameter(Mandatory = $true)]
         $DCSession,
         [Parameter(Mandatory = $true)]
         $KidId
    )
    return Get-DailyConnectKidSummaryByDay -DCSession $DCSession -KidId $KidId -Date (Get-Date)
}

function Get-DailyConnectKidStatusByDay {
    param(
         [Parameter(Mandatory = $true)]
         $DCSession,
         [Parameter(Mandatory = $true)]
         $KidId,
         [Parameter(Mandatory = $true)]
         [datetime]$Date
    )
    $pdt = $Date.ToString("yyMMdd")
    $body = "__srf_token__=$($DCSession.srf_token)&cmd=StatusList&Kid=$KidId&pdt=$pdt&fmt=long"
    Write-Verbose "Requesting kid status for KidId: $KidId on date: $pdt..."
    $response = Invoke-WebRequest -UseBasicParsing `
        -Uri "https://www.dailyconnect.com/CmdListW" `
        -Method "POST" `
        -WebSession $DCSession.Session `
        -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
        -Body $body
    if ($response.StatusCode -eq 200) {
         return $response.Content | ConvertFrom-Json
    }
    else {
         Write-Error "Error retrieving kid status. Status code: $($response.StatusCode)"
         return $null
    }
}

function Get-DailyConnectKidStatus {
    param(
         [Parameter(Mandatory = $true)]
         $DCSession,
         [Parameter(Mandatory = $true)]
         $KidId
    )
    return Get-DailyConnectKidStatusByDay -DCSession $DCSession -KidId $KidId -Date (Get-Date)
}

Export-ModuleMember -Function *-DailyConnect*