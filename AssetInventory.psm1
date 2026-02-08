<#
.SYNOPSIS
    AssetInventory PowerShell Module - Reusable functions for asset discovery and inventory.

.DESCRIPTION
    This module provides functions for:
    - Network scanning and discovery
    - Computer inventory collection
    - Asset data export
    - Remote computer management

.NOTES
    Author: Modernized Asset Inventory Module
    Version: 3.0
    Requires: PowerShell 5.1 or later
#>

#region Network Discovery Functions

function Find-NetworkComputers {
    <#
    .SYNOPSIS
        Scans network ranges to discover active computers.
    
    .DESCRIPTION
        Performs ping sweeps and optional port scans to discover computers.
        Returns list of responsive hosts with basic information.
    
    .PARAMETER IPRange
        IP address range in CIDR notation (e.g., "192.168.1.0/24") or as array of IPs.
    
    .PARAMETER StartIP
        Starting IP address for range scan.
    
    .PARAMETER EndIP
        Ending IP address for range scan.
    
    .PARAMETER Subnet
        Subnet to scan (e.g., "192.168.1").
    
    .PARAMETER TestPort
        Test specific ports (135, 445, 5985 common for Windows).
    
    .PARAMETER Timeout
        Ping timeout in milliseconds. Default is 1000.
    
    .PARAMETER MaxThreads
        Maximum parallel threads. Default is 50.
    
    .EXAMPLE
        Find-NetworkComputers -IPRange "192.168.1.0/24"
    
    .EXAMPLE
        Find-NetworkComputers -StartIP "10.0.1.1" -EndIP "10.0.1.254" -TestPort 445
    
    .EXAMPLE
        Find-NetworkComputers -Subnet "192.168.1" -Timeout 500
    #>
    [CmdletBinding(DefaultParameterSetName = 'CIDR')]
    param (
        [Parameter(ParameterSetName = 'CIDR', Mandatory = $true)]
        [string]$IPRange,

        [Parameter(ParameterSetName = 'Range', Mandatory = $true)]
        [string]$StartIP,

        [Parameter(ParameterSetName = 'Range', Mandatory = $true)]
        [string]$EndIP,

        [Parameter(ParameterSetName = 'Subnet', Mandatory = $true)]
        [string]$Subnet,

        [Parameter()]
        [int[]]$TestPort = @(445, 135, 5985),

        [Parameter()]
        [int]$Timeout = 1000,

        [Parameter()]
        [int]$MaxThreads = 50
    )

    Write-Host "[*] Starting network discovery..." -ForegroundColor Cyan

    # Generate IP list based on parameter set
    $ipList = switch ($PSCmdlet.ParameterSetName) {
        'CIDR' {
            Get-IPsFromCIDR -CIDR $IPRange
        }
        'Range' {
            Get-IPsFromRange -Start $StartIP -End $EndIP
        }
        'Subnet' {
            1..254 | ForEach-Object { "$Subnet.$_" }
        }
    }

    Write-Host "[*] Scanning $($ipList.Count) IP addresses..." -ForegroundColor Cyan

    # Parallel ping sweep
    $activeHosts = $ipList | ForEach-Object -Parallel {
        $ip = $_
        $timeout = $using:Timeout
        
        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds ($timeout / 1000)
        
        if ($ping) {
            [PSCustomObject]@{
                IPAddress = $ip
                Status = 'Alive'
                Timestamp = Get-Date
            }
        }
    } -ThrottleLimit $MaxThreads

    Write-Host "[+] Found $($activeHosts.Count) active hosts" -ForegroundColor Green

    # Port scanning on active hosts
    if ($TestPort) {
        Write-Host "[*] Testing ports on active hosts..." -ForegroundColor Cyan
        
        $detailedHosts = $activeHosts | ForEach-Object -Parallel {
            $ip = $_.IPAddress
            $ports = $using:TestPort
            
            $portResults = foreach ($port in $ports) {
                $tcpClient = New-Object System.Net.Sockets.TcpClient
                try {
                    $connect = $tcpClient.BeginConnect($ip, $port, $null, $null)
                    $wait = $connect.AsyncWaitHandle.WaitOne(1000, $false)
                    
                    if ($wait) {
                        $tcpClient.EndConnect($connect)
                        [PSCustomObject]@{
                            Port = $port
                            Status = 'Open'
                        }
                    }
                    else {
                        [PSCustomObject]@{
                            Port = $port
                            Status = 'Closed'
                        }
                    }
                }
                catch {
                    [PSCustomObject]@{
                        Port = $port
                        Status = 'Filtered'
                    }
                }
                finally {
                    $tcpClient.Close()
                }
            }
            
            # Try to resolve hostname
            $hostname = try {
                [System.Net.Dns]::GetHostEntry($ip).HostName
            }
            catch {
                'Unknown'
            }
            
            [PSCustomObject]@{
                IPAddress = $ip
                Hostname = $hostname
                Status = 'Alive'
                Ports = $portResults
                SMBOpen = ($portResults | Where-Object { $_.Port -eq 445 -and $_.Status -eq 'Open' }) -ne $null
                WinRMOpen = ($portResults | Where-Object { $_.Port -eq 5985 -and $_.Status -eq 'Open' }) -ne $null
                Timestamp = Get-Date
            }
        } -ThrottleLimit $MaxThreads
        
        return $detailedHosts
    }
    
    return $activeHosts
}

