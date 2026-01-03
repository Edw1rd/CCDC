# ================================
# Network Connection Audit
# Lists processes with network activity
# ================================

$OutputDir = "C:\CCDC"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutTxt = "$OutputDir\NetworkConnections_$Timestamp.txt"
$OutCsv = "$OutputDir\NetworkConnections_$Timestamp.csv"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Get-ProcessInfo {
    param([int]$Pid)

    $info = @{
        Name      = ""
        Path      = ""
        Cmd       = ""
        User      = ""
        Parent    = ""
        Signature = ""
    }

    try {
        $proc = Get-Process -Id $Pid -ErrorAction Stop
        $info.Name = $proc.ProcessName
        try { $info.Path = $proc.Path } catch {}
    } catch {
        return $info
    }

    try {
        $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$Pid"
        $info.Cmd = $cim.CommandLine
        $info.Parent = $cim.ParentProcessId

        try {
            $owner = Invoke-CimMethod -InputObject $cim -MethodName GetOwner
            if ($owner.ReturnValue -eq 0) {
                $info.User = "$($owner.Domain)\$($owner.User)"
            }
        } catch {}
    } catch {}

    if ($info.Path -and (Test-Path $info.Path)) {
        try {
            $sig = Get-AuthenticodeSignature $info.Path
            $info.Signature = $sig.Status
        } catch {}
    }

    return $info
}

$results = @()

#  TCP CONNECTIONS
foreach ($c in Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $pinfo = Get-ProcessInfo -Pid $c.OwningProcess

    $results += [pscustomobject]@{
        Protocol      = "TCP"
        State         = $c.State
        LocalAddress  = $c.LocalAddress
        LocalPort     = $c.LocalPort
        RemoteAddress = $c.RemoteAddress
        RemotePort    = $c.RemotePort
        PID           = $c.OwningProcess
        Process       = $pinfo.Name
        Path          = $pinfo.Path
        User          = $pinfo.User
        CommandLine   = $pinfo.Cmd
        ParentPID     = $pinfo.Parent
        Signature     = $pinfo.Signature
    }
}

# UDP ENDPOINTS
foreach ($u in Get-NetUDPEndpoint -ErrorAction SilentlyContinue) {
    $pinfo = Get-ProcessInfo -Pid $u.OwningProcess

    $results += [pscustomobject]@{
        Protocol      = "UDP"
        State         = ""
        LocalAddress  = $u.LocalAddress
        LocalPort     = $u.LocalPort
        RemoteAddress = ""
        RemotePort    = ""
        PID           = $u.OwningProcess
        Process       = $pinfo.Name
        Path          = $pinfo.Path
        User          = $pinfo.User
        CommandLine   = $pinfo.Cmd
        ParentPID     = $pinfo.Parent
        Signature     = $pinfo.Signature
    }
}

# SAVE FILES
$results | Export-Csv -Path $OutCsv -NoTypeInformation -Encoding UTF8

"==== Network Activity Report ====" | Out-File $OutTxt
"Generated: $(Get-Date)" | Add-Content $OutTxt
"" | Add-Content $OutTxt

foreach ($r in $results) {
    Add-Content $OutTxt "----------------------------------------"
    Add-Content $OutTxt "Process   : $($r.Process)"
    Add-Content $OutTxt "PID       : $($r.PID)"
    Add-Content $OutTxt "User      : $($r.User)"
    Add-Content $OutTxt "Path      : $($r.Path)"
    Add-Content $OutTxt "Protocol  : $($r.Protocol)"
    Add-Content $OutTxt "Local     : $($r.LocalAddress):$($r.LocalPort)"
    Add-Content $OutTxt "Remote    : $($r.RemoteAddress):$($r.RemotePort)"
    Add-Content $OutTxt "Signature : $($r.Signature)"
    Add-Content $OutTxt "Command   : $($r.CommandLine)"
}

Write-Host "[OK] Network inspection completed."
Write-Host "[OK] TXT saved to: $OutTxt"
Write-Host "[OK] CSV saved to: $OutCsv"
