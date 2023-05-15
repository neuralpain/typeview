# Install-Module ps2exe # run if ps2exe not installed
# Import-Module ps2exe # run if ps2exe not installed

$archive = ".\typeview.zip"

if (Test-Path .\dist) { Remove-Item .\dist\* -Recurse }
else { mkdir .\dist >$null 2>&1 }

mkdir .\dist\web_assets >$null 2>&1 

if (Test-Path $archive) { Remove-Item $archive >$null 2>&1 }

Invoke-PS2EXE .\typeview.ps1 .\dist\typeview.exe

Copy-Item .\index.html .\dist

foreach ($item in (Get-ChildItem .\web_assets\*)) { Copy-Item $item .\dist\web_assets }

Add-Type -Assembly System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(".\dist", $archive)

Move-Item $archive .\dist
