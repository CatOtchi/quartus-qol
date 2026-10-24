Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:Utf8 = New-Object Text.UTF8Encoding($false)
$script:EditorHash = 'fd3982bf07b1b7ef227406cb612facff2646fb639f0df4eaeefa58cc30b9056d'
$script:OptionsHash = 'ed9e3a115915b04bb843c155faf2af01602c4333541f830a1c82f5bd380db64d'
function Write-Utf8($Path, $Text) { [IO.File]::WriteAllText($Path, $Text, $script:Utf8) }
function Assert-QuartusClosed {
    if (Get-Process -Name quartus -ErrorAction SilentlyContinue) {
        throw 'Close all Quartus windows before installing, upgrading or uninstalling. No files have been changed.'
    }
}
function Get-QuartusRoot([string]$Requested) {
    if ($Requested) {
        $candidate = [IO.Path]::GetFullPath($Requested.Trim('"'))
        if ($candidate.EndsWith('quartus.exe')) { $candidate = Split-Path (Split-Path $candidate) }
        if (!(Test-Path (Join-Path $candidate 'bin64/edt_tedq.dll'))) {
            throw "Expected a Quartus folder containing bin64: $candidate"
        }
        return $candidate
    }
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    if ($env:QUARTUS_ROOTDIR) { $candidates.Add($env:QUARTUS_ROOTDIR) }
    $command = Get-Command quartus.exe -ErrorAction SilentlyContinue
    if ($command) { $candidates.Add((Split-Path (Split-Path $command.Source))) }
    foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
        foreach ($pattern in @('altera_lite/*/quartus','intelFPGA_lite/*/quartus','altera/*/quartus','intelFPGA/*/quartus')) {
            foreach ($directory in @(Get-Item (Join-Path $drive.Root $pattern) -ErrorAction SilentlyContinue)) {
                $candidates.Add($directory.FullName)
            }
        }
    }
    $supported = @($candidates | Select-Object -Unique | Where-Object {
        $dll = Join-Path $_ 'bin64/edt_tedq.dll'
        (Test-Path $dll) -and (Get-FileHash $dll -Algorithm SHA256).Hash -eq $script:EditorHash
    })
    if ($supported.Count -eq 1) { return $supported[0] }
    if ($supported.Count -gt 1) {
        Write-Host 'Multiple compatible installations found:'
        $supported | ForEach-Object { Write-Host "  $_" }
    }
    return Get-QuartusRoot (Read-Host 'Paste your Quartus folder (for example C:\altera_lite\24.1std\quartus)')
}
function Assert-CompatibleQuartus([string]$Root) {
    foreach ($entry in @(@('edt_tedq.dll',$script:EditorHash), @('gcl_afcq.dll',$script:OptionsHash))) {
        $path = Join-Path $Root ('bin64/' + $entry[0])
        if (!(Test-Path $path) -or (Get-FileHash $path -Algorithm SHA256).Hash -ne $entry[1]) {
            throw 'Unsupported Quartus binaries. Only Windows x64 Lite 24.1std build 1077 is supported. Nothing was patched.'
        }
    }
}
function Remove-OwnedDirectory([string]$Path, [string]$Parent) {
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $boundary = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    if (!$full.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe cleanup path.' }
    if (Test-Path -LiteralPath $full) { Remove-Item -LiteralPath $full -Recurse -Force }
}
function Invoke-StartupHook([string]$Script, [string]$Root, [string]$InstallRoot, [string]$Action) {
    try { & $Script -QuartusRoot $Root -InstallRoot $InstallRoot -Action $Action }
    catch [UnauthorizedAccessException] {
        Write-Host 'Windows protects the Quartus folder. Approve the administrator prompt to update its startup hook.'
        # Only the hook operation elevates; downloads and user files stay under the current account.
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -QuartusRoot "{1}" -InstallRoot "{2}" -Action {3}' -f $Script,$Root,$InstallRoot,$Action
        $process = Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments -Wait -PassThru -WindowStyle Hidden
        if ($process.ExitCode -ne 0) { throw 'The startup hook could not be updated. Existing settings were preserved.' }
    }
}
