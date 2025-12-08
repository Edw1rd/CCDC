Write-Host "[*] Starting PowerShell Auditing Configuration..." -ForegroundColor Cyan


# =================================================== #
#  Safe registry set (prevents errors if key missing) #
# =================================================== #
function Set-SafeRegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [object]$Value
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Force
}


# ======================================== #
# 1) ENABLE POWERSHELL SCRIPTBLOCK LOGGING #
# Logs full text of every PS command       #
# ======================================== #
Write-Host "[*] Enabling ScriptBlock Logging..." -ForegroundColor Yellow

Set-SafeRegistryValue `
    -Path "HKLM:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" `
    -Name "ScriptBlockLogging" `
    -Value 1

Write-Host "[+] ScriptBlock Logging enabled." -ForegroundColor Green


# ============================================ #
# 2) ENABLE MODULE LOGGING                     #
# Logs what PowerShell modules attackers load  #
# ============================================ #
Write-Host "[*] Enabling Module Logging..." -ForegroundColor Yellow

Set-SafeRegistryValue `
    -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" `
    -Name "EnableModuleLogging" `
    -Value 1

Write-Host "[+] Module Logging enabled." -ForegroundColor Green


# ==========================================================
# 3) ENABLE POWERSHELL TRANSCRIPTION (OPTIONAL BUT USEFUL)
# Captures full PowerShell sessions to a folder
# ==========================================================
$TranscriptPath = "C:\PS_Transcript"

if (-not (Test-Path $TranscriptPath)) {
    New-Item -ItemType Directory -Path $TranscriptPath | Out-Null
}

Write-Host "[*] Enabling PowerShell Transcription..." -ForegroundColor Yellow

Set-SafeRegistryValue `
    -Path "HKLM:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" `
    -Name "EnableTranscripting" `
    -Value 1

Set-SafeRegistryValue `
    -Path "HKLM:\Software\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" `
    -Name "OutputDirectory" `
    -Value $TranscriptPath

Write-Host "[+] PowerShell Transcription enabled." -ForegroundColor Green


# ==========================================================
# 4) GENERATE TEST EVENT TO PROVE LOGGING IS ACTIVE
# You will see this in Event Viewer → PowerShell → Operational → Event ID 4104
# ==========================================================
Write-Host "[*] Generating test ScriptBlock event..." -ForegroundColor Yellow
$TestCommand = "Test-Logging-Event: $(Get-Date)"
Invoke-Expression $TestCommand

Write-Host "[+] Test ScriptBlock event generated." -ForegroundColor Green


# ==========================================================
# 5) DISPLAY INSTRUCTIONS
# ==========================================================
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " PowerShell Logging Successfully Enabled!" -ForegroundColor Green
Write-Host " You can verify logging here:" -ForegroundColor White
Write-Host "   Event Viewer → Applications and Services Logs →" -ForegroundColor White
Write-Host "   Microsoft → Windows PowerShell → Operational" -ForegroundColor White
Write-Host ""
Write-Host " LOOK FOR: Event ID 4104 (ScriptBlock Logging)" -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[DONE] Script finished safely." -ForegroundColor Green
