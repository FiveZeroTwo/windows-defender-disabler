<#
    Restore-Defender.ps1
    Re-enables Microsoft Defender and SmartScreen by reverting the policy keys
    that Disable-Defender.ps1 sets.

    LIMITATIONS:
      - Smart App Control CANNOT be re-enabled by script. Once Off it stays Off
        until you reset / reinstall Windows.
      - Tamper Protection must be turned back on manually in the GUI.

    RUN (elevated): .\Restore-Defender.ps1  (or via Run.bat -> choose restore)
#>

#--------------------------------------------------------------------- helpers
$Script:Pass = 0
$Script:Fail = 0

function Write-Banner {
    $art = @(
        '  ____  _____ ____ _____ ___  ____  _____ ',
        ' |  _ \| ____/ ___|_   _/ _ \|  _ \| ____|',
        ' | |_) |  _| \___ \ | || | | | |_) |  _|  ',
        ' |  _ <| |___ ___) || || |_| |  _ <| |___ ',
        ' |_| \_\_____|____/ |_| \___/|_| \_\_____|',
        '            defender // back on            '
    )
    Write-Host ""
    foreach ($l in $art) { Write-Host $l -ForegroundColor Green }
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

#--------------------------------------------------------------------- start
Clear-Host
Write-Banner

Write-Section "Pre-flight checks"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
if ($isAdmin) { Write-Host "   [ OK ] Running elevated (administrator)" -ForegroundColor Green }
else { Write-Host "   [ !! ] Not elevated - relaunch as administrator." -ForegroundColor Red; return }

# --- Defender ---
Write-Section "Microsoft Defender"
$pol = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtp = "$pol\Real-Time Protection"
Step "Re-enable real-time protection"  { if (Test-Path $rtp) { Remove-Item $rtp -Recurse -Force } }
Step "Re-enable anti-spyware engine"   { Remove-ItemProperty $pol "DisableAntiSpyware" -ErrorAction SilentlyContinue }
Step "Re-enable antivirus engine"      { Remove-ItemProperty $pol "DisableAntiVirus"   -ErrorAction SilentlyContinue }

# --- SmartScreen ---
Write-Section "SmartScreen"
$sys  = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
$exp  = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
$edge = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
Step "Re-enable Windows SmartScreen"   { if (Test-Path $sys) { Set-ItemProperty $sys "EnableSmartScreen" 1 -Type DWord } }
Step "Restore Explorer app check"      { Set-ItemProperty $exp "SmartScreenEnabled" "Warn" -Type String }
Step "Re-enable Edge SmartScreen"      { if (Test-Path $edge) { Set-ItemProperty $edge "SmartScreenEnabled" 1 -Type DWord } }

# --- things this script CANNOT do ---
Write-Section "Manual steps still required"
Write-Host "   1. Turn Tamper Protection back ON:" -ForegroundColor Yellow
Write-Host "      Windows Security > Virus & threat protection > Manage settings." -ForegroundColor Gray
Write-Host "   2. Smart App Control stays OFF - it cannot be re-enabled without" -ForegroundColor Yellow
Write-Host "      resetting or reinstalling Windows." -ForegroundColor Gray

# --- summary ---
$color = if ($Script:Fail -eq 0) { "Green" } else { "Yellow" }
Write-Host ""
Write-Host "  +--------------------------------------------------+" -ForegroundColor $color
Write-Host ("  |  Summary:  {0,2} succeeded   {1,2} failed            |" -f $Script:Pass, $Script:Fail) -ForegroundColor $color
Write-Host "  +--------------------------------------------------+" -ForegroundColor $color
Write-Host ""
Write-Host "  Reboot to finish re-enabling protection." -ForegroundColor Green
Write-Host ""
$reboot = Read-Host "  Reboot now? (y/N)"
if ($reboot -match '^(y|yes)$') { shutdown /r /t 5 /c "Restore-Defender: applying changes" }
else { Write-Host "  Reboot later to finish." -ForegroundColor DarkGray; Write-Host "" }
