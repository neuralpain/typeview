param([string] $Directory)

# if (-not(Test-Path "$Directory\_fontwebview")) { mkdir "$Directory\_fontwebview" }

$FONT_DIR = $Directory
$FONT_WEBVIEW = $Directory
# $FONT_WEBVIEW = "$Directory\_fontwebview"
$FONT_WEBVIEW_INDEX = "$FONT_WEBVIEW\index.html"
$FONT_WEBVIEW_CSS = "$FONT_WEBVIEW\fontcache.css"
$FDIR_LIST = "$FONT_WEBVIEW\DIRLIST.CSV"
$FONT_LIST = "$FONT_WEBVIEW\FONTLIST.CSV"

# clean up endings
while (($Directory.Substring($Directory.Length - 1) -eq "\") -or ($Directory.Substring($Directory.Length - 1) -eq "/")) {
  $Directory = $Directory.Substring(0, $Directory.Length - 1)
}

function RemoveQuotesFromPath {
  param ( $File, $TableName )
  $content = Get-Content -Path $File
  $content | Select-Object -Skip 1 | 
  ForEach-Object { $_ -replace '"' } | 
  Set-Content -Path $File
}

function Clear-FontCache { 
  if (Test-Path $FDIR_LIST) { Clear-Content $FDIR_LIST }
  if (Test-Path $FONT_LIST) { Clear-Content $FONT_LIST }
  if (Test-Path $FONT_WEBVIEW_CSS) { Clear-Content $FONT_WEBVIEW_CSS } 
  # if (Test-Path $FONT_WEBVIEW_INDEX) { Clear-Content $FONT_WEBVIEW_INDEX } 
}

Clear-FontCache

Get-ChildItem -Path $FONT_DIR -Recurse -Include *.otf, *.ttf | 
Select-Object DirectoryName -Unique | 
Export-Csv -Path $FDIR_LIST -NoTypeInformation

RemoveQuotesFromPath -File $FDIR_LIST

$DIR = (Get-Content -Path $FDIR_LIST)
foreach ($_path in $DIR) { 
  Get-ChildItem -Path "$_path" -Recurse -Include *.otf, *.ttf | 
  Select-Object FullName | 
  Export-Csv -Path $FONT_LIST -Append -NoTypeInformation 
}

RemoveQuotesFromPath -File $FONT_LIST

$FONT = (Get-Content -Path $FONT_LIST)

Copy-Item ".\index.html" $FONT_WEBVIEW_INDEX

foreach ($_font in $FONT) {
  $font_family = ($_font | Split-Path -Leaf).replace('.otf', '-OTF').replace('.ttf', '-TTF')
  $font_url = $_font.replace($Directory,'').replace('\','/').substring(1)
  
  ( "@font-face { font-family: `"$font_family`"; src: url(`"$font_url`"); }" ) | 
  Out-File $FONT_WEBVIEW_CSS -Append -Encoding ascii

  ("<option value=`"$font_family`">$font_family</option>") | Out-File $FONT_WEBVIEW_INDEX -Append  -Encoding ascii
}


(Get-Content ".\index_end.html") | Out-File $FONT_WEBVIEW_INDEX -Append -Encoding ascii