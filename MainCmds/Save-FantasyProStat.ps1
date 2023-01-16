<#
.SYNOPSIS
Scraps weekly NFL stats from FantasyPros.com & saves the stats to a JSON file

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
    $Week,

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

    <#
    Example URI
    https://www.fantasypros.com/nfl/stats/qb.php?year=2021&week=17&range=week&scoring=HALF

    ^ reference to remind how to properly format the input values for Get-FantasyProStat
    #>

    $StatYear = Get-StatYear $Year

    $Stats = @{}

    Write-Status "Getting stats from the Fantansy Pros website"

    $OutputFileNameBase = "FantasyPro-NFL-Stats-Y{0}" -f $StatYear.SubString(2, 2)
    switch ( $PSCmdlet.ParameterSetName ) {
      "AllWeeks" {
        # INSERT code to check an 'up to week' value if the regular season has not finished

        $Msg = "For all weeks from the {0} NFL season" -f $StatYear
        Write-Status $Msg

        $Stats = @()

        $Stats += @{
          Title     = "NFL Fantasy Stats from the FantasyPros.com website"
          NFLSeason = $StatYear
        }

        foreach ( $ThisWeek in (1 .. 18) ) {
          $Msg = "> Week {0:N2}" -f $ThisWeek
          Write-Status $Msg

          foreach ( $ThisPosition in $PositionArray ) {
            $Msg = "  > {0}" -f $ThisPosition
            Write-Status $Msg

            $StatCallParam = @{
              Year     = $StatYear
              Week     = $ThisWeek
              Position = $ThisPosition
            }

            $StatsForThisWeek = Get-FantasyProStat @StatCallParam

            # or ... could INSERT a check here if prior weekly stats match the newest scrap as an exit condition

            $Stats += $StatsForThisWeek

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

    try {
      $JsonStats = $Stats | ConvertTo-Json
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
