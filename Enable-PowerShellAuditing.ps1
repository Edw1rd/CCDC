# PowerShell ScriptBlock Logging saves all executed commands under Event ID 4104.

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

# Enable ScriptBlock Logging
$SBLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
Set-SafeRegistryValue -Path $SBLPath -Name "EnableScriptBlockLogging" -Value 1

# Enable Module Logging
$MLPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
Set-SafeRegistryValue -Path $MLPath -Name "EnableModuleLogging" -Value 1

# Enable Transcription Logging
$TranscriptPath = "C:\PS_Transcript"
if (-not (Test-Path $TranscriptPath)) {
    New-Item -ItemType Directory -Path $TranscriptPath | Out-Null
}

$TransPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription"
Set-SafeRegistryValue -Path $TransPath -Name "EnableTranscripting" -Value 1
Set-SafeRegistryValue -Path $TransPath -Name "OutputDirectory" -Value $TranscriptPath

# Generate test ScriptBlock event silently
"Test ScriptBlock Logging Event $(Get-Date)" | Out-Null
