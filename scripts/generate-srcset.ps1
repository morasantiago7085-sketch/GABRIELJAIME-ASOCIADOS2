

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

  $pattern = '<img\s+[^>]*src\s*=\s*"' + [regex]::Escape("$ImgDir/") + '([^"\\>]+)"[^>]*>'
  $matches = [regex]::Matches($content, $pattern, 'IgnoreCase')
  foreach($m in $matches){
    $imgFile = $m.Groups[1].Value 
    $base = [System.IO.Path]::GetFileNameWithoutExtension($imgFile)
    $ext = [System.IO.Path]::GetExtension($imgFile)

    $opt480 = Join-Path $OptDir ("{0}-480{1}" -f $base, $ext)
    $opt768 = Join-Path $OptDir ("{0}-768{1}" -f $base, $ext)
    $optOrig = Join-Path $OptDir ("{0}{1}" -f $base, $ext)
    $webpOrig = Join-Path $OptDir ("{0}-orig.webp" -f $base)

    $sources = @()
    if(Test-Path $opt768){ $sources += @{path=$opt768;w=768} }
    if(Test-Path $opt480){ $sources += @{path=$opt480;w=480} }
    if(Test-Path $optOrig){ $sources += @{path=$optOrig;w=0} }

    $webps = Get-ChildItem -Path $OptDir -Filter ("$base*.webp") -File -ErrorAction SilentlyContinue

    if($sources.Count -eq 0 -and $webps.Count -eq 0){
      continue
    }

    $imgTag = $m.Value
    $alt = ''
    $altMatch = [regex]::Match($imgTag, 'alt\s*=\s*"([^"]*)"', 'IgnoreCase')
    if($altMatch.Success){ $alt = $altMatch.Groups[1].Value }

    $picture = "<picture>\n"
    if($webps.Count -gt 0){
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

    $fallback = if(Test-Path $optOrig){ $optOrig } else { (Join-Path $ImgDir $imgFile) }
    $fallback = $fallback -replace '\\','/'

    $altAttr = ''
    if($alt -ne ''){ $altAttr = " alt='$alt'" }

    $picture += "  <img src='$fallback'$altAttr loading='lazy'>`n"
    $picture += "</picture>"

    $content = $content.Replace($imgTag, $picture)

    $changed = $true
  }

  if($changed -and $content -ne $original){

    Copy-Item -Path $hf.FullName -Destination ($hf.FullName + ".bak") -Force
    Set-Content -Path $hf.FullName -Value $content -Encoding UTF8
    Write-Output "Updated: $($hf.Name) (backup: $($hf.Name).bak)"
  } else {
    Write-Output "No changes for: $($hf.Name)"
  }
}

Write-Output "generate-srcset finished. Review modified files if any."
