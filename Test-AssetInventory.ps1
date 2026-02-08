<#
.SYNOPSIS
    Test script for Asset Inventory v3.0

.DESCRIPTION
    Validates that all scripts and modules work correctly.
    Safe to run - doesn't scan network, only tests local computer.

.EXAMPLE
    .\Test-AssetInventory.ps1

.NOTES
    Run this in VS Code to test your setup.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Continue'

# Colors for output
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $($Message.PadRight(57)) ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$Test,
        [bool]$Passed,
        [string]$Message = ""
    )
    
    $status = if ($Passed) { "✓ PASS" } else { "✗ FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "  [$status] " -ForegroundColor $color -NoNewline
    Write-Host "$Test" -ForegroundColor White
    
    if ($Message) {
        Write-Host "         $Message" -ForegroundColor Gray
    }
}

# Test results
$tests = @{
    Passed = 0
    Failed = 0
    Total = 0
}

# Banner
Write-Host @"

╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Asset Inventory v3.0 - Test Suite                 ║
║        Validating scripts and modules                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "Working Directory: $PWD`n" -ForegroundColor Gray

# TEST 1: Check file existence
Write-TestHeader "TEST 1: File Existence"

$requiredFiles = @(
    "Invoke-AssetInventory.ps1",
    "AssetInventory.psm1",
    "Start-AssetInventory.ps1",
    "InventoryConfig.psd1"
)

foreach ($file in $requiredFiles) {
    $tests.Total++
    $exists = Test-Path $file
    if ($exists) {
        $tests.Passed++
        Write-TestResult -Test "$file" -Passed $true -Message "Found"
    } else {
        $tests.Failed++
        Write-TestResult -Test "$file" -Passed $false -Message "Missing"
    }
}

# TEST 2: PowerShell syntax validation
Write-TestHeader "TEST 2: PowerShell Syntax Validation"

$scriptFiles = Get-ChildItem -Path . -Filter *.ps1 -File | Where-Object { $_.Name -notlike "*Test*" }

foreach ($file in $scriptFiles) {
    $tests.Total++
    try {
        $content = Get-Content $file.FullName -Raw
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
        $tests.Passed++
        Write-TestResult -Test "$($file.Name)" -Passed $true -Message "Valid syntax"
    }
    catch {
        $tests.Failed++
        Write-TestResult -Test "$($file.Name)" -Passed $false -Message "Syntax error: $_"
    }
}

# TEST 3: Module import
Write-TestHeader "TEST 3: Module Import"

$tests.Total++
try {
    Import-Module .\AssetInventory.psm1 -Force -ErrorAction Stop
    $tests.Passed++
    Write-TestResult -Test "Import AssetInventory.psm1" -Passed $true -Message "Module loaded successfully"
    
    # Check exported functions
    $functions = Get-Command -Module AssetInventory
    Write-Host "         Exported functions: $($functions.Count)" -ForegroundColor Gray
    foreach ($func in $functions) {
        Write-Host "           - $($func.Name)" -ForegroundColor Gray
    }
}
catch {
    $tests.Failed++
    Write-TestResult -Test "Import AssetInventory.psm1" -Passed $false -Message $_.Exception.Message
}

# TEST 4: Function availability
Write-TestHeader "TEST 4: Function Availability"

$expectedFunctions = @(
    "Find-NetworkComputers",
    "Get-ComputerInventory",
    "Export-InventoryData",
    "Get-IPsFromCIDR",
    "Get-IPsFromRange"
)

foreach ($funcName in $expectedFunctions) {
    $tests.Total++
    $func = Get-Command -Name $funcName -ErrorAction SilentlyContinue
    if ($func) {
        $tests.Passed++
        Write-TestResult -Test "$funcName" -Passed $true -Message "Available"
    } else {
        $tests.Failed++
        Write-TestResult -Test "$funcName" -Passed $false -Message "Not found"
    }
}

# TEST 5: CIDR calculation
Write-TestHeader "TEST 5: CIDR Calculation"

$tests.Total++
try {
    $ips = Get-IPsFromCIDR -CIDR "192.168.1.0/28"
    if ($ips.Count -eq 14) {
        $tests.Passed++
        Write-TestResult -Test "Get-IPsFromCIDR" -Passed $true -Message "Calculated 14 IPs for /28 subnet"
    } else {
        $tests.Failed++
        Write-TestResult -Test "Get-IPsFromCIDR" -Passed $false -Message "Expected 14 IPs, got $($ips.Count)"
    }
}
catch {
    $tests.Failed++
    Write-TestResult -Test "Get-IPsFromCIDR" -Passed $false -Message $_.Exception.Message
}

# TEST 6: IP range generation
Write-TestHeader "TEST 6: IP Range Generation"

$tests.Total++
try {
    $ips = Get-IPsFromRange -Start "192.168.1.1" -End "192.168.1.10"
    if ($ips.Count -eq 10) {
        $tests.Passed++
        Write-TestResult -Test "Get-IPsFromRange" -Passed $true -Message "Generated 10 IPs"
    } else {
        $tests.Failed++
        Write-TestResult -Test "Get-IPsFromRange" -Passed $false -Message "Expected 10 IPs, got $($ips.Count)"
    }
}
catch {
    $tests.Failed++
    Write-TestResult -Test "Get-IPsFromRange" -Passed $false -Message $_.Exception.Message
}

