# PSTools Migration Guide

## Should You Keep PSInfo?

### ❌ **Recommendation: REMOVE PSTools (psinfo)**

Here's why you should migrate away from PSTools/PSInfo:

---

## Reasons to Remove PSTools

### 1. **External Dependency**
- **PSTools**: Requires downloading and deploying external executables
- **PowerShell**: Built into Windows, no external dependencies

### 2. **Maintenance Burden**
- **PSTools**: Need to manually download, update, and distribute
- **PowerShell**: Automatically updated with Windows

### 3. **Security Concerns**
- **PSTools**: Additional executables to audit and trust
- **PSTools**: Can be flagged by antivirus/EDR solutions
- **PowerShell**: Native Microsoft tooling, trusted by default

### 4. **Functionality Available Natively**
Everything PSInfo does can be done with built-in PowerShell cmdlets:

| PSInfo Function | PowerShell Equivalent |
|----------------|----------------------|
| Computer info | `Get-CimInstance Win32_ComputerSystem` |
| OS details | `Get-CimInstance Win32_OperatingSystem` |
| Installed software | `Get-ItemProperty HKLM:\Software\...\Uninstall\*` |
| Service info | `Get-Service` or `Get-CimInstance Win32_Service` |
| Process info | `Get-Process` or `Get-CimInstance Win32_Process` |
| Uptime | `(Get-CimInstance Win32_OperatingSystem).LastBootUpTime` |
| System specs | `Get-CimInstance Win32_Processor`, `Win32_PhysicalMemory` |

### 5. **Better Remote Capabilities**
- **PSTools**: Uses SMB/RPC (ports 135, 445, 137-139)
- **PowerShell**: Uses WinRM (port 5985/5986) - more secure, firewall-friendly

### 6. **Structured Output**
- **PSTools**: Text output, needs parsing
- **PowerShell**: Object output, easy to work with

### 7. **Modern Windows Support**
- **PSTools**: Aging tool, irregular updates
- **PowerShell**: Actively developed, full Windows 11 support

---

## PSInfo vs PowerShell Comparison

### Getting Computer Information

**PSInfo way (old)**:
```batch
psinfo \\COMPUTER01
```

Output (text):
```
System information for \\COMPUTER01:
Uptime:                    2 days 5 hours 23 minutes 10 seconds
Kernel version:            Windows 11 Pro
Product type:              Professional
Product version:           10.0
...
```

**PowerShell way (modern)**:
```powershell
Get-ComputerInventory -ComputerName COMPUTER01
```

Output (structured object):
```json
{
  "ComputerName": "COMPUTER01",
  "System": {
    "Manufacturer": "Dell Inc.",
    "Model": "OptiPlex 7090",
    "SerialNumber": "ABC123",
    ...
  },
  "OperatingSystem": {
    "Name": "Microsoft Windows 11 Pro",
    "Version": "10.0.22631",
    ...
  }
}
```

### Remote Computer Query

**PSInfo way**:
```batch
psinfo \\COMPUTER01 \\COMPUTER02 \\COMPUTER03
```

**PowerShell way**:
```powershell
"COMPUTER01", "COMPUTER02", "COMPUTER03" | ForEach-Object {
    Get-ComputerInventory -ComputerName $_
}
```

### Multiple Computers from File

**PSInfo way**:
```batch
FOR /F %%i IN (computers.txt) DO psinfo \\%%i
```

**PowerShell way**:
```powershell
Get-Content computers.txt | Get-ComputerInventory
```

---

## Migration Steps

### Step 1: Remove PSInfo Dependencies

**Before (with PSInfo)**:
```
asset-inventory/
├── psinfo/
│   ├── psinfo.bat
│   ├── psinfo.exe      ← REMOVE
│   └── psinfo64.exe    ← REMOVE
```

**After (PowerShell only)**:
```
asset-inventory/
├── Invoke-AssetInventory.ps1
└── AssetInventory.psm1
```

