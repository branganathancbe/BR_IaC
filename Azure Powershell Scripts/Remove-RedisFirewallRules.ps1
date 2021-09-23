Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$RedisCacheName
)

Begin {
    Write-Output "Script started working"
}

Process {
    Write-Output "Removing all firewall rules for Redis"
    Get-AzRedisCacheFirewallRule -ResourceGroupName $ResourceGroupName -Name $RedisCacheName | Remove-AzRedisCacheFirewallRule
}

End {
    Write-Output "Script finished working"
}