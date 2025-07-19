# share_launcher.ps1
param (
    [string]$FilePath
)

# Define paths and settings
$tempFile = "$env:TEMP\cylonix_shared_files.txt"
$mutexName = "CylonixLauncherMutex"
$timeoutSeconds = 2  # Wait 2 seconds to collect files

# Try to resolve exePath from registry (64-bit and 32-bit uninstall keys)
$exePath = $null
$uninstallPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $uninstallPaths) {
    $uninstallEntry = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq "Cylonix Node Agent" }
    if ($uninstallEntry -and $uninstallEntry.InstallLocation) {
        $exePath = Join-Path $uninstallEntry.InstallLocation "cylonix.exe"
        Write-Host "Resolved exePath from registry: $exePath" -ForegroundColor Yellow
        break
    }
}

# Fallback to default paths
if (-not $exePath -or -not (Test-Path $exePath)) {
    $fallbackPaths = @(
        "$env:ProgramFiles\Cylonix\cylonix.exe",
        "${env:ProgramFiles(x86)}\Cylonix\cylonix.exe"
    )
    foreach ($path in $fallbackPaths) {
        if (Test-Path $path) {
            $exePath = $path
            Write-Host "Resolved exePath from fallback: $exePath" -ForegroundColor Yellow
            break
        }
    }
}

# Verify executable exists
if (-not $exePath -or -not (Test-Path $exePath)) {
    Write-Error "Executable not found at any known path"
    exit 1
}

# Create or acquire mutex to ensure single-instance coordination
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$null)
if (-not $mutex.WaitOne(0, $false)) {
    # Another instance is running; append file path and exit
    if ($FilePath -and (Test-Path $FilePath)) {
        Add-Content -Path $tempFile -Value $FilePath -Force
    }
    $mutex.Close()
    exit
}

try {
    # Append the file path to the temporary file
    if ($FilePath -and (Test-Path $FilePath)) {
        Add-Content -Path $tempFile -Value $FilePath -Force
    }

    # Wait briefly to collect additional files
    Start-Sleep -Seconds $timeoutSeconds

    # Read all file paths, remove duplicates, and verify existence
    if (Test-Path $tempFile) {
        $filePaths = Get-Content -Path $tempFile | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
        if ($filePaths) {
            # Log collected files
            Write-Host "Collected files: $($filePaths -join ', ')" -ForegroundColor Green
            # Create quoted argument string
            $arguments = ($filePaths | ForEach-Object { "`"$_`"" }) -join " "
            $arguments = "--share $arguments"
            Write-Host "Launching: $exePath $arguments" -ForegroundColor Green
            # Launch cylonix.exe with all file paths
            Start-Process -FilePath $exePath -ArgumentList $arguments -NoNewWindow
            # Clear the temporary file
            Clear-Content -Path $tempFile -Force
        } else {
            Write-Host "No valid files to process" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "Error: $_"
    Start-Sleep -Seconds 25  # Allow time to read error message
}
finally {
    # Release the mutex
    $mutex.ReleaseMutex()
    $mutex.Close()
}