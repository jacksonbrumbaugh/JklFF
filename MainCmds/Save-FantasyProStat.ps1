<#
.SYNOPSIS
Scraps weekly NFL stats (defaulting to Stanrd - no PPR - scoring) from FantasyPros.com & saves the stats to a JSON file

.NOTES
Created by Jackson Brumbaugh on 2022.11.13
VersionCode: 23Jan15-A
#>
function Save-FantasyProStat {
  <# Plan of Attack
  add a switch parameter to also pass the stats thru at the CMD line while saving the JSON file

  ... what did i mean by ^ that??
  #>
  [CmdletBinding( DefaultParameterSetName = "AllWeeks" )]
  param (
    [Parameter(
      Mandatory,
      ParameterSetName = "AllWeeks"
    )]
    [Parameter(
      ParameterSetName = "SelectWeek"
    )]
    [ValidateRange(
      2002, 2102 # Arbitrarily picked 100 years from the lowest value shown on the Fantasy Pro's site
    )]
    [int]
    $Year,

    [Parameter(
      Mandatory,
      ParameterSetName = "SelectWeek"
    )]
    [ValidateRange(
      1, 18
    )]  
    [Alias("W")]
    [int]
    $Week,

    [ValidateSet(
      "PPR",
      "P",
      "HALF",
      "HPR",
      "H",
      "Standard",
      "Std",
      "Stan",
      "S"
    )]
    [string]
    $Scoring,

    # Optional flag to hide status messages sent to the host console
    [switch]
    $SilentlyGet
  ) # End block:param

  begin {
    $PositionArray = @(
      "QB",
      "RB",
      "WR",
      "TE"      
    )

    function Write-Status ( [string[]]$Message, [boolean]$Silent = $SilentlyGet ) {
      if ( -not $Silent ) {
        foreach ( $ThisLine in $Message ) {
          Write-Host $Message
        }
      }
    } # End function

    # Hope to have this trigger but it'll be there if needed
    $ErrorDetails = @{
      ErrorAction = "Stop"
    }

  } # End block:begin

  process {
    $StatFolder = Join-Path $ModulePath "Stats"

    Write-Verbose "Checking for the stats folder in the JklFF PowerShell module"
    $FoundStatFolder = Test-Path $StatFolder
    if ( -not $FoundStatFolder ) {
      $ErrorDetails.Message = "Failed to locate a Stats folder in the JklFF PowerShell module"
      Write-Error @ErrorDetails
    }

    $StatYear = Get-StatYear $Year

    $Stats = @{}

    Write-Status "Getting stats from the Fantansy Pros website"

    $OutputFileNameBase = "FantasyPro-NFL-Stats-Y{0}" -f $StatYear
    switch ( $PSCmdlet.ParameterSetName ) {
      "AllWeeks" {
        # INSERT code to check an 'up to week' value if the regular season has not finished

        $Msg = "For all weeks from the {0:D4} NFL season" -f $StatYear
        Write-Status $Msg

        $Stats = [PSCustomObject]@{
          Title     = "{0:D4} NFL Fantasy Stats from the FantasyPros.com website" -f $Year
          NFLSeason = $StatYear
          Stats     = @()
        }

        foreach ( $ThisWeek in (1 .. 18) ) {
          $Msg = "> Week {0:D2}" -f $ThisWeek
          Write-Status $Msg

          foreach ( $ThisPosition in $PositionArray ) {
            $Msg = "  > {0}" -f $ThisPosition
            Write-Status $Msg

            <#
            Example URI // when Standard (no PPR) ?week=1&range=week
            https://www.fantasypros.com/nfl/stats/qb.php?year=2021&week=17&range=week&scoring=HALF

            ^ reference to remind how to properly format the input values for Get-FantasyProStat
            #>

            $StatCallParam = @{
              Year     = $StatYear
              Week     = $ThisWeek
              Position = $ThisPosition
            }

            if ( -not [string]::IsNullOrEmpty($Scoring) ) {
              $StatCallParam.Scoring = $Scoring
            }

            $StatsForThisWeek = Get-FantasyProStat @StatCallParam

            <#
            Fantasy Pros will return a page from a week that has not happened yet
            so this check is in case, for e.g., it is only week 7 of a season
            but ThisWeek -eq 8
            #>
            if ( $PriorWeekStats -ne $StatsForThisWeek ) {
              $Stats.Stats += $StatsForThisWeek
            } else {
              break
            }

          } # End block:foreach Position

        } # End block:foreach Week

      } # End case:AllWeeks
      
      "SelectWeek" {
        $OutputFileNameBase += "-W{0:D2}" -f $Week

        $Stats = @{}

        $Msg = "For week {0:N2} from the {1} NFL season" -f $Week, $StatYear
        Write-Status $Msg

        foreach ( $ThisPosition in ("QB", "RB", "WR", "TE") ) {
          Write-Status "> $ThisPosition"
    
          $StatDetails = @{
            Year     = $StatYear
            Week     = $Week
            Position = $ThisPosition
          }

          $Stats.$ThisPosition = Get-FantasyProStat @StatDetails

        }

      } # End case:SelectWeek

    } # End block:switch on Parameter Set Name

    $OutputFileName = $OutputFileNameBase + ".json"
    $OutputFileFullName = Join-Path $StatFolder $OutputFileName

    if ( $true ) {
      Write-Output $Stats
    }
    try {
      $JsonStats = $Stats | ConvertTo-Json -Depth 4
    } catch {
      $ErrorDetails.Message = "Failed to convert the stats to a JSON format"
      Write-Error @ErrorDetails
    }

    $JsonStats | Set-Content -Path $OutputFileFullName

    try { $OutputItem = Get-Item $OutputFileFullName }
    catch {
      $ErrorDetails.Message = "Failed to save JSON formatted stats out to a file"
      Write-Error @ErrorDetails
    }

    Write-Output $OutputItem.Name

  } # End block:process

} # End function
