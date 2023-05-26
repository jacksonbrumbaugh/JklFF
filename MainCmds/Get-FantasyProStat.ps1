<#
.SYNOPSIS
Scraps weekly NFL stats (defaulting to Standard - no PPR - scoring) from the Fantasy Pros website, 

.NOTES
Created on 2022-10-13 by Jackson Brumbaugh
VersionCode: 2023May26-A
#>
function Get-FantasyProStat {
  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory
    )]
    [ValidateSet(
      "QB",
      "RB",
      "WR",
      "TE"
    )]
    [string]
    $Position,

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
    [Alias("Score")]
    $Scoring,

    [Parameter(
      Mandatory
    )]
    [ValidateRange(
      1, 18
    )]
    [Alias("Wk")]
    [int]
    $Week,

    # Defaults to the current NFL year if the current month is Sep -> Dec
    [ValidateRange(
      2002, 2102 # Arbitrarily picked 100 years from lowest value shown on the Fantasy Pro's site
    )]
    [int]
    $Year
    ) # End block:param

  process {
    <#
    Example URI
    https://www.fantasypros.com/nfl/stats/qb.php?year=2021&week=17&range=week&scoring=HALF
    #>
    $BaseSite = "https://www.fantasypros.com/nfl/stats/"

    $StatYear = Get-StatYear $Year

    $UriParams = @(
      $BaseSite,
      $Position.ToLower(),
      $StatYear,
      $Week
    )
    $URI = "{0}{1}.php?year={2}&range=week&week={3}" -f $UriParams

    switch -Regex ($Scoring) {
      "^P" { $URI += "&scoring=PPR" }

      "^H" { $URI += "&scoring=HALF" }

      # Standard scording does not get a URI query parameter for scoring
    }

    try { $Response = Invoke-WebRequest -URI $URI }
    catch {
      $ErrorDetails = @{
        Message = "Failed to properly call the URI(" + $URI + ")"
        ErrorAction = "Stop"
      }

      Write-Error $ErrorDetails
    }

    $ResponseStatus = $Response.StatusCode
    if ( $ResponseStatus -ne "200" ) {
      $WarningMsg = "Status code -ne 200; instead, it was " + $ResponseStatus
      Write-Warning $WarningMsg
    }

    $HTML = $Response.ParsedHtml
    $Tables = $Html.GetElementsByTagName( 'table' )
    $Rows = $Tables[0].Rows
    $StatHeader = $Rows[1]
    $StatHeaderItems = $StatHeader.InnerHtml.split("`n")

    <#
    Using the Prior Stat Name as a guide for what the current stat name will be
    Example
    For QB's, Passing Yds stat follows the PCT (or completion percentage) stat
    #>
    $PriorStatName = ""
    $StatKeys = foreach ( $ThisStat in $StatHeaderItems ) {
      $StatNoSmall = $ThisStat -replace "<SMALL>", "" -replace "</SMALL>", ""
      $StatName = $StatNoSmall -replace ".*TH.*>(.+)</TH.*", '$1'

      Write-Verbose "Stat Name: $StatName"

      $ThisStatKey = $StatName

      if ( $StatName -eq "YDS" ) {
        $ThisStatKey = switch ( $PriorStatName ) {
          "CMP" { "PASS" + $StatName } # For QB
          "ATT" { "RUSH" + $StatName } # For RB
          "TGT" { "REC" + $StatName }  # For WR & TE
          Default { $StatName }
        }
      }

      if ( $StatName -eq "ATT" ) {
        # Passing attempts were not coming thru for QB
        if ( $Position -eq "QB" ) {
          $ThisStatKey = switch ( $PriorStatName ) {
            "CMP"   { "PASS" + $StatName }
            "SACKS" { "RUSH" + $StatName }
          }
        }

        if ( $Position -eq "RB" ) {
          $ThisStatKey = "RUSHATT"
        }

      }

      if ( $StatName -eq "TD" ) {
        if ( $Position -eq "QB" ) {
          $ThisStatKey = switch ( $PriorStatName ) {
            "Y/A" {"PASS" + $StatName }
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

      } # End block:if StatName is TD

      if ( $StatName -eq "Y/A" ) {
        $ThisStatKey = switch ( $Position ) {
          "QB" { "YdsPerPass" }
          "RB" { "YdsPerRush" }
          Default { $ThisStatKey}
        }
      }

      $PriorStatName = $StatName

      $Replaces = @(
        @{ Old = "20+"     ; New = "Over20" },
        @{ Old = "ATT"     ; New = "Rush" },
        @{ Old = "RUSHATT" ; New = "Att" },
        @{ Old = "PASSATT" ; New = "PassAtt" },
        @{ Old = "CMP"     ; New = "Comp" },
        @{ Old = "FL"      ; New = "Fum" },
        @{ Old = "FPTS"    ; New = "Pts" },
        @{ Old = "FPTS/G"  ; New = "AvgPts" },
        @{ Old = "G"       ; New = "Games" },
        @{ Old = "INT"     ; New = "Int" },
        @{ Old = "LG"      ; New = "Long" },
        @{ Old = "PASSTD"  ; New = "PassTD" },
        @{ Old = "PASSYDS" ; New = "PassYds" },
        @{ Old = "PCT"     ; New = "Perc" },
        @{ Old = "Player"  ; New = "Name" },
        @{ Old = "REC"     ; New = "Rec" },
        @{ Old = "RECTD"   ; New = "RecTD" },
        @{ Old = "RECYDS"  ; New = "RecYds" },
        @{ Old = "ROST"    ; New = "Rost" },
        @{ Old = "RUSHYDS" ; New = "RushYds" },
        @{ Old = "RUSHTD"  ; New = "RushTD" },
        @{ Old = "SACKS"   ; New = "Sack" },
        @{ Old = "TGT"     ; New = "Tgt" },
        @{ Old = "Y/A"     ; New = "YdsPerAtt" },
        @{ Old = "Y/R"     ; New = "YdsPerRec" }
      )

      foreach ( $ThisReplace in $Replaces ) {
        if ( $ThisStatKey -eq $ThisReplace.Old ) {
          $ThisStatKey = $ThisReplace.New
        }
      }

      # Add this as part of the StatKeys array
      $ThisStatKey

    } # End block:foreach ThisStat in StatHeaderItems

    $RowCounter = 0
    $RowSize = $StatHeader.count
    $PlayerStatsHash = foreach ( $ThisRow in $Rows ) {
      # Skip the 2 header rows
      if ( $RowCounter++ -in (0..1) ) {
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
          0 { $RawValue -replace "<TD>(\d*)</TD>",'$1' } # Player's Weekly Rank
          1 {
            $Stats["Team"] = $RawValue -replace ".*\((.+)\).*", '$1'

            # E.g. <tr class="mpb-player-18562"><td>127</td><td class="player-label"><a href="/nfl/stats/gardner-minshew.php" class="player-name">Gardner Minshew II</a> (IND) <a href="#" aria-hidden="true" tabindex="-1" class="fp-player-link fp-id-18562" fp-player-name="Gardner Minshew II"></a></td><td class="center">0</td>

            $RawValue -replace ".*player-name=.(.+).></A.*",'$1'
          }
          Default { $RawValue -replace ".*=center>(.*)</TD>.*",'$1' }
        }

        if ( $StatKey -notin ("Name", "Rost") ) {
          $Value = $value -as [float]
        }

        Write-Verbose "Stat Key: $StatKey"
        Write-Verbose "Stat Value: $Value"
        Write-Verbose ""

        $Stats[$StatKey] = $Value

      } # End block:for RowContent

      $Stats.Week = $Week
      $Stats.Year = $StatYear
      $Stats.Pos = $Position

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

        # Could clean this section up with a type coersion [Hashtable] -> [PSCustomObject]
        $PlayerStatsObject | Add-Member @MemberDetails

      }

      $PlayerStatsObject

    }

    Write-Output $OutputStats

  } # End block:process

} # End function

$Aliases = @(
  "stat"
)

foreach ( $ThisAlias in $Aliases ) {
  Set-Alias -Name $ThisAlias -Value Get-FantasyProStat
  Export-ModuleMember -Alias $ThisAlias
}
