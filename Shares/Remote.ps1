#$cred = Get-Credential
# Invoke-Command -ComputerName "db21m" -FilePath ".\CopyMarketShares.ps1" #-Credential $cred
Enter-PSSession -ComputerName $computerName .\CopyMarketShares.ps1


<#
$remoteComputer = "RemoteComputer"
$scriptPath = "C:\Path\To\Script.ps1"

Enter-PSSession -ComputerName $remoteComputer -Credential (Get-Credential) -ScriptBlock {
    param($script)
    & $script
} -ArgumentList $scriptPath
#>