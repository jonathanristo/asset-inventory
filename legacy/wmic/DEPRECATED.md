# ⚠️ DEPRECATED: WMIC

## This Directory Contains Obsolete Tools

**Status:** ❌ **DEPRECATED AND REMOVED BY MICROSOFT**

---

## ⚠️ CRITICAL: WMIC HAS BEEN REMOVED

Microsoft removed WMIC in Windows 11 (October 2021).

### Timeline

| Date | Event |
|------|-------|
| May 2021 | WMIC deprecated in Windows 10 21H1 |
| Oct 2021 | WMIC removed from Windows 11 |
| **Now** | **WMIC does not exist on Windows 11+** |

---

## WMIC to PowerShell Migration

### Computer System Information
```powershell
# WMIC (obsolete)
wmic csproduct get name,identifyingnumber

# PowerShell (current)
Get-CimInstance -ClassName Win32_ComputerSystemProduct | 
    Select-Object Name, IdentifyingNumber
```

### Operating System
```powershell
# WMIC (obsolete)
wmic os get caption,version

# PowerShell (current)
Get-CimInstance -ClassName Win32_OperatingSystem | 
    Select-Object Caption, Version
```

---

## Best Practice: Use v3.0

Instead of individual WMIC commands, use the comprehensive module:

```powershell
Get-ComputerInventory -ComputerName $env:COMPUTERNAME |
    Export-InventoryData -OutputPath "." -Format JSON
```

---

**WMIC is gone. It's not coming back.**

Migrate to PowerShell CIM cmdlets or v3.0 module.

See: `../../docs/PSTOOLS_MIGRATION.md`
