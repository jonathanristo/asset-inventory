# Quick Start Guide - Asset Inventory Script

## 5-Minute Setup

### Step 1: Copy Files
Copy all files to a folder on your computer, for example:
```
C:\Scripts\AssetInventory\
```

### Step 2: Configure (Optional)
Edit `InventoryConfig.psd1` to set your preferences:
- Output location
- Email settings
- Whether to include software inventory

### Step 3: Run the Script

**Option A - Simple (Double-click)**
```
Double-click: Run-AssetInventory.bat
```

**Option B - PowerShell Command Line**
```powershell
# Navigate to script folder
cd C:\Scripts\AssetInventory

# Run with defaults
.\Get-AssetInventory.ps1

# Run with configuration file
.\Start-AssetInventory.ps1
```

**Option C - Custom Parameters**
```powershell
# Basic inventory with email
.\Get-AssetInventory.ps1 `
    -OutputPath "C:\Inventory" `
    -OutputFormat CSV `
    -EmailResults `
    -EmailTo "admin@company.com" `
    -EmailFrom "inventory@company.com" `
    -SmtpServer "smtp.company.com"
```

### Step 4: Check Output
Look in your output folder for:
- CSV files with inventory data
- Log file with execution details
- (If email enabled) Check your inbox

## Common Scenarios

### Scenario 1: Quick Local Inventory
**Need**: Get inventory of this computer right now

```powershell
.\Get-AssetInventory.ps1
```
**Result**: Files in your temp folder

---

### Scenario 2: Inventory with Software List
**Need**: Full inventory including all installed programs

```powershell
.\Get-AssetInventory.ps1 -IncludeSoftware -OutputPath "C:\Inventory"
```
**Result**: Detailed inventory including software in C:\Inventory

---

### Scenario 3: Remote Computer Inventory
**Need**: Inventory a computer named "DESKTOP-01"

```powershell
.\Get-AssetInventory.ps1 -ComputerName "DESKTOP-01" -OutputPath "\\Server\Inventory"
```
**Result**: DESKTOP-01 inventory saved to network share

---

### Scenario 4: Multiple Computers
**Need**: Inventory 10 computers from a list

```powershell
# Create computers.txt with one computer name per line
$computers = Get-Content "computers.txt"
foreach ($pc in $computers) {
    .\Get-AssetInventory.ps1 -ComputerName $pc -OutputPath "C:\Inventory"
}
```
**Result**: All computers inventoried

---

### Scenario 5: Automated Daily Email
**Need**: Run automatically every day and email results

1. Edit `InventoryConfig.psd1` - set email settings
2. Save SMTP credentials:
   ```powershell
   .\Start-AssetInventory.ps1 -SaveCredential
   ```
3. Import scheduled task:
   - Edit `AssetInventory_ScheduledTask.xml`
   - Replace YOUR_USERNAME and paths
   - Import into Task Scheduler

**Result**: Automatic daily inventory emails

---

## Troubleshooting Quick Fixes

### "Cannot run scripts"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Cannot connect to remote computer"
```powershell
# On remote computer, run:
Enable-PSRemoting -Force
```

### "Access denied"
- Run PowerShell as Administrator for full inventory
- Or use an account with admin rights

### "Email not sending"
```powershell
# Test SMTP
Test-NetConnection -ComputerName smtp.yourserver.com -Port 25

# Or try with authentication
$cred = Get-Credential
.\Get-AssetInventory.ps1 -EmailResults -Credential $cred -UseSsl
```

## Output Files Explained

After running, you'll see files like:

```
COMPUTERNAME_Inventory_20260207_143022_Computer.csv
COMPUTERNAME_Inventory_20260207_143022_Monitors.csv
COMPUTERNAME_Inventory_20260207_143022_Network.csv
COMPUTERNAME_Inventory_20260207_143022_DockingStation.csv
COMPUTERNAME_Inventory_20260207_143022_Webcams.csv
COMPUTERNAME_Inventory_20260207_143022_Software.csv
AssetInventory_20260207_143022.log
```

**What they contain:**
- **Computer.csv**: Basic system info (model, serial, RAM, OS)
- **Monitors.csv**: All connected monitors with serial numbers
- **Network.csv**: Network adapters, IPs, MAC addresses
- **DockingStation.csv**: Surface Dock info (if applicable)
- **Webcams.csv**: Connected cameras and USB devices
- **Software.csv**: All installed programs (if -IncludeSoftware used)
- **.log**: Detailed execution log for troubleshooting

## Next Steps

### For One-Time Use
You're done! Check your output files.

### For Regular Use
1. Test the configuration file approach
2. Set up scheduled task for automation
3. Configure email reporting

### For Multiple Computers
1. Create a list of computer names
2. Use the batch processing example
3. Save results to a central location

### For Advanced Users
1. Integrate with your asset management database
2. Create custom reports from CSV files
3. Build PowerBI dashboards from the data
4. Set up monitoring for inventory changes

## Getting Help

1. **Check the log file** - Most issues are explained there
2. **Run with -Verbose** for detailed output
3. **Review README.md** for comprehensive documentation
4. **Test connectivity** before remote inventories

## Default Locations

- **Output**: `$env:TEMP` (usually C:\Users\YourName\AppData\Local\Temp)
- **Logs**: Same as output
- **Config**: Same folder as scripts
- **Credentials**: Same folder as scripts (smtp_credential.xml)

## Security Notes

- Never store passwords in scripts
- Use credential files or Task Scheduler credential storage
- Protect config files if they contain sensitive data
- Use SSL/TLS for email if available
- Review permissions on output folders

---

**Time to First Inventory**: < 2 minutes  
**Setup for Automation**: < 10 minutes  
**Learning Curve**: Gentle (works out of the box)

Happy Inventorying! 🎯
