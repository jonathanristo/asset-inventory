# Asset Inventory v3.0

Modern PowerShell-based IT asset inventory and network discovery tool for Windows environments.

## 🚀 Features

- **Network Discovery** - Scan subnets using CIDR notation, IP ranges, or custom lists
- **Parallel Processing** - Multi-threaded scanning for fast inventory collection
- **Comprehensive Data** - System info, hardware, software, network adapters, monitors, disks
- **Multiple Formats** - Export to JSON, XML, or CSV
- **No Dependencies** - Pure PowerShell, no external tools required
- **Modern & Maintained** - Built for PowerShell 5.1+, Windows 10+, Server 2016+

---

## 📋 Quick Start

### Scan Your Network
```powershell
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1" -OutputFormat JSON
```

### Inventory Specific Computers
```powershell
.\Invoke-AssetInventory.ps1 -ComputerName "PC01","PC02" -OutputFormat CSV
```

### Complete Inventory with All Options
```powershell
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "10.0.1" -IncludeAll -OutputFormat JSON
```

See [QUICKSTART.md](QUICKSTART.md) for 5-minute setup guide.

---

## 📖 Documentation

- **[Quick Start Guide](QUICKSTART.md)** - Get started in 5 minutes
- **[Complete Documentation](docs/README_v3.md)** - Full feature documentation
- **[Examples & Scenarios](docs/EXAMPLES.md)** - Real-world use cases
- **[Repository Structure](REPOSITORY_STRUCTURE.md)** - How this repo is organized
- **[Migration Guide](docs/PSTOOLS_MIGRATION.md)** - Moving from PSTools/WMIC

---

## 🗂️ What's Included

### Core Scripts
- **Invoke-AssetInventory.ps1** - Main inventory scanner
- **AssetInventory.psm1** - PowerShell module with reusable functions
- **Start-AssetInventory.ps1** - Config file-based wrapper
- **Test-AssetInventory.ps1** - Test suite

### Configuration
- **InventoryConfig.psd1** - Configuration template
- **Run-AssetInventory.bat** - Simple Windows launcher
- **asset-inventory.code-workspace** - VS Code workspace

---

## 💡 Key Capabilities

### Network Discovery
```powershell
# CIDR notation
.\Invoke-AssetInventory.ps1 -ScanNetwork -IPRange "10.0.0.0/24"

# IP range
.\Invoke-AssetInventory.ps1 -ScanNetwork -StartIP "192.168.1.1" -EndIP "192.168.1.50"

# Subnet shorthand
.\Invoke-AssetInventory.ps1 -ScanNetwork -Subnet "192.168.1"
```

### Module Functions
```powershell
Import-Module .\AssetInventory.psm1

# Discover network hosts
$hosts = Find-NetworkComputers -Subnet "192.168.1"

# Collect inventory
$inventory = Get-ComputerInventory -ComputerName "PC01" -IncludeSoftware

# Export data
$inventory | Export-InventoryData -OutputPath "." -Format JSON
```

### Data Collection
- System: Manufacturer, model, serial, BIOS, domain, memory
- OS: Name, version, build, architecture, install date, uptime
- Hardware: CPU, GPU, disks, network adapters
- Monitors: Manufacturer, model, serial numbers
- Optional: Installed software, Windows updates, network shares, services

---

## ⚠️ Deprecation Notice

**PSTools/PSInfo and WMIC are deprecated.** They have been moved to the `legacy/` directory.

### Why Deprecated?

- **PSInfo**: External dependencies, security concerns, text-only output
- **WMIC**: Removed by Microsoft in Windows 11
- **Old Scripts**: Limited features, no network scanning

### Migration

All functionality is available in v3.0 with better features:

```powershell
# Old (PSInfo)
psinfo \\PC01

# New (v3.0)
Get-ComputerInventory -ComputerName PC01

# Old (WMIC)
wmic csproduct get name

# New (v3.0)
Get-CimInstance Win32_ComputerSystemProduct | Select-Object Name
```

See [legacy/DEPRECATION_NOTICE.md](legacy/DEPRECATION_NOTICE.md) for details.

---

## 🎯 Use Cases

- **Small Office (1-50 computers)** - Single subnet scan
- **Medium Business (50-500)** - Multi-subnet batch processing  
- **Enterprise (500+)** - Department-based scanning with optimization
- **Compliance Audits** - Complete data collection
- **Software License Management** - Track installed software
- **Hardware Refresh Planning** - Identify old systems
- **Security Audits** - Find outdated OS versions
- **Scheduled Scanning** - Weekly/monthly inventory updates

---

## 💻 Requirements

- **PowerShell**: 5.1 or later (PowerShell 7+ recommended)
- **Windows**: 10/11 or Server 2016+
- **Permissions**: Administrator rights for full inventory
- **Network**: WinRM enabled for remote computers (ports 5985/5986)

---

## 📦 Installation

### Download
```bash
git clone https://github.com/jonathanristo/asset-inventory.git
cd asset-inventory
```

### Test Installation
```powershell
.\Test-AssetInventory.ps1
```

### First Run
```powershell
.\Invoke-AssetInventory.ps1 -ComputerName $env:COMPUTERNAME -OutputFormat JSON
```

---

## 🔧 Configuration

### Using Config Files
1. Copy `InventoryConfig.psd1` to create custom configs
2. Edit settings (network ranges, output paths, credentials)
3. Run: `.\Start-AssetInventory.ps1`

### Scheduled Tasks
Import `AssetInventory_ScheduledTask.xml` into Task Scheduler for automated weekly/monthly scans.

---

## 🤝 Contributing

Contributions welcome! This tool was created for IT administrators and evolved from a SANS whitepaper implementation.

### Areas for Contribution
- Additional export formats
- Cloud integration (Azure, AWS)
- Database backends
- Web dashboard
- Additional hardware detection

---

## 📜 Version History

| Version | Date | Notes |
|---------|------|-------|
| **v3.0** | 2026-02 | Network scanning, parallel processing, modular design |
| v2.0 | 2026-02 | Refactored from v1.0, removed external dependencies |
| v1.0 | 2022-01 | Original implementation based on SANS paper |

---


## 📄 License

See [LICENSE](LICENSE) file for details.

---

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/jonathanristo/asset-inventory/issues)
- **Documentation**: See `docs/` directory
- **Examples**: See `docs/EXAMPLES.md`

---

## ⚡ Quick Links

- 📚 [Complete Documentation](docs/README_v3.md)
- 🚀 [Quick Start](QUICKSTART.md)
- 📋 [Examples](docs/EXAMPLES.md)
- 🔄 [Migration Guide](docs/PSTOOLS_MIGRATION.md)
- 🗂️ [Repository Structure](REPOSITORY_STRUCTURE.md)

---

**Built with ❤️ for IT Administrators**

*Modern inventory management for modern infrastructure.*
