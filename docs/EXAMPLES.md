# Asset Inventory v3.0 - Quick Start Examples

## 30-Second Start

```powershell
# 1. Copy files to C:\Scripts\AssetInventory\
# 2. Open PowerShell
cd C:\Scripts\AssetInventory

# 3. Run it!
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -OutputFormat JSON
```

That's it! You now have a complete inventory of your network.

---

## Common Scenarios

### 🏢 Small Office (1-50 computers)

**Scenario**: You manage a small office network and want to inventory all computers.

```powershell
# Scan your office subnet
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "192.168.1" `
    -IncludeSoftware `
    -OutputFormat CSV `
    -OutputPath "\\FileServer\IT\Inventory"
```

**What you get**:
- Complete list of all computers found
- Hardware specs (CPU, RAM, disks)
- Installed software
- Network configuration
- Monitors and peripherals

**Time**: ~5-10 minutes

---

### 🏭 Medium Business (50-500 computers)

**Scenario**: Multiple subnets, need to inventory specific network segments.

```powershell
# Scan multiple subnets
$subnets = "10.0.1", "10.0.2", "10.0.3", "10.0.5"

foreach ($subnet in $subnets) {
    Write-Host "Scanning subnet: $subnet.0/24" -ForegroundColor Cyan
    
    .\Invoke-AssetInventory.ps1 `
        -ScanNetwork `
        -Subnet $subnet `
        -QuickScan `
        -OutputFormat JSON `
        -OutputPath "\\FileServer\Inventory\$(Get-Date -F yyyy-MM)"
}
```

**What you get**:
- Separate inventory for each subnet
- Organized by month
- Fast scanning with QuickScan

**Time**: ~20-40 minutes

---

### 🏢 Enterprise (500+ computers)

**Scenario**: Large environment, need to inventory by department/location.

```powershell
# departments.csv:
# Name,Subnet
# Accounting,10.10.0
# Engineering,10.20.0
# Sales,10.30.0
# HR,10.40.0

Import-Csv departments.csv | ForEach-Object {
    $dept = $_.Name
    $subnet = $_.Subnet
    
    Write-Host "Processing $dept..." -ForegroundColor Cyan
    
    .\Invoke-AssetInventory.ps1 `
        -ScanNetwork `
        -Subnet $subnet `
        -QuickScan `
        -MaxThreads 50 `
        -OutputFormat JSON `
        -OutputPath "\\FileServer\Inventory\$dept\$(Get-Date -F yyyy-MM-dd)"
}
```

**What you get**:
- Inventory organized by department
- Optimized for speed (QuickScan + more threads)
- Daily snapshots for trend analysis

**Time**: ~1-3 hours (depending on network)

---

### 🔒 Compliance Audit

**Scenario**: Need comprehensive inventory for compliance (SOC2, ISO 27001, etc.)

```powershell
# Get EVERYTHING for compliance
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -IPRange "10.0.0.0/16" `
    -IncludeAll `
    -OutputFormat JSON `
    -OutputPath "\\FileServer\Compliance\2026-Q1-Audit"
```

What `-IncludeAll` includes:
- ✅ System information
- ✅ Installed software
- ✅ Windows updates
- ✅ Network shares
- ✅ Running services
- ✅ Hardware details
- ✅ Network configuration

**Time**: ~3-6 hours (complete data collection)

---

### 🔍 Specific Computer List

**Scenario**: You have a list of specific computers to inventory.

**Method 1: Direct list**
```powershell
.\Invoke-AssetInventory.ps1 `
    -ComputerName "PC01","PC02","SERVER01","LAPTOP05" `
    -IncludeSoftware `
    -OutputFormat CSV
```

**Method 2: From file**
```powershell
# computers.txt:
# PC01
# PC02
# SERVER01
# LAPTOP05

.\Invoke-AssetInventory.ps1 `
    -ComputerListFile "computers.txt" `
    -IncludeSoftware `
    -OutputFormat JSON
```

**Method 3: From Active Directory**
```powershell
# Get computers from AD OU
$computers = Get-ADComputer -Filter * -SearchBase "OU=Workstations,DC=company,DC=local" | 
             Select-Object -ExpandProperty Name

.\Invoke-AssetInventory.ps1 `
    -ComputerName $computers `
    -OutputFormat JSON
```

---

### 📊 Software Compliance Check

**Scenario**: Find all computers with (or without) specific software.

```powershell
# Inventory with software
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "192.168.1" `
    -IncludeSoftware `
    -OutputFormat JSON `
    -OutputPath ".\Inventory"

# Load and analyze
$inventory = Get-Content ".\Inventory\AssetInventory_*.json" | ConvertFrom-Json

# Find computers WITH specific software
$withChrome = $inventory | Where-Object {
    $_.InstalledSoftware.Name -like "*Chrome*"
}

Write-Host "Computers with Chrome: $($withChrome.Count)"
$withChrome.ComputerName

# Find computers WITHOUT specific software
$withoutZoom = $inventory | Where-Object {
    $_.InstalledSoftware.Name -notlike "*Zoom*"
}

Write-Host "Computers without Zoom: $($withoutZoom.Count)"
$withoutZoom.ComputerName
```

---

### 💾 Disk Space Monitoring

**Scenario**: Find computers running low on disk space.

```powershell
# Collect inventory
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "10.0.1" `
    -OutputFormat JSON

# Analyze disk space
$inventory = Get-Content ".\Inventory\AssetInventory_*.json" | ConvertFrom-Json

$lowSpace = $inventory | ForEach-Object {
    $comp = $_.ComputerName
    $_.Disks | Where-Object { $_.PercentFree -lt 20 } | ForEach-Object {
        [PSCustomObject]@{
            Computer = $comp
            Drive = $_.DeviceID
            SizeGB = $_.SizeGB
            FreeGB = $_.FreeSpaceGB
            PercentFree = $_.PercentFree
        }
    }
}

$lowSpace | Format-Table -AutoSize

# Export alert list
$lowSpace | Export-Csv "LowDiskSpace_$(Get-Date -F yyyyMMdd).csv" -NoTypeInformation
```

---

### 📅 Scheduled Weekly Scan

**Scenario**: Automatically scan your network every week.

**WeeklyScan.ps1**:
```powershell
# Weekly automated inventory
$timestamp = Get-Date -Format "yyyy-MM-dd"
$outputPath = "\\FileServer\Inventory\Weekly\$timestamp"

# Scan production network
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "10.0.10" `
    -IncludeSoftware `
    -OutputFormat JSON `
    -OutputPath $outputPath `
    -MaxThreads 30

# Email summary
$summary = Get-Content "$outputPath\Summary_*.json" | ConvertFrom-Json

$body = @"
Weekly Inventory Scan Complete

Date: $timestamp
Computers Found: $($summary.TotalTargets)
Successfully Inventoried: $($summary.SuccessfulInventories)

Report location: $outputPath
"@

Send-MailMessage `
    -To "it-team@company.com" `
    -From "inventory@company.com" `
    -Subject "Weekly Inventory - $timestamp" `
    -Body $body `
    -SmtpServer "smtp.company.com"
```

**Create Scheduled Task**:
```powershell
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\Scripts\AssetInventory\WeeklyScan.ps1" `
    -WorkingDirectory "C:\Scripts\AssetInventory"

$trigger = New-ScheduledTaskTrigger `
    -Weekly `
    -DaysOfWeek Monday `
    -At 6am

Register-ScheduledTask `
    -TaskName "Weekly Asset Inventory" `
    -Action $action `
    -Trigger $trigger `
    -User "SYSTEM" `
    -RunLevel Highest
```

---

### 🌐 Multi-Site Inventory

**Scenario**: Company with multiple locations/sites.

```powershell
# sites.csv:
# Site,CIDR
# HQ,10.1.0.0/16
# Branch1,10.2.0.0/24
# Branch2,10.3.0.0/24
# DataCenter,10.10.0.0/20

Import-Csv sites.csv | ForEach-Object {
    $site = $_.Site
    $cidr = $_.CIDR
    
    Write-Host "`nScanning $site ($cidr)..." -ForegroundColor Cyan
    
    .\Invoke-AssetInventory.ps1 `
        -ScanNetwork `
        -IPRange $cidr `
        -QuickScan `
        -OutputFormat JSON `
        -OutputPath "\\FileServer\Inventory\Sites\$site\$(Get-Date -F yyyy-MM)"
}

# Consolidate results
$allInventory = Get-ChildItem "\\FileServer\Inventory\Sites" -Recurse -Filter "AssetInventory_*.json" |
                Get-Content | 
                ConvertFrom-Json

Write-Host "`nTotal computers across all sites: $($allInventory.Count)"
```

---

### 🔐 Security Audit

**Scenario**: Identify security risks.

```powershell
# Collect comprehensive data
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "192.168.1" `
    -IncludeAll `
    -OutputFormat JSON

# Load data
$inventory = Get-Content ".\Inventory\AssetInventory_*.json" | ConvertFrom-Json

# Find computers with outdated OS
$oldOS = $inventory | Where-Object {
    $_.OperatingSystem.Name -like "*Windows 7*" -or
    $_.OperatingSystem.Name -like "*Windows 8*" -or
    $_.OperatingSystem.Name -like "*Server 2008*"
}

Write-Host "`nComputers with outdated OS: $($oldOS.Count)" -ForegroundColor Red
$oldOS | Select-Object ComputerName, @{N='OS';E={$_.OperatingSystem.Name}}

# Find computers with less than 8GB RAM
$lowRam = $inventory | Where-Object {
    $_.System.TotalMemoryGB -lt 8
}

Write-Host "`nComputers with less than 8GB RAM: $($lowRam.Count)" -ForegroundColor Yellow
$lowRam | Select-Object ComputerName, @{N='RAM_GB';E={$_.System.TotalMemoryGB}}

# Find computers not updated recently
$notUpdated = $inventory | Where-Object {
    $_.RecentUpdates.Count -eq 0
}

Write-Host "`nComputers without recent updates: $($notUpdated.Count)" -ForegroundColor Red
```

---

### 📈 Trend Analysis

**Scenario**: Track changes over time.

```powershell
# Run inventory monthly
$month = Get-Date -Format "yyyy-MM"
$outputPath = "\\FileServer\Inventory\Monthly\$month"

.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "192.168.1" `
    -IncludeSoftware `
    -OutputFormat JSON `
    -OutputPath $outputPath

# Compare with last month
$thisMonth = Get-Content "$outputPath\AssetInventory_*.json" | ConvertFrom-Json
$lastMonth = Get-Content "\\FileServer\Inventory\Monthly\2026-01\AssetInventory_*.json" | ConvertFrom-Json

# New computers
$newComputers = $thisMonth | Where-Object {
    $_.ComputerName -notin $lastMonth.ComputerName
}

# Removed computers  
$removedComputers = $lastMonth | Where-Object {
    $_.ComputerName -notin $thisMonth.ComputerName
}

Write-Host "`nChanges from last month:"
Write-Host "New computers: $($newComputers.Count)" -ForegroundColor Green
Write-Host "Removed computers: $($removedComputers.Count)" -ForegroundColor Red

# Software changes
$newSoftware = $thisMonth.InstalledSoftware | 
               Where-Object { $_.Name -notin $lastMonth.InstalledSoftware.Name }

Write-Host "New software installations: $($newSoftware.Count)" -ForegroundColor Cyan
```

---

### 🚀 Quick Discovery Only

**Scenario**: Just want to know what's on the network (no full inventory).

```powershell
# Import module directly
Import-Module .\AssetInventory.psm1

# Quick discovery
$hosts = Find-NetworkComputers -Subnet "192.168.1" -TestPort @(445, 3389)

# View results
$hosts | Format-Table IPAddress, Hostname, SMBOpen, WinRMOpen -AutoSize

# Export
$hosts | Export-Csv "NetworkDiscovery_$(Get-Date -F yyyyMMdd).csv" -NoTypeInformation

# Count by type
$windowsHosts = $hosts | Where-Object { $_.SMBOpen }
$remoteableHosts = $hosts | Where-Object { $_.WinRMOpen }

Write-Host "`nDiscovery Summary:"
Write-Host "Total hosts found: $($hosts.Count)"
Write-Host "Windows computers: $($windowsHosts.Count)"
Write-Host "WinRM enabled: $($remoteableHosts.Count)"
```

**Time**: ~2-5 minutes

---

### 🎯 Targeted Inventory by IP Range

**Scenario**: Inventory just servers (specific IP range).

```powershell
# Server range: 10.0.1.1 - 10.0.1.50
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -StartIP "10.0.1.1" `
    -EndIP "10.0.1.50" `
    -IncludeShares `
    -IncludeServices `
    -OutputFormat JSON `
    -OutputPath ".\ServerInventory"
```

---

## Performance Tips

### For Small Networks (<50 hosts)
```powershell
# Use defaults
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1"
```

### For Medium Networks (50-500 hosts)
```powershell
# Increase threads, use QuickScan
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -IPRange "10.0.0.0/16" `
    -QuickScan `
    -MaxThreads 50
```

### For Large Networks (500+ hosts)
```powershell
# Maximum threads, QuickScan, skip software
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -IPRange "10.0.0.0/8" `
    -QuickScan `
    -MaxThreads 100
```

---

## Common Patterns

### Pattern 1: Scan → Analyze → Report
```powershell
# 1. Scan
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -IncludeSoftware

# 2. Analyze
$data = Get-Content ".\Inventory\AssetInventory_*.json" | ConvertFrom-Json

# 3. Report
$data | Select-Object ComputerName,
    @{N='Manufacturer';E={$_.System.Manufacturer}},
    @{N='Model';E={$_.System.Model}},
    @{N='RAM_GB';E={$_.System.TotalMemoryGB}},
    @{N='OS';E={$_.OperatingSystem.Name}} |
Export-Csv "ComputerReport.csv" -NoTypeInformation
```

### Pattern 2: Filter → Inventory
```powershell
# 1. Discover
Import-Module .\AssetInventory.psm1
$hosts = Find-NetworkComputers -Subnet "10.0.1"

# 2. Filter (only Windows computers)
$windowsHosts = $hosts | Where-Object { $_.SMBOpen }

# 3. Inventory
$inventory = $windowsHosts | ForEach-Object {
    Get-ComputerInventory -ComputerName $_.IPAddress
}

# 4. Export
$inventory | Export-InventoryData -OutputPath ".\Inventory" -Format JSON
```

---

## Troubleshooting Examples

### Can't reach computers?
```powershell
# Test first
Test-Connection -ComputerName 192.168.1.100 -Count 1

# Check firewall
Get-NetFirewallProfile | Select-Object Name, Enabled

# Enable WinRM on remote
Invoke-Command -ComputerName PC01 -ScriptBlock { Enable-PSRemoting -Force }
```

### Access denied?
```powershell
# Use credentials
$cred = Get-Credential
.\Invoke-AssetInventory.ps1 -ComputerName "PC01" -Credential $cred
```

### Too slow?
```powershell
# Use QuickScan and more threads
.\Invoke-AssetInventory.ps1 `
    -ScanNetwork `
    -Subnet "192.168.1" `
    -QuickScan `
    -MaxThreads 50
```

---

**Pick a scenario above and try it! Most take less than 10 minutes to set up.**