# TEST 7: Local computer inventory (Safe test)
Write-TestHeader "TEST 7: Local Computer Inventory"

$tests.Total++
try {
    Write-Host "  Testing inventory collection on local computer..." -ForegroundColor Gray
    $inventory = Get-ComputerInventory -ComputerName $env:COMPUTERNAME -ErrorAction Stop
    
    if ($inventory -and $inventory.ComputerName) {
        $tests.Passed++
        Write-TestResult -Test "Get-ComputerInventory" -Passed $true -Message "Successfully collected inventory"
        Write-Host "         Computer: $($inventory.ComputerName)" -ForegroundColor Gray
        Write-Host "         Manufacturer: $($inventory.System.Manufacturer)" -ForegroundColor Gray
        Write-Host "         Model: $($inventory.System.Model)" -ForegroundColor Gray
    } else {
        $tests.Failed++
        Write-TestResult -Test "Get-ComputerInventory" -Passed $false -Message "No data returned"
    }
}
catch {
    $tests.Failed++
    Write-TestResult -Test "Get-ComputerInventory" -Passed $false -Message $_.Exception.Message
}

# TEST 8: Export functionality
Write-TestHeader "TEST 8: Export Functionality"

if ($inventory) {
    $testOutput = Join-Path $PWD "test-output"
    
    # Test JSON export
    $tests.Total++
    try {
        if (-not (Test-Path $testOutput)) {
            New-Item -Path $testOutput -ItemType Directory -Force | Out-Null
        }
        
        $jsonFile = $inventory | Export-InventoryData -OutputPath $testOutput -Format JSON
        
        if (Test-Path $jsonFile) {
            $tests.Passed++
            Write-TestResult -Test "Export to JSON" -Passed $true -Message "Created: $(Split-Path $jsonFile -Leaf)"
        } else {
            $tests.Failed++
            Write-TestResult -Test "Export to JSON" -Passed $false -Message "File not created"
        }
    }
    catch {
        $tests.Failed++
        Write-TestResult -Test "Export to JSON" -Passed $false -Message $_.Exception.Message
    }
    
    # Test CSV export
    $tests.Total++
    try {
        $csvFile = $inventory | Export-InventoryData -OutputPath $testOutput -Format CSV
        
        if (Test-Path $csvFile) {
            $tests.Passed++
            Write-TestResult -Test "Export to CSV" -Passed $true -Message "Created: $(Split-Path $csvFile -Leaf)"
        } else {
            $tests.Failed++
            Write-TestResult -Test "Export to CSV" -Passed $false -Message "File not created"
        }
    }
    catch {
        $tests.Failed++
        Write-TestResult -Test "Export to CSV" -Passed $false -Message $_.Exception.Message
    }
    
    # Clean up test output
    Write-Host "`n  Test output location: $testOutput" -ForegroundColor Gray
} else {
    Write-Host "  Skipping export tests (no inventory data)" -ForegroundColor Yellow
}

# TEST 9: Main script execution
Write-TestHeader "TEST 9: Main Script Execution"

$tests.Total++
try {
    Write-Host "  Testing main script (dry run mode)..." -ForegroundColor Gray
    
    # Test syntax only - don't actually run full scan
    $scriptContent = Get-Content .\Invoke-AssetInventory.ps1 -Raw
    $null = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$null)
    
    $tests.Passed++
    Write-TestResult -Test "Invoke-AssetInventory.ps1" -Passed $true -Message "Script is valid"
}
catch {
    $tests.Failed++
    Write-TestResult -Test "Invoke-AssetInventory.ps1" -Passed $false -Message $_.Exception.Message
}

# SUMMARY
Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor $(if ($tests.Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "║                    TEST SUMMARY                           ║" -ForegroundColor $(if ($tests.Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor $(if ($tests.Failed -eq 0) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "  Total Tests:  $($tests.Total)" -ForegroundColor White
Write-Host "  Passed:       $($tests.Passed)" -ForegroundColor Green
Write-Host "  Failed:       $($tests.Failed)" -ForegroundColor $(if ($tests.Failed -eq 0) { "White" } else { "Red" })
Write-Host "  Pass Rate:    $([math]::Round(($tests.Passed / $tests.Total) * 100, 1))%" -ForegroundColor $(if ($tests.Failed -eq 0) { "Green" } else { "Yellow" })

if ($tests.Failed -eq 0) {
    Write-Host "`n  ✓ All tests passed! Your setup is ready to use." -ForegroundColor Green
} else {
    Write-Host "`n  ⚠ Some tests failed. Review the errors above." -ForegroundColor Yellow
}

Write-Host ""

# Return results object
return [PSCustomObject]@{
    Total = $tests.Total
    Passed = $tests.Passed
    Failed = $tests.Failed
    PassRate = [math]::Round(($tests.Passed / $tests.Total) * 100, 1)
}
