<#
  typeview.ps1, Version 0.4.0
  Copyright (c) 2023, neuralpain
  View your local typefaces in the browser
#>

param(
  [Parameter(Mandatory)] [string] $Directory, 
  [switch] $Update,
  [switch] $OpenInBrowser,
  [switch] $Install,
  [switch] $AddShortcut
)

# if (-not(Test-Path "$Directory\_fontwebview")) { mkdir "$Directory\_fontwebview" }

# clean up slash endings
while (($Directory.Substring($Directory.Length - 1) -eq "\") -or ($Directory.Substring($Directory.Length - 1) -eq "/")) {
  $Directory = $Directory.Substring(0, $Directory.Length - 1)
}

if (-not(Test-Path $Directory)) { Write-Host "typeview: " -NoNewline; Write-Host "Directory does not exist." -ForegroundColor DarkRed; exit }

# $FONT_WEBVIEW = "$Directory\_fontwebview" # Re: `Clear-FontCache`
$FONT_WEBVIEW_INDEX = "$Directory\index.html"
$FONT_WEBVIEW_CSS = "$Directory\fontcache.css"
# $FDIR_LIST = "$Directory\DIRLIST.CSV" 
$FONT_LIST = "$Directory\FONTLIST.CSV"

Write-Host;

function Remove-Typeview {
  if ((Test-Path $FDIR_LIST) -or (Test-Path $FONT_LIST) -or (Test-Path $FONT_WEBVIEW_INDEX) -or (Test-Path $FONT_WEBVIEW_CSS)) {
    # Remove-Item $FDIR_LIST >$null 2>&1
    Remove-Item $FONT_LIST >$null 2>&1
    Remove-Item $FONT_WEBVIEW_INDEX >$null 2>&1
    Remove-Item $FONT_WEBVIEW_CSS >$null 2>&1
  }
}

function RemoveQuotesFromPath {
  param ( $File, $TableName )
  $content = Get-Content -Path $File
  $content | Select-Object -Skip 1 | 
  ForEach-Object { $_ -replace '"' } | 
  Set-Content -Path $File
}

function Reset-FontStylesheet {
  if (Test-Path $FONT_WEBVIEW_CSS) { Clear-Content $FONT_WEBVIEW_CSS } 
}

function Get-FontList {
  return (Get-Content -Path $FONT_LIST)
}

function Reset-FontCache {

  # if (Test-Path $FDIR_LIST) { Clear-Content $FDIR_LIST }
  if (Test-Path $FONT_LIST) { Clear-Content $FONT_LIST }
  
  <# removed to resolve issues when editing with live server
    if (Test-Path $FONT_WEBVIEW_INDEX) { Clear-Content $FONT_WEBVIEW_INDEX }
  #>

  Write-Host "==> Scanning directories... " -NoNewline
  Get-ChildItem -Path $Directory -Recurse -Include *.otf, *.ttf | 
  Select-Object DirectoryName -Unique | 
  Export-Csv -Path $FONT_LIST -NoTypeInformation
  RemoveQuotesFromPath -File $FONT_LIST
  Write-Host "Done."
  
  $DIR = Get-FontList
  Clear-Content $FONT_LIST
  Write-Host "==> Collecting fonts... " -NoNewline
  foreach ($_path in $DIR) { 
    Get-ChildItem -Path "$_path" -Recurse -Include *.otf, *.ttf | 
    Select-Object FullName | 
    Export-Csv -Path $FONT_LIST -Append -NoTypeInformation 
  }
  RemoveQuotesFromPath -File $FONT_LIST
  Write-Host "Done."
}

$install_location = "C:\typeview"
function New-Shortcut {
  param (
    [string] $Name,
    [string] $Target,
    [string] $Arguments,
    [switch] $RunPowerShell
  )

  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("$Home\Desktop\$Name.lnk")
  
  if ($RunPowerShell) { 
    $Target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Arguments = " -noexit -ExecutionPolicy Bypass -File `"$install_location\typeview.ps1`" -Directory `"$Directory`" $Arguments"
  }

  $Shortcut.TargetPath = "`"$Target`""
  $Shortcut.Arguments = $Arguments
  $Shortcut.WorkingDirectory = $install_location
  $Shortcut.Save()
}

if (($Update) -or (-not(Test-Path $FONT_LIST))) { Reset-FontCache }

Write-Host "==> Compiling webview... " -NoNewline
Reset-FontStylesheet
$FONT = Get-FontList
Copy-Item ".\index.html" $FONT_WEBVIEW_INDEX

foreach ($_font in $FONT) {
  $font_family = ($_font | Split-Path -Leaf).replace('.otf', '-OTF').replace('.ttf', '-TTF')
  $font_url = $_font.replace($Directory, '').replace('\', '/').substring(1)
  
  ("@font-face{font-family:`"$font_family`";src:url(`"$font_url`");}") | 
  Out-File $FONT_WEBVIEW_CSS -Append -Encoding ascii
  
  $font_family_space = $font_family.Replace(" ", "-")

  ("<div class=`"typeview_TypefaceDisplay`" 
    onmouseover=`"document.getElementById('$font_family_space').style.fontFamily='$font_family';`" 
    onmouseout=`"document.getElementById('$font_family_space').style.fontFamily='';`">
    <div id=`"$font_family_space`" class=`"typeview_Typeface`">$font_family</div>
  </div>") | Out-File $FONT_WEBVIEW_INDEX -Append -Encoding ascii
}

(Get-Content ".\index_end.html") | 
Out-File $FONT_WEBVIEW_INDEX -Append -Encoding ascii
Write-Host "Done."


if ($Install) {
  Write-Host "==> Installing to $install_location... " -NoNewline
  Copy-Item (Get-ChildItem) $install_location -Force
  Write-Host "Done."
  Write-Host "==> Creating shortcuts... " -NoNewline
  New-Shortcut -Name "Open Typeview Font Webview" -Target "$FONT_WEBVIEW_INDEX"
  New-Shortcut -Name "Update Typeview Font Cache" -Arguments "-Update" -RunPowerShell
  New-Shortcut -Name "Rebuild Typeview Webview" -RunPowerShell
  Write-Host "Done."
}

elseif ($AddShortcut) {
  Write-Host "==> Creating shortcut... " -NoNewline
  New-Shortcut -Name "Open Typeview Font Webview" -Target "$FONT_WEBVIEW_INDEX"
  Write-Host "Done."
}

Write-Host "`nWebview location: " -NoNewline; 
Write-Host "$FONT_WEBVIEW_INDEX`n" -ForegroundColor DarkCyan

if ($OpenInBrowser) {
  Write-Host "==> Opening in default browser...`n"
  Start-Process $FONT_WEBVIEW_INDEX
}

exit
