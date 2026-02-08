<#
.SYNOPSIS
    Network-aware asset inventory scanner with range scanning capabilities.

.DESCRIPTION
    Modern asset inventory tool that can:
    - Scan network ranges (CIDR, IP ranges, subnets)
    - Discover active computers
    - Collect comprehensive inventory
    - Export to JSON, XML, or CSV
    - Process multiple computers in parallel

.PARAMETER ScanNetwork
    Enable network scanning mode.

.PARAMETER IPRange
    IP range in CIDR notation (e.g., "192.168.1.0/24").

.PARAMETER StartIP
    Starting IP for range scan.

.PARAMETER EndIP
    Ending IP for range scan.

.PARAMETER Subnet
    Subnet to scan (e.g., "192.168.1" scans .1-.254).

.PARAMETER ComputerName
    Specific computer name(s) to inventory.

.PARAMETER ComputerListFile
    File containing list of computer names (one per line).

.PARAMETER OutputPath
    Directory for output files.

.PARAMETER OutputFormat
    Output format: JSON, XML, or CSV. Default is JSON.

.PARAMETER IncludeSoftware
    Include installed software inventory.

.PARAMETER IncludeUpdates
    Include Windows Update history.

.PARAMETER IncludeShares
    Include network shares.

.PARAMETER IncludeServices
    Include running services.

.PARAMETER MaxThreads
    Maximum parallel threads. Default is 20.

.PARAMETER Credential
    Credentials for remote access.

.PARAMETER QuickScan
    Quick scan mode (skip detailed port scanning).

.EXAMPLE
    .\Invoke-AssetInventory.ps1 -ScanNetwork -IPRange "192.168.1.0/24" -OutputFormat JSON

.EXAMPLE
    .\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "10.0.1" -IncludeSoftware -OutputFormat CSV

.EXAMPLE
    .\Invoke-AssetInventory.ps1 -ComputerName "PC01","PC02","PC03" -OutputFormat JSON

.EXAMPLE
    .\Invoke-AssetInventory.ps1 -ComputerListFile "computers.txt" -IncludeAll -OutputFormat XML

.EXAMPLE
    .\Invoke-AssetInventory.ps1 -ScanNetwork -StartIP "192.168.1.1" -EndIP "192.168.1.50" -QuickScan
#>

[CmdletBinding(DefaultParameterSetName = 'ComputerList')]
param (
    [Parameter(ParameterSetName = 'NetworkCIDR')]
    [Parameter(ParameterSetName = 'NetworkRange')]
    [Parameter(ParameterSetName = 'NetworkSubnet')]
    [switch]$ScanNetwork,

    [Parameter(ParameterSetName = 'NetworkCIDR', Mandatory = $true)]
    [string]$IPRange,

    [Parameter(ParameterSetName = 'NetworkRange', Mandatory = $true)]
    [string]$StartIP,

    [Parameter(ParameterSetName = 'NetworkRange', Mandatory = $true)]
    [string]$EndIP,

    [Parameter(ParameterSetName = 'NetworkSubnet', Mandatory = $true)]
    [string]$Subnet,

    [Parameter(ParameterSetName = 'ComputerList')]
    [string[]]$ComputerName,

    [Parameter(ParameterSetName = 'FileList')]
    [ValidateScript({ Test-Path $_ })]
    [string]$ComputerListFile,

    [Parameter()]
    [string]$OutputPath = ".\Inventory",

    [Parameter()]
    [ValidateSet('JSON', 'XML', 'CSV')]
    [string]$OutputFormat = 'JSON',

    [Parameter()]
    [switch]$IncludeSoftware,

    [Parameter()]
    [switch]$IncludeUpdates,

    [Parameter()]
    [switch]$IncludeShares,

    [Parameter()]
    [switch]$IncludeServices,

    [Parameter()]
    [switch]$IncludeAll,

    [Parameter()]
    [int]$MaxThreads = 20,

    [Parameter()]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter()]
    [switch]$QuickScan
)

