param(
    [switch]$AnalyzeOnly
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$packRoot = Join-Path $PSScriptRoot "Maxi's-JM+CM_Pixel-U11"
$iconRoot = Join-Path $packRoot 'assets/cobblemon/textures/entity_icon'
if (-not (Test-Path -LiteralPath $iconRoot -PathType Container)) {
    throw "Icon directory not found: $iconRoot"
}

$total = 0
$trimmed = 0
$unchanged = 0
$empty = 0
$widthBefore = 0L
$heightBefore = 0L
$widthAfter = 0L
$heightAfter = 0L

foreach ($file in Get-ChildItem -LiteralPath $iconRoot -Recurse -File -Filter '*.png') {
    $total++
    $bitmap = [System.Drawing.Bitmap]::new($file.FullName)
    try {
        $left = $bitmap.Width
        $top = $bitmap.Height
        $right = -1
        $bottom = -1

        for ($y = 0; $y -lt $bitmap.Height; $y++) {
            for ($x = 0; $x -lt $bitmap.Width; $x++) {
                if ($bitmap.GetPixel($x, $y).A -eq 0) { continue }
                if ($x -lt $left) { $left = $x }
                if ($x -gt $right) { $right = $x }
                if ($y -lt $top) { $top = $y }
                if ($y -gt $bottom) { $bottom = $y }
            }
        }

        if ($right -lt 0) {
            $empty++
            continue
        }

        $newWidth = $right - $left + 1
        $newHeight = $bottom - $top + 1
        $widthBefore += $bitmap.Width
        $heightBefore += $bitmap.Height
        $widthAfter += $newWidth
        $heightAfter += $newHeight

        if ($left -eq 0 -and $top -eq 0 -and $newWidth -eq $bitmap.Width -and $newHeight -eq $bitmap.Height) {
            $unchanged++
            continue
        }

        $trimmed++
        if ($AnalyzeOnly) { continue }

        $rect = [System.Drawing.Rectangle]::new($left, $top, $newWidth, $newHeight)
        $cropped = $bitmap.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $temporary = Join-Path $file.DirectoryName ('.' + $file.Name + '.' + [guid]::NewGuid().ToString('N') + '.tmp')
        try {
            $cropped.Save($temporary, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $cropped.Dispose()
        }
        $bitmap.Dispose()
        $backup = $temporary + '.backup'
        [System.IO.File]::Replace($temporary, $file.FullName, $backup)
        Remove-Item -LiteralPath $backup -Force
    } finally {
        $bitmap.Dispose()
    }
}

[pscustomobject]@{
    Mode = if ($AnalyzeOnly) { 'AnalyzeOnly' } else { 'Trim' }
    Icons = $total
    Trimmed = $trimmed
    Unchanged = $unchanged
    FullyTransparent = $empty
    SumWidthBefore = $widthBefore
    SumHeightBefore = $heightBefore
    SumWidthAfter = $widthAfter
    SumHeightAfter = $heightAfter
}
