<#
PowerShell helper: replace <img src="img/name.ext" ...> with a <picture> element using files in img/optimized
- Backs up each HTML file to .bak before modifying
- Looks for optimized variants in img/optimized: name-480.ext, name-768.ext, name.ext and name-<variant>.webp
- If optimized files are not found for an image, it is skipped
#>

param(
  [string]$HtmlDir = ".",
  [string]$ImgDir = "img",
  [string]$OptDir = "img/optimized"
)

Write-Output "Generating <picture> blocks using files in $OptDir"

if(-not (Test-Path $OptDir)){
  Write-Warning "$OptDir not found. Run the optimize script first or verify path. Exiting."
  exit 0
}

$htmlFiles = Get-ChildItem -Path $HtmlDir -Filter *.html -File

foreach($hf in $htmlFiles){
  $content = Get-Content $hf.FullName -Raw
  $original = $content
  $changed = $false

  # find img tags that reference img/<name>.<ext>
  $pattern = '<img\s+[^>]*src\s*=\s*"' + [regex]::Escape("$ImgDir/") + '([^"\\>]+)"[^>]*>'
  $matches = [regex]::Matches($content, $pattern, 'IgnoreCase')
  foreach($m in $matches){
    $imgFile = $m.Groups[1].Value # e.g. hero.svg or blog1.svg
    $base = [System.IO.Path]::GetFileNameWithoutExtension($imgFile)
    $ext = [System.IO.Path]::GetExtension($imgFile)

    # find optimized variants
    $opt480 = Join-Path $OptDir ("{0}-480{1}" -f $base, $ext)
    $opt768 = Join-Path $OptDir ("{0}-768{1}" -f $base, $ext)
    $optOrig = Join-Path $OptDir ("{0}{1}" -f $base, $ext)
    $webpOrig = Join-Path $OptDir ("{0}-orig.webp" -f $base)

    $sources = @()
    if(Test-Path $opt768){ $sources += @{path=$opt768;w=768} }
    if(Test-Path $opt480){ $sources += @{path=$opt480;w=480} }
    if(Test-Path $optOrig){ $sources += @{path=$optOrig;w=0} }

    # find any webp variants matching *-*.webp
    $webps = Get-ChildItem -Path $OptDir -Filter ("$base*.webp") -File -ErrorAction SilentlyContinue

    if($sources.Count -eq 0 -and $webps.Count -eq 0){
      # nothing to replace
      continue
    }

    # extract alt attribute if present
    $imgTag = $m.Value
    $alt = ''
    $altMatch = [regex]::Match($imgTag, 'alt\s*=\s*"([^"]*)"', 'IgnoreCase')
    if($altMatch.Success){ $alt = $altMatch.Groups[1].Value }

    # build picture markup
    $picture = "<picture>\n"
    if($webps.Count -gt 0){
      # prefer a webp source listing all webp files
      $srcsetWebp = ($webps | ForEach-Object { $_.FullName -replace '\\','/' }) -join ", "
      $picture += "  <source type='image/webp' srcset='$srcsetWebp'>\n"
    }
    if($sources.Count -gt 0){
      $srcsetLines = @()
      foreach($s in $sources){
        if($s.w -gt 0){ $srcsetLines += ( ($s.path -replace '\\','/') + " " + $s.w + "w" ) }
      }
      if($srcsetLines.Count -gt 0){
        $picture += "  <source srcset='" + ($srcsetLines -join ", ") + "'>\n"
      }
    }

    # fallback img: prefer optimized original if present, else keep original path
    $fallback = if(Test-Path $optOrig){ $optOrig } else { (Join-Path $ImgDir $imgFile) }
    $fallback = $fallback -replace '\\','/'

    $altAttr = ''
    if($alt -ne ''){ $altAttr = " alt='$alt'" }

    $picture += "  <img src='$fallback'$altAttr loading='lazy'>`n"
    $picture += "</picture>"

    # replace the first occurrence of this exact img tag using simple string replace
    $content = $content.Replace($imgTag, $picture)

    $changed = $true
  }

  if($changed -and $content -ne $original){
    # backup
    Copy-Item -Path $hf.FullName -Destination ($hf.FullName + ".bak") -Force
    Set-Content -Path $hf.FullName -Value $content -Encoding UTF8
    Write-Output "Updated: $($hf.Name) (backup: $($hf.Name).bak)"
  } else {
    Write-Output "No changes for: $($hf.Name)"
  }
}

Write-Output "generate-srcset finished. Review modified files if any."
