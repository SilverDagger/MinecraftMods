param(
    [string]$RawDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Raw'),
    [string]$OrderFile = (Join-Path $PSScriptRoot 'order.json'),
    [string]$OutputDirectory = (Split-Path $PSScriptRoot -Parent)
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Read-ZipText($entry) {
    $reader = [IO.StreamReader]::new($entry.Open(), [Text.Encoding]::UTF8)
    try { return $reader.ReadToEnd() } finally { $reader.Dispose() }
}

function Assert-ZipPath([string]$path) {
    if ($path.StartsWith('/') -or $path.Contains('\') -or $path -match '(^|/)\.\.?(/|$)' -or $path -match '^[A-Za-z]:') {
        throw "Unsafe ZIP entry path: $path"
    }
}

function Get-OverlayRange($overlay) {
    if ($null -ne $overlay.min_format -and $null -ne $overlay.max_format) {
        return @([int]$overlay.min_format, [int]$overlay.max_format)
    }
    $formats = $overlay.formats
    if ($null -ne $formats.min_inclusive) {
        return @([int]$formats.min_inclusive, [int]$formats.max_inclusive)
    }
    if ($formats -is [array]) { return @([int]$formats[0], [int]$formats[-1]) }
    return @([int]$formats, [int]$formats)
}

$config = Get-Content -LiteralPath $OrderFile -Raw -Encoding UTF8 | ConvertFrom-Json
$order = @($config.packs_low_to_high)
$format = [int]$config.target_pack_format
if ($format -lt 1 -or $order.Count -eq 0) { throw 'order.json needs a positive target_pack_format and a nonempty packs_low_to_high list.' }
$seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach ($name in $order) {
    if ([IO.Path]::GetFileName([string]$name) -cne [string]$name -or -not ([string]$name).EndsWith('.zip', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Expected a ZIP filename only: $name"
    }
    if (-not $seen.Add([string]$name)) { throw "Duplicate order entry: $name" }
    if (-not (Test-Path -LiteralPath (Join-Path $RawDirectory $name) -PathType Leaf)) { throw "Missing input: $name" }
}
$inputs = @(Get-ChildItem -LiteralPath $RawDirectory -File -Filter '*.zip')
$unlisted = @($inputs | Where-Object { -not $seen.Contains($_.Name) })
if ($unlisted.Count) { throw "Unlisted ZIP(s) in Raw: $($unlisted.Name -join ', ')" }

$archives = [Collections.Generic.List[object]]::new()
$merged = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
$collisions = [Collections.Generic.Dictionary[string,int]]::new([StringComparer]::Ordinal)
$icon = $null
$fusion = $null
$outputPath = $null
$outputStream = $null
$uuidPath = $null
$uuidCreated = $false
try {
    foreach ($name in $order) {
        $zip = [IO.Compression.ZipFile]::OpenRead((Join-Path $RawDirectory $name))
        $archives.Add($zip)
        $metadataEntry = $zip.GetEntry('pack.mcmeta')
        if ($null -eq $metadataEntry) { throw "Missing root pack.mcmeta: $name" }
        $metadata = Read-ZipText $metadataEntry | ConvertFrom-Json
        if ($null -eq $metadata.pack) { throw "Invalid pack.mcmeta: $name" }
        if ($null -ne $metadata.fusion) {
            if ($null -ne $fusion) { throw 'Multiple packs declare Fusion metadata; manual reconciliation is needed.' }
            $fusion = $metadata.fusion
        }
        $local = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
        $iconEntry = $zip.GetEntry('pack.png')
        if ($null -eq $icon -and $null -ne $iconEntry) { $icon = $iconEntry }

        foreach ($entry in $zip.Entries) {
            $path = $entry.FullName
            Assert-ZipPath $path
            if ($path.EndsWith('/')) { continue }
            if ($path -match '^(assets|data|fusion_overrides)/') { $local[$path] = $entry }
        }
        foreach ($overlay in @($metadata.overlays.entries)) {
            if ($null -eq $overlay) { continue }
            $range = @(Get-OverlayRange $overlay)
            if ($format -lt $range[0] -or $format -gt $range[1]) { continue }
            $directory = [string]$overlay.directory
            if ($directory -notmatch '^[^/\\.][^/\\]*$' -or $directory -eq '..') { throw "Invalid overlay directory in $name" }
            $prefix = "$directory/"
            foreach ($entry in $zip.Entries) {
                if ($entry.FullName.EndsWith('/') -or -not $entry.FullName.StartsWith($prefix, [StringComparison]::Ordinal)) { continue }
                $path = $entry.FullName.Substring($prefix.Length)
                if ($path -match '^(assets|data|fusion_overrides)/') { $local[$path] = $entry }
            }
        }
        foreach ($pair in $local.GetEnumerator()) {
            if ($merged.ContainsKey($pair.Key)) {
                if (-not $collisions.ContainsKey($name)) { $collisions[$name] = 0 }
                $collisions[$name]++
            }
            $merged[$pair.Key] = $pair.Value
        }
        Write-Host ("Applied {0}: {1} asset files" -f $name, $local.Count)
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) { New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
    $stamp = Get-Date -Format 'dd.MM.yy'
    foreach ($suffix in @('') + @([char[]](97..122) | ForEach-Object { "$_" })) {
        $candidate = Join-Path $OutputDirectory "SUCCU_ResourcePack_$stamp$suffix.zip"
        if (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($candidate, '.uuid'))) { continue }
        try {
            $outputStream = [IO.File]::Open($candidate, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
            $outputPath = $candidate
            break
        } catch [IO.IOException] {
            if (-not (Test-Path -LiteralPath $candidate)) { throw }
        }
    }
    if ($null -eq $outputStream) { throw "All output names for $stamp already exist (through -z)." }
    $output = [IO.Compression.ZipArchive]::new($outputStream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        $metaObject = @{ pack = @{ pack_format = $format; description = 'SUCCU combined resource pack' } }
        if ($null -ne $fusion) { $metaObject.fusion = $fusion }
        $meta = $metaObject | ConvertTo-Json -Depth 8
        $metaEntry = $output.CreateEntry('pack.mcmeta', [IO.Compression.CompressionLevel]::Optimal)
        $writer = [IO.StreamWriter]::new($metaEntry.Open(), [Text.UTF8Encoding]::new($false))
        try { $writer.Write($meta) } finally { $writer.Dispose() }
        if ($null -ne $icon) {
            $dest = $output.CreateEntry('pack.png', [IO.Compression.CompressionLevel]::Optimal)
            $sourceStream = $icon.Open(); $destStream = $dest.Open()
            try { $sourceStream.CopyTo($destStream) } finally { $sourceStream.Dispose(); $destStream.Dispose() }
        }
        foreach ($pair in @($merged.GetEnumerator() | Sort-Object Key)) {
            $dest = $output.CreateEntry($pair.Key, [IO.Compression.CompressionLevel]::Optimal)
            $sourceStream = $pair.Value.Open(); $destStream = $dest.Open()
            try { $sourceStream.CopyTo($destStream) } finally { $sourceStream.Dispose(); $destStream.Dispose() }
        }
    } finally { $output.Dispose() }
    $outputStream.Dispose(); $outputStream = $null
    $uuid = [guid]::NewGuid().ToString('D')
    $uuidPath = [IO.Path]::ChangeExtension($outputPath, '.uuid')
    $uuidStream = [IO.File]::Open($uuidPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    $uuidCreated = $true
    try {
        $uuidWriter = [IO.StreamWriter]::new($uuidStream, [Text.UTF8Encoding]::new($false))
        try { $uuidWriter.WriteLine($uuid) } finally { $uuidWriter.Dispose() }
    } finally { $uuidStream.Dispose() }
    Write-Host "Created $outputPath ($($merged.Count) combined files)."
    Write-Host "Resource pack UUID: $uuid (saved to $uuidPath)"
    foreach ($pair in @($collisions.GetEnumerator() | Sort-Object Key)) { Write-Host "  $($pair.Key) replaced $($pair.Value) earlier paths" }
} catch {
    if ($null -ne $outputStream) { $outputStream.Dispose() }
    if ($uuidCreated -and (Test-Path -LiteralPath $uuidPath)) { Remove-Item -LiteralPath $uuidPath -Force }
    if ($null -ne $outputPath -and (Test-Path -LiteralPath $outputPath)) { Remove-Item -LiteralPath $outputPath -Force }
    throw
} finally {
    foreach ($archive in $archives) { $archive.Dispose() }
}
