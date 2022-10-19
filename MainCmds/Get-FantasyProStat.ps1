<#
.SYNOPSIS
Pulls NFL stats from the Fantasy Pros website

.NOTES
Created on 2022-10-13 by Jackson Brumbaugh
VersionCode: 20221018-C
#>
function Get-FantasyProStat {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory)]
    [ValidateSet(
      "QB",
      "RB",
      "WR",
      "TE"
    )]
    [string]
    $Position,

    [Parameter(Mandatory)]
    [ValidateRange(1, 18)]
    [int]
    $Week

  ) # End block:param

  process {
    # Example URI
    # https://www.fantasypros.com/nfl/stats/rb.php?week=6&scoring=HALF&range=week
    $BaseSite = "https://www.fantasypros.com/nfl/stats/"

    $UriParams = @(
      $BaseSite,
      $Position.ToLower(),
      $Week
    )
    $URI = "{0}{1}.php?scoring=HALF&range=week&week={2}" -f $UriParams

    try {
      $Response = Invoke-WebRequest -URI $URI
    }
    catch {
      $ErrorDetails = @{
        Message = "Failed to get the URI(" + $URI + ")"
        ErrorAction = "Stop"
      }

      Write-Error $ErrorDetails
    }

    $HTML = $Response.ParsedHtml
    $Tables = $Html.GetElementsByTagName( 'table' )
    $Rows = $Tables[0].Rows
    $StatHeader = $Rows[1]
    $StatHeaderItems = $StatHeader.InnerHtml.split("`n")

    # BUG
    # Need to properly label PassTD vs RushTD vs RecTD
    $PriorStatName = ""
    $StatKeys = foreach ( $ThisStat in $StatHeaderItems ) {
      $StatNoSmall = $ThisStat -replace "<SMALL>", "" -replace "</SMALL>", ""
      $StatName = $StatNoSmall -replace ".*TH.*>(.+)</TH.*", '$1'

      $ThisStatKey = $StatName

      if ( $StatName -eq "YDS" ) {
        $ThisStatKey = switch ( $PriorStatName ) {
          "PCT" { "PASS" + $StatName }
          "ATT" { "RUSH" + $StatName }
          "TGT" { "REC" + $StatName }
          Default { $StatName }
        }
      }

      if ( $StatName -eq "TD" ) {
        if ( $Position -eq "QB" ) {
          $ThisStatKey = switch ( $PriorStatName ) {
            "Y/A" { "PASS" + $StatName }
            "YDS" { "RUSH" + $StatName }
            Default { $StatName }
          }
        }

        if ( $Position -eq "RB" ) {
          $ThisStatKey = switch ( $PriorStatName ) {
            "20+" { "RUSH" + $StatName }
            "Y/R" { "REC" + $StatName }
            Default { $StatName }
          }
        }

        if ( $Position -in ("WR", "TE") ) {
          $ThisStatKey = switch ( $PriorStatName ) {
            "20+" { "REC" + $StatName }
            "YDS" { "RUSH" + $StatName }
            Default { $StatName }
          }
        }

      }

      $PriorStatName = $StatName

      # Add this as part of StatKeys
      $ThisStatKey

    } # End block:foreach ThisStat in StatHeaderItems

    $RowSize = $StatHeader.count
    $PlayerStatsHash = foreach ( $ThisRow in $Rows ) {
      # Skip the header rows
      if ( $ThisRow -eq $Rows[0] ) {
        continue
      }
      if ( $ThisRow -eq $Rows[1] ) {
        continue
      }

      $RowContent = $ThisRow.InnerHtml.split("`n")

      if ( $null -eq $RowSize ) {
        $RowSize = $RowContent.count
      }

      $Stats = [ordered]@{}
      for ( $i = 0; $i -lt $RowSize; $i++ ) {
        $StatKey = $StatKeys[$i]

        $RawValue = $RowContent[$i]

        $Value = switch ( $i ) {
          0 { $RawValue -replace "<TD>(\d*)</TD>",'$1' }
          1 { $RawValue -replace ".*fp-player-name=.(.+).></A.*",'$1' }
          Default { $RawValue -replace ".*=center>(.*)</TD>.*",'$1' }
        }

        if ( $StatKey -notin ("Player", "ROST") ) {
          $Value = $value -as [float]
        }

        $Stats[$StatKey] = $Value

      } # End block:for RowContent

      $Stats

    } # End block:foreach ThisRow in Rows

    $OutputStats = foreach ( $ThisPlayer in $PlayerStatsHash ) {
      $PlayerStatsObject = [PSCustomObject]@{}
      foreach ( $ThisStat in $ThisPlayer.Keys ) {
        $MemberDetails = @{
          MemberType = "NoteProperty"
          Name       = $ThisStat
          Value      = $ThisPlayer.$ThisStat
        }

        $PlayerStatsObject | Add-Member @MemberDetails
      }

      $PlayerStatsObject
    }

    Write-Output $OutputStats

  } # End block:process

} # End function
