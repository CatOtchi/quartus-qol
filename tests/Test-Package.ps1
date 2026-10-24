param([Parameter(Mandatory)][string]$PreparedRoot, [Parameter(Mandatory)][string]$QuartusRoot)
. "$PSScriptRoot/../scripts/Common.ps1"
function Assert($Condition, $Message) { if (!$Condition) { throw "FAIL: $Message" } }
$root = Split-Path $PSScriptRoot
$testRoot = Join-Path $root ('.build/tests-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
try {
    foreach ($scriptFile in Get-ChildItem (Join-Path $root scripts) -Filter *.ps1) {
        $tokens=$null; $errors=$null
        [Management.Automation.Language.Parser]::ParseFile($scriptFile.FullName,[ref]$tokens,[ref]$errors) | Out-Null
        Assert (!$errors) "PowerShell syntax: $($scriptFile.Name)"
    }
    Assert-CompatibleQuartus $QuartusRoot
    $tcl = Join-Path $QuartusRoot 'bin64/tclsh86.exe'
    $app = Join-Path $PreparedRoot app
    foreach ($test in @('test-completion.tcl','test-settings.tcl')) {
        $result = & $tcl (Join-Path $app $test) 2>&1
        Assert (($result -join "`n") -match '^PASS:') "Tcl test $test : $result"
        Write-Host ($result -join "`n")
    }
    & (Join-Path $PreparedRoot 'tools/node-22.20.0/node.exe') (Join-Path $app 'test-colors.cjs')
    Assert ($LASTEXITCODE -eq 0) 'TextMate coloring'
    $sourceFile = Join-Path $testRoot 'bad.sv'
    Write-Utf8 $sourceFile 'module bad(output logic y); assign y = missing_signal; endmodule'
    $lint = @{path=$sourceFile;sources=@($sourceFile);root=$testRoot;slang=(Join-Path $PreparedRoot 'tools/slang-11.0/slang.exe');slang_args=@('-Wextra');include_dirs=@();defines=@();top=''}
    $format = @{path=$sourceFile;verible=(Join-Path $PreparedRoot 'tools/verible-4294/verible-verilog-format.exe');format_args=@('--indentation_spaces=4')}
    Write-Utf8 (Join-Path $testRoot lint.json) ($lint | ConvertTo-Json -Depth 5)
    Write-Utf8 (Join-Path $testRoot format.json) ($format | ConvertTo-Json -Depth 5)
    $result = & $tcl "$PSScriptRoot/worker-smoke.tcl" $app (Join-Path $PreparedRoot 'tools/python-3.13.7/python.exe') (Join-Path $testRoot lint.json) (Join-Path $testRoot format.json) 2>&1
    Assert (($result -join "`n") -match '^PASS:') "Worker smoke: $result"
    Write-Host ($result -join "`n")
    $fake = Join-Path $testRoot fake-quartus
    $fakeBin = Join-Path $fake bin64
    $fakeStartup = Join-Path $fake 'common/tcl/internal/qui_init.tcl'
    New-Item -ItemType Directory -Path $fakeBin,(Split-Path $fakeStartup) -Force | Out-Null
    foreach ($dll in @('edt_tedq.dll','gcl_afcq.dll')) { Copy-Item -LiteralPath (Join-Path $QuartusRoot "bin64/$dll") -Destination $fakeBin }
    Write-Utf8 $fakeStartup "# Synthetic startup; no Altera source`r`nset example 1`r`n"
    & "$root/scripts/StartupHook.ps1" -QuartusRoot $fake -InstallRoot $PreparedRoot
    & "$root/scripts/StartupHook.ps1" -QuartusRoot $fake -InstallRoot $PreparedRoot
    $installed = [IO.File]::ReadAllText($fakeStartup)
    Assert (([regex]::Matches($installed,'# BEGIN QUARTUS_QOL_NATIVE')).Count -eq 1) 'idempotent hook'
    Write-Utf8 $fakeStartup ($installed + "# unrelated customization`r`n")
    & "$root/scripts/StartupHook.ps1" -QuartusRoot $fake -InstallRoot $PreparedRoot -Action Uninstall
    $removed = [IO.File]::ReadAllText($fakeStartup)
    Assert (!$removed.Contains('BEGIN QUARTUS_QOL_NATIVE') -and $removed.Contains('unrelated customization') -and $removed.Contains('set example 1')) 'uninstall preserves unrelated startup edits'
    Write-Utf8 $fakeStartup ($installed.Replace($PreparedRoot.Replace('\','/'),'C:/another-install'))
    $refused = $false
    try { & "$root/scripts/StartupHook.ps1" -QuartusRoot $fake -InstallRoot $PreparedRoot -Action Uninstall } catch { $refused=$true }
    Assert $refused 'foreign hook is not removed'
    Write-Host 'PASS: PowerShell syntax, supported DLLs, hook idempotence and scoped uninstall'
} finally { Remove-OwnedDirectory $testRoot (Join-Path $root '.build') }
