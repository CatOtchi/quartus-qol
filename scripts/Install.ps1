param([string]$QuartusRoot, [string]$InstallRoot = (Join-Path $env:LOCALAPPDATA 'QuartusQOL'),
      [switch]$PrepareOnly)
. "$PSScriptRoot/Common.ps1"
try {
    # An isolated preparation directory can be tested while an unrelated Quartus runs.
    $defaultRoot = Join-Path $env:LOCALAPPDATA 'QuartusQOL'
    if (!$PrepareOnly -or [IO.Path]::GetFullPath($InstallRoot) -eq [IO.Path]::GetFullPath($defaultRoot) -or (Test-Path (Join-Path $InstallRoot 'installation.json'))) { Assert-QuartusClosed }
    if (![Environment]::Is64BitOperatingSystem) { throw 'Windows x64 is required.' }
    $source = Split-Path $PSScriptRoot
    $version = ([IO.File]::ReadAllText((Join-Path $source 'VERSION'))).Trim()
    $InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
    if ($InstallRoot -match '[{}\r\n]') { throw 'Install path cannot contain braces or newlines.' }
    if ($InstallRoot.TrimEnd('\') -eq [IO.Path]::GetPathRoot($InstallRoot).TrimEnd('\')) { throw 'Choose a dedicated installation folder, not the root of a drive.' }
    if ($InstallRoot.TrimEnd('\') -eq $source.TrimEnd('\')) { throw 'Install into a different directory from the download.' }
    $ownership = Join-Path $InstallRoot '.quartus-qol-install'
    if (!(Test-Path $ownership) -and ((Test-Path (Join-Path $InstallRoot app)) -or (Test-Path (Join-Path $InstallRoot app-previous)))) { throw 'This directory already has an app folder and is not a QOL-managed install. Choose a new folder.' }
    if (!$PrepareOnly) { $QuartusRoot = Get-QuartusRoot $QuartusRoot; Assert-CompatibleQuartus $QuartusRoot }
    New-Item -ItemType Directory -Force -Path $InstallRoot,(Join-Path $InstallRoot 'user'),(Join-Path $InstallRoot 'tools'),(Join-Path $InstallRoot 'cache') | Out-Null
    Write-Utf8 $ownership 'Quartus QOL managed installation'
    $manifest = Get-Content -Raw (Join-Path $source 'dependencies.json') | ConvertFrom-Json
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    foreach ($dependency in $manifest) {
        $tool = Join-Path $InstallRoot ('tools/' + $dependency.id)
        $executable = Join-Path $tool $dependency.exe
        $receipt = Join-Path $tool '.archive-sha256'
        if ((Test-Path $executable) -and (Test-Path $receipt) -and ([IO.File]::ReadAllText($receipt)).Trim() -eq $dependency.sha256) {
            Write-Host "Keeping $($dependency.id)"
            continue
        }
        $archive = Join-Path $InstallRoot ('cache/' + $dependency.id + '.zip')
        if (!(Test-Path $archive) -or (Get-FileHash $archive -Algorithm SHA256).Hash -ne $dependency.sha256) {
            Write-Host "Downloading $($dependency.id)..."
            Invoke-WebRequest -UseBasicParsing -Uri $dependency.url -OutFile ($archive + '.part')
            if ((Get-FileHash ($archive + '.part') -Algorithm SHA256).Hash -ne $dependency.sha256) { throw "Checksum mismatch: $($dependency.id)" }
            Move-Item -LiteralPath ($archive + '.part') -Destination $archive -Force
        }
        if ((Get-FileHash $archive -Algorithm SHA256).Hash -ne $dependency.sha256) { throw "Checksum mismatch: $archive" }
        $extract = Join-Path $InstallRoot ('staging-' + $dependency.id)
        Remove-OwnedDirectory $extract $InstallRoot
        Expand-Archive -LiteralPath $archive -DestinationPath $extract
        $matches = @(Get-ChildItem -LiteralPath $extract -Recurse -File -Filter $dependency.exe)
        if ($matches.Count -ne 1) { throw "Archive layout changed: $($dependency.id)" }
        $payload = $matches[0].Directory.FullName
        Remove-OwnedDirectory $tool $InstallRoot
        if ($payload -eq $extract) { Move-Item -LiteralPath $extract -Destination $tool }
        else { Move-Item -LiteralPath $payload -Destination $tool; Remove-OwnedDirectory $extract $InstallRoot }
        Write-Utf8 $receipt $dependency.sha256
        $testArgs = @($dependency.testArgs)
        & $executable @testArgs
        if ($LASTEXITCODE -ne 0) { throw "Could not run $($dependency.id)." }
    }
    $stage = Join-Path $InstallRoot 'app-next'
    Remove-OwnedDirectory $stage $InstallRoot
    Copy-Item -LiteralPath (Join-Path $source 'app') -Destination $stage -Recurse
    foreach ($relative in @('qolnative-v13.dll','qolpump.dll','qolworker-v3.exe')) {
        $expected = (Get-FileHash (Join-Path $source "app/$relative") -Algorithm SHA256).Hash
        if ((Get-FileHash (Join-Path $stage $relative) -Algorithm SHA256).Hash -ne $expected) { throw "Copy failed: $relative" }
    }
    $previous = Join-Path $InstallRoot 'app-previous'
    Remove-OwnedDirectory $previous $InstallRoot
    $app = Join-Path $InstallRoot 'app'
    if (Test-Path $app) { Move-Item -LiteralPath $app -Destination $previous }
    Move-Item -LiteralPath $stage -Destination $app
    $installedScripts = Join-Path $InstallRoot 'scripts'
    New-Item -ItemType Directory -Path $installedScripts -Force | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $source 'scripts') -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $installedScripts -Force }
    Copy-Item -LiteralPath (Join-Path $source 'Uninstall.cmd') -Destination $InstallRoot -Force
    Copy-Item -LiteralPath (Join-Path $source 'config.example.tcl') -Destination (Join-Path $InstallRoot 'user/config.example.tcl') -Force
    Copy-Item -LiteralPath (Join-Path $source 'VERSION') -Destination $InstallRoot -Force
    if (!$PrepareOnly) {
        Invoke-StartupHook (Join-Path $InstallRoot 'scripts/StartupHook.ps1') $QuartusRoot $InstallRoot Install
        Write-Utf8 (Join-Path $InstallRoot 'installation.json') (@{version=$version;quartusRoot=$QuartusRoot;installRoot=$InstallRoot} | ConvertTo-Json)
    }
    Write-Host "Quartus QOL $version is ready in $InstallRoot" -ForegroundColor Green
    if ($PrepareOnly) { Write-Host 'Preparation only: Quartus startup was not changed.' }
    else { Write-Host 'Open Quartus normally. Run this installer again to upgrade; your settings will be kept.' }
} catch {
    Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
