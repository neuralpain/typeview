<#
  typeview.ps1, Version 0.6.0
  Copyright (c) 2023, neuralpain
  View your local typefaces in the browser
#>

param(
  [Parameter(Mandatory)] [string] $Directory, 
  [switch] $Update,
  [switch] $OpenInBrowser,
  [switch] $Install,
  [string] $InstallLocation = "C:\",
  [switch] $Uninstall,
  [switch] $AddShortcut,
  [string] $ShortcutLocation = "$Home\Desktop"
)

function Remove-DirectorySlash {
  param ( [string] $Directory )
  
  $Directory = $Directory.Replace("typeview", "")
  
  while (($Directory.Substring($Directory.Length - 1) -eq "\") -or ($Directory.Substring($Directory.Length - 1) -eq "/")) { 
    $Directory = $Directory.Substring(0, $Directory.Length - 1) # $Directory.Remove($Directory.Length - 1, 1)
  }
  
  return $Directory 
}

function Test-DirectoryLocation {
  param ( [string] $Directory )
  
  if (-not(Test-Path $Directory)) {
    Write-Host "typeview: " -NoNewline
    Write-Host "`"$Directory`" does not exist." -ForegroundColor DarkRed
    exit
  }
}


$Directory = (Remove-DirectorySlash $Directory)
$ShortcutLocation = (Remove-DirectorySlash $ShortcutLocation)
$InstallLocation = (Remove-DirectorySlash $InstallLocation)
Test-DirectoryLocation $Directory
Test-DirectoryLocation $ShortcutLocation
Test-DirectoryLocation $InstallLocation
$InstallLocation = "$InstallLocation\typeview"

$TV_WEBVIEW = "$Directory\_fontwebview"
$TV_WEBVIEW_INDEX = "$Directory\index.html"
$TV_WEBVIEW_CSS = "$TV_WEBVIEW\fontcache.css"
$FONT_LIST = "$TV_WEBVIEW\FONTLIST.CSV"

$TV_SHORTCUT_OPEN = "Open Typeview Font Webview.lnk"
$TV_SHORTCUT_UPDATE = "Update Typeview Font Cache.lnk"
$TV_SHORTCUT_REBUILD = "Rebuild Typeview Webview.lnk"

Write-Host;

function Remove-Typeview {
  
  if ((Test-Path $TV_WEBVIEW_INDEX) -or (Test-Path $TV_WEBVIEW)) {
    Write-Host "==> Removing typeview... " -NoNewline
    Remove-Item $TV_WEBVIEW_INDEX -Force >$null 2>&1
    Remove-Item $TV_WEBVIEW -Force -Recurse >$null 2>&1
    Remove-Item $InstallLocation -Force -Recurse >$null 2>&1
    if (Test-Path "$ShortcutLocation\$TV_SHORTCUT_OPEN") { Remove-Item "$ShortcutLocation\$TV_SHORTCUT_OPEN" >$null 2>&1 }
    if (Test-Path "$ShortcutLocation\$TV_SHORTCUT_UPDATE") { Remove-Item "$ShortcutLocation\$TV_SHORTCUT_UPDATE" >$null 2>&1 }
    if (Test-Path "$ShortcutLocation\$TV_SHORTCUT_REBUILD") { Remove-Item "$ShortcutLocation\$TV_SHORTCUT_REBUILD" >$null 2>&1 }
    Write-Host "Done.`n"
  }
  else {
    Write-Host "typeview: " -NoNewline
    Write-Host "typeview is not installed.`n" -ForegroundColor DarkRed
  }
}

function RemoveQuotesFromPath {
  param ( $File, $TableName )
  $content = (Get-Content -Path $File)
  $content | Select-Object -Skip 1 | 
  ForEach-Object { $_ -replace '"' } | 
  Set-Content -Path $File
}

function Reset-FontStylesheet { if (Test-Path $TV_WEBVIEW_CSS) { Clear-Content $TV_WEBVIEW_CSS } }
function Get-FontList { return (Get-Content -Path $FONT_LIST) }

function Reset-FontCache {
  if (-not(Test-Path $TV_WEBVIEW)) { mkdir $TV_WEBVIEW >$null 2>&1 }
  if (Test-Path $FONT_LIST) { Clear-Content $FONT_LIST }
  if (Test-Path $TV_WEBVIEW_INDEX) { Clear-Content $TV_WEBVIEW_INDEX }

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

function New-Shortcut {
  param (
    [string] $Name,
    [string] $Target,
    [string] $Arguments,
    [switch] $RunPowerShell
  )

  $WshShell = New-Object -ComObject WScript.Shell
  $Shortcut = $WshShell.CreateShortcut("$ShortcutLocation\$Name")
  
  if ($RunPowerShell) { 
    $Target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $Arguments = " -noexit -ExecutionPolicy Bypass -File `"$InstallLocation\typeview.ps1`" -Directory `"$Directory`" $Arguments"
  }

  $Shortcut.TargetPath = "`"$Target`""
  $Shortcut.Arguments = $Arguments
  $Shortcut.WorkingDirectory = $InstallLocation
  $Shortcut.Save()
}

function Invoke-Install {
  Write-Host "==> Installing... " -NoNewline
  Copy-Item (Get-ChildItem) $InstallLocation -Force
  Write-Host "Done."
  Write-Host "==> Creating shortcuts... " -NoNewline
  New-Shortcut -Name $TV_SHORTCUT_OPEN -Target "$TV_WEBVIEW_INDEX"
  New-Shortcut -Name $TV_SHORTCUT_UPDATE -Arguments "-Update" -RunPowerShell
  New-Shortcut -Name $TV_SHORTCUT_REBUILD -RunPowerShell
  Write-Host "Done."
}

function Invoke-InstallShortcut {
  Write-Host "==> Creating shortcut... " -NoNewline
  New-Shortcut -Name $TV_SHORTCUT_OPEN -Target "$TV_WEBVIEW_INDEX"
  Write-Host "Done."
}

function New-CreateWebview {
  Write-Host "==> Compiling webview... " -NoNewline
  Reset-FontStylesheet
  $FONT = (Get-FontList)
  Copy-Item ".\index.html" $TV_WEBVIEW_INDEX

  foreach ($_font in $FONT) {
    $font_family = ($_font | Split-Path -Leaf).replace('.otf', '-OTF').replace('.ttf', '-TTF')
    $font_url = $_font.replace($Directory, '').replace('\', '/').substring(1)
    
    ("@font-face{font-family:`"$font_family`";src:url(`"../$font_url`");}") | 
    Out-File $TV_WEBVIEW_CSS -Append -Encoding ascii
    
    $font_family_space = $font_family.Replace(" ", "-")

    ("<div class=`"typeview_TypefaceDisplay`" 
      onmouseover=`"document.getElementById('$font_family_space').style.fontFamily='$font_family';`" 
      onmouseout=`"document.getElementById('$font_family_space').style.fontFamily='';`">
      <div id=`"$font_family_space`" class=`"typeview_Typeface`">$font_family</div>
    </div>") | Out-File $TV_WEBVIEW_INDEX -Append -Encoding ascii
  }

  (Get-Content ".\index_end.html") | 
  Out-File $TV_WEBVIEW_INDEX -Append -Encoding ascii
  Write-Host "Done."

  if ($Install) { 
    Invoke-Install 
    Write-Host "`nInstall location: " -NoNewline
    Write-Host "$InstallLocation" -ForegroundColor DarkCyan
  }
  elseif ($AddShortcut) { Invoke-InstallShortcut }

  Write-Host "`nWebview location: " -NoNewline
  Write-Host "$TV_WEBVIEW_INDEX" -ForegroundColor DarkCyan
}

if ($Uninstall) { Remove-Typeview; exit }
if (($Update) -or (-not(Test-Path $TV_WEBVIEW))) { Reset-FontCache }

New-CreateWebview

if ($OpenInBrowser) {
  Write-Host "`n==> Opening in default browser..."
  Start-Process $TV_WEBVIEW_INDEX
}

Write-Host; exit
