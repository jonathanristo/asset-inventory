<#
.SYNOPSIS
    Wrapper script for Get-AssetInventory.ps1 that uses a configuration file.

.DESCRIPTION
    This script loads settings from InventoryConfig.psd1 and runs the asset
    inventory collection with those settings. It can process single or multiple
    computers and handles credential management.

.PARAMETER ConfigPath
    Path to the configuration file. Defaults to InventoryConfig.psd1 in the same directory.

.PARAMETER SaveCredential
    Prompts for and saves SMTP credentials securely for email functionality.

.EXAMPLE
    .\Start-AssetInventory.ps1
    Runs inventory using default configuration file.

.EXAMPLE
    .\Start-AssetInventory.ps1 -ConfigPath "C:\Scripts\CustomConfig.psd1"
    Runs inventory using a custom configuration file.

.EXAMPLE
    .\Start-AssetInventory.ps1 -SaveCredential
    Prompts to save SMTP credentials before running inventory.
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$ConfigPath = (Join-Path $PSScriptRoot "InventoryConfig.psd1"),

    [Parameter()]
    [switch]$SaveCredential
)

# Load configuration
try {
    Write-Host "Loading configuration from: $ConfigPath" -ForegroundColor Cyan
    $config = Import-PowerShellDataFile -Path $ConfigPath -ErrorAction Stop
}
catch {
    Write-Error "Failed to load configuration file: $_"
    exit 1
}

# Credential management
$credentialPath = Join-Path $PSScriptRoot "smtp_credential.xml"
$credential = $null

if ($SaveCredential) {
    Write-Host "`nSaving SMTP Credentials..." -ForegroundColor Yellow
    $credential = Get-Credential -Message "Enter SMTP authentication credentials"
    $credential | Export-Clixml -Path $credentialPath
    Write-Host "Credentials saved to: $credentialPath" -ForegroundColor Green
}
elseif ($config.EmailSettings.Enabled -and (Test-Path $credentialPath)) {
    Write-Host "Loading saved SMTP credentials..." -ForegroundColor Cyan
    $credential = Import-Clixml -Path $credentialPath
}

# Build parameters for the main script
$scriptPath = Join-Path $PSScriptRoot "Get-AssetInventory.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Error "Asset inventory script not found at: $scriptPath"
    exit 1
}

# Determine if we're processing single or multiple computers
$computers = @()

if ($config.Computers) {
    $computers = $config.Computers
    Write-Host "`nProcessing $($computers.Count) computers..." -ForegroundColor Cyan
}
elseif ($config.ComputerName) {
    $computers = @($config.ComputerName)
    Write-Host "`nProcessing computer: $($config.ComputerName)" -ForegroundColor Cyan
}
else {
    $computers = @($env:COMPUTERNAME)
    Write-Host "`nProcessing local computer..." -ForegroundColor Cyan
}

# Create output directory if it doesn't exist
if (-not (Test-Path $config.OutputPath)) {
    Write-Host "Creating output directory: $($config.OutputPath)" -ForegroundColor Yellow
    New-Item -Path $config.OutputPath -ItemType Directory -Force | Out-Null
}

# Process each computer
$results = @()
$successCount = 0
$failCount = 0

foreach ($computer in $computers) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Processing: $computer" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    try {
        # Build parameter hashtable
        $params = @{
            ComputerName = $computer
            OutputPath = $config.OutputPath
            OutputFormat = $config.OutputFormat
        }

        # Add optional parameters
        if ($config.IncludeSoftware) {
            $params.Add('IncludeSoftware', $true)
        }

        if ($config.WebcamModel) {
            $params.Add('WebcamModel', $config.WebcamModel)
        }

        # Add email parameters if enabled
        if ($config.EmailSettings.Enabled) {
            $params.Add('EmailResults', $true)
            $params.Add('EmailTo', $config.EmailSettings.To)
            $params.Add('EmailFrom', $config.EmailSettings.From)
            $params.Add('SmtpServer', $config.EmailSettings.SmtpServer)
            $params.Add('SmtpPort', $config.EmailSettings.SmtpPort)

            if ($config.EmailSettings.UseSsl) {
                $params.Add('UseSsl', $true)
            }

            if ($credential) {
                $params.Add('Credential', $credential)
            }
        }

        # Add verbose output if configured
        if ($config.VerboseOutput) {
            $params.Add('Verbose', $true)
        }

        # Run the inventory script
        $result = & $scriptPath @params

        $results += [PSCustomObject]@{
            ComputerName = $computer
            Status = "Success"
            Timestamp = Get-Date
            Result = $result
        }

        $successCount++
        Write-Host "`n[SUCCESS] Inventory completed for $computer" -ForegroundColor Green

    }
    catch {
        $results += [PSCustomObject]@{
            ComputerName = $computer
            Status = "Failed"
            Timestamp = Get-Date
            Error = $_.Exception.Message
        }

        $failCount++
        Write-Host "`n[ERROR] Failed to inventory $computer : $_" -ForegroundColor Red
    }
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "INVENTORY COLLECTION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Computers: $($computers.Count)" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "White" })
Write-Host "Output Location: $($config.OutputPath)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Export summary report
$summaryPath = Join-Path $config.OutputPath "InventorySummary_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$results | Export-Csv -Path $summaryPath -NoTypeInformation
Write-Host "`nSummary report saved to: $summaryPath" -ForegroundColor Cyan

# Return results object
return $results
