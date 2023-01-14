<#
.NOTES
Created by Jackson Brumbaugh on 2023.01.14
VersionCode: 23Jan14-A
#>
function Get-WeekOneDate {
  [CmdletBinding()]
  param (
    [Parameter(
      ValueFromPipeline
    )]
    [int]
    $Year
  ) # End block:param

  begin {
    Write-Verbose "Running Get-WeekOneDate. "

    $ErrorDetails = @{
      ErrorAction = "Stop"
    }

    Write-Verbose "Getting the JklFF PowerShell module configuration settings. "
    $Config = Get-Config

  } # End block:begin

  process {
    Write-Verbose "Determining which year to check for the NFL week one date. "
    $ThisYear = if ( $Year ) {
      $StatusMsg = "Setting year to the input value of {0}. " -f $Year
      Write-Verbose $StatusMsg
      $Year
    } else {
      $Today = Get-Date
      $NowYear = $Today.Year

      if ( $Today.Month -lt 9 ) {
        $NowYear--
      }

      $StatusMsg = "Setting year to this current {0} NFL season. " -f $NowYear
      Write-Verbose $StatusMsg

      $NowYear

    }

    $ValidYearArray = $Config.WeekOne.PSObject.Properties.Name
 
    $StatusMsg =  "Checking if {0} has been assigned" -f $ThisYear
    $StatusMsg += " an NFL week one date in the JSON Config settings. "
    Write-Verbose $StatusMsg

    if ( $ThisYear -notin $ValidYearArray ) {
      $ErrorDetails.Message = "The year {0} has not been assigned an NFL week one date" -f $ThisYear
      $ErrorDetails.Message += " in the JklFF PowerShell module JSON Config file. "
      $ErrorDetails.Message += "Please set this value then try again. "
      Write-Error @ErrorDetails
    }

    $WeekOneDate = $Config.WeekOne.$ThisYear

    Write-Output $WeekOneDate

  } # End block:process

} # End function
