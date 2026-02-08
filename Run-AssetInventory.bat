@echo off
REM ============================================================================
REM Asset Inventory Launcher
REM ============================================================================
REM This batch file launches the PowerShell inventory script
REM Run this by double-clicking or from Task Scheduler
REM ============================================================================

echo.
echo ========================================
echo Asset Inventory Collection
echo ========================================
echo.

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Set PowerShell execution policy for this session only
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%Get-AssetInventory.ps1'"

REM Pause to see results (remove this line if running from Task Scheduler)
echo.
echo ========================================
echo Inventory collection complete!
echo ========================================
echo.
pause