function Get-IPsFromCIDR {
    <#
    .SYNOPSIS
        Converts CIDR notation to list of IP addresses.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$CIDR
    )

    $networkInfo = $CIDR -split '/'
    $ipAddress = $networkInfo[0]
    $prefixLength = [int]$networkInfo[1]

    # Convert IP to binary
    $ipBytes = [System.Net.IPAddress]::Parse($ipAddress).GetAddressBytes()
    [array]::Reverse($ipBytes)
    $ipInt = [System.BitConverter]::ToUInt32($ipBytes, 0)

    # Calculate network range
    $mask = [uint32]([math]::Pow(2, 32) - [math]::Pow(2, (32 - $prefixLength)))
    $networkInt = $ipInt -band $mask
    $hostCount = [math]::Pow(2, (32 - $prefixLength)) - 2

    # Generate IP list (skip network and broadcast)
    $ipList = 1..$hostCount | ForEach-Object {
        $hostInt = $networkInt + $_
        $bytes = [System.BitConverter]::GetBytes($hostInt)
        [array]::Reverse($bytes)
        ([System.Net.IPAddress]$bytes).ToString()
    }

    return $ipList
}

function Get-IPsFromRange {
    <#
    .SYNOPSIS
        Generates list of IPs from start to end range.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Start,
        
        [Parameter(Mandatory = $true)]
        [string]$End
    )

    $startBytes = [System.Net.IPAddress]::Parse($Start).GetAddressBytes()
    [array]::Reverse($startBytes)
    $startInt = [System.BitConverter]::ToUInt32($startBytes, 0)

    $endBytes = [System.Net.IPAddress]::Parse($End).GetAddressBytes()
    [array]::Reverse($endBytes)
    $endInt = [System.BitConverter]::ToUInt32($endBytes, 0)

    $ipList = $startInt..$endInt | ForEach-Object {
        $bytes = [System.BitConverter]::GetBytes($_)
        [array]::Reverse($bytes)
        ([System.Net.IPAddress]$bytes).ToString()
    }

    return $ipList
}

#endregion

#region Inventory Collection Functions

