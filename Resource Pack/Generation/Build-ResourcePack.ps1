param(
    [string]$RawDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Raw'),
    [string]$OrderFile = (Join-Path $PSScriptRoot 'order.json'),
    [string]$OutputDirectory = (Split-Path $PSScriptRoot -Parent),
    [switch]$UseVanillaTextShaders
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
$sha1Path = $null
$sha1Created = $false
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

    if ($format -eq 34) {
        # Whimscape's 3D minecart inventory models render incorrectly in this pack.
        # Let Minecraft's built-in flat models use Whimscape's item textures instead.
        foreach ($item in @('minecart', 'chest_minecart', 'command_block_minecart', 'furnace_minecart', 'hopper_minecart', 'tnt_minecart')) {
            $path = "assets/minecraft/models/item/$item.json"
            if (-not $merged.Remove($path)) { throw "Missing minecart model for manual fix: $path" }
        }

        # Whimscape's format_18-42 overlay also supplies 3D inventory boat models.
        # Minecraft 1.21.1 can use its built-in flat boat models and item textures.
        foreach ($wood in @('acacia', 'birch', 'cherry', 'dark_oak', 'jungle', 'mangrove', 'oak', 'pale_oak', 'spruce')) {
            foreach ($kind in @('boat', 'chest_boat')) {
                $path = "assets/minecraft/models/item/${wood}_$kind.json"
                if (-not $merged.Remove($path)) { throw "Missing boat model for manual fix: $path" }
            }
        }
        foreach ($kind in @('raft', 'chest_raft')) {
            $path = "assets/minecraft/models/item/bamboo_$kind.json"
            if (-not $merged.Remove($path)) { throw "Missing raft model for manual fix: $path" }
        }

        # The built-in chest boat fallback still renders missing textures in
        # inventories. Write explicit flat item models using the merged icons.
        foreach ($wood in @('acacia', 'birch', 'cherry', 'dark_oak', 'jungle', 'mangrove', 'oak', 'pale_oak', 'spruce')) {
            $name = "${wood}_chest_boat"
            $texture = "assets/minecraft/textures/item/$name.png"
            if (-not $merged.ContainsKey($texture)) { throw "Missing flat item texture: $texture" }
            $merged["assets/minecraft/models/item/$name.json"] =
                '{"parent":"minecraft:item/generated","textures":{"layer0":"minecraft:item/' + $name + '"}}'
        }
        $name = 'bamboo_chest_raft'
        $texture = "assets/minecraft/textures/item/$name.png"
        if (-not $merged.ContainsKey($texture)) { throw "Missing flat item texture: $texture" }
        $merged["assets/minecraft/models/item/$name.json"] =
            '{"parent":"minecraft:item/generated","textures":{"layer0":"minecraft:item/' + $name + '"}}'

        # Vanilla Tweaks supplies 3D sign item models. Replace them with flat
        # icon models; placed standing, wall, and hanging signs keep their textures.
        foreach ($wood in @('acacia', 'bamboo', 'birch', 'cherry', 'crimson', 'dark_oak', 'jungle', 'mangrove', 'oak', 'pale_oak', 'spruce', 'warped')) {
            foreach ($kind in @('sign', 'hanging_sign')) {
                $name = "${wood}_$kind"
                $model = "assets/minecraft/models/item/$name.json"
                $texture = "assets/minecraft/textures/item/$name.png"
                if (-not $merged.ContainsKey($model)) { throw "Missing sign model for manual fix: $model" }
                if (-not $merged.ContainsKey($texture)) { throw "Missing flat item texture: $texture" }
                $merged[$model] =
                    '{"parent":"minecraft:item/generated","textures":{"layer0":"minecraft:item/' + $name + '"}}'
            }
        }

        # Cobblemon Interface's selection sprite is opaque over the selected item.
        $whimscapeIndex = [Array]::IndexOf($order, 'Whimscape_1.20.2-1.21.11_r7.zip')
        if ($whimscapeIndex -lt 0) { throw 'Missing Whimscape source for hotbar selection fix.' }
        $selectionPath = 'assets/minecraft/textures/gui/sprites/hud/hotbar_selection.png'
        $selectionEntry = $archives[$whimscapeIndex].GetEntry($selectionPath)
        if ($null -eq $selectionEntry) { throw "Missing Whimscape hotbar selection sprite: $selectionPath" }
        $merged[$selectionPath] = $selectionEntry
    }

    if ($UseVanillaTextShaders) {
        foreach ($path in @(
            'assets/minecraft/shaders/core/rendertype_text.fsh',
            'assets/minecraft/shaders/core/rendertype_text_intensity.fsh'
        )) {
            if (-not $merged.Remove($path)) { throw "Missing custom text shader for comparison build: $path" }
        }
        Write-Host 'Using Minecraft built-in text shaders for comparison build.'
    }

    if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) { New-Item -ItemType Directory -Path $OutputDirectory | Out-Null }
    $stamp = Get-Date -Format 'yy.MM.dd'
    foreach ($suffix in @('') + @([char[]](97..122) | ForEach-Object { "$_" })) {
        $candidate = Join-Path $OutputDirectory "SUCCU_ResourcePack_$stamp$suffix.zip"
        if ((Test-Path -LiteralPath ([IO.Path]::ChangeExtension($candidate, '.uuid'))) -or
            (Test-Path -LiteralPath ([IO.Path]::ChangeExtension($candidate, '.sha1')))) { continue }
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
            if ($pair.Value -is [string]) {
                $writer = [IO.StreamWriter]::new($dest.Open(), [Text.UTF8Encoding]::new($false))
                try { $writer.Write($pair.Value) } finally { $writer.Dispose() }
            } else {
                $sourceStream = $pair.Value.Open(); $destStream = $dest.Open()
                try { $sourceStream.CopyTo($destStream) } finally { $sourceStream.Dispose(); $destStream.Dispose() }
            }
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
    $sha1 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA1).Hash.ToLowerInvariant()
    $sha1Path = [IO.Path]::ChangeExtension($outputPath, '.sha1')
    $sha1Stream = [IO.File]::Open($sha1Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write)
    $sha1Created = $true
    try {
        $sha1Writer = [IO.StreamWriter]::new($sha1Stream, [Text.UTF8Encoding]::new($false))
        try { $sha1Writer.WriteLine($sha1) } finally { $sha1Writer.Dispose() }
    } finally { $sha1Stream.Dispose() }
    Write-Host "Created $outputPath ($($merged.Count) combined files)."
    Write-Host "Resource pack UUID: $uuid (saved to $uuidPath)"
    Write-Host "Resource pack SHA-1: $sha1 (saved to $sha1Path)"
    foreach ($pair in @($collisions.GetEnumerator() | Sort-Object Key)) { Write-Host "  $($pair.Key) replaced $($pair.Value) earlier paths" }
} catch {
    if ($null -ne $outputStream) { $outputStream.Dispose() }
    if ($sha1Created -and (Test-Path -LiteralPath $sha1Path)) { Remove-Item -LiteralPath $sha1Path -Force }
    if ($uuidCreated -and (Test-Path -LiteralPath $uuidPath)) { Remove-Item -LiteralPath $uuidPath -Force }
    if ($null -ne $outputPath -and (Test-Path -LiteralPath $outputPath)) { Remove-Item -LiteralPath $outputPath -Force }
    throw
} finally {
    foreach ($archive in $archives) { $archive.Dispose() }
}
