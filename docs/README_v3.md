# Asset Inventory Scanner v3.0 - Complete Documentation

## 🚀 What's New in v3.0

### Major Features
- ✅ **Network Scanning**: Scan IP ranges, CIDR blocks, or subnets
- ✅ **Parallel Processing**: Multi-threaded scanning and inventory collection
- ✅ **Modular Design**: Reusable PowerShell module (AssetInventory.psm1)
- ✅ **Multiple Formats**: JSON, XML, and CSV export
- ✅ **Comprehensive Data**: System, network, software, updates, services, shares
- ✅ **Auto-Discovery**: Find computers on your network automatically
- ✅ **Remote Capable**: Inventory remote computers with credentials
- ✅ **Progress Tracking**: Real-time progress indicators

---

## 📋 Table of Contents
1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Network Scanning](#network-scanning)
4. [Inventory Collection](#inventory-collection)
5. [Output Formats](#output-formats)
6. [Advanced Usage](#advanced-usage)
7. [Module Functions](#module-functions)
8. [PSTools Migration](#pstools-migration)

---

## Installation

### 1. Copy Files
Place these files in your scripts directory:
```
C:\Scripts\AssetInventory\
├── Invoke-AssetInventory.ps1  (main script)
└── AssetInventory.psm1         (module with functions)
```

### 2. Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Verify
```powershell
cd C:\Scripts\AssetInventory
Import-Module .\AssetInventory.psm1
Get-Command -Module AssetInventory
```

---

## Quick Start

### Scan Your Local Network
```powershell
# Scan entire subnet and inventory all found computers
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -OutputFormat JSON
```

### Inventory Specific Computers
```powershell
# Inventory specific computers
.\Invoke-AssetInventory.ps1 -ComputerName "PC01","PC02","PC03" -OutputFormat CSV
```

### Full Inventory with Everything
```powershell
# Complete inventory including software, updates, services, shares
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -IncludeAll -OutputFormat JSON
```

---

## Network Scanning

### Scan by CIDR Notation
```powershell
# Scan 192.168.1.0/24 (192.168.1.1 - 192.168.1.254)
.\Invoke-AssetInventory.ps1 -ScanNetwork -IPRange "192.168.1.0/24" -OutputFormat JSON

# Scan smaller range /28 (14 hosts)
.\Invoke-AssetInventory.ps1 -ScanNetwork -IPRange "10.0.1.16/28" -QuickScan
```

### Scan by IP Range
```powershell
# Scan specific IP range
.\Invoke-AssetInventory.ps1 -ScanNetwork -StartIP "10.0.1.50" -EndIP "10.0.1.100"
```

### Scan by Subnet
```powershell
# Scan entire subnet (192.168.100.1-254)
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.100" -OutputFormat CSV
```

### Quick Scan (Faster)
```powershell
# Skip detailed port scanning
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "10.0.0" -QuickScan
```

---

## Inventory Collection

### Basic Inventory
```powershell
# Collects: System info, OS, CPU, GPU, Disks, Network, Monitors
.\Invoke-AssetInventory.ps1 -ComputerName "DESKTOP-01" -OutputFormat JSON
```

### Include Installed Software
```powershell
# Adds complete software inventory
.\Invoke-AssetInventory.ps1 -ComputerName "DESKTOP-01" -IncludeSoftware -OutputFormat CSV
```

### Include Windows Updates
```powershell
# Adds recent Windows Update history
.\Invoke-AssetInventory.ps1 -ComputerName "SERVER-01" -IncludeUpdates -OutputFormat JSON
```

### Include Network Shares
```powershell
# Adds shared folders
.\Invoke-AssetInventory.ps1 -ComputerName "FILE-SERVER" -IncludeShares -OutputFormat JSON
```

### Include Running Services
```powershell
# Adds all running services
.\Invoke-AssetInventory.ps1 -ComputerName "WEB-SERVER" -IncludeServices -OutputFormat CSV
```

### Everything (Complete Inventory)
```powershell
# Include all available information
.\Invoke-AssetInventory.ps1 -ComputerName "SERVER-01" -IncludeAll -OutputFormat JSON
```

---

## Output Formats

### JSON (Recommended)
**Best for**: API integration, parsing, complex data structures

```powershell
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -OutputFormat JSON
```

**Output**: Single JSON file with nested structure
```json
{
  "ComputerName": "PC01",
  "System": {
    "Manufacturer": "Dell Inc.",
    "Model": "OptiPlex 7090"
  },
  "NetworkAdapters": [...]
}
```

### XML (PowerShell Native)
**Best for**: PowerShell workflows, re-importing data

```powershell
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -OutputFormat XML
```

**Features**:
- Can be re-imported: `Import-Clixml`
- Preserves object types
- Compact format

### CSV (Spreadsheet Friendly)
**Best for**: Excel analysis, database import, reporting

```powershell
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -OutputFormat CSV
```

**Output**: Multiple CSV files:
- `AssetInventory_TIMESTAMP.csv` - Main system info (flattened)
- `AssetInventory_NetworkAdapters_TIMESTAMP.csv`
- `AssetInventory_Disks_TIMESTAMP.csv`
- `AssetInventory_Software_TIMESTAMP.csv` (if included)

---

## Advanced Usage

### Batch Inventory from File
```powershell
# Create computers.txt with one computer per line
Get-Content computers.txt
# PC01
# PC02
# SERVER-01

# Run inventory
.\Invoke-AssetInventory.ps1 -ComputerListFile "computers.txt" -OutputFormat JSON
```

### Use Credentials for Remote Access
```powershell
# Prompt for credentials
$cred = Get-Credential

# Scan with credentials
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "10.0.1" `
    -Credential $cred `
    -OutputFormat JSON
```

### Custom Thread Count
```powershell
# Increase parallelism (default is 20)
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -IPRange "192.168.0.0/16" `
    -MaxThreads 50 `
    -OutputFormat JSON
```

### Custom Output Location
```powershell
.\Invoke-AssetInventory.ps1 `
    -ComputerName "PC01" `
    -OutputPath "\\FileServer\Inventory\2026-02" `
    -OutputFormat CSV
```

---

## Module Functions

The `AssetInventory.psm1` module provides reusable functions you can use in your own scripts:

### Find-NetworkComputers
Discovers active computers on the network.

```powershell
Import-Module .\AssetInventory.psm1

# CIDR scan
$hosts = Find-NetworkComputers -IPRange "192.168.1.0/24"

# Range scan
$hosts = Find-NetworkComputers -StartIP "10.0.1.1" -EndIP "10.0.1.50"

# Subnet scan
$hosts = Find-NetworkComputers -Subnet "172.16.5"

# Custom port testing
$hosts = Find-NetworkComputers -Subnet "192.168.1" -TestPort @(80, 443, 3389)

# View results
$hosts | Format-Table IPAddress, Hostname, SMBOpen, WinRMOpen
```

**Output Example**:
```
IPAddress     Hostname        SMBOpen WinRMOpen
---------     --------        ------- ---------
192.168.1.10  DESKTOP-01      True    False
192.168.1.15  SERVER-01       True    True
192.168.1.20  192.168.1.20    True    False
```

### Get-ComputerInventory
Collects comprehensive inventory from a computer.

```powershell
Import-Module .\AssetInventory.psm1

# Basic inventory
$inv = Get-ComputerInventory -ComputerName "PC01"

# With software
$inv = Get-ComputerInventory -ComputerName "PC01" -IncludeSoftware

# All options
$inv = Get-ComputerInventory `
    -ComputerName "SERVER-01" `
    -IncludeSoftware `
    -IncludeUpdates `
    -IncludeShares `
    -IncludeServices

# View specific sections
$inv.System
$inv.OperatingSystem
$inv.NetworkAdapters
```

### Export-InventoryData
Exports inventory to various formats.

```powershell
Import-Module .\AssetInventory.psm1

# Collect from multiple computers
$computers = "PC01", "PC02", "PC03"
$inventory = $computers | ForEach-Object {
    Get-ComputerInventory -ComputerName $_
}

# Export to JSON
$inventory | Export-InventoryData -OutputPath "C:\Inventory" -Format JSON

# Export to CSV
$inventory | Export-InventoryData -OutputPath "C:\Inventory" -Format CSV

# Export to XML
$inventory | Export-InventoryData -OutputPath "C:\Inventory" -Format XML
```

### Get-IPsFromCIDR
Converts CIDR notation to IP list.

```powershell
Import-Module .\AssetInventory.psm1

# Get all IPs in range
$ips = Get-IPsFromCIDR -CIDR "192.168.1.0/24"
$ips.Count  # 254 IPs

# Smaller range
$ips = Get-IPsFromCIDR -CIDR "10.0.0.0/28"
$ips.Count  # 14 IPs
```

### Get-IPsFromRange
Generates IP list from start to end.

```powershell
Import-Module .\AssetInventory.psm1

$ips = Get-IPsFromRange -Start "192.168.1.100" -End "192.168.1.150"
$ips.Count  # 51 IPs
```

---

## Custom Scripts Using the Module

### Example 1: Weekly Automated Scan
```powershell
# WeeklyScan.ps1
Import-Module C:\Scripts\AssetInventory\AssetInventory.psm1

# Scan production subnet
$hosts = Find-NetworkComputers -Subnet "10.0.10" -TestPort @(445, 5985)

# Inventory accessible hosts
$inventory = $hosts | Where-Object { $_.SMBOpen -or $_.WinRMOpen } | ForEach-Object {
    Get-ComputerInventory -ComputerName $_.IPAddress -IncludeSoftware
}

# Export
$inventory | Export-InventoryData -OutputPath "\\FileServer\Inventory" -Format JSON

# Email results
$summary = "Scanned: $($hosts.Count) hosts, Inventoried: $($inventory.Count) computers"
Send-MailMessage -To "admin@company.com" -Subject "Weekly Inventory" -Body $summary
```

### Example 2: Software Compliance Check
```powershell
# CheckSoftware.ps1
Import-Module .\AssetInventory.psm1

$computers = Get-Content "computers.txt"

$inventory = $computers | ForEach-Object {
    Get-ComputerInventory -ComputerName $_ -IncludeSoftware
}

# Find computers with specific software
$withChrome = $inventory | Where-Object {
    $_.InstalledSoftware.Name -like "*Chrome*"
}

Write-Host "Computers with Chrome: $($withChrome.Count)"
$withChrome.ComputerName
```

### Example 3: Disk Space Report
```powershell
# DiskSpaceReport.ps1
Import-Module .\AssetInventory.psm1

$computers = Get-Content "servers.txt"

$inventory = $computers | ForEach-Object {
    Get-ComputerInventory -ComputerName $_
}

# Extract disk info
$diskReport = $inventory | ForEach-Object {
    $comp = $_.ComputerName
    $_.Disks | ForEach-Object {
        [PSCustomObject]@{
            Computer = $comp
            Drive = $_.DeviceID
            SizeGB = $_.SizeGB
            FreeGB = $_.FreeSpaceGB
            PercentFree = $_.PercentFree
        }
    }
}

# Show low disk space
$diskReport | Where-Object { $_.PercentFree -lt 20 } | Format-Table
```

---

## Data Structure Reference

### Complete Inventory Object
```json
{
  "ComputerName": "DESKTOP-01",
  "Timestamp": "2026-02-07 14:30:15",
  "System": {
    "Manufacturer": "Dell Inc.",
    "Model": "OptiPlex 7090",
    "SerialNumber": "ABC123",
    "BIOSVersion": "1.2.3",
    "Domain": "COMPANY.LOCAL",
    "CurrentUser": "COMPANY\\jdoe",
    "TotalMemoryGB": 16,
    "NumberOfProcessors": 1,
    "SystemType": "x64-based PC"
  },
  "OperatingSystem": {
    "Name": "Microsoft Windows 11 Pro",
    "Version": "10.0.22631",
    "Build": "22631",
    "Architecture": "64-bit",
    "InstallDate": "2025-01-15",
    "LastBootTime": "2026-02-06 08:15:00",
    "FreePhysicalMemoryMB": 8192,
    "TotalVisibleMemoryMB": 16384
  },
  "CPU": {
    "Name": "Intel Core i7-10700",
    "Manufacturer": "GenuineIntel",
    "NumberOfCores": 8,
    "NumberOfLogicalProcessors": 16,
    "MaxClockSpeed": 2900,
    "CurrentClockSpeed": 2900
  },
  "GPU": [
    {
      "Name": "NVIDIA GeForce RTX 3060",
      "VideoProcessor": "NVIDIA GeForce RTX 3060",
      "VideoMemoryMB": 12288,
      "DriverVersion": "31.0.15.3168",
      "CurrentResolution": "1920x1080"
    }
  ],
  "Disks": [
    {
      "DeviceID": "C:",
      "FileSystem": "NTFS",
      "SizeGB": 476,
      "FreeSpaceGB": 235,
      "PercentFree": 49.37,
      "VolumeName": "Windows"
    }
  ],
  "NetworkAdapters": [
    {
      "Description": "Intel Ethernet Connection",
      "MACAddress": "00:11:22:33:44:55",
      "IPAddress": "192.168.1.100, fe80::1234",
      "SubnetMask": "255.255.255.0",
      "DefaultGateway": "192.168.1.1",
      "DNSServers": "192.168.1.1, 8.8.8.8",
      "DHCPEnabled": true,
      "DHCPServer": "192.168.1.1"
    }
  ],
  "Monitors": [
    {
      "Manufacturer": "Dell",
      "Model": "P2419H",
      "SerialNumber": "ABC1234567"
    }
  ],
  "InstalledSoftware": [
    {
      "Name": "Google Chrome",
      "Version": "120.0.6099.130",
      "Publisher": "Google LLC",
      "InstallDate": "20250115"
    }
  ]
}
```

---

## Performance Optimization

### Network Scanning
- **Small networks** (<50 hosts): Use default settings
- **Medium networks** (50-500 hosts): Increase `-MaxThreads 50`
- **Large networks** (500+ hosts): Use `-MaxThreads 100` and `-QuickScan`

### Inventory Collection
- **Quick inventory**: Don't use `-IncludeSoftware` or `-IncludeUpdates`
- **Complete inventory**: Use `-IncludeAll` but expect longer runtime
- **Parallel processing**: Adjust `-MaxThreads` based on your CPU

### Typical Performance
- **Ping sweep**: ~500 IPs/minute
- **Basic inventory**: ~10-20 computers/minute
- **Full inventory (with software)**: ~5-10 computers/minute

---

## Troubleshooting

### Network Scanning Issues

**No hosts found**:
```powershell
# Test basic connectivity first
Test-Connection -ComputerName 192.168.1.1 -Count 1

# Check firewall
Get-NetFirewallProfile | Select-Object Name, Enabled
```

**Slow scanning**:
```powershell
# Use QuickScan
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -QuickScan

# Increase threads
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -MaxThreads 50
```

### Inventory Collection Issues

**Access denied**:
```powershell
# Use credentials
$cred = Get-Credential
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -Credential $cred
```

**WinRM not available**:
```powershell
# On remote computer, enable WinRM
Enable-PSRemoting -Force

# Or use firewall rule
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
```

**Software inventory fails**:
- Requires admin rights
- WinRM must be enabled
- Remote registry must be accessible

---

## Output Files Reference

### JSON Format
```
AssetInventory_20260207_143022.json          # Main inventory file
NetworkDiscovery_20260207_143022.csv         # Discovery results (if network scan)
Summary_20260207_143022.json                 # Scan summary
```

### CSV Format
```
AssetInventory_20260207_143022.csv           # Flattened system info
AssetInventory_NetworkAdapters_20260207_143022.csv
AssetInventory_Disks_20260207_143022.csv
AssetInventory_Software_20260207_143022.csv  # If -IncludeSoftware
NetworkDiscovery_20260207_143022.csv         # Discovery results
Summary_20260207_143022.json                 # Scan summary
```

### XML Format
```
AssetInventory_20260207_143022.xml           # PowerShell XML format
NetworkDiscovery_20260207_143022.csv         # Discovery results
Summary_20260207_143022.json                 # Scan summary
```

---

## Best Practices

1. **Start small**: Test on a few computers before scanning entire networks
2. **Use credentials**: Store service account credentials securely
3. **Schedule scans**: Run during off-hours to minimize impact
4. **Archive data**: Keep historical inventory for trend analysis
5. **Export to database**: Import JSON/CSV into SQL for better querying
6. **Monitor performance**: Watch resource usage on scan host
7. **Use QuickScan**: For large networks, skip detailed port scanning
8. **Segment scans**: Break large networks into smaller chunks

---

## Comparison with v2.0

| Feature | v2.0 | v3.0 |
|---------|------|------|
| Network Scanning | ❌ | ✅ CIDR/Range/Subnet |
| Parallel Processing | ❌ | ✅ Multi-threaded |
| Modular Design | ❌ | ✅ Reusable module |
| Output Formats | CSV, JSON, XML, TXT | JSON, XML, CSV |
| Discovery Mode | ❌ | ✅ Auto-find computers |
| Progress Tracking | ❌ | ✅ Real-time progress |
| Port Scanning | ❌ | ✅ Multiple ports |
| DNS Resolution | ❌ | ✅ Auto-resolve |
| Batch Processing | Manual loops | ✅ Built-in |
| Remote Credentials | Basic | ✅ PSCredential |

---

Next: [PSTools Migration Guide](PSTOOLS_MIGRATION.md)
