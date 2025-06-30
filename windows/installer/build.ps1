param(
    [string]$WixPath = "C:\Program Files (x86)\WiX Toolset v3.14\bin",
    [switch]$Clean
)

function Invoke-FlutterHarvest {
    param(
        [string]$WixPath,
        [string]$FlutterDataDir
    )

    Write-Host "Harvesting Flutter data files..." -ForegroundColor Yellow

    # Check if Flutter data directory exists
    if (!(Test-Path $FlutterDataDir)) {
        throw "Flutter data directory not found at $FlutterDataDir. Please run 'flutter build windows' first."
    }

    # Check if Heat.exe exists
    $heatExe = Join-Path $WixPath "heat.exe"
    if (!(Test-Path $heatExe)) {
        throw "WiX Heat tool not found at $heatExe. Please install WiX Toolset."
    }

    Write-Host "Flutter data directory: $FlutterDataDir" -ForegroundColor Cyan
    Write-Host "WiX directory: $WixPath" -ForegroundColor Cyan

    # Generate WiX fragment for Flutter data
    $heatArgs = @(
        "dir"
        $FlutterDataDir
        "-cg"
        "FlutterDataFiles"
        "-gg"
        "-scom"
        "-sreg"
        "-sfrag"
        "-srd"
        "-dr"
        "FlutterDataFolder"
        "-var"
        "var.FlutterDataDir"
        "-out"
        "FlutterDataFiles.wxs"
    )

    Write-Host "Running: heat.exe $($heatArgs -join ' ')" -ForegroundColor Gray

    $heatProcess = Start-Process -FilePath $heatExe -ArgumentList $heatArgs -NoNewWindow -Wait -PassThru

    if ($heatProcess.ExitCode -ne 0) {
        throw "Heat harvesting failed with error code $($heatProcess.ExitCode)"
    }

    if (!(Test-Path "FlutterDataFiles.wxs")) {
        throw "FlutterDataFiles.wxs was not generated"
    }

    # Post-process the generated file to add the include
    Write-Host "Adding Variables.wxs include to FlutterDataFiles.wxs..." -ForegroundColor Yellow
    $content = Get-Content "FlutterDataFiles.wxs" -Raw
    $updatedContent = $content -replace '<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">', @"
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
    <?include Variables.wxs ?>
"@

    Set-Content -Path "FlutterDataFiles.wxs" -Value $updatedContent -Encoding UTF8

    Write-Host "Flutter data files harvested successfully!" -ForegroundColor Green

    # Show some info about generated files
    $fileCount = (Select-String -Path "FlutterDataFiles.wxs" -Pattern "File Id").Count
    Write-Host "Generated $fileCount file entries" -ForegroundColor Cyan
}
function Invoke-FlutterRuntimeHarvest {
    param(
        [string]$WixPath,
        [string]$FlutterReleaseDir
    )

    Write-Host "Harvesting Flutter runtime files (DLLs only)..." -ForegroundColor Yellow

    # Check if Flutter release directory exists
    if (!(Test-Path $FlutterReleaseDir)) {
        throw "Flutter release directory not found at $FlutterReleaseDir. Please run 'flutter build windows' first."
    }

    # Check if Heat.exe exists
    $heatExe = Join-Path $WixPath "heat.exe"
    if (!(Test-Path $heatExe)) {
        throw "WiX Heat tool not found at $heatExe. Please install WiX Toolset."
    }

    Write-Host "Flutter release directory: $FlutterReleaseDir" -ForegroundColor Cyan
    Write-Host "WiX directory: $WixPath" -ForegroundColor Cyan

    # Create a temporary directory with only DLL files
    $tempDllDir = Join-Path $env:TEMP "FlutterDlls"
    if (Test-Path $tempDllDir) {
        Remove-Item -Path $tempDllDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempDllDir -Force | Out-Null

    # Copy only DLL files to temp directory
    $dllFiles = Get-ChildItem -Path $FlutterReleaseDir -Filter "*.dll" -File
    Write-Host "Found $($dllFiles.Count) DLL files:" -ForegroundColor Cyan

    foreach ($dll in $dllFiles) {
        Copy-Item -Path $dll.FullName -Destination $tempDllDir
        Write-Host "  - $($dll.Name)" -ForegroundColor Gray
    }

    if ($dllFiles.Count -eq 0) {
        throw "No DLL files found in $FlutterReleaseDir"
    }

    # Generate WiX fragment for DLL files only
    $heatArgs = @(
        "dir"
        $tempDllDir
        "-cg"
        "FlutterRuntimeFiles"
        "-gg"
        "-scom"
        "-sreg"
        "-sfrag"
        "-srd"
        "-dr"
        "INSTALLFOLDER"  # Install to main application folder
        "-var"
        "var.FlutterReleaseDir"
        "-out"
        "FlutterRuntimeFiles_temp.wxs"
    )

    Write-Host "Running: heat.exe $($heatArgs -join ' ')" -ForegroundColor Gray

    $heatProcess = Start-Process -FilePath $heatExe -ArgumentList $heatArgs -NoNewWindow -Wait -PassThru

    if ($heatProcess.ExitCode -ne 0) {
        throw "Heat harvesting failed with error code $($heatProcess.ExitCode)"
    }

    if (!(Test-Path "FlutterRuntimeFiles_temp.wxs")) {
        throw "FlutterRuntimeFiles_temp.wxs was not generated"
    }

    # Post-process the generated file to fix paths and add include
    Write-Host "Post-processing FlutterRuntimeFiles.wxs..." -ForegroundColor Yellow
    $content = Get-Content "FlutterRuntimeFiles_temp.wxs" -Raw

    # Add Variables.wxs include
    $updatedContent = $content -replace '<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">', @"
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
    <?include Variables.wxs ?>
"@

    Set-Content -Path "FlutterRuntimeFiles.wxs" -Value $updatedContent -Encoding UTF8

    # Clean up temp files
    Remove-Item "FlutterRuntimeFiles_temp.wxs" -Force
    Remove-Item -Path $tempDllDir -Recurse -Force

    Write-Host "Flutter runtime files (DLLs only) harvested successfully!" -ForegroundColor Green
    Write-Host "Generated $($dllFiles.Count) DLL entries" -ForegroundColor Cyan
}

Write-Host "Building Cylonix WiX Installer with Flutter Data Harvesting..." -ForegroundColor Green

# Set environment variables
$ProjectDir = $PSScriptRoot
$OutputDir = Join-Path $ProjectDir "bin"
$TempDir = Join-Path $ProjectDir "temp"
$FlutterReleaseDir = "..\..\build\windows\x64\runner\Release"
$FlutterDataDir = "$FlutterReleaseDir\data"

# Clean if requested
if ($Clean) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    if (Test-Path $OutputDir) { Remove-Item -Path $OutputDir -Recurse -Force }
    if (Test-Path $TempDir) { Remove-Item -Path $TempDir -Recurse -Force }
    if (Test-Path "FlutterDataFiles.wxs") { Remove-Item "FlutterDataFiles.wxs" -Force }
    if (Test-Path "FlutterRuntimeFiles.wxs") { Remove-Item "FlutterRuntimeFiles.wxs" -Force }
}

