<#
.SYNOPSIS
Extract a value from the [Position] enum

.NOTES
Create by Jackson Brumbaugh on 2023-09-14
Version: 2023Sep14-JCB
#>
function Test-Position ( [Position]$Position ) {
  Write-Host "Comparing members"

  Write-Host "Input Position -> Get-Member"
  $Position | Get-Member
  
  $Pos_AsString = $Position -as [string]
  Write-Host "Input Position as a String -> Get-Member"
  $Pos_AsString | Get-Member
  
  Write-Host "Position as an enum"
  Write-Host ("The enum postion {0} was inserted into this message" -f $Position)

  Write-Host "Position as a string"
  Write-Host ("The string postion {0} was inserted into this message" -f $Pos_AsString)

  Write-Host "Testing if enum Position == string Position"
  if ( $Position -eq $Pos_AsString ) {
    Write-Host "They are equal"
  } else {
    Write-Host "They did not equal"
  }

} # End function
