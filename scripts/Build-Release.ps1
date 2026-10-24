param([string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot) 'dist'))
. "$PSScriptRoot/Common.ps1"
$root = Split-Path $PSScriptRoot
$version = (Get-Content -Raw (Join-Path $root VERSION)).Trim()
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$output = Join-Path $OutputDirectory "QuartusQOL-$version-windows-x64.zip"
$include = @('app','scripts','tests','docs','demo','Install.cmd','Uninstall.cmd','dependencies.json','config.example.tcl','VERSION','README.md','LICENSE','THIRD_PARTY.md','CHANGELOG.md')
$paths = @($include | ForEach-Object { Join-Path $root $_ })
Compress-Archive -LiteralPath $paths -DestinationPath $output -Force
$digest = (Get-FileHash $output -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Utf8 (Join-Path $OutputDirectory 'SHA256SUMS.txt') ($digest + '  ' + (Split-Path $output -Leaf) + "`n")
Write-Host $output
