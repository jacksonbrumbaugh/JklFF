<#
.NOTES
Created by Jackson Brumbaugh on ?
Version: 2023Aug25-A
#>
$ModulePath = $PSScriptRoot

enum Position {
  QB
  RB
  WR
  TE
}

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