function Get-ComputerInventory {
    <#
    .SYNOPSIS
        Collects comprehensive computer inventory.
    
    .DESCRIPTION
        Gathers hardware, software, and configuration information from local or remote computers.
        Returns structured data suitable for JSON/XML/CSV export.
    
    .PARAMETER ComputerName
        Computer name or IP address.
    
    .PARAMETER IncludeSoftware
        Include installed software inventory.
    
    .PARAMETER IncludeUpdates
        Include Windows Update information.
    
    .PARAMETER IncludeShares
        Include network shares.
    
    .PARAMETER IncludeServices
        Include running services.
    
    .PARAMETER Credential
        PSCredential for remote access.
    
    .EXAMPLE
        Get-ComputerInventory -ComputerName "PC01"
    
    .EXAMPLE
        Get-ComputerInventory -ComputerName "192.168.1.100" -IncludeSoftware -IncludeUpdates
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ComputerName,

        [Parameter()]
        [switch]$IncludeSoftware,

        [Parameter()]
        [switch]$IncludeUpdates,

        [Parameter()]
        [switch]$IncludeShares,

        [Parameter()]
        [switch]$IncludeServices,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )

    begin {
        $sessionParams = @{
            ComputerName = $ComputerName
            ErrorAction = 'Stop'
        }
        
        if ($Credential) {
            $sessionParams.Credential = $Credential
        }
    }

    process {
        try {
            Write-Verbose "Collecting inventory from $ComputerName..."

            # Test connectivity first
            if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
                throw "Cannot reach $ComputerName"
            }

            # Collect basic system info
            $inventory = [ordered]@{
                ComputerName = $ComputerName
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }

            # System Information
            $cs = Get-CimInstance -ClassName Win32_ComputerSystem @sessionParams
            $bios = Get-CimInstance -ClassName Win32_BIOS @sessionParams
            $os = Get-CimInstance -ClassName Win32_OperatingSystem @sessionParams
            $cpu = Get-CimInstance -ClassName Win32_Processor @sessionParams | Select-Object -First 1
            $gpu = Get-CimInstance -ClassName Win32_VideoController @sessionParams

            $inventory.System = @{
                Manufacturer = $cs.Manufacturer
                Model = $cs.Model
                SerialNumber = $bios.SerialNumber
                BIOSVersion = $bios.SMBIOSBIOSVersion
                Domain = $cs.Domain
                CurrentUser = $cs.UserName
                TotalMemoryGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
                NumberOfProcessors = $cs.NumberOfProcessors
                SystemType = $cs.SystemType
            }

            # Operating System
            $inventory.OperatingSystem = @{
                Name = $os.Caption
                Version = $os.Version
                Build = $os.BuildNumber
                Architecture = $os.OSArchitecture
                InstallDate = $os.InstallDate.ToString('yyyy-MM-dd')
                LastBootTime = $os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm:ss')
                FreePhysicalMemoryMB = [math]::Round($os.FreePhysicalMemory / 1KB, 2)
                TotalVisibleMemoryMB = [math]::Round($os.TotalVisibleMemorySize / 1KB, 2)
            }

            # CPU Information
            $inventory.CPU = @{
                Name = $cpu.Name
                Manufacturer = $cpu.Manufacturer
                NumberOfCores = $cpu.NumberOfCores
                NumberOfLogicalProcessors = $cpu.NumberOfLogicalProcessors
                MaxClockSpeed = $cpu.MaxClockSpeed
                CurrentClockSpeed = $cpu.CurrentClockSpeed
            }

            # GPU Information
            $inventory.GPU = $gpu | ForEach-Object {
                @{
                    Name = $_.Name
                    VideoProcessor = $_.VideoProcessor
                    VideoMemoryMB = [math]::Round($_.AdapterRAM / 1MB, 2)
                    DriverVersion = $_.DriverVersion
                    CurrentResolution = "$($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution)"
                }
            }

            # Disk Information
            $disks = Get-CimInstance -ClassName Win32_LogicalDisk @sessionParams | Where-Object { $_.DriveType -eq 3 }
            $inventory.Disks = $disks | ForEach-Object {
                @{
                    DeviceID = $_.DeviceID
                    FileSystem = $_.FileSystem
                    SizeGB = [math]::Round($_.Size / 1GB, 2)
                    FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
                    PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                    VolumeName = $_.VolumeName
                }
            }

            # Network Adapters
            $adapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration @sessionParams | 
                        Where-Object { $_.IPEnabled -eq $true }
            
            $inventory.NetworkAdapters = $adapters | ForEach-Object {
                @{
                    Description = $_.Description
                    MACAddress = $_.MACAddress
                    IPAddress = $_.IPAddress -join ', '
                    SubnetMask = $_.IPSubnet -join ', '
                    DefaultGateway = $_.DefaultIPGateway -join ', '
                    DNSServers = $_.DNSServerSearchOrder -join ', '
                    DHCPEnabled = $_.DHCPEnabled
                    DHCPServer = $_.DHCPServer
                }
            }

            # Monitor Information
            try {
                $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID @sessionParams
                $inventory.Monitors = $monitors | ForEach-Object {
                    @{
                        Manufacturer = if ($_.ManufacturerName) { 
                            [System.Text.Encoding]::ASCII.GetString($_.ManufacturerName -ne 0).Trim() 
                        } else { 'Unknown' }
                        Model = if ($_.UserFriendlyName) { 
                            [System.Text.Encoding]::ASCII.GetString($_.UserFriendlyName -ne 0).Trim() 
                        } else { 'Unknown' }
                        SerialNumber = if ($_.SerialNumberID) { 
                            [System.Text.Encoding]::ASCII.GetString($_.SerialNumberID -ne 0).Trim() 
                        } else { 'Not Available' }
                    }
                }
            }
            catch {
                Write-Verbose "Could not retrieve monitor information: $_"
            }

            # Installed Software (if requested)
            if ($IncludeSoftware) {
                Write-Verbose "Collecting installed software..."
                
                $software = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    $apps = @()
                    
                    # 64-bit apps
                    $apps += Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                             Where-Object { $_.DisplayName } |
                             Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
                    
                    # 32-bit apps on 64-bit system
                    if ([Environment]::Is64BitOperatingSystem) {
                        $apps += Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue |
                                 Where-Object { $_.DisplayName } |
                                 Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
                    }
                    
                    $apps | Sort-Object DisplayName -Unique
                } @sessionParams
                
                $inventory.InstalledSoftware = $software | ForEach-Object {
                    @{
                        Name = $_.DisplayName
                        Version = $_.DisplayVersion
                        Publisher = $_.Publisher
                        InstallDate = $_.InstallDate
                    }
                }
            }

            # Windows Updates (if requested)
            if ($IncludeUpdates) {
                Write-Verbose "Collecting Windows Update information..."
                
                try {
                    $updates = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        $session = New-Object -ComObject Microsoft.Update.Session
                        $searcher = $session.CreateUpdateSearcher()
                        $history = $searcher.GetTotalHistoryCount()
                        
                        if ($history -gt 0) {
                            $searcher.QueryHistory(0, [Math]::Min($history, 50)) | 
                            Select-Object Title, Date, 
                                @{Name='Result'; Expression={
                                    switch ($_.ResultCode) {
                                        2 { 'Succeeded' }
                                        3 { 'Succeeded with errors' }
                                        4 { 'Failed' }
                                        5 { 'Aborted' }
                                        default { 'Unknown' }
                                    }
                                }}
                        }
                    } @sessionParams -ErrorAction Stop
                    
                    $inventory.RecentUpdates = $updates | Select-Object -First 10 | ForEach-Object {
                        @{
                            Title = $_.Title
                            Date = $_.Date.ToString('yyyy-MM-dd')
                            Result = $_.Result
                        }
                    }
                }
                catch {
                    Write-Verbose "Could not retrieve update information: $_"
                }
            }

            # Network Shares (if requested)
            if ($IncludeShares) {
                Write-Verbose "Collecting network shares..."
                
                $shares = Get-CimInstance -ClassName Win32_Share @sessionParams
                $inventory.Shares = $shares | ForEach-Object {
                    @{
                        Name = $_.Name
                        Path = $_.Path
                        Type = $_.Type
                        Description = $_.Description
                    }
                }
            }

            # Running Services (if requested)
            if ($IncludeServices) {
                Write-Verbose "Collecting service information..."
                
                $services = Get-CimInstance -ClassName Win32_Service @sessionParams | 
                           Where-Object { $_.State -eq 'Running' }
                
                $inventory.RunningServices = $services | ForEach-Object {
                    @{
                        Name = $_.Name
                        DisplayName = $_.DisplayName
                        StartMode = $_.StartMode
                        ProcessId = $_.ProcessId
                        PathName = $_.PathName
                    }
                }
            }

            return [PSCustomObject]$inventory

        }
        catch {
            Write-Error "Failed to collect inventory from ${ComputerName}: $_"
            return $null
        }
    }
}

