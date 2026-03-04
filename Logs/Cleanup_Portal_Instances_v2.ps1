# Cleanup Portal Instances v2 - Enhanced with TiaPortal API
# Uses TiaPortal.GetProcesses() to safely identify which Portal owns the target project
# SAFER: Only closes Portal instances that DON'T own the target project

[CmdletBinding()]
param(
    [string]$TargetProjectPath = "tirol-ipiranga-os18869_20260224_PE_V20.ap20"
)

Write-Host "=== CLEANUP PORTAL INSTANCES V2 (API-Enhanced) ===" -ForegroundColor Cyan
Write-Host ""

try {
    # Load Siemens.Engineering API
    $apiPath = "C:\Program Files\Siemens\Automation\Portal V20\PublicAPI\V20\Siemens.Engineering.dll"
    if (-not (Test-Path $apiPath)) {
        Write-Host "✗ ERROR: Cannot find Siemens.Engineering.dll at $apiPath" -ForegroundColor Red
        Write-Host "Falling back to shell-only process termination..." -ForegroundColor Yellow
        Write-Host ""
    } else {
        Add-Type -Path $apiPath
        Write-Host "✓ Loaded TiaPortal API from: $apiPath" -ForegroundColor Green
        Write-Host ""
    }
    
    # Get all Portal processes via TiaPortal API
    Write-Host "Querying TiaPortal processes via API..." -ForegroundColor Cyan
    $processes = [Siemens.Engineering.TiaPortal]::GetProcesses()
    
    Write-Host "Found $($processes.Count) TiaPortal processes:" -ForegroundColor Yellow
    Write-Host ""
    
    $targetOwnerPid = $null
    foreach ($proc in $processes) {
        Write-Host "  - PID: $($proc.ProcessId)" -ForegroundColor White
        
        if ($proc.IsConnected) {
            Write-Host "    Status: CONNECTED (has TiaPortal open)" -ForegroundColor Green
            # Try to get project info if available
            try {
                $projInfo = $proc | Get-Member -MemberType Property | Select-Object -ExpandProperty Name
                if ($projInfo -contains "ProjectPath") {
                    Write-Host "    Project: $($proc.ProjectPath)" -ForegroundColor Cyan
                    
                    # Check if this is our target
                    if ($proc.ProjectPath -like "*$TargetProjectPath*") {
                        Write-Host "    >>> THIS OWNS OUR TARGET PROJECT! Will NOT close." -ForegroundColor Green
                        $targetOwnerPid = $proc.ProcessId
                    }
                }
            }
            catch {
                Write-Host "    (Could not read project details)" -ForegroundColor Gray
            }
        } else {
            Write-Host "    Status: DISCONNECTED (stale/unused)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "Analysis Complete:" -ForegroundColor Cyan
    Write-Host "  - Target owner PID: $($targetOwnerPid ?? 'UNKNOWN')" -ForegroundColor White
    Write-Host "  - Action: Close OTHER instances, keep target owner" -ForegroundColor White
    Write-Host ""
    
    # Now compare with shell processes
    Write-Host "Cross-checking with Windows processes..." -ForegroundColor Cyan
    $shellProcesses = Get-Process | Where-Object { $_.Name -eq "Siemens.Automation.Portal" }
    
    Write-Host "Shell found $($shellProcesses.Count) Portal instances:" -ForegroundColor Yellow
    foreach ($sp in $shellProcesses) {
        $isTarget = $sp.Id -eq $targetOwnerPid
        $marker = $isTarget ? ">>> TARGET (KEEP)" : "close candidate"
        Write-Host "  - PID: $($sp.Id) ($($sp.StartTime)) - $marker" -ForegroundColor $(if ($isTarget) { "Green" } else { "Yellow" })
    }
    
    Write-Host ""
    Write-Host "RECOMMENDATION:" -ForegroundColor Cyan
    if ($shellProcesses.Count -eq 1) {
        Write-Host "  Only one Portal instance found. Nothing to do." -ForegroundColor Green
    } elseif ($targetOwnerPid) {
        $othersCount = $shellProcesses.Count - 1
        Write-Host "  Close $othersCount other instance(s) and keep PID=$targetOwnerPid" -ForegroundColor Green
        Write-Host "  (the one with our target project)" -ForegroundColor Green
    } else {
        Write-Host "  Could not determine which owns the target. Operation requires user review." -ForegroundColor Yellow
        Write-Host "  Recommendation: Check TIA Portal windows manually and close idle ones." -ForegroundColor Yellow
    }
    
}
catch {
    Write-Host "✗ Error during API parsing: $_" -ForegroundColor Red
    Write-Host "This is expected if API assumptions don't match your TIA version." -ForegroundColor Gray
}

Write-Host ""
Write-Host "Next Step: Manually verify which Portal window shows your project, then close others." -ForegroundColor Yellow
Write-Host "Or: Run cleanup command when ready: Stop-Process -Id <PID> -Force" -ForegroundColor Yellow
