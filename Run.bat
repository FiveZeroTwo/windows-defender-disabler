@echo off
:: Run.bat - one-click menu launcher.
:: Lets you pick an action, then self-elevates (UAC prompt) and runs the chosen
:: script with execution policy bypassed. Window stays open (-NoExit).
setlocal

echo.
echo   windows-defender-disabler
echo   =========================
echo.
echo     [1] Disable   - turn off Defender, SmartScreen, Smart App Control
echo     [2] Restore   - re-enable Defender + SmartScreen
echo     [Q] Quit
echo.
set /p choice="  Choose: "

if /i "%choice%"=="1" set script=Disable-Defender.ps1
if /i "%choice%"=="2" set script=Restore-Defender.ps1
if /i "%choice%"=="Q" exit /b

if not defined script (
    echo   Invalid choice.
    pause
    exit /b
)

powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoExit -File \"%~dp0%script%\"'"
