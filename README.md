# windows-defender-disabler

A small PowerShell script that disables Microsoft Defender and Windows Smart App
Control on a Windows machine.

Disabling these features weakens your system's security. Only use this if you
understand the trade-off (for example, you've installed another antivirus or
you're working in an isolated/test environment).

## What it does

- Disables Microsoft Defender's antivirus engine and real-time protection.
- Disables Windows Smart App Control.

## Prerequisites

- Tamper Protection must be turned off first (Settings > Windows Security >
  Virus & threat protection > Manage settings > Tamper Protection > Off).
- An elevated PowerShell session (Run as administrator).

## Usage

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\Disable-Defender.ps1
```

Reboot afterwards to make sure all changes take effect.

## Notes

- Defender's real-time protection can be turned back on by reverting the policy
  keys and re-enabling Tamper Protection.
- Smart App Control cannot be re-enabled without a clean Windows reinstall.

## License

Use at your own risk. No warranty of any kind.
