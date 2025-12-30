$OutputDir = "C:\CCDC"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutTxt = "$OutputDir\NetworkConnections_$Timestamp.txt"
$OutCsv = "$OutputDir\NetworkConnections_$Timestamp.csv"

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

function Safe([object]$v) {
    if ($null -eq $v) { return "" }
    return [string]$v
}

function Get-ProcessInfo($Pid) {
    $info = @{
        Name = ""
        Path = ""
        Cmd  = ""
        User = ""
        Parent = ""
        Signature = ""
    }

    try {
        $p = Get-Process -Id $Pid -ErrorAction Stop
        $info.Name = $p.ProcessName
        try { $info.Path = $p.Path } catch {}
    } catch { return $info }

    try {
        $c = Get-CimInstance Win32_Process -Filter "ProcessId=$Pid"
        $info.Cmd = $c.CommandLine
        $info.Parent = $c.ParentProcessId

        try {
            $owner = Invoke-CimMethod -InputObject $c -MethodName GetOwner
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

# TCP connections
foreach ($c in Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $pinfo = Get-ProcessInfo $c.OwningProcess

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

# UDP endpoints
foreach ($u in Get-NetUDPEndpoint -ErrorAction SilentlyContinue) {
    $pinfo = Get-ProcessInfo $u.OwningProcess

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

# Save reports
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
Write-Host "[OK] TXT: $OutTxt"
Write-Host "[OK] CSV: $OutCsv"
