<#
.SYNOPSIS
Scraps weekly NFL stats & saves to a JSON file

.NOTES
Created by Jackson Brumbaugh on 2022.11.13
VersionCode: 22no13-A
#>
function Save-FantasyProStat {
  <# Plan of Attack
  add a switch parameter to also pass the stats thru at the CMD line while saving the JSON file
  #>
  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory
    )]
    [ValidateRange(
      1, 18
    )]
    [Alias("W")]
    $Week,

    $Year
  ) # End block:param

  process {
    $StatFolder = Join-Path $ModulePath "Stats"
    $FoundStatFolder = Test-Path $StatFolder
    if ( -not $FoundStatFolder ) {
      $ErrorDetails = @{
        Message     = "Failed to locate a Stats folder in our PowerShell module"
        ErrorAction = "Stop"
      }
      Write-Error @ErrorDetails
    }

    <#
    Example URI
    https://www.fantasypros.com/nfl/stats/qb.php?year=2021&week=17&range=week&scoring=HALF
    #>

    $StatYear = Format-StatYear $Year

    $Stats = @{}

    Write-Host "Pulling position stats from Fantansy Pros website"
    foreach ( $ThisPosition in ("QB", "RB", "WR", "TE") ) {
      Write-Host " > $ThisPosition"

      $StatDetails = @{
        Year     = $StatYear
        Week     = $Week
        Position = $ThisPosition
      }
      $Stats.$ThisPosition = Get-FantasyProStat @StatDetails
    }
    Write-Host "All positions pulled"

    $OutputFileName = "FantasyPro-NFL-Stats-{0:D2}-{1:D2}.json" -f $StatYear, $Week
    $OutputFileFullName = Join-Path $StatFolder $OutputFileName

    try {
      $Stats | ConvertTo-Json | Set-Content -Path $OutputFileFullName
    } catch {
      $ErrorDetails = @{
        Message     = "Failed to save stats to a JSON file in the Stats folder"
        ErrorAction = "Stop"
      }
      Write-Error @ErrorDetails
    }

    $OutputItem = Get-Item $OutputFileFullName
    Write-Output $OutputItem.Name

  } # End block:process

} # End function
