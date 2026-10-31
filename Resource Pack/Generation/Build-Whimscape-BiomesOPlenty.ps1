param(
    [string]$WhimscapeZip = (Join-Path $PSScriptRoot '..\Raw\Whimscape_1.20.2-1.21.11_r7.zip'),
    [string]$BiomesOPlentyJar = (Join-Path $PSScriptRoot '..\..\Mods\Individual\Client-Server\BiomesOPlenty-fabric-1.21.1-21.1.0.14.jar'),
    [string]$OutputZip = (Join-Path $PSScriptRoot '..\Raw\Whimscape x Biomes o Plenty.zip')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class WhimscapePalette
{
    private static double[] Mean(Bitmap bitmap, int height)
    {
        double[] result = new double[3];
        double count = 0;
        for (int y = 0; y < height; y++)
        for (int x = 0; x < bitmap.Width; x++)
        {
            Color c = bitmap.GetPixel(x, y);
            if (c.A == 0) continue;
            double weight = c.A / 255.0;
            result[0] += c.R * weight;
            result[1] += c.G * weight;
            result[2] += c.B * weight;
            count += weight;
        }
        if (count == 0) throw new InvalidDataException("Palette reference has no visible pixels.");
        for (int i = 0; i < 3; i++) result[i] /= count;
        return result;
    }

    private static double Luma(double r, double g, double b)
    {
        return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    private static int Byte(double value)
    {
        return Math.Max(0, Math.Min(255, (int)Math.Round(value)));
    }

    private static double Deviation(Bitmap bitmap, int height, double[] mean)
    {
        double center = Luma(mean[0], mean[1], mean[2]);
        double total = 0;
        double count = 0;
        for (int y = 0; y < height; y++)
        for (int x = 0; x < bitmap.Width; x++)
        {
            Color c = bitmap.GetPixel(x, y);
            if (c.A == 0) continue;
            double weight = c.A / 255.0;
            double difference = Luma(c.R, c.G, c.B) - center;
            total += difference * difference * weight;
            count += weight;
        }
        return count == 0 ? 0 : Math.Sqrt(total / count);
    }

    // Keep a BOP-specific silhouette or overlay, but bring its light/dark
    // contrast closer to the matching Whimscape material.
    public static byte[] Restyle(byte[] motif, byte[] style)
    {
        using (var motifStream = new MemoryStream(motif))
        using (var styleStream = new MemoryStream(style))
        using (var source = new Bitmap(motifStream))
        using (var reference = new Bitmap(styleStream))
        using (var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        using (var result = new MemoryStream())
        {
            double[] mean = Mean(source, source.Height);
            double[] styleMean = Mean(reference, reference.Height);
            double meanLuma = Luma(mean[0], mean[1], mean[2]);
            double sourceSpread = Deviation(source, source.Height, mean);
            double styleSpread = Deviation(reference, reference.Height, styleMean);
            double scale = sourceSpread < 1 ? 1 : Math.Max(0.75, Math.Min(1.5, styleSpread / sourceSpread));
            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (c.A == 0) continue;
                double luma = Luma(c.R, c.G, c.B);
                double shade = Math.Round((luma - meanLuma) * scale / 4.0) * 4.0;
                double r = mean[0] + shade + 0.35 * ((c.R - luma) - (mean[0] - meanLuma));
                double g = mean[1] + shade + 0.35 * ((c.G - luma) - (mean[1] - meanLuma));
                double b = mean[2] + shade + 0.35 * ((c.B - luma) - (mean[2] - meanLuma));
                output.SetPixel(x, y, Color.FromArgb(c.A, Byte(r), Byte(g), Byte(b)));
            }
            output.Save(result, ImageFormat.Png);
            return result.ToArray();
        }
    }

    private static bool IsTopMaterial(Color c, bool snow)
    {
        return snow
            ? c.R + c.G + c.B > 480 && Math.Abs(c.R - c.G) < 60
            : c.G > c.R * 1.10 && c.G > c.B * 1.15;
    }

    // Grass and snow sides have two separate palettes. A single image-wide
    // mean would turn both the upper material and the dirt underneath tan.
    public static byte[] RecolorSplit(byte[] pattern, byte[] reference, bool snow)
    {
        using (var sourceStream = new MemoryStream(pattern))
        using (var referenceStream = new MemoryStream(reference))
        using (var source = new Bitmap(sourceStream))
        using (var target = new Bitmap(referenceStream))
        using (var output = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        using (var result = new MemoryStream())
        {
            if (source.Width != target.Width || source.Height != target.Height)
                throw new InvalidDataException("Split recolor requires matching dimensions.");
            double[,] sourceMean = new double[2, 3];
            double[,] targetMean = new double[2, 3];
            double[] counts = new double[2];
            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color s = source.GetPixel(x, y);
                Color t = target.GetPixel(x, y);
                if (s.A == 0 || t.A == 0) continue;
                int group = IsTopMaterial(t, snow) ? 1 : 0;
                double weight = Math.Min(s.A, t.A) / 255.0;
                sourceMean[group, 0] += s.R * weight;
                sourceMean[group, 1] += s.G * weight;
                sourceMean[group, 2] += s.B * weight;
                targetMean[group, 0] += t.R * weight;
                targetMean[group, 1] += t.G * weight;
                targetMean[group, 2] += t.B * weight;
                counts[group] += weight;
            }
            for (int group = 0; group < 2; group++)
            {
                if (counts[group] == 0) throw new InvalidDataException("Grass/snow palette group is empty.");
                for (int channel = 0; channel < 3; channel++)
                {
                    sourceMean[group, channel] /= counts[group];
                    targetMean[group, channel] /= counts[group];
                }
            }
            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (c.A == 0) continue;
                int group = IsTopMaterial(target.GetPixel(x, y), snow) ? 1 : 0;
                double center = Luma(sourceMean[group, 0], sourceMean[group, 1], sourceMean[group, 2]);
                double luma = Luma(c.R, c.G, c.B);
                double shade = luma - center;
                double r = targetMean[group, 0] + shade + 0.35 * ((c.R - luma) - (sourceMean[group, 0] - center));
                double g = targetMean[group, 1] + shade + 0.35 * ((c.G - luma) - (sourceMean[group, 1] - center));
                double b = targetMean[group, 2] + shade + 0.35 * ((c.B - luma) - (sourceMean[group, 2] - center));
                output.SetPixel(x, y, Color.FromArgb(c.A, Byte(r), Byte(g), Byte(b)));
            }
            output.Save(result, ImageFormat.Png);
            return result.ToArray();
        }
    }

    public static byte[] Recolor(byte[] pattern, byte[] reference)
    {
        using (var sourceStream = new MemoryStream(pattern))
        using (var referenceStream = new MemoryStream(reference))
        using (var source = new Bitmap(sourceStream))
        using (var target = new Bitmap(referenceStream))
        {
        // Whimscape's nether stems are animated sheets. BOP logs are static,
        // so use the first 16-pixel frame rather than an unanimated tall PNG.
        int height = source.Width == target.Width && source.Height > target.Height &&
            source.Height % target.Height == 0 ? target.Height : source.Height;
        using (var output = new Bitmap(source.Width, height, PixelFormat.Format32bppArgb))
        using (var result = new MemoryStream())
        {
            double[] sourceMean = Mean(source, height);
            double[] targetMean = Mean(target, target.Height);
            double sourceLuma = Luma(sourceMean[0], sourceMean[1], sourceMean[2]);
            for (int y = 0; y < height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                Color c = source.GetPixel(x, y);
                if (c.A == 0) continue;
                double luma = Luma(c.R, c.G, c.B);
                double shade = luma - sourceLuma;
                // Preserve Whimscape's pixel placement and tonal variation. The
                // BOP reference supplies the mean hue and brightness for this part.
                double r = targetMean[0] + shade + 0.35 * ((c.R - luma) - (sourceMean[0] - sourceLuma));
                double g = targetMean[1] + shade + 0.35 * ((c.G - luma) - (sourceMean[1] - sourceLuma));
                double b = targetMean[2] + shade + 0.35 * ((c.B - luma) - (sourceMean[2] - sourceLuma));
                output.SetPixel(x, y, Color.FromArgb(c.A, Byte(r), Byte(g), Byte(b)));
            }
            output.Save(result, ImageFormat.Png);
            return result.ToArray();
        }
        }
    }
}
'@

function Read-ZipEntry([IO.Compression.ZipArchive]$Archive, [string]$Name) {
    $entry = $Archive.GetEntry($Name)
    if ($null -eq $entry) { throw "Missing archive entry: $Name" }
    $stream = $entry.Open()
    $memory = New-Object IO.MemoryStream
    try {
        $stream.CopyTo($memory)
        return $memory.ToArray()
    } finally {
        $memory.Dispose()
        $stream.Dispose()
    }
}

function Write-ZipEntry([IO.Compression.ZipArchive]$Archive, [string]$Name, [byte[]]$Bytes) {
    $entry = $Archive.CreateEntry($Name, [IO.Compression.CompressionLevel]::Optimal)
    $stream = $entry.Open()
    try { $stream.Write($Bytes, 0, $Bytes.Length) }
    finally { $stream.Dispose() }
}

$woods = @(
    @{ Name='dead'; Base='pale_oak' },
    @{ Name='empyreal'; Base='crimson'; BoatBase='dark_oak' },
    @{ Name='fir'; Base='spruce' },
    @{ Name='hellbark'; Base='dark_oak' },
    @{ Name='jacaranda'; Base='pale_oak' },
    @{ Name='magic'; Base='warped'; BoatBase='oak' },
    @{ Name='mahogany'; Base='cherry' },
    @{ Name='maple'; Base='oak' },
    @{ Name='palm'; Base='birch' },
    @{ Name='pine'; Base='spruce' },
    @{ Name='redwood'; Base='mangrove' },
    @{ Name='umbran'; Base='dark_oak' },
    @{ Name='willow'; Base='birch' }
)

$outPath = [IO.Path]::GetFullPath($OutputZip)
if (Test-Path -LiteralPath $outPath) { throw "Output already exists: $outPath" }
$source = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($WhimscapeZip))
$mod = [IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($BiomesOPlentyJar))
try {
    $zip = [IO.Compression.ZipFile]::Open($outPath, [IO.Compression.ZipArchiveMode]::Create)
    try {
        $meta = '{"pack":{"pack_format":34,"description":"Whimscape x Biomes o Plenty | wood, stone, leaves and plants | MC 1.21.1"}}'
        Write-ZipEntry $zip 'pack.mcmeta' ([Text.Encoding]::UTF8.GetBytes($meta))
        $count = 0
        foreach ($wood in $woods) {
            $name = $wood.Name
            $base = $wood.Base
            $logType = if ($base -in @('crimson','warped')) { 'stem' } else { 'log' }
            $boatBase = if ($wood.ContainsKey('BoatBase')) { $wood.BoatBase } else { $base }
            $parts = @(
                @{ Target="${name}_planks"; Pattern="${base}_planks"; Palette="${name}_planks" },
                @{ Target="${name}_planks_alt_1"; Pattern="${base}_planks_alt_1"; Palette="${name}_planks" },
                @{ Target="${name}_planks_alt_2"; Pattern="${base}_planks_alt_2"; Palette="${name}_planks" },
                @{ Target="${name}_log"; Pattern="${base}_${logType}"; Palette="${name}_log" },
                @{ Target="${name}_log_top"; Pattern="${base}_${logType}_top"; Palette="${name}_log_top" },
                @{ Target="stripped_${name}_log"; Pattern="stripped_${base}_${logType}"; Palette="stripped_${name}_log" },
                @{ Target="stripped_${name}_log_top"; Pattern="stripped_${base}_${logType}_top"; Palette="stripped_${name}_log_top" },
                @{ Target="${name}_door_bottom"; Pattern="${base}_door_bottom"; Palette="${name}_door_bottom" },
                @{ Target="${name}_door_top"; Pattern="${base}_door_top"; Palette="${name}_door_top" },
                @{ Target="${name}_door_bottom_right"; Pattern="${base}_door_bottom_right"; Palette="${name}_door_bottom" },
                @{ Target="${name}_door_top_right"; Pattern="${base}_door_top_right"; Palette="${name}_door_top" },
                @{ Target="${name}_trapdoor"; Pattern="${base}_trapdoor"; Palette="${name}_trapdoor" },
                @{ Target="${name}_button"; Pattern="${base}_button"; Palette="${name}_planks" },
                @{ Target="${name}_fence"; Pattern="${base}_fence"; Palette="${name}_planks" }
            )
            foreach ($part in $parts) {
                $src = "assets/minecraft/textures/block/$($part.Pattern).png"
                $ref = "assets/biomesoplenty/textures/block/$($part.Palette).png"
                $dest = "assets/biomesoplenty/textures/block/$($part.Target).png"
                Write-ZipEntry $zip $dest ([WhimscapePalette]::Recolor((Read-ZipEntry $source $src), (Read-ZipEntry $mod $ref)))
                $count++
            }
            foreach ($folder in @('item','entity/boat','entity/chest_boat','entity/signs','entity/signs/hanging')) {
                $names = if ($folder -eq 'item') { @('boat','chest_boat','door','sign','hanging_sign') } else { @('') }
                foreach ($suffix in $names) {
                    $file = if ($suffix) { "${name}_${suffix}.png" } else { "$name.png" }
                    $patternWood = if ($folder -match 'boat' -or $suffix -match 'boat') { $boatBase } else { $base }
                    $baseFile = if ($suffix) { "${patternWood}_${suffix}.png" } else { "$patternWood.png" }
                    $src = "assets/minecraft/textures/$folder/$baseFile"
                    $ref = "assets/biomesoplenty/textures/$folder/$file"
                    $dest = $ref
                    Write-ZipEntry $zip $dest ([WhimscapePalette]::Recolor((Read-ZipEntry $source $src), (Read-ZipEntry $mod $ref)))
                    $count++
                }
            }

            # The BOP blockstates name these same models. Adapt Whimscape's
            # doors, buttons and fences so their dedicated patterns are used.
            foreach ($entry in $source.Entries) {
                if ($entry.FullName -notmatch "^assets/minecraft/models/block/$([regex]::Escape($base))_(button|fence|door|planks_alt_)") { continue }
                if ($entry.FullName -notlike '*.json') { continue }
                $json = [Text.Encoding]::UTF8.GetString((Read-ZipEntry $source $entry.FullName))
                $json = $json.Replace("minecraft:block/${base}_", "biomesoplenty:block/${name}_")
                $json = $json.Replace('"block/' + $base + '_', '"biomesoplenty:block/' + $name + '_')
                $dest = $entry.FullName.Replace('assets/minecraft/models/block/', 'assets/biomesoplenty/models/block/').Replace("/${base}_", "/${name}_")
                Write-ZipEntry $zip $dest ([Text.Encoding]::UTF8.GetBytes($json))
            }
            $state = '{"variants":{"":[' +
                '{"model":"biomesoplenty:block/' + $name + '_planks","weight":2},' +
                '{"model":"biomesoplenty:block/' + $name + '_planks_alt_1"},' +
                '{"model":"biomesoplenty:block/' + $name + '_planks_alt_2"}]}}'
            Write-ZipEntry $zip "assets/biomesoplenty/blockstates/${name}_planks.json" ([Text.Encoding]::UTF8.GetBytes($state))
        }
        # Whimscape's custom door and fence model parents are required when
        # this add-on is loaded independently of the Whimscape base ZIP.
        foreach ($entry in $source.Entries) {
            if ($entry.FullName -match '^assets/minecraft/models/block/(whimscape/template_fence_[^/]+|door_[^/]+_custom)\.json$') {
                Write-ZipEntry $zip $entry.FullName (Read-ZipEntry $source $entry.FullName)
            }
        }

        # Stone families in the installed BOP 21.1.0.14 JAR. Each sandstone
        # color has 10 shaped variants driven by these shared six textures.
        $stoneParts = @()
        foreach ($color in @('black','white','orange')) {
            $sandPattern = if ($color -eq 'orange') { 'red_sand' } else { 'sand' }
            $sandstonePattern = if ($color -eq 'orange') { 'red_sandstone' } else { 'sandstone' }
            $stoneParts += @{ Target="${color}_sand"; Pattern=$sandPattern }
            foreach ($i in 1..2) {
                $stoneParts += @{ Target="${color}_sand_alt_$i"; Pattern="${sandPattern}_alt_$i"; Palette="${color}_sand" }
                $model = '{"parent":"minecraft:block/cube_all","textures":{"all":"biomesoplenty:block/' + $color + '_sand_alt_' + $i + '"}}'
                Write-ZipEntry $zip "assets/biomesoplenty/models/block/${color}_sand_alt_$i.json" ([Text.Encoding]::UTF8.GetBytes($model))
            }
            $state = '{"variants":{"":[' +
                '{"model":"biomesoplenty:block/' + $color + '_sand","weight":2},' +
                '{"model":"biomesoplenty:block/' + $color + '_sand_alt_1","weight":2},' +
                '{"model":"biomesoplenty:block/' + $color + '_sand_alt_2"}]}}'
            Write-ZipEntry $zip "assets/biomesoplenty/blockstates/${color}_sand.json" ([Text.Encoding]::UTF8.GetBytes($state))
            foreach ($suffix in @('','_top','_bottom')) {
                $stoneParts += @{ Target="${color}_sandstone$suffix"; Pattern="$sandstonePattern$suffix" }
            }
            $chiseled = if ($color -eq 'orange') { 'chiseled_red_sandstone' } else { 'chiseled_sandstone' }
            $cut = if ($color -eq 'orange') { 'cut_red_sandstone' } else { 'cut_sandstone' }
            $stoneParts += @{ Target="chiseled_${color}_sandstone"; Pattern=$chiseled }
            $stoneParts += @{ Target="cut_${color}_sandstone"; Pattern=$cut }
        }

        $stoneParts += @(
            @{ Target='brimstone'; Pattern='netherrack' },
            @{ Target='brimstone_bricks'; Pattern='nether_bricks' },
            @{ Target='chiseled_brimstone_bricks'; Pattern='chiseled_nether_bricks' },
            @{ Target='brimstone_bud'; Style='netherrack' },
            @{ Target='brimstone_cluster_bottom'; Style='netherrack' },
            @{ Target='brimstone_cluster_top'; Style='netherrack' },
            @{ Target='brimstone_fumarole'; Style='netherrack' },
            @{ Target='brimstone_fumarole_side'; Style='netherrack' },
            @{ Target='blackstone_bulb'; Style='blackstone' },
            @{ Target='blackstone_spines'; Style='blackstone' },
            @{ Target='rose_quartz_block'; Pattern='amethyst_block' },
            @{ Target='rose_quartz_cluster'; Style='amethyst_cluster_model' },
            @{ Target='large_rose_quartz_bud'; Style='amethyst_cluster_model' },
            @{ Target='medium_rose_quartz_bud'; Style='amethyst_cluster_model' },
            @{ Target='small_rose_quartz_bud'; Style='amethyst_cluster_model' },
            @{ Target='algal_end_stone'; Style='end_stone' },
            @{ Target='algal_end_stone_side'; Style='end_stone' },
            @{ Target='null_overlay'; Style='end_stone' },
            @{ Target='null_overlay_alt'; Style='end_stone' },
            @{ Target='dried_salt'; Pattern='sand' },
            @{ Target='mossy_black_sand'; Style='sand' },
            @{ Target='mossy_black_sand_side'; Style='grass_block_side_overlay' },
            @{ Target='mossy_black_sand_top'; Style='moss_block' },
            @{ Target='glowing_moss_block'; Style='moss_block' },
            @{ Target='origin_grass_block_side'; Pattern='grass_block_side'; Split='grass' },
            @{ Target='origin_grass_block_snow'; Pattern='grass_block_snow'; Split='snow' },
            @{ Target='origin_grass_block_top'; Pattern='grass_block_top' }
        )
        foreach ($suffix in @('','_2','_3','_4','_5')) {
            $stoneParts += @{ Target="thermal_calcite$suffix"; Style='calcite' }
            $stoneParts += @{ Target="thermal_calcite_vent$suffix"; Style='calcite' }
        }
        $stoneParts += @{ Target='thermal_calcite_inventory'; Style='calcite' }

        foreach ($part in $stoneParts) {
            $palette = if ($part.ContainsKey('Palette')) { $part.Palette } else { $part.Target }
            $reference = Read-ZipEntry $mod "assets/biomesoplenty/textures/block/$palette.png"
            if ($part.ContainsKey('Pattern')) {
                $pattern = Read-ZipEntry $source "assets/minecraft/textures/block/$($part.Pattern).png"
                if ($part.ContainsKey('Split')) {
                    $bytes = [WhimscapePalette]::RecolorSplit($pattern, $reference, ($part.Split -eq 'snow'))
                } else {
                    $bytes = [WhimscapePalette]::Recolor($pattern, $reference)
                }
            } else {
                $style = Read-ZipEntry $source "assets/minecraft/textures/block/$($part.Style).png"
                $bytes = [WhimscapePalette]::Restyle($reference, $style)
            }
            Write-ZipEntry $zip "assets/biomesoplenty/textures/block/$($part.Target).png" $bytes
        }

        # Ordinary foliage takes the Whimscape leaf silhouette and BOP's
        # original palette. Rainbow birch already points to minecraft:birch_leaves.
        $leafBases = @(
            @{ Name='bramble'; Base='oak' },
            @{ Name='cypress'; Base='spruce' },
            @{ Name='dead'; Base='pale_oak' },
            @{ Name='empyreal'; Base='cherry' },
            @{ Name='fir'; Base='spruce' },
            @{ Name='flowering_oak'; Base='oak' },
            @{ Name='hellbark'; Base='dark_oak' },
            @{ Name='jacaranda'; Base='cherry'; SplitColors=$true },
            @{ Name='magic'; Base='oak' },
            @{ Name='mahogany'; Base='jungle' },
            @{ Name='orange_maple'; Base='oak' },
            @{ Name='origin'; Base='oak' },
            @{ Name='palm'; Base='jungle' },
            @{ Name='pine'; Base='spruce' },
            @{ Name='red_maple'; Base='oak' },
            @{ Name='redwood'; Base='spruce' },
            @{ Name='snowblossom'; Base='cherry'; SplitColors=$true },
            @{ Name='umbran'; Base='dark_oak' },
            @{ Name='willow'; Base='mangrove' },
            @{ Name='yellow_maple'; Base='oak' }
        )
        $leafCount = 0
        foreach ($leaf in $leafBases) {
            $texture = "$($leaf.Name)_leaves"
            $base = "$($leaf.Base)_leaves"
            $dest = "assets/biomesoplenty/textures/block/$texture.png"
            $pattern = Read-ZipEntry $source "assets/minecraft/textures/block/$base.png"
            $palette = Read-ZipEntry $mod $dest
            $pixels = if ($leaf.ContainsKey('SplitColors')) {
                [WhimscapePalette]::RecolorSplit($pattern, $palette, $false)
            } else {
                [WhimscapePalette]::Recolor($pattern, $palette)
            }
            Write-ZipEntry $zip $dest $pixels
            Write-ZipEntry $zip "$dest.mcmeta" (Read-ZipEntry $source "assets/minecraft/textures/block/$base.png.mcmeta")
            $leafCount++
        }
        $leafDetails = @(
            @{ Name='magic_leaves_alt'; Pattern='oak_leaves_alt_1' },
            @{ Name='flowering_oak_leaves_overlay'; Style='flowering_azalea_leaves' },
            @{ Name='pine_leaves_overlay'; Style='spruce_leaves' },
            @{ Name='willow_leaves_mossy'; Style='mangrove_leaves' },
            @{ Name='willow_leaves_mossy_overlay'; Style='vine_leaves' }
        )
        foreach ($part in $leafDetails) {
            $dest = "assets/biomesoplenty/textures/block/$($part.Name).png"
            $original = Read-ZipEntry $mod $dest
            if ($part.ContainsKey('Pattern')) {
                $bytes = [WhimscapePalette]::Recolor((Read-ZipEntry $source "assets/minecraft/textures/block/$($part.Pattern).png"), $original)
            } else {
                $bytes = [WhimscapePalette]::Restyle($original, (Read-ZipEntry $source "assets/minecraft/textures/block/$($part.Style).png"))
            }
            Write-ZipEntry $zip $dest $bytes
            Write-ZipEntry $zip "$dest.mcmeta" (Read-ZipEntry $source 'assets/minecraft/textures/block/oak_leaves.png.mcmeta')
            $leafCount++
        }
        # Null leaves previously shared their PNGs with null End stone. Give
        # them leaf-specific textures so the End stone overlay stays intact.
        foreach ($part in @(
            @{ Name='null_leaves'; Pattern='dark_oak_leaves'; Palette='null_overlay' },
            @{ Name='null_leaves_alt'; Pattern='dark_oak_leaves_alt_1'; Palette='null_overlay_alt' }
        )) {
            $dest = "assets/biomesoplenty/textures/block/$($part.Name).png"
            Write-ZipEntry $zip $dest ([WhimscapePalette]::Recolor(
                (Read-ZipEntry $source "assets/minecraft/textures/block/$($part.Pattern).png"),
                (Read-ZipEntry $mod "assets/biomesoplenty/textures/block/$($part.Palette).png")))
            Write-ZipEntry $zip "$dest.mcmeta" (Read-ZipEntry $source 'assets/minecraft/textures/block/oak_leaves.png.mcmeta')
            $model = '{"parent":"minecraft:block/leaves","textures":{"all":"biomesoplenty:block/' + $part.Name + '"}}'
            Write-ZipEntry $zip "assets/biomesoplenty/models/block/$($part.Name).json" ([Text.Encoding]::UTF8.GetBytes($model))
            $leafCount++
        }
        foreach ($color in @('orange','red','yellow')) {
            $name = "${color}_maple_leaf_pile"
            foreach ($folder in @('block','item')) {
                $dest = "assets/biomesoplenty/textures/$folder/$name.png"
                $original = Read-ZipEntry $mod $dest
                $style = Read-ZipEntry $source 'assets/minecraft/textures/block/oak_leaves.png'
                Write-ZipEntry $zip $dest ([WhimscapePalette]::Restyle($original, $style))
                $leafCount++
            }
        }

        # Only one-to-one plant silhouettes. Keep the BOP models so petal
        # counts, facing, and the potted rose continue to work unchanged.
        $simplePlants = @(
            @{ Name='bush'; Pattern='bush' },
            @{ Name='dead_grass'; Pattern='short_dry_grass' },
            @{ Name='desert_grass'; Pattern='short_dry_grass' },
            @{ Name='dune_grass'; Pattern='tall_dry_grass' },
            @{ Name='rose'; Pattern='poppy'; Copy=$true },
            @{ Name='white_petals'; Pattern='pink_petals' },
            @{ Name='white_petals_stem'; Pattern='pink_petals_stem' },
            @{ Name='wildflower'; Pattern='wildflowers' },
            @{ Name='wildflower_stem'; Pattern='wildflowers_stem' }
        )
        $plantCount = 0
        foreach ($plant in $simplePlants) {
            $dest = "assets/biomesoplenty/textures/block/$($plant.Name).png"
            $pattern = Read-ZipEntry $source "assets/minecraft/textures/block/$($plant.Pattern).png"
            $palette = Read-ZipEntry $mod $dest
            $bytes = if ($plant.ContainsKey('Copy')) {
                $pattern
            } elseif ($plant.ContainsKey('SplitColors')) {
                [WhimscapePalette]::RecolorSplit($pattern, $palette, $false)
            } else {
                [WhimscapePalette]::Recolor($pattern, $palette)
            }
            Write-ZipEntry $zip $dest $bytes
            $plantCount++
        }
        foreach ($plant in @(
            @{ Name='white_petals'; Pattern='pink_petals' },
            @{ Name='wildflower'; Pattern='wildflowers' }
        )) {
            $dest = "assets/biomesoplenty/textures/item/$($plant.Name).png"
            $pattern = Read-ZipEntry $source "assets/minecraft/textures/item/$($plant.Pattern).png"
            $palette = Read-ZipEntry $mod $dest
            Write-ZipEntry $zip $dest ([WhimscapePalette]::RecolorSplit($pattern, $palette, $false))
            $plantCount++
        }
        Write-Output "Created $outPath with $count wood, $($stoneParts.Count) stone/terrain, $leafCount leaf/pile, and $plantCount plant textures."
    } finally { $zip.Dispose() }
} catch {
    if (Test-Path -LiteralPath $outPath) { Remove-Item -LiteralPath $outPath -Force }
    throw
} finally {
    $mod.Dispose()
    $source.Dispose()
}
