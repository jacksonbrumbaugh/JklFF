<#
.SYNOPSIS
Returns the NFL stat year for a calendar date

.NOTES
Created by Jackson Brumbaugh on 2022.11.13
#>
function Format-StatYear {
  [CmdletBinding()]
  param (
    [int]
    $Year
  ) # End block:param

  process {
    $StatYear = if ( $Year -eq 0 ) {
      $Today = Get-Date
      $ThisYear = $Today.Year
      if ( $Today.Month -in (1..8) ) {
        $ThisYear - 1
      } else {
        $ThisYear
      }
    } else {
      $Year
    }

    Write-Output $StatYear

  } # End block:process

} # End function
