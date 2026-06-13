@echo off
:: Run.bat - one-click launcher for Disable-Defender.ps1
:: Self-elevates (UAC prompt) and runs the script with execution policy bypassed.
:: The script window stays open (-NoExit) so you can read the results.

powershell -Command "Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -NoExit -File \"%~dp0Disable-Defender.ps1\"'"
