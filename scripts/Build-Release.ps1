param([string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot) 'dist'))
. "$PSScriptRoot/Common.ps1"
$root = Split-Path $PSScriptRoot
$version = (Get-Content -Raw (Join-Path $root VERSION)).Trim()
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$output = Join-Path $OutputDirectory "QuartusQOL-$version-windows-x64.zip"
$include = @('app','scripts','tests','docs','demo','Install.cmd','Uninstall.cmd','dependencies.json','config.example.tcl','VERSION','README.md','LICENSE','THIRD_PARTY.md','CHANGELOG.md')
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stream = [IO.File]::Open($output, [IO.FileMode]::Create)
$archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($item in $include) {
        $path = Join-Path $root $item
        $files = if (Test-Path -LiteralPath $path -PathType Container) { Get-ChildItem -LiteralPath $path -Recurse -File } else { Get-Item -LiteralPath $path }
        foreach ($file in $files) {
            $entry = $file.FullName.Substring($root.Length + 1).Replace('\','/')
            if ($entry -match '(^|/)(\.runtime|__pycache__)(/|$)|\.(bak|tmp|res)$') { continue }
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $entry, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    }
} finally { $archive.Dispose(); $stream.Dispose() }
$digest = (Get-FileHash $output -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Utf8 (Join-Path $OutputDirectory 'SHA256SUMS.txt') ($digest + '  ' + (Split-Path $output -Leaf) + "`n")
Write-Host $output
