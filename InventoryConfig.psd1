# Asset Inventory Configuration Template
# Save this as InventoryConfig.psd1 and modify for your environment
# Load with: $config = Import-PowerShellDataFile -Path .\InventoryConfig.psd1

@{
    # Output Settings
    OutputPath = "C:\Inventory"
    OutputFormat = "CSV"  # CSV, JSON, XML, or TXT
    
    # Email Settings (leave blank to disable email)
    EmailSettings = @{
        Enabled = $true
        To = "admin@company.com"
        From = "inventory@company.com"
        SmtpServer = "smtp.company.com"
        SmtpPort = 25
        UseSsl = $false
        # For authentication, use Get-Credential and save securely
        # Don't store passwords in this file!
    }
    
    # Collection Options
    IncludeSoftware = $false  # Set to $true to collect installed software
    WebcamModel = "Logitech*"  # Wildcard pattern for webcam detection
    
    # Computer List
    # For single computer, use: ComputerName = "PC01"
    # For multiple computers, use: Computers = @("PC01", "PC02", "PC03")
    ComputerName = $env:COMPUTERNAME
    
    # Computers = @(
    #     "DESKTOP-01"
    #     "DESKTOP-02"
    #     "LAPTOP-01"
    # )
    
    # Advanced Options
    LoggingEnabled = $true
    VerboseOutput = $false
    
    # Scheduling (for Task Scheduler reference)
    Schedule = @{
        Frequency = "Weekly"
        Day = "Monday"
        Time = "08:00"
        RunAsAccount = "DOMAIN\ServiceAccount"
    }
}
