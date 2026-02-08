#!/bin/bash

# Test runner for Mac
# Wraps PowerShell script execution

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                           ║"
echo "║        Asset Inventory - Test Runner (Mac)               ║"
echo "║                                                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check if PowerShell is installed
if ! command -v pwsh &> /dev/null; then
    echo "❌ PowerShell not found!"
    echo ""
    echo "The .ps1 scripts require PowerShell to run."
    echo ""
    echo "To install PowerShell on Mac:"
    echo "  brew install --cask powershell"
    echo ""
    echo "Or download from:"
    echo "  https://github.com/PowerShell/PowerShell/releases"
    echo ""
    exit 1
fi

echo "✓ PowerShell found: $(pwsh --version)"
echo ""
echo "Running Test-AssetInventory.ps1..."
echo "─────────────────────────────────────────────────────────────"
echo ""

# Run the PowerShell test script
pwsh -NoProfile -ExecutionPolicy Bypass -File ./Test-AssetInventory.ps1

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "Test complete!"
echo ""