#endregion

#region Export Functions

function Export-InventoryData {
    <#
    .SYNOPSIS
        Exports inventory data to specified format.
    
    .DESCRIPTION
        Exports inventory data to JSON, XML, or CSV format with proper structure.
    
    .PARAMETER Data
        Inventory data to export.
    
    .PARAMETER OutputPath
        Directory to save output files.
    
    .PARAMETER Format
        Output format: JSON, XML, or CSV.
    
    .PARAMETER FileNamePrefix
        Prefix for output file names.
    
    .EXAMPLE
        Export-InventoryData -Data $inventory -OutputPath "C:\Inventory" -Format JSON
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]$Data,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet('JSON', 'XML', 'CSV')]
        [string]$Format,

        [Parameter()]
        [string]$FileNamePrefix = 'Inventory'
    )

    begin {
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $allData = @()
    }

    process {
        $allData += $Data
    }

    end {
        $fileName = "${FileNamePrefix}_${timestamp}.${Format.ToLower()}"
        $fullPath = Join-Path $OutputPath $fileName

        try {
            switch ($Format) {
                'JSON' {
                    $allData | ConvertTo-Json -Depth 10 | Out-File -FilePath $fullPath -Encoding UTF8
                }
                'XML' {
                    $allData | Export-Clixml -Path $fullPath -Depth 10
                }
                'CSV' {
                    # Flatten nested objects for CSV
                    $flatData = $allData | ForEach-Object {
                        $obj = $_
                        $flat = @{
                            ComputerName = $obj.ComputerName
                            Timestamp = $obj.Timestamp
                        }
                        
                        # Flatten system info
                        if ($obj.System) {
                            foreach ($key in $obj.System.Keys) {
                                $flat["System_$key"] = $obj.System[$key]
                            }
                        }
                        
                        # Flatten OS info
                        if ($obj.OperatingSystem) {
                            foreach ($key in $obj.OperatingSystem.Keys) {
                                $flat["OS_$key"] = $obj.OperatingSystem[$key]
                            }
                        }
                        
                        # Flatten CPU info
                        if ($obj.CPU) {
                            foreach ($key in $obj.CPU.Keys) {
                                $flat["CPU_$key"] = $obj.CPU[$key]
                            }
                        }
                        
                        [PSCustomObject]$flat
                    }
                    
                    $flatData | Export-Csv -Path $fullPath -NoTypeInformation
                    
                    # Create additional CSV files for complex data
                    if ($allData[0].NetworkAdapters) {
                        $netFile = "${FileNamePrefix}_NetworkAdapters_${timestamp}.csv"
                        $netPath = Join-Path $OutputPath $netFile
                        $allData | ForEach-Object {
                            $comp = $_.ComputerName
                            $_.NetworkAdapters | ForEach-Object {
                                [PSCustomObject]($_ + @{ComputerName = $comp})
                            }
                        } | Export-Csv -Path $netPath -NoTypeInformation
                    }
                    
                    if ($allData[0].Disks) {
                        $diskFile = "${FileNamePrefix}_Disks_${timestamp}.csv"
                        $diskPath = Join-Path $OutputPath $diskFile
                        $allData | ForEach-Object {
                            $comp = $_.ComputerName
                            $_.Disks | ForEach-Object {
                                [PSCustomObject]($_ + @{ComputerName = $comp})
                            }
                        } | Export-Csv -Path $diskPath -NoTypeInformation
                    }
                    
                    if ($allData[0].InstalledSoftware) {
                        $softFile = "${FileNamePrefix}_Software_${timestamp}.csv"
                        $softPath = Join-Path $OutputPath $softFile
                        $allData | ForEach-Object {
                            $comp = $_.ComputerName
                            $_.InstalledSoftware | ForEach-Object {
                                [PSCustomObject]($_ + @{ComputerName = $comp})
                            }
                        } | Export-Csv -Path $softPath -NoTypeInformation
                    }
                }
            }

            Write-Host "[+] Data exported to: $fullPath" -ForegroundColor Green
            return $fullPath

        }
        catch {
            Write-Error "Failed to export data: $_"
            throw
        }
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Find-NetworkComputers',
    'Get-ComputerInventory',
    'Export-InventoryData',
    'Get-IPsFromCIDR',
    'Get-IPsFromRange'
)
