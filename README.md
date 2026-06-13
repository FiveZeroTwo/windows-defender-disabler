# windows-defender-disabler

A small PowerShell script that disables Microsoft Defender and Windows Smart App
Control on a Windows machine.

Disabling these features weakens your system's security. Only use this if you
understand the trade-off (for example, you've installed another antivirus or
you're working in an isolated/test environment).

## What it does

- Disables Microsoft Defender's antivirus engine and real-time protection.
- Disables Windows Smart App Control.
- Disables SmartScreen (Windows shell, Explorer app check, and Edge).

## Contents

- `Run.bat` - one-click menu launcher (self-elevates). Pick Disable or Restore.
- `Disable-Defender.ps1` - turns the protections off.
- `Restore-Defender.ps1` - re-enables Defender and SmartScreen. (Smart App
  Control and Tamper Protection cannot be re-enabled by script.)

## Prerequisites

- Tamper Protection must be turned off first (Settings > Windows Security >
  Virus & threat protection > Manage settings > Tamper Protection > Off).
- An elevated PowerShell session (Run as administrator).

## Steps (easy way)

1. Turn off Tamper Protection:
   Settings > Windows Security > Virus & threat protection > Manage settings >
   Tamper Protection > Off.

2. Double-click `Run.bat`, choose an action, and approve the UAC prompt.
   It self-elevates and runs the chosen script for you (no need to set
   execution policy or open an admin terminal manually).

3. When the script asks, reboot the computer. This is required for the Smart
   App Control and SmartScreen changes to take effect.

To undo later, run `Run.bat` again and choose Restore.

## Steps (manual way)

1. Turn off Tamper Protection (see above).

2. Open PowerShell as administrator:
   Press Start, type "PowerShell", right-click "Windows PowerShell" and choose
   "Run as administrator".

3. Go to the folder containing the script:

   ```powershell
   cd C:\Users\host\Documents\projects\windows-defender-disabler
   ```

4. Allow the script to run for this session, then run it:

   ```powershell
   Set-ExecutionPolicy -Scope Process Bypass -Force
   .\Disable-Defender.ps1
   ```

   (Alternatively, run it in one line without changing the policy:
   `powershell -ExecutionPolicy Bypass -File ".\Disable-Defender.ps1"`)

5. Reboot the computer. This is required for the Smart App Control and
   SmartScreen changes to take effect.

6. (Optional) Verify after reboot:

   ```powershell
   Get-MpComputerStatus | Select RealTimeProtectionEnabled
   Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' VerifiedAndReputablePolicyState
   ```

   `RealTimeProtectionEnabled` should be `False` and
   `VerifiedAndReputablePolicyState` should be `0`.

## Notes

- If a script fails with "running scripts is disabled on this system", you
  skipped the `Set-ExecutionPolicy` line in step 4. Run it first, in the same
  window.
- Defender's real-time protection and SmartScreen can be turned back on by
  reverting the policy keys and re-enabling Tamper Protection.
- Smart App Control cannot be re-enabled without a clean Windows reinstall.

## License

MIT - see `LICENSE`. Use at your own risk. No warranty of any kind.