### Step 2: Replace PSInfo Commands

Find this in your old scripts:
```batch
psinfo \\%COMPUTERNAME% > output.txt
```

Replace with:
```powershell
Get-ComputerInventory -ComputerName $env:COMPUTERNAME | 
    Export-InventoryData -OutputPath . -Format JSON
```

### Step 3: Update Collection Methods

**Old PSInfo batch script**:
```batch
@echo off
set computer=%COMPUTERNAME%
psinfo \\%computer% > C:\temp\%computer%.txt
psinfo64 \\%computer% >> C:\temp\%computer%.txt
```

**New PowerShell script**:
```powershell
Import-Module .\AssetInventory.psm1
Get-ComputerInventory -ComputerName $env:COMPUTERNAME |
    Export-InventoryData -OutputPath "C:\temp" -Format JSON
```

### Step 4: Update Remote Execution

**Old (PSInfo)**:
```batch
psinfo \\SERVER01 -u DOMAIN\admin -p password
```

**New (PowerShell with proper credential handling)**:
```powershell
$cred = Get-Credential
Get-ComputerInventory -ComputerName SERVER01 -Credential $cred
```

---

## Complete Feature Mapping

### System Information

```powershell
# PSInfo equivalent: psinfo
Get-CimInstance -ClassName Win32_ComputerSystem
Get-CimInstance -ClassName Win32_OperatingSystem
Get-CimInstance -ClassName Win32_BIOS

# Or use the module (recommended)
Get-ComputerInventory -ComputerName $env:COMPUTERNAME
```

### Installed Applications

```powershell
# PSInfo equivalent: psinfo -s
Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher

# Or use the module
Get-ComputerInventory -ComputerName $env:COMPUTERNAME -IncludeSoftware
```

### Running Services

```powershell
# PSInfo equivalent: psinfo -services
Get-Service | Where-Object { $_.Status -eq 'Running' }

# Or with more detail
Get-CimInstance -ClassName Win32_Service | 
    Where-Object { $_.State -eq 'Running' }

# Or use the module
Get-ComputerInventory -ComputerName $env:COMPUTERNAME -IncludeServices
```

### Hotfixes/Updates

```powershell
# PSInfo equivalent: psinfo -h
Get-HotFix | Sort-Object InstalledOn -Descending

# Or with Windows Update history
Get-ComputerInventory -ComputerName $env:COMPUTERNAME -IncludeUpdates
```

### Disk Information

```powershell
# PSInfo equivalent: psinfo -d
Get-CimInstance -ClassName Win32_LogicalDisk | 
    Where-Object { $_.DriveType -eq 3 } |
    Select-Object DeviceID, 
        @{N='SizeGB';E={[math]::Round($_.Size/1GB,2)}},
        @{N='FreeGB';E={[math]::Round($_.FreeSpace/1GB,2)}}
```

---

## Benefits of Migrating

### ✅ No External Files
- No executables to download
- No license acceptance
- No antivirus false positives

### ✅ Better Security
- Native Windows tools
- Proper credential management
- No credential exposure in command lines

### ✅ Richer Data
- Structured objects instead of text
- Easy filtering and formatting
- Direct export to JSON/CSV/XML

### ✅ Modern Features
- Remote PowerShell (WinRM)
- Parallel processing
- Progress indicators
- Error handling

### ✅ Easier Automation
- Native scheduling
- Better logging
- Email integration
- Database connectivity

---

## Real-World Example

### Old Approach (PSInfo + Batch)

**inventory.bat**:
```batch
@echo off
REM Download PSInfo from Sysinternals
REM Accept EULA: psinfo -accepteula

set COMPUTER=%COMPUTERNAME%
set OUTPUT=C:\temp\%COMPUTER%.txt

echo Running inventory on %COMPUTER%...

REM Basic system info
psinfo \\%COMPUTER% > %OUTPUT%

REM Installed software
psinfo -s \\%COMPUTER% >> %OUTPUT%

REM Services
psinfo -services \\%COMPUTER% >> %OUTPUT%

REM Hotfixes
psinfo -h \\%COMPUTER% >> %OUTPUT%

echo Done! Output: %OUTPUT%
pause
```

