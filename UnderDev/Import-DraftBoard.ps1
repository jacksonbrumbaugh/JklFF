$StartingLocation = Get-Location

Set-Location "J:/"
Set-Location *Foot*
Set-Location Best*
Set-Location Draft*

try {
  $TestingDraftBoardFile = Get-Item "DraftBoard*05.16-12Person-Seat8*raw*"
}
catch {
  $FFError = $true
  Write-Error "Failed to find the testing Draft Board file. "
}

Set-Location $StartingLocation

if ( $FFError ) {
  return $null
}

$Raw = Get-Content $TestingDraftBoardFile

$RawNoBlanks = $Raw.where{ -not [string]::IsNullOrEmpty($_) }

$NewTeamKeyword = "userAvatar"

$Teams = [ordered]@{}
$PriorRow = $null
$isCollecting = $false
foreach ( $ThisRow in $RawNoBlanks ) {
  $isSkip = $false

  if ( $ThisRow -eq $NewTeamKeyword ) {
    $isCollecting = $true
    $isSkip = $true
  }

  if ( $PriorRow -eq $NewTeamKeyword ) {
    $isSKip = $true
    $TeamName = $ThisRow
    $Teams.$TeamName = @()
  }

  $PriorRow = $ThisRow
  if ( $isSkip ) {
    continue
  }

  if ( $isCollecting -and $TeamName ) {
    $AddRow = -not [string]::IsNullOrEmpty($ThisRow)
    if ( $AddRow ) {
      $Teams.$TeamName += $ThisRow
    }
  }

} # End block:foreach Row

$Output = foreach ( $ThisTeam in $Teams.Keys ) {
  $RawDraft = $Teams.$ThisTeam

  $Manager = $ThisTeam

  $DraftPicks = @()
  for ( $n = 0; $n -lt 18; $n++ ) {
    $Start = 4*$n
    $End = $Start + 3

    $ThisPick = $RawDraft[$Start .. $End]

    $PickNumber = $ThisPick[0]
    $PlayerFirstName = $ThisPick[1]
    $PlayerLastName = $ThisPick[2]
    $BottomLineSplit = ($ThisPick[3] -replace " - ", " ") -split " "

    $Pos = $BottomLineSplit[0]
    $RoundPick = $BottomLineSplit[-1]

    $PlayerTeam = if ( $BottomLineSplit.Count -eq 2 ) {
      $null
    } else {
      $BottomLineSplit[1]
    }

    $DraftPicks += [PSCustomObject]@{
      Player = $PlayerFirstName + " " + $PlayerLastName
      Pos = $Pos
      Team = $PlayerTeam
      Pick = $PickNumber
      RoundPick = $RoundPick
    }

  } # End block:for all 18 rounds

  [PSCustomObject]@{
    Manager = $Manager
    DraftPicks = $DraftPicks
  }

} # End block:foreach Team

Write-Host "var(Output)"
$Output
