. "$PSScriptRoot/../scripts/Common.ps1"
function Assert($Condition,$Message) { if (!$Condition) { throw "FAIL: $Message" } }
$script:calls = 0
$script:answer = $false
$script:sample = [pscustomobject]@{Editor=$script:EditorHash; Options=$script:OptionsHash; Version='24.1.0.1077'}
function Get-QuartusFingerprint([string]$Root) { return $script:sample }
function Show-VersionWarning([string]$Version,[string]$Root) { $script:calls++; return $script:answer }
$known = Confirm-QuartusCompatibility 'unused'
Assert ($script:calls -eq 0) 'tested build skips dialog'
$script:sample = [pscustomobject]@{Editor=('a'*64);Options=('b'*64);Version='untested demo'}
$cancelled = $false
try { Confirm-QuartusCompatibility 'unused' | Out-Null } catch { $cancelled=$true }
Assert ($cancelled -and $script:calls -eq 1) 'Cancel stops installation'
$script:answer = $true
$accepted = Confirm-QuartusCompatibility 'unused'
Assert ($accepted.Editor -eq ('a'*64) -and $script:calls -eq 2) 'Continue returns exact binaries'
$consent = Join-Path ([IO.Path]::GetTempPath()) ('qol-consent-' + [Guid]::NewGuid().ToString('N'))
try {
    Write-Utf8 $consent "editor $($accepted.Editor) options $($accepted.Options)"
    Assert-CompatibleQuartus 'unused' $consent
    $script:sample.Options = 'c'*64
    $rejected = $false
    try { Assert-CompatibleQuartus 'unused' $consent } catch { $rejected=$true }
    Assert $rejected 'consent does not apply after binaries change'
} finally { Remove-Item -LiteralPath $consent -ErrorAction SilentlyContinue }
Write-Host 'PASS: tested build, warning cancellation, acknowledgement and exact-build consent'
