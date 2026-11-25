# Microsoft Defender for Endpoint - Citrix VDI Onboarding Wrapper
# Waits for successful DNS resolution before initiating onboarding

# Configuration
$DnsName = "edr-weu.eu.endpoint.security.microsoft.com"
$RetryInterval = 10
$TimeoutSeconds = 300
$OnboardingScript = Join-Path $PSScriptRoot "Onboard-NonPersistentMachine.ps1"
$LogDirectory = "C:\ProgramData\MDEOnboarding"
$LogFile = Join-Path $LogDirectory "Onboarding-Wrapper.log"

# Create log directory
New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null

# Logging function
function Write-Log {
    param ([string]$Message)

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$Timestamp - $Message"
}

Write-Log "=================================================="
Write-Log "MDE onboarding wrapper started."
Write-Log "Computer name: $env:COMPUTERNAME"
Write-Log "Execution account: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Log "DNS target: $DnsName"

# Check that the onboarding script exists
if (-not (Test-Path $OnboardingScript)) {
    Write-Log "ERROR: Onboarding script not found: $OnboardingScript"
    exit 1
}

# Start DNS readiness checks
$Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$DnsResolved = $false
$Attempt = 0

while ($Stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {

    $Attempt++

    try {
        $Result = Resolve-DnsName -Name $DnsName `
            -DnsOnly -QuickTimeout -ErrorAction Stop

        $IPAddresses = @(
            $Result | Where-Object { $_.IPAddress } |
                Select-Object -ExpandProperty IPAddress
        )

        if ($IPAddresses.Count -eq 0) {
            throw "No IP addresses returned."
        }

        $DnsResolved = $true
        Write-Log "DNS resolution successful on attempt $Attempt."
        Write-Log "Resolved IP addresses: $($IPAddresses -join ', ')"
        break
    }
    catch {
        Write-Log "DNS attempt $Attempt failed: $($_.Exception.Message)"
        Start-Sleep -Seconds $RetryInterval
    }
}

$ElapsedSeconds = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)
$Stopwatch.Stop()

# Stop if DNS resolution was unsuccessful
if (-not $DnsResolved) {
    Write-Log "ERROR: DNS resolution failed after $ElapsedSeconds seconds."
    Write-Log "MDE onboarding script will not be executed."
    exit 1
}

Write-Log "DNS became available after $ElapsedSeconds seconds."
Write-Log "Starting Microsoft MDE onboarding script."

# Execute the original Microsoft onboarding script
try {
    $PowerShellExe = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    $Process = Start-Process `
        -FilePath $PowerShellExe `
        -ArgumentList "-NoProfile -NonInteractive -File `"$OnboardingScript`"" `
        -WorkingDirectory $PSScriptRoot `
        -Wait `
        -PassThru `
        -ErrorAction Stop

    Write-Log "Onboarding script exited with code: $($Process.ExitCode)"

    if ($Process.ExitCode -ne 0) {
        Write-Log "ERROR: Onboarding script returned a non-zero exit code."
        exit $Process.ExitCode
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    exit 1
}

Write-Log "MDE onboarding script execution completed."
Write-Log "MDE onboarding wrapper finished."
exit 0