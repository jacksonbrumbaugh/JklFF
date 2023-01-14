<#
.NOTES
Created by Jackson Brumbaugh on 2023.01.14
VersionCode: 23Jan14-A
#>
function Get-Config {
  Write-Verbose "Running Get-Config. "

  $ErrorDetails = @{
    ErrorAction = "Stop"
  }

  Write-Verbose "Getting the JklFF PowerShell module Support directory path. "
  $SupportDirectoryPath = Get-SupportPath
  $ConfigFilePath = Get-Item $SupportDirectoryPath\*Config*json | Select-Object -ExpandProperty FullName

  if ( -not(Test-Path $ConfigFilePath) ) {
    $ErrorDetails.Message = "Failed to find the JSON Config file for the JklFF PowerShell module"
  }

  Write-Verbose "Found JSON Config file for the JklFF PowerShell module"

  Write-Verbose "Converting raw JSON config into a PS Custom Object"
  try { $Config = Get-Content $ConfigFilePath | ConvertFrom-JSON }
  catch {
    $ErrorDetails.Message = "Failed to convert the JSON from the Config file into a PS Custom Object. "
    $ErrorDetails.Message += "Please check the format of the Config file then try again. "
    Write-Error @ErrorDetails
  }

  Write-Output $Config

} # End function
