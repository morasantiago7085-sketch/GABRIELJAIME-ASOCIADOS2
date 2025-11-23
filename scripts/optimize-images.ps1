# Image optimization script (PowerShell)
# Requires: cwebp (from libwebp) for WebP conversion and/or ImageMagick (magick) for resizing
# Usage: Run in project root. Example: .\scripts\optimize-images.ps1

param(
    [string]$SrcDir = "img",
    [string]$OutDir = "img/optimized",
    [int[]]$Sizes = @(480,768)
)

Write-Output "Starting image optimization script"
Write-Output "Source directory: $SrcDir"
Write-Output "Output directory: $OutDir"

if(-not (Test-Path $SrcDir)){
    Write-Error "Source directory '$SrcDir' not found."
    exit 1
}

if(-not (Test-Path $OutDir)){
    New-Item -ItemType Directory -Path $OutDir | Out-Null
    Write-Output "Created output directory: $OutDir"
}

$hasMagick = (Get-Command magick -ErrorAction SilentlyContinue) -ne $null
$hasCwebp = (Get-Command cwebp -ErrorAction SilentlyContinue) -ne $null

Write-Output "ImageMagick (magick) available: $hasMagick"
Write-Output "cwebp available: $hasCwebp"

Get-ChildItem -Path $SrcDir -Include *.png,*.jpg,*.jpeg,*.svg -File | ForEach-Object {
    $file = $_
    $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $ext = $file.Extension.ToLower()

    if($hasMagick){
        foreach($w in $Sizes){
            $outFile = Join-Path $OutDir ("{0}-{1}{2}" -f $name, $w, $ext)
            Write-Output "Resizing $($file.Name) -> $($outFile) (width=${w})"
            try{
                magick convert "$($file.FullName)" -resize ${w}x "$outFile" | Out-Null
            } catch {
                Write-Warning "Failed to resize $($file.Name) to ${w}px: $_"
            }
        }
        # Also create a copy of original size in out dir
        $origOut = Join-Path $OutDir ("{0}{1}" -f $name, $ext)
        Write-Output "Copying original $($file.Name) -> $($origOut)"
        Copy-Item -Path $file.FullName -Destination $origOut -Force
    } else {
        Write-Output "Skipping resizing for $($file.Name): ImageMagick (magick) not found."
    }

    if($hasCwebp){
        # Create webp for original and resized versions if they exist
        $sourceFiles = @()
        if($hasMagick){
            $sourceFiles += (Get-ChildItem -Path $OutDir -Filter "${name}-*${ext}" -File -ErrorAction SilentlyContinue)
            $sourceFiles += (Get-ChildItem -Path $OutDir -Filter "${name}${ext}" -File -ErrorAction SilentlyContinue)
        } else {
            $sourceFiles += $file
        }
        foreach($s in $sourceFiles){
            $webpOut = Join-Path $OutDir ("{0}-{1}.webp" -f $name, ([System.IO.Path]::GetFileNameWithoutExtension($s.Name)))
            Write-Output "Creating WebP: $($s.Name) -> $($webpOut)"
            try{
                & cwebp -q 80 "$($s.FullName)" -o "$webpOut" | Out-Null
            } catch {
                Write-Warning "Failed to create WebP for $($s.Name): $_"
            }
        }
    } else {
        Write-Output "Skipping WebP generation for $($file.Name): cwebp not found."
    }
}

Write-Output "Optimization script finished. Check the $OutDir folder for generated images."
