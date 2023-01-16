<#
.SYNOPSIS
Returns the NFL stat year for a calendar year or date, or for the current date w/o any input

.NOTES
Created by Jackson Brumbaugh on 2022.11.13
VersionCode: 23Jan15-A
#>
function Get-StatYear {
  param (
    [int]
    $Year

  ) # End block:param

  begin {
    # INSERT code to cross check against valid years from Config file for Week 1 date

  } # End block:begin

  process {
    $NFLSeasonYear = if ( $Year -eq 0 ) {
      $Today = Get-Date
      $NowYear = $Today.Year

      # If the month is Jan thru Aug, then roll back to the prior year to match the NFL season year
      if ( $Today.Month -in (1..8) ) {
        $NowYear - 1
      } else {
        $NowYear
      }

    } else {
      $Year
    }

    Write-Output $NFLSeasonYear

  } # End block:process

} # End function
