<#
Created by Jackson Brumbaugh on 2023.07.13
Version: 2023JUl15-JCB
#>
function Import-DraftBoard {
  [CmdletBinding()]
  param (
    [Parameter(
      Mandatory,
      ValueFromPipeline
    )]
    [string[]]
    $Path
  ) # End block:param

  process {
    foreach ( $ThisPath in $Path ) {
      try {
        $ThisDraftBoardItem = Get-Item $ThisPath
      }
      catch {
        Write-Error "Failed to find the $($ThisPath) Draft Board file. "
        continue
      }

      $RawDraftBoard = (Get-Content $ThisDraftBoardItem).where{ -not [string]::IsNullOrEmpty($_) }

      $NewTeamKeyword = "userAvatar"

      $Teams = [ordered]@{}
      $isCollecting = $false
      $TeamName = $null
      $PriorRow = $null
      foreach ( $ThisRow in $RawDraftBoard ) {
        if ( $ThisRow -eq $NewTeamKeyword ) {
          $isCollecting = $true
          $PriorRow = $ThisRow
          continue
        }

        if ( $PriorRow -eq $NewTeamKeyword ) {
          $TeamName = $ThisRow
          $Teams.$TeamName = @()
          $PriorRow = $ThisRow
          continue
        }

        if ( $isCollecting -and $TeamName ) {
          $Teams.$TeamName += $ThisRow
        }

      } # End block:foreach Row

      $OutputDraftBoard = foreach ( $ThisTeam in $Teams.Keys ) {
        $RawDraft = $Teams.$ThisTeam

        $Manager = $ThisTeam

        $DraftPicks = @()
        for ( $n = 0; $n -lt 18; $n++ ) {
          $Start = 4*$n
          $End = $Start + 3

          $ThisPick = $RawDraft[$Start .. $End]

          $PickNumber = $ThisPick[0] -as [int]
          $PlayerFirstName = $ThisPick[1]
          $PlayerLastName = $ThisPick[2]
          $BottomLineSplit = ($ThisPick[3] -replace " - ", " ") -split " "

          $Pos = $BottomLineSplit[0]
          $RoundPick = $BottomLineSplit[-1]

          $PlayerTeam = if ( $BottomLineSplit.Count -eq 3 ) {
            $BottomLineSplit[1]
          } else {
            $null
          }

          $DraftPicks += [PSCustomObject]@{
            Player    = $PlayerFirstName + " " + $PlayerLastName
            Pos       = $Pos
            Team      = $PlayerTeam
            Pick      = $PickNumber
            RoundPick = $RoundPick
          }

        } # End block:for all 18 rounds

        [PSCustomObject]@{
          Manager = $Manager
          Draft   = $DraftPicks
        }

      } # End block:foreach Team

      Write-Output $OutputDraftBoard

    } # End block:foreach Path

  } # End block:process

} # End function
