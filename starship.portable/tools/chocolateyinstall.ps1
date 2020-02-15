$ErrorActionPreference = 'Stop'
$toolsDir   = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Join-Path $toolsDir 'starship-x86_64-pc-windows-msvc.zip'

Get-ChocolateyUnzip -PackageName starship -FileFullPath64 $fileLocation -Destination $toolsDir
Remove-Item $fileLocation