# Create output directories
if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force }
if (!(Test-Path $TempDir)) { New-Item -ItemType Directory -Path $TempDir -Force }

Write-Host "Copying bitmap and icon files to $TempDir..." -ForegroundColor Yellow
Copy-Item -Path "$ProjectDir\*.bmp" -Destination $TempDir -Force
Copy-Item -Path "$ProjectDir\cylonix.ico" -Destination $TempDir -Force

# Check prerequisites
if (!(Test-Path "$WixPath\candle.exe")) {
    Write-Error "WiX Toolset not found at $WixPath"
    exit 1
}

$FlutterExe = "$FlutterReleaseDir\cylonix.exe"
if (!(Test-Path $FlutterExe)) {
    Write-Error "Flutter build not found at $FlutterExe"
    Write-Host "Please run 'flutter build windows' first"
    exit 1
}

try {
    # Step 1: Harvest Flutter data files
    Write-Host "Step 1: Harvesting Flutter data files..." -ForegroundColor Yellow
    Invoke-FlutterHarvest -WixPath $WixPath -FlutterDataDir $FlutterDataDir

    # Step 2: Harvest Flutter runtime files (DLLs, EXE)
    Write-Host "Step 2: Harvesting Flutter runtime files..." -ForegroundColor Yellow
    Invoke-FlutterRuntimeHarvest -WixPath $WixPath -FlutterReleaseDir $FlutterReleaseDir

    # Step 3: Compile WiX source files
    Write-Host "Step 3: Compiling WiX source files..." -ForegroundColor Yellow

    $candleArgs = @(
        "-out", "$TempDir\"
        "-ext", "WixUtilExtension"
        "-ext", "WixFirewallExtension"
        "-ext", "WixUIExtension"
        "-dShareExtDir=$TempDir"
        "Product.wxs"
        "Components.wxs"
        "FlutterDataFiles.wxs"
        "FlutterRuntimeFiles.wxs"  # Add the runtime files
    )

    & "$WixPath\candle.exe" @candleArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Compilation failed with exit code $LASTEXITCODE"
    }

    # Step 4: Link installer package
    Write-Host "Step 4: Linking installer package..." -ForegroundColor Yellow

    $lightArgs = @(
        "-out", "$OutputDir\CylonixInstaller.msi"
        "-ext", "WixUtilExtension"
        "-ext", "WixFirewallExtension"
        "-ext", "WixUIExtension"
        "-sice:ICE60"  # Suppress ICE60 warnings for font files
        "$TempDir\Product.wixobj"
        "$TempDir\Components.wixobj"
        "$TempDir\FlutterDataFiles.wixobj"
        "$TempDir\FlutterRuntimeFiles.wixobj"  # Add the runtime files
    )

    & "$WixPath\light.exe" @lightArgs

    if ($LASTEXITCODE -ne 0) {
        throw "Linking failed with exit code $LASTEXITCODE"
    }

    # Step 5: Clean up
    Write-Host "Step 5: Cleaning up temporary files..." -ForegroundColor Yellow
    Remove-Item -Path $TempDir -Recurse -Force

    $installerPath = "$OutputDir\CylonixInstaller.msi"
    $fileInfo = Get-Item $installerPath

    Write-Host "SUCCESS!" -ForegroundColor Green
    Write-Host "Installer created: $installerPath" -ForegroundColor Green
    Write-Host "File size: $([math]::Round($fileInfo.Length / 1MB, 2)) MB" -ForegroundColor Green

    # Open the output directory
    Start-Process explorer.exe -ArgumentList $OutputDir

} catch {
    Write-Error "Build failed: $_"
    exit 1
}