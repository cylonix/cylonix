# Generate UUIDs for Cylonix WiX project

Write-Host "Generating UUIDs for Cylonix WiX Installer..." -ForegroundColor Green
Write-Host ""

$components = @(
    "ProductUpgradeCode",
    "MainExecutableGuid",
    "ShareLauncherExecutableGuid",
    "RuntimeLibrariesGuid",
    "DocumentationGuid",
    "FlutterDataGuid",
    "CylonixdExecutableGuid",
    "ApplicationShortcutsGuid",
    "FirewallRulesGuid",
    "RegistryEntriesGuid"
)

foreach ($component in $components) {
    $guid = [System.Guid]::NewGuid().ToString().ToUpper()
    Write-Host "<?define $component = `"{$guid}`" ?>" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Copy these GUIDs to your Variables.wxs file" -ForegroundColor Green