<#
.NOTES
Modified = @{
  By   = Jackson Brumbaugh
  Date = 2023-11-11
}
#>

$ModulePath = $PSScriptRoot
#$ModuleName = $ModulePath | Split-Path -Leaf

enum Position {
  QB
  RB
  WR
  TE
}

enum ScoringFormat {
  PPR
  HPR
  STD
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

<#
look up from McL modules how to quickly export Aliases that were initiated inside the function source code files
#>
