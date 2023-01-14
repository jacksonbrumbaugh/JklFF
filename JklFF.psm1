<#
.NOTES
Created by Jackson Brumbaugh on ?
VersionCode: 23Jan14-A
#>
$ModulePath = $PSScriptRoot

$NonExportFolders = @(
  "HelperCmds"
)

$ExportFolders = @(
  "MainCmds",
  "UnderDev"
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
