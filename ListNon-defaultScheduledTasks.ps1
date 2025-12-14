$ReportDir  = "C:\CCDC"
$ReportFile = "$ReportDir\ScheduledTasks_Report.txt"

# Create report directory if missing
if (-not (Test-Path $ReportDir)) {
    New-Item -ItemType Directory -Path $ReportDir | Out-Null
}

# Clear previous report
"" | Out-File -FilePath $ReportFile -Encoding UTF8

# Paths that usually belong to Windows / Microsoft
$DefaultPaths = @(
    "\Microsoft\Windows",
    "\Microsoft"
)

# Get all scheduled tasks
$Tasks = Get-ScheduledTask | Sort-Object TaskPath, TaskName

foreach ($t in $Tasks) {

    $TaskName = $t.TaskName
    $TaskPath = $t.TaskPath.Trim()

    # Skip default Microsoft tasks
    $IsDefault = $false
    foreach ($p in $DefaultPaths) {
        if ($TaskPath.StartsWith($p)) {
            $IsDefault = $true
            break
        }
    }

    if ($IsDefault) { continue }

    # Get task actions (what it runs)
    $Actions = ($t.Actions | ForEach-Object {
        $_.Execute + " " + $_.Arguments
    }).Trim()

    # Write task info to report
    Add-Content $ReportFile "======================================="
    Add-Content $ReportFile "Task Name : $TaskName"
    Add-Content $ReportFile "Task Path : $TaskPath"
    Add-Content $ReportFile "Author    : $($t.Author)"
    Add-Content $ReportFile "Actions   : $Actions"
    Add-Content $ReportFile ""
}

Write-Host "[OK] Scan completed. Report saved to $ReportFile" -ForegroundColor Green
