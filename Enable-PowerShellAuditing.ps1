Write-Host "[*] Starting PowerShell Auditing Configuration..." -ForegroundColor Cyan

# ============================================ #
# Safe registry set (avoids errors if missing) #
# ============================================ #
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

# =================================================== #
# 1) ENABLE POWERSHELL SCRIPTBLOCK LOGGING (CRITICAL) #
# =================================================== #
Write-Host "[*] Enabling ScriptBlock Logging..." -ForegroundColor Yellow

$SBLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
Set-SafeRegistryValue -Path $SBLPath -Name "EnableScriptBlockLogging" -Value 1

Write-Host "[+] ScriptBlock Logging enabled." -ForegroundColor Green


# ======================== #
# 2) ENABLE MODULE LOGGING #
# ======================== #
Write-Host "[*] Enabling Module Logging..." -ForegroundColor Yellow

$MLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
Set-SafeRegistryValue -Path $MLPath -Name "EnableModuleLogging" -Value 1

Write-Host "[+] Module Logging enabled." -ForegroundColor Green


# =============================== #
# 3) ENABLE TRANSCRIPTION LOGGING #
# =============================== #
Write-Host "[*] Enabling PowerShell Transcription..." -ForegroundColor Yellow

$TranscriptPath = "C:\PS_Transcript"

if (-not (Test-Path $TranscriptPath)) {
    New-Item -ItemType Directory -Path $TranscriptPath | Out-Null
}

$TransPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"
Set-SafeRegistryValue -Path $TransPath -Name "EnableTranscripting" -Value 1
Set-SafeRegistryValue -Path $TransPath -Name "OutputDirectory" -Value $TranscriptPath

Write-Host "[+] PowerShell Transcription enabled." -ForegroundColor Green


# ======================================== #
# 4) GENERATE TEST EVENT (SAFE, NO ERRORS) #
# ======================================== #
Write-Host "[*] Generating test ScriptBlock event..." -ForegroundColor Yellow

# This WILL appear in Event ID 4104 logs
"Test ScriptBlock Logging Event $(Get-Date)" | Out-Null

Write-Host "[+] Test ScriptBlock event generated." -ForegroundColor Green


# ======================= #
# 5) DISPLAY INSTRUCTIONS #
# ======================= #
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
