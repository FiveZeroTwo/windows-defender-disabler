<#
    Disable-Defender.ps1
    Disables Microsoft Defender (engine + real-time protection), Smart App
    Control, and SmartScreen via policy/registry keys.

    PREREQ: Tamper Protection OFF (GUI only):
      Settings > Windows Security > Virus & threat protection >
      Manage settings > Tamper Protection > Off

    RUN (elevated PowerShell):
      Set-ExecutionPolicy -Scope Process Bypass -Force
      .\Disable-Defender.ps1

    REVERSE: set the policy values back to 0 (or delete the keys) and re-enable
    Tamper Protection. Smart App Control cannot be re-enabled without a reinstall.
#>

#--------------------------------------------------------------------- helpers
$Script:Pass = 0
$Script:Fail = 0

function Write-Banner {
    $art = @(
        '  ____  _____ _____ _____ _   _ ____  _____ ____  ',
        ' |  _ \| ____|  ___| ____| \ | |  _ \| ____|  _ \ ',
        ' | | | |  _| | |_  |  _| |  \| | | | |  _| | |_) |',
        ' | |_| | |___|  _| | |___| |\  | |_| | |___|  _ < ',
        ' |____/|_____|_|   |_____|_| \_|____/|_____|_| \_\',
        '            d i s a b l e r   //   off-switch     '
    )
    Write-Host ""
    foreach ($l in $art) { Write-Host $l -ForegroundColor Magenta }
    Write-Host ""
}

function Write-Section($text) {
    Write-Host ""
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * $text.Length)) -ForegroundColor DarkCyan
}

function Step($label, [scriptblock]$action) {
    Write-Host ("   [ .. ] " + $label) -NoNewline -ForegroundColor Gray
    try {
        & $action
        Write-Host ("`r   [ ") -NoNewline -ForegroundColor DarkGray
        Write-Host "OK" -NoNewline -ForegroundColor Green
        Write-Host (" ] " + $label) -ForegroundColor White
        $Script:Pass++
    } catch {
        Write-Host ("`r   [ ") -NoNewline -ForegroundColor DarkGray
        Write-Host "!!" -NoNewline -ForegroundColor Red
        Write-Host (" ] " + $label) -ForegroundColor White
        Write-Host ("        -> " + $_.Exception.Message) -ForegroundColor DarkRed
        $Script:Fail++
    }
}

function Spin($text, $cycles = 12) {
    $frames = '|','/','-','\'
    for ($i = 0; $i -lt $cycles; $i++) {
        Write-Host ("`r   " + $frames[$i % 4] + " " + $text) -NoNewline -ForegroundColor DarkYellow
        Start-Sleep -Milliseconds 60
    }
    Write-Host ("`r   * " + $text) -ForegroundColor DarkYellow
}

#--------------------------------------------------------------------- start
Clear-Host
Write-Banner

# --- pre-flight checks ---
Write-Section "Pre-flight checks"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) { Write-Host "   [ OK ] Running elevated (administrator)" -ForegroundColor Green }
else {
    Write-Host "   [ !! ] Not elevated - relaunch PowerShell as administrator." -ForegroundColor Red
    return
}

$tp = $null
try { $tp = (Get-MpComputerStatus -ErrorAction Stop).IsTamperProtected } catch {}
if ($tp -eq $true) {
    Write-Host "   [ !! ] Tamper Protection is ON - changes will be reverted." -ForegroundColor Red
    Write-Host "          Turn it off: Windows Security > Virus & threat protection >" -ForegroundColor Yellow
    Write-Host "          Manage settings > Tamper Protection > Off, then re-run." -ForegroundColor Yellow
    return
} elseif ($tp -eq $false) {
    Write-Host "   [ OK ] Tamper Protection is OFF" -ForegroundColor Green
} else {
    Write-Host "   [ ?? ] Could not read Tamper Protection status - continuing" -ForegroundColor DarkYellow
}

# --- heads up (no prompt; Smart App Control is one-way) ---
Write-Section "Heads up"
Write-Host "   Disabling Defender real-time protection, SmartScreen, and" -ForegroundColor Gray
Write-Host "   Smart App Control. Smart App Control" -NoNewline -ForegroundColor Gray
Write-Host " cannot be re-enabled " -NoNewline -ForegroundColor Red
Write-Host "without reinstalling Windows." -ForegroundColor Gray

Spin "Applying changes" 16

# --- Defender ---
Write-Section "Microsoft Defender"
$pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtp = "$pol\Real-Time Protection"
Step "Create policy keys"            { New-Item -Path $pol -Force | Out-Null; New-Item -Path $rtp -Force | Out-Null }
Step "Disable anti-spyware engine"   { Set-ItemProperty $pol "DisableAntiSpyware"          1 -Type DWord }
Step "Disable antivirus engine"      { Set-ItemProperty $pol "DisableAntiVirus"            1 -Type DWord }
Step "Disable real-time monitoring"  { Set-ItemProperty $rtp "DisableRealtimeMonitoring"   1 -Type DWord }
Step "Disable behavior monitoring"   { Set-ItemProperty $rtp "DisableBehaviorMonitoring"   1 -Type DWord }
Step "Disable on-access protection"  { Set-ItemProperty $rtp "DisableOnAccessProtection"   1 -Type DWord }
Step "Disable scan-on-enable"        { Set-ItemProperty $rtp "DisableScanOnRealtimeEnable" 1 -Type DWord }

# --- Smart App Control (0 = Off, 1 = On, 2 = Evaluation; reboot to apply) ---
Write-Section "Smart App Control"
Step "Set state to Off (one-way)"    { Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy' VerifiedAndReputablePolicyState 0 -Type DWord }

# --- SmartScreen ---
Write-Section "SmartScreen"
$sys  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$exp  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$edge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Step "Disable Windows SmartScreen"   { New-Item -Path $sys  -Force | Out-Null; Set-ItemProperty $sys  "EnableSmartScreen"  0     -Type DWord }
Step "Disable Explorer app check"    { Set-ItemProperty $exp  "SmartScreenEnabled" "Off" -Type String }
Step "Disable Edge SmartScreen"      { New-Item -Path $edge -Force | Out-Null; Set-ItemProperty $edge "SmartScreenEnabled" 0     -Type DWord }

# --- summary ---
$color = if ($Script:Fail -eq 0) { "Green" } else { "Yellow" }
Write-Host ""
Write-Host "  +--------------------------------------------------+" -ForegroundColor $color
Write-Host ("  |  Summary:  {0,2} succeeded   {1,2} failed            |" -f $Script:Pass, $Script:Fail) -ForegroundColor $color
Write-Host "  +--------------------------------------------------+" -ForegroundColor $color
Write-Host ""
if ($Script:Fail -eq 0) {
    Write-Host "  All set. Reboot required for Smart App Control + SmartScreen." -ForegroundColor Green
} else {
    Write-Host "  Some steps failed (see red lines above). Tamper Protection or a" -ForegroundColor Yellow
    Write-Host "  managed-device policy is the usual cause." -ForegroundColor Yellow
}
Write-Host ""

$reboot = Read-Host "  Reboot now? (y/N)"
if ($reboot -match '^(y|yes)$') { shutdown /r /t 5 /c "Disable-Defender: applying changes" }
else { Write-Host "  Reboot later to finish applying changes." -ForegroundColor DarkGray; Write-Host "" }
