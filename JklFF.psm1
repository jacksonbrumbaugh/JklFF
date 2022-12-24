<#
NOTES
Created by Jackson Brumbaugh on ?
VersionCode: 2022Dec24-A
#>
$ModulePath = $PSScriptRoot

$NonExportFolders = @(
  "HelperCmds"
)

$ExportFolders = @(
  "MainCmds"
)

$LoadDirectories = @(
  $ModulePath
)

foreach ( $ThisFolder in ($NonExportFolders + $ExportFolders) ) {
  $LoadDirectories += Join-Path $ModulePath $ThisFolder
}

foreach ( $ThisDir in $LoadDirectories ) {
  $ExportThis = $true
  foreach ( $NoExportKeyword in $NonExportFolders ) {
    if ( $ThisDir -match $NoExportKeyword ) {
      $ExportThis = $false
    }
  }

  # DO NOT USE -Recurse
  # Otherwise the HelperCmds children will be exported
  $LoadScripts = Get-ChildItem $ThisDir\*.ps1
  foreach ( $ThisScript in $LoadScripts ) {
    . $ThisScript.FullName

    if ( $ExportThis ) {
      $FunctionName = $ThisScript.BaseName
      Export-ModuleMember -Function $FunctionName
    }
  }

}

<#
$LoadDirectories | ForEach-Object {
  Get-ChildItem $_\*.ps1 | ForEach-Object {
    . $_.FullName
  }
}
#>

<#
$ExportDirectories | ForEach-Object {
  Get-ChildItem $_\*.ps1 | ForEach-Object {
    $FunctionName = $_.BaseName
    Export-ModuleMember -Function $FunctionName
  }
}
#>
