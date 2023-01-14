<#
.NOTES
Created by Jackson Brumbaugh on 2023.01.14
VersionCode: 23Jan14-A
#>
function Get-SupportPath {
  $ErrorDetails = @{
    ErrorAction = "Stop"
  }

  Write-Verbose "Running Get-SupportPath. "

  $HelperCommandsDirectory = $PSScriptRoot
  $ModuleDirectory = Split-Path $HelperCommandsDirectory -Parent
  $SupportDirectoryPath = Get-Item $ModuleDirectory\*Support* | Select-Object -ExpandProperty FullName

  if ( -not(Test-Path $SupportDirectoryPath) ) {
    $ErrorDetails.Message = "Failed to find the *Support* directory for the JklFF PowerShell module. "
    Write-Error @ErrorDetails
  }

  Write-Verbose "Found the *Support* directory for the JklFF PowerShell module. "

  Write-Output $SupportDirectoryPath

} # End function
