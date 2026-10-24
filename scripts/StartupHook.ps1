param([Parameter(Mandatory)][string]$QuartusRoot,
      [Parameter(Mandatory)][string]$InstallRoot,
      [ValidateSet('Install','Uninstall')][string]$Action = 'Install')
. "$PSScriptRoot/Common.ps1"
if ($Action -eq 'Install') { Assert-CompatibleQuartus $QuartusRoot (Join-Path $InstallRoot 'user/compatibility.dict') }
$target = Join-Path $QuartusRoot 'common/tcl/internal/qui_init.tcl'
$original = [IO.File]::ReadAllText($target)
$pattern = '(?ms)^# BEGIN QUARTUS_QOL_NATIVE\r?\n.*?^# END QUARTUS_QOL_NATIVE[^\S\r\n]*(?:\r?\n|$)'
$blocks = [regex]::Matches($original, $pattern)
if ($blocks.Count -gt 1) { throw 'Multiple QOL hooks found; review startup before continuing.' }
if ($original.Contains('# BEGIN QUARTUS_QOL_NATIVE') -and $blocks.Count -eq 0) { throw 'Incomplete QOL hook; review startup before continuing.' }
$bootstrap = (Join-Path $InstallRoot 'app/bootstrap.tcl').Replace('\','/')
if ($bootstrap -match '[{}\r\n]') { throw 'Install path cannot contain braces or newlines.' }
$clean = [regex]::Replace($original, $pattern, '')
if ($Action -eq 'Uninstall') {
    if ($blocks.Count -eq 0) { return }
    if (!$blocks[0].Value.Contains($bootstrap)) { throw 'The startup hook belongs to a different QOL installation; leaving it alone.' }
    $next = $clean
} else {
    $next = $clean.TrimEnd("`r","`n") + "`r`n`r`n# BEGIN QUARTUS_QOL_NATIVE`r`nif {[catch {source {$bootstrap}} qol_startup_error]} {`r`n    post_message -type warning `"Quartus QOL: `$qol_startup_error`"`r`n}`r`n# END QUARTUS_QOL_NATIVE`r`n"
}
if ($next -eq $original) { return }
# Preserve a before-image without overwriting a previous installation's backup.
$backup = $target + '.quartus-qol-backup'
if (!(Test-Path $backup)) { [IO.File]::WriteAllBytes($backup, [IO.File]::ReadAllBytes($target)) }
$temporary = $target + '.quartus-qol.tmp'
Write-Utf8 $temporary $next
$replacementBackup = $target + '.replace-' + [Guid]::NewGuid().ToString('N')
try { [IO.File]::Replace($temporary, $target, $replacementBackup) }
finally {
    if (Test-Path $temporary) { Remove-Item -LiteralPath $temporary }
    if (Test-Path $replacementBackup) { Remove-Item -LiteralPath $replacementBackup }
}
