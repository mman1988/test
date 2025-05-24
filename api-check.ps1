
# API Script Executor - Cross-Platform Compatible
param(
    [string]$ScriptsPath = "api-ps-files",
    [string]$LogsPath = "logs"
)

# Determine the correct PowerShell executable (pwsh for macOS/Linux, powershell for Windows)
$powerShellCmd = if ($IsWindows) { "powershell" } else { "pwsh" }

# Clean up and recreate the logs directory
if (Test-Path $LogsPath) {
    Remove-Item -Path $LogsPath -Recurse -Force
}
New-Item -ItemType Directory -Path $LogsPath -Force | Out-Null

# Initialize counters and log file
$failedScripts = @()
$totalScripts = 0
$passedScripts = 0
$failedCount = 0
$failedLogFile = "$LogsPath\failed_apis_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

"API Failed Calls Log - $(Get-Date)" | Out-File -FilePath $failedLogFile
"============================================================" | Add-Content -Path $failedLogFile
"" | Add-Content -Path $failedLogFile

Write-Host "Starting API checks..." -ForegroundColor Cyan

# Collect all script files
$apiScripts = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -ErrorAction SilentlyContinue

if ($apiScripts.Count -eq 0) {
    Write-Host "No scripts found in '$ScriptsPath'!" -ForegroundColor Red
    exit 1
}

foreach ($script in $apiScripts) {
    $totalScripts++
    Write-Host ""
    Write-Host "Running $($script.Name)"
    Write-Host "-------------------------"

    # Run the script and capture output/errors to temp files
    $outFile = "temp_output.txt"
    $errFile = "temp_error.txt"

    if (Test-Path $outFile) { Remove-Item $outFile -Force }
    if (Test-Path $errFile) { Remove-Item $errFile -Force }

    try {
        $process = Start-Process -FilePath $powerShellCmd `
                                 -ArgumentList "-File", $script.FullName `
                                 -Wait -PassThru `
                                 -RedirectStandardOutput $outFile `
                                 -RedirectStandardError $errFile `
                                 -NoNewWindow

        # Read outputs
        $output = if (Test-Path $outFile) { Get-Content $outFile -Raw } else { "" }
        $errorOut = if (Test-Path $errFile) { Get-Content $errFile -Raw } else { "" }

        # Cleanup temp files
        if (Test-Path $outFile) { Remove-Item $outFile -Force }
        if (Test-Path $errFile) { Remove-Item $errFile -Force }

        $combinedOutput = "$output`n$errorOut".Trim()

        if ($process.ExitCode -ne 0 -or $combinedOutput -match "ERROR:") {
            $failedCount++
            Write-Host "$($script.Name) FAILED" -ForegroundColor Red

            Add-Content -Path $failedLogFile -Value "Script: $($script.Name)"
            Add-Content -Path $failedLogFile -Value "Time: $(Get-Date)"
            Add-Content -Path $failedLogFile -Value "Output:"
            Add-Content -Path $failedLogFile -Value $combinedOutput
            Add-Content -Path $failedLogFile -Value "------------------------------------------------------------"
            Add-Content -Path $failedLogFile -Value ""

            $failedScripts += $script.Name
        } else {
            $passedScripts++
            Write-Host "$($script.Name) PASSED" -ForegroundColor Green
            if ($output) {
                Write-Host $output.Trim()
            }
        }

    } catch {
        $failedCount++
        $errorMessage = "EXECUTION ERROR: $($_.Exception.Message)"
        Write-Host "$($script.Name) EXECUTION FAILED" -ForegroundColor Red

        Add-Content -Path $failedLogFile -Value "Script: $($script.Name)"
        Add-Content -Path $failedLogFile -Value "Time: $(Get-Date)"
        Add-Content -Path $failedLogFile -Value "Execution Error:"
        Add-Content -Path $failedLogFile -Value $errorMessage
        Add-Content -Path $failedLogFile -Value "------------------------------------------------------------"
        Add-Content -Path $failedLogFile -Value ""

        $failedScripts += $script.Name
    }
}

# Final Summary
Write-Host ""
Write-Host "============================================================"
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host "Total Scripts: $totalScripts"
Write-Host "Passed: $passedScripts" -ForegroundColor Green
Write-Host "Failed: $failedCount" -ForegroundColor Red

if ($failedCount -gt 0) {
    Write-Host ""
    Write-Host "Failed script details written to: $failedLogFile" -ForegroundColor Yellow
    exit 1
} else {
    Remove-Item $failedLogFile -Force
    Write-Host "All scripts executed successfully." -ForegroundColor Green
    exit 0
}