**Problems**:
- Requires PSInfo.exe
- Text output only
- Hard to parse
- No error handling
- Manual credential input
- Single computer at a time

### New Approach (PowerShell Module)

**inventory.ps1**:
```powershell
Import-Module .\AssetInventory.psm1

# Single line for everything
Get-ComputerInventory `
    -ComputerName $env:COMPUTERNAME `
    -IncludeSoftware `
    -IncludeUpdates `
    -IncludeServices |
Export-InventoryData `
    -OutputPath "C:\temp" `
    -Format JSON
```

**Benefits**:
- No external dependencies
- Structured JSON output
- Built-in error handling
- Secure credential handling
- Can process multiple computers
- Easy to extend

---

## Migration Checklist

- [ ] **Backup existing PSInfo scripts**
  ```powershell
  Copy-Item .\psinfo -Destination .\psinfo_backup -Recurse
  ```

- [ ] **Test new PowerShell scripts**
  ```powershell
  # Test on local computer first
  Get-ComputerInventory -ComputerName $env:COMPUTERNAME
  ```

- [ ] **Update scheduled tasks**
  - Replace batch files with PowerShell scripts
  - Update task actions

- [ ] **Remove PSInfo executables**
  ```powershell
  Remove-Item .\psinfo\*.exe
  ```

- [ ] **Update documentation**
  - Update procedures
  - Train users on new scripts

- [ ] **Archive old scripts**
  ```powershell
  Move-Item .\psinfo -Destination .\archive\psinfo_$(Get-Date -F yyyyMMdd)
  ```

---

## Still Need PSInfo?

### Rare Cases Where PSInfo Might Be Useful

1. **Legacy Systems**: Windows XP/2003 without PowerShell 2.0+
2. **Air-Gapped Networks**: Systems without PowerShell remoting
3. **Specific Tools**: If you need PsList, PsKill, etc. from PSTools suite

### Hybrid Approach (Not Recommended)

If you absolutely must use both:

```powershell
# Use PowerShell where possible
$inventory = Get-ComputerInventory -ComputerName "PC01"

# Fall back to PSInfo only if needed
if (-not $inventory) {
    $psInfoOutput = & psinfo \\PC01
    # Parse text output...
}
```

---

## Final Recommendation

### ✅ DO THIS:
1. Use the new PowerShell module (AssetInventory.psm1)
2. Replace all PSInfo scripts with PowerShell equivalents
3. Remove PSTools from your deployment
4. Update documentation and procedures

### ❌ DON'T DO THIS:
1. Keep PSInfo "just in case"
2. Mix PSInfo and PowerShell approaches
3. Delay migration - do it now

---

## Quick Reference

### Common PSInfo Commands → PowerShell

| PSInfo Command | PowerShell Equivalent |
|----------------|----------------------|
| `psinfo` | `Get-ComputerInventory` |
| `psinfo \\PC01` | `Get-ComputerInventory -ComputerName PC01` |
| `psinfo -s` | `Get-ComputerInventory -IncludeSoftware` |
| `psinfo -d` | View `.Disks` property in inventory |
| `psinfo -h` | `Get-ComputerInventory -IncludeUpdates` |
| `psinfo @computers.txt` | `Get-Content computers.txt \| Get-ComputerInventory` |

---

## Support

If you have specific PSInfo use cases not covered here:

1. Review the [complete documentation](README_v3.md)
2. Check module functions with `Get-Command -Module AssetInventory`
3. Use `Get-Help` on any function for details

---

**Bottom Line**: PSInfo was great in its time, but modern PowerShell provides all the same functionality with better security, structure, and integration. Make the switch today!
