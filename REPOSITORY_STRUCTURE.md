# Asset Inventory Repository - Recommended Structure

## Current Directory Structure

```
asset-inventory/
├── README.md                          # Main repository documentation
├── QUICKSTART.md                      # 5-minute getting started guide
├── Invoke-AssetInventory.ps1          # Main v3.0 script
├── AssetInventory.psm1                # PowerShell module with functions
├── InventoryConfig.psd1               # Configuration template
├── Start-AssetInventory.ps1           # Wrapper script for config file
├── Run-AssetInventory.bat             # Simple launcher
├── AssetInventory_ScheduledTask.xml   # Task scheduler template
│
├── docs/                              # Documentation
│   ├── README_v3.md                   # Complete v3.0 documentation
│   ├── EXAMPLES.md                    # Real-world examples
│   ├── PSTOOLS_MIGRATION.md           # PSTools deprecation guide
│
├── examples/                          # Example scripts
│   ├── WeeklyScan.ps1                 # Scheduled scanning example
│   ├── SoftwareCompliance.ps1         # Software audit example
│   ├── DiskSpaceReport.ps1            # Disk monitoring example
│   └── MultiSiteInventory.ps1         # Multi-location example
│
└── legacy/                            # DEPRECATED - DO NOT USE
    ├── DEPRECATION_NOTICE.md          # Why these are deprecated
    ├── powershell/                    # Old v1.0/v2.0 scripts
    │   └── (old scripts)
    ├── psinfo/                        # PSTools (deprecated)
    │   ├── psinfo.bat
    │   └── DEPRECATED.md
    └── wmic/                          # WMIC (removed in Windows 11)
        ├── (wmic scripts)
        └── DEPRECATED.md
```

---

## What to Use

### ✅ Current (Use These)

**Primary Scripts:**
- `Invoke-AssetInventory.ps1` - Main inventory scanner (v3.0)
- `AssetInventory.psm1` - PowerShell module with reusable functions
- `Start-AssetInventory.ps1` - Config-based wrapper

**Supporting Files:**
- `InventoryConfig.psd1` - Configuration template
- `Run-AssetInventory.bat` - Simple launcher
- `AssetInventory_ScheduledTask.xml` - Scheduled task template

**Documentation:**
- `README.md` - Start here
- `QUICKSTART.md` - Quick start guide
- `docs/README_v3.md` - Complete documentation
- `docs/EXAMPLES.md` - Real-world examples

---

## ⚠️ Deprecated (Do Not Use)

### `legacy/powershell/`
**Status:** Deprecated  
**Replaced by:** `Invoke-AssetInventory.ps1` + `AssetInventory.psm1`  
**Why deprecated:**
- No network scanning
- No parallel processing
- Limited output formats
- Manual credential handling

### `legacy/psinfo/`
**Status:** Deprecated  
**Replaced by:** Native PowerShell (`Get-CimInstance`, module functions)  
**Why deprecated:**
- External dependency (PSTools.exe)
- Security concerns (flagged by antivirus)
- Text output (hard to parse)
- No structured data
- All functionality available natively in PowerShell

**See:** `docs/PSTOOLS_MIGRATION.md`

### `legacy/wmic/`
**Status:** Deprecated & Removed  
**Replaced by:** `Get-CimInstance` cmdlets  
**Why deprecated:**
- **WMIC is REMOVED in Windows 11**
- Deprecated in Windows 10 21H1
- Microsoft officially recommends PowerShell CIM cmdlets
- No longer maintained

**Migration:**
```powershell
# Old WMIC
wmic csproduct get name,identifyingnumber

# New PowerShell
Get-CimInstance -ClassName Win32_ComputerSystemProduct | 
    Select-Object Name, IdentifyingNumber
```

---

## Migration Paths

### From PSInfo → v3.0
```powershell
# Old
psinfo \\PC01 > output.txt

# New
Get-ComputerInventory -ComputerName PC01 | 
    Export-InventoryData -OutputPath . -Format JSON
```

### From WMIC → v3.0
```powershell
# Old
wmic /node:PC01 csproduct get name

# New
Get-CimInstance -ComputerName PC01 -ClassName Win32_ComputerSystemProduct
```

### From v1.0/v2.0 → v3.0
```powershell
# Old (v2.0)
.\Get-AssetInventory.ps1 -ComputerName PC01 -OutputFormat CSV

# New (v3.0) - Same syntax, more features!
.\Invoke-AssetInventory.ps1 -ComputerName PC01 -OutputFormat CSV

# Plus new capabilities:
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1"
```

---

## Version History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| **v3.0** | 2026-02 | ✅ Current | Network scanning, parallel processing, modular |
| v2.0 | 2026-02 | ⚠️ Legacy | Refactored from v1.0, no scanning |
| v1.0 | 2022-01 | ⚠️ Legacy | Original from SANS paper |
| PSInfo | Various | ❌ Deprecated | External PSTools dependency |
| WMIC | N/A | ❌ Removed | Removed by Microsoft in Win11 |

---

## Quick Decision Guide

**"What should I use?"**
→ Use `Invoke-AssetInventory.ps1` (v3.0)

**"I have the old scripts, what do I do?"**
→ Move them to `legacy/` and start using v3.0

**"Do I need PSTools?"**
→ No! Everything is native PowerShell now

**"What about WMIC?"**
→ Don't use it - it's been removed from Windows 11

**"Can I still use v2.0?"**
→ You can, but v3.0 has all v2.0 features plus much more

---

## Cleanup Steps

If you're migrating from old structure:

```powershell
# 1. Create legacy directory
New-Item -Path ".\legacy" -ItemType Directory

# 2. Move old directories
Move-Item -Path ".\powershell" -Destination ".\legacy\powershell"
Move-Item -Path ".\psinfo" -Destination ".\legacy\psinfo"
Move-Item -Path ".\wmic" -Destination ".\legacy\wmic"

# 3. Create deprecation notices
# (see next section for templates)

# 4. Update your scripts to use v3.0
# Point to .\Invoke-AssetInventory.ps1 instead of old scripts

# 5. Test everything
.\Invoke-AssetInventory.ps1 -ComputerName $env:COMPUTERNAME -OutputFormat JSON

# 6. Update documentation/procedures

# 7. Notify team about migration
```

---

## Support

- **Current version issues:** Open an issue with "v3.0" tag
- **Migration questions:** See `docs/PSTOOLS_MIGRATION.md`
- **Legacy scripts:** Archive only, no support provided

---

## Repository Maintenance

### Keep These Updated
- ✅ Main scripts (`Invoke-AssetInventory.ps1`, `AssetInventory.psm1`)
- ✅ Documentation (`README.md`, `docs/`)
- ✅ Examples (`examples/`)

### Archive Only (No Updates)
- 📦 Everything in `legacy/`
- 📦 Old version scripts
- 📦 Deprecated tools

---

**Last Updated:** 2026-02-07  
**Current Version:** 3.0  
**Minimum PowerShell:** 5.1  
**Supported OS:** Windows 10+, Windows Server 2016+
