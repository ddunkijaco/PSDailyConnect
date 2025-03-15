# PSDailyConnect PowerShell Module

The **PSDailyConnect** module provides a set of functions for interacting with the DailyConnect API. This module allows you to authenticate with DailyConnect, retrieve user information (including details about your kids), and get daily summaries and statuses for each kid.

## Features

- **Authentication:** Log in with your DailyConnect credentials.
- **User Information:** Retrieve your account information, including kid details (under the `myKids` property).
- **Kid Summary:** Get daily summaries for each kid.
- **Kid Status:** Retrieve daily status for each kid.

## Installation

Clone or download the repository from GitHub:

```bash
git clone https://github.com/yourusername/PSDailyConnect.git
```

Place the `PSDailyConnect` folder (which contains `PSDailyConnect.psm1` and the optional manifest `PSDailyConnect.psd1`) into one of your PowerShell module directories, for example:

```
$env:USERPROFILE\Documents\WindowsPowerShell\Modules\PSDailyConnect
```

## Usage

Import the module into your PowerShell session:

```powershell
Import-Module PSDailyConnect
```

### Example

Below is an example script demonstrating how to use the module:

```powershell
# Create a new DailyConnect session object with your credentials
$dcSession = New-DailyConnectSession -Email "your.email@example.com" -Password "yourPassword"

# Log in to DailyConnect
if (Invoke-DailyConnectLogin -DCSession $dcSession) {
    Write-Host "Logged in successfully!"
} else {
    Write-Error "Login failed."
    exit
}

# Retrieve user information (includes kid details under "myKids")
$userInfo = Get-DailyConnectUserInfo -DCSession $dcSession
$userInfo | ConvertTo-Json -Depth 10 | Write-Output

# Iterate through each kid and display their summary and status
if ($userInfo.myKids -and $userInfo.myKids.Count -gt 0) {
    foreach ($kid in $userInfo.myKids) {
        Write-Host "---------------------------------------------"
        Write-Host "Processing Kid: $($kid.Name) (ID: $($kid.Id))"
        
        $summary = Get-DailyConnectKidSummary -DCSession $dcSession -KidId $kid.Id
        Write-Host "Kid Summary:"
        $summary | ConvertTo-Json -Depth 10 | Write-Output

        $status = Get-DailyConnectKidStatus -DCSession $dcSession -KidId $kid.Id
        Write-Host "Kid Status:"
        $status | ConvertTo-Json -Depth 10 | Write-Output
    }
} else {
    Write-Error "No kids found in user info."
}
```

## Module Functions

- **New-DailyConnectSession**  
  Creates a new session object with your DailyConnect email, password, and a web session.

- **Invoke-DailyConnectLogin**  
  Authenticates using the session object and extracts the required `__srf_token__`.

- **Get-DailyConnectUserInfo**  
  Retrieves user details (including kid information) from DailyConnect.

- **Get-DailyConnectKidSummaryByDay**  
  Retrieves a kid's summary for a specified day (formatted as `yymmdd`).

- **Get-DailyConnectKidSummary**  
  Retrieves a kid's summary for today.

- **Get-DailyConnectKidStatusByDay**  
  Retrieves a kid's status for a specified day.

- **Get-DailyConnectKidStatus**  
  Retrieves a kid's status for today.

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with any improvements or bug fixes.

## License

This project is licensed under the MIT License.