#Requires -Version 5.1

# Import the module
$modulePath = Join-Path $PSScriptRoot "AssetInventory.psm1"
if (-not (Test-Path $modulePath)) {
    Write-Error "Module not found at: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Banner
Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        ASSET INVENTORY SCANNER v3.0                       ║
║        Network Discovery & Inventory Collection          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "[+] Created output directory: $OutputPath" -ForegroundColor Green
}

# Build target list
$targetComputers = @()

if ($ScanNetwork) {
    Write-Host "`n[*] PHASE 1: Network Discovery" -ForegroundColor Yellow
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
    
    $discoveryParams = @{
        MaxThreads = $MaxThreads
    }
    
    if (-not $QuickScan) {
        $discoveryParams.TestPort = @(135, 445, 3389, 5985)
    }
    
    switch ($PSCmdlet.ParameterSetName) {
        'NetworkCIDR' {
            $discoveryParams.IPRange = $IPRange
            Write-Host "[*] Scanning CIDR: $IPRange"
        }
        'NetworkRange' {
            $discoveryParams.StartIP = $StartIP
            $discoveryParams.EndIP = $EndIP
            Write-Host "[*] Scanning range: $StartIP - $EndIP"
        }
        'NetworkSubnet' {
            $discoveryParams.Subnet = $Subnet
            Write-Host "[*] Scanning subnet: $Subnet.0/24"
        }
    }
    
    $discoveredHosts = Find-NetworkComputers @discoveryParams
    
    # Filter hosts with SMB or WinRM open for inventory
    $targetComputers = $discoveredHosts | Where-Object {
        $_.SMBOpen -or $_.WinRMOpen
    } | ForEach-Object {
        if ($_.Hostname -ne 'Unknown') {
            $_.Hostname
        } else {
            $_.IPAddress
        }
    }
    
    Write-Host "`n[+] Discovery complete!" -ForegroundColor Green
    Write-Host "    Total hosts found: $($discoveredHosts.Count)" -ForegroundColor White
    Write-Host "    Accessible for inventory: $($targetComputers.Count)" -ForegroundColor White
    
    # Export discovery results
    $discoveryFile = "NetworkDiscovery_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $discoveredHosts | Export-Csv -Path (Join-Path $OutputPath $discoveryFile) -NoTypeInformation
    Write-Host "    Discovery results saved to: $discoveryFile" -ForegroundColor Cyan
}
elseif ($ComputerListFile) {
    Write-Host "[*] Loading computers from file: $ComputerListFile" -ForegroundColor Cyan
    $targetComputers = Get-Content $ComputerListFile | Where-Object { $_ -and $_ -notmatch '^\s*#' }
    Write-Host "[+] Loaded $($targetComputers.Count) computers" -ForegroundColor Green
}
elseif ($ComputerName) {
    $targetComputers = $ComputerName
    Write-Host "[*] Processing $($targetComputers.Count) specified computer(s)" -ForegroundColor Cyan
}
else {
    $targetComputers = @($env:COMPUTERNAME)
    Write-Host "[*] Processing local computer only" -ForegroundColor Cyan
}

if ($targetComputers.Count -eq 0) {
    Write-Host "`n[!] No target computers found. Exiting." -ForegroundColor Red
    exit 0
}

# Phase 2: Inventory Collection
Write-Host "`n[*] PHASE 2: Inventory Collection" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "[*] Collecting inventory from $($targetComputers.Count) computer(s)..." -ForegroundColor Cyan
Write-Host "[*] Output format: $OutputFormat" -ForegroundColor Cyan

# Build inventory parameters
$inventoryParams = @{
    ErrorAction = 'Continue'
}

if ($IncludeAll) {
    $IncludeSoftware = $true
    $IncludeUpdates = $true
    $IncludeShares = $true
    $IncludeServices = $true
}

if ($IncludeSoftware) { $inventoryParams.IncludeSoftware = $true }
if ($IncludeUpdates) { $inventoryParams.IncludeUpdates = $true }
if ($IncludeShares) { $inventoryParams.IncludeShares = $true }
if ($IncludeServices) { $inventoryParams.IncludeServices = $true }
if ($Credential) { $inventoryParams.Credential = $Credential }

# Progress tracking
$completed = 0
$failed = 0
$inventoryData = @()

# Collect inventory from each computer
$targetComputers | ForEach-Object -ThrottleLimit $MaxThreads -Parallel {
    $computer = $_
    $params = $using:inventoryParams
    
    # Import module in parallel thread
    $modulePath = $using:modulePath
    Import-Module $modulePath -Force
    
    Write-Host "    [>] Processing: $computer" -ForegroundColor Gray
    
    try {
        $inventory = Get-ComputerInventory -ComputerName $computer @params -Verbose:$false
        
        if ($inventory) {
            Write-Host "    [✓] Success: $computer" -ForegroundColor Green
            $inventory
        }
        else {
            Write-Host "    [✗] Failed: $computer (no data returned)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "    [✗] Failed: $computer - $($_.Exception.Message)" -ForegroundColor Red
    }
} | ForEach-Object {
    $inventoryData += $_
    $completed++
    
    $progress = [math]::Round(($completed / $targetComputers.Count) * 100, 0)
    Write-Progress -Activity "Collecting Inventory" -Status "$completed of $($targetComputers.Count) completed ($progress%)" -PercentComplete $progress
}

Write-Progress -Activity "Collecting Inventory" -Completed

$failed = $targetComputers.Count - $inventoryData.Count

# Summary
Write-Host "`n[*] COLLECTION SUMMARY" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow
Write-Host "    Total targets: $($targetComputers.Count)" -ForegroundColor White
Write-Host "    Successful: $($inventoryData.Count)" -ForegroundColor Green
Write-Host "    Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "White" })

if ($inventoryData.Count -eq 0) {
    Write-Host "`n[!] No inventory data collected. Exiting." -ForegroundColor Red
    exit 1
}

# Phase 3: Export Data
Write-Host "`n[*] PHASE 3: Export" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Yellow

$exportedFile = $inventoryData | Export-InventoryData -OutputPath $OutputPath -Format $OutputFormat -FileNamePrefix "AssetInventory"

# Generate summary report
Write-Host "`n[*] Generating summary report..." -ForegroundColor Cyan

$summary = @{
    ScanDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    TotalTargets = $targetComputers.Count
    SuccessfulInventories = $inventoryData.Count
    FailedInventories = $failed
    OutputFormat = $OutputFormat
    OutputLocation = $OutputPath
    IncludedSoftware = $IncludeSoftware.IsPresent
    IncludedUpdates = $IncludeUpdates.IsPresent
    IncludedShares = $IncludeShares.IsPresent
    IncludedServices = $IncludeServices.IsPresent
    Computers = $inventoryData | ForEach-Object {
        @{
            Name = $_.ComputerName
            Manufacturer = $_.System.Manufacturer
            Model = $_.System.Model
            SerialNumber = $_.System.SerialNumber
            OS = $_.OperatingSystem.Name
            MemoryGB = $_.System.TotalMemoryGB
        }
    }
}

$summaryFile = "Summary_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$summaryPath = Join-Path $OutputPath $summaryFile
$summary | ConvertTo-Json -Depth 5 | Out-File -FilePath $summaryPath -Encoding UTF8

Write-Host "[+] Summary report: $summaryFile" -ForegroundColor Green

# Final output
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "║                  SCAN COMPLETE!                           ║" -ForegroundColor Green
Write-Host "║                                                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`nOutput files saved to: $OutputPath" -ForegroundColor Cyan
Write-Host "Primary inventory file: $(Split-Path $exportedFile -Leaf)" -ForegroundColor Cyan

# Return inventory data object
return $inventoryData
