<#
    Disable-Defender.ps1
    Disables Microsoft Defender's engine + real-time protection via policy keys.

    PREREQ: Tamper Protection OFF (GUI only):
      Settings > Windows Security > Virus & threat protection >
      Manage settings > Tamper Protection > Off

    RUN (elevated PowerShell):
      Set-ExecutionPolicy -Scope Process Bypass -Force
      .\Disable-Defender.ps1

    REVERSE: set the same values to 0 (or delete the keys), turn Tamper
    Protection back on, reboot.
#>

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "ERROR: not elevated. Run PowerShell as administrator." -ForegroundColor Red; return
}

$pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtp = "$pol\Real-Time Protection"
New-Item -Path $pol -Force | Out-Null
New-Item -Path $rtp -Force | Out-Null

Set-ItemProperty $pol "DisableAntiSpyware"          1 -Type DWord
Set-ItemProperty $pol "DisableAntiVirus"            1 -Type DWord
Set-ItemProperty $rtp "DisableRealtimeMonitoring"   1 -Type DWord
Set-ItemProperty $rtp "DisableBehaviorMonitoring"   1 -Type DWord
Set-ItemProperty $rtp "DisableOnAccessProtection"   1 -Type DWord
Set-ItemProperty $rtp "DisableScanOnRealtimeEnable" 1 -Type DWord

# Disable Smart App Control (2 = Off). NOTE: one-way - SAC cannot be re-enabled
# without a clean Windows reinstall.
Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' -Name VerifiedAndReputablePolicyState -Value 2 -Type DWord

Write-Host "Done. Engine + real-time protection disabled via policy; Smart App Control off." -ForegroundColor Green
Write-Host "Verify with:  Get-MpComputerStatus | Select RealTimeProtectionEnabled" -ForegroundColor Cyan
