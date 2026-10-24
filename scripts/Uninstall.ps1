param([string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'QuartusQOL'))
. "$PSScriptRoot/Common.ps1"
try {
    Assert-QuartusClosed
    $state = Join-Path $InstallRoot 'installation.json'
    if (!(Test-Path $state)) { throw "No installation record in $InstallRoot" }
    $installation = Get-Content -Raw $state | ConvertFrom-Json
    Invoke-StartupHook "$PSScriptRoot/StartupHook.ps1" $installation.quartusRoot $InstallRoot Uninstall
    Remove-Item -LiteralPath $state
    Write-Host 'QOL startup disabled. Your settings and downloaded tools were kept.'
    Write-Host "You can delete $InstallRoot after closing Quartus if you want to remove them too."
} catch { Write-Host "Uninstall failed: $($_.Exception.Message)" -ForegroundColor Red; exit 1 }
