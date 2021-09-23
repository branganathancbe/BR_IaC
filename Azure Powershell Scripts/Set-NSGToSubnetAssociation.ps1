Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$VnetName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$SubnetName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$NsgName
)

Begin {
    Write-Output "Script started working"
}

Process {
    Write-Output "Associating subnet $SubnetName with NSG $NsgName"
    $Vnet = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $ResourceGroupName
    $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $Vnet -Name $SubnetName
    $NSG = Get-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Name $NsgName
    $Subnet.NetworkSecurityGroup = $NSG
    Set-AzVirtualNetwork -VirtualNetwork $Vnet | Out-Null
}

End {
    Write-Output "Script finished working"
}