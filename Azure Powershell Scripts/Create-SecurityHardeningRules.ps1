Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$resourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$cosmosDBName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$SQLServerName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$appServicePlanName2, #App Service Plan #2 with no ASE integration

    [Parameter(Mandatory=$true,Position=4)]
    [string]$appServicePlanName3, #App Service Plan #3 with no ASE integration

    [Parameter(Mandatory=$true,Position=5)]
    [string]$integrationVnetName,

    [Parameter(Mandatory=$true,Position=6)]
    [string]$integrationSubnetName
)

Begin {
    Write-Output "Script started working"

    #region IP address scopes

    # EY EMEIA Office scopes
    $DEFRAOfficeCIDR = 'IPAddress'
    $DEFRAOfficeRangeStart = 'IPAddress'
    $DEFRAOfficeRangeEnd = 'IPAddress'

    $DERUSOfficeCIDR = 'IPAddress'
    $DERUSOfficeRangeStart = 'IPAddress'
    $DERUSOfficeRangeEnd = 'IPAddress'

    # EY EMEIA Remote Connect scopes
    $DEFRARemoteCIDR = 'IPAddress'
    $DEFRARemoteRangeStart = 'IPAddress'
    $DEFRARemoteRangeEnd = 'IPAddress'

    $DERUSRemoteCIDR = 'IPAddress'
    $DERUSRemoteRangeStart = 'IPAddress'
    $DERUSRemoteRangeEnd = 'IPAddress'

    # EY EMEIA GOLR firewall IPs
    $GOLRFirewall01 = 'IPAddress'
    $GOLRFirewall02 = 'IPAddress'

    # Release agents public IP
    $releaseAgnets = 'IPAddress'

    # Aure Portal IP Addresses for CosmosDB 
    $azurePortal = 'IPAddress'

    # Retrieve worker process public IPs
    Write-Output "Retrieving worker public IPs from App Service Plans"
    $asp2 = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName2
    $webAppsInAsp2 = Get-AzWebApp -AppServicePlan $asp2 | Select-Object -ExpandProperty Name | Sort-Object
    [array]$workerIPs = $webAppsInAsp2 | ForEach-Object {(Get-AzWebApp -Name $_ | Select-Object -ExpandProperty OutboundIpAddresses).split(',')} | Select-Object -Unique

    $asp3 = Get-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName3
    $webAppsInAsp3 = Get-AzWebApp -AppServicePlan $asp3 | Select-Object -ExpandProperty Name | Sort-Object
    $workerIPs += $webAppsInAsp3 | ForEach-Object {(Get-AzWebApp -Name $_ | Select-Object -ExpandProperty OutboundIpAddresses).split(',')} | Select-Object -Unique
    #endregion IP address scopes
}

Process {
    #region retrieve subnet service endpoints
    Write-Output "Getting Vnet properties"
    $vnetObject = Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name $integrationVnetName
    [array]$integratedServices = (Get-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -VirtualNetwork $vnetObject).ServiceEndpoints.Service
    #endregion retrieve subnet service endpoints

    #region SQL Server
    Write-Output "Performing actions on SQL Server"
    #region SQL Server Vnet integration

    if ($integratedServices -notcontains 'Microsoft.Sql') {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName do not have enpoint for SQL - endpoint will be created"
        Write-Output "Configuring endpoint for SQL"
        $integratedServices = $integratedServices + 'Microsoft.Sql'
        $integrationSubnetAddressPrefix = (Get-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -VirtualNetwork $vnetObject).AddressPrefix
        $newVnetSettings = Set-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -AddressPrefix $integrationSubnetAddressPrefix -VirtualNetwork $vnetObject -ServiceEndpoint $integratedServices -WarningAction SilentlyContinue
        Set-AzVirtualNetwork -VirtualNetwork $newVnetSettings | Out-Null
    }
    else {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName already have endpoint for SQL server - No action required"
    }

    if ($null -eq (Get-AzSqlServerVirtualNetworkRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName | Where-Object {($_.VirtualNetworkSubnetId).split('/')[-1] -eq $integrationSubnetName})) {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName do not have integration for SQL  - integration will be configured"
        Write-Output "Configuring integration for SQL"
        $subnetObject = Get-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -VirtualNetwork $vnetObject
        New-AzSqlServerVirtualNetworkRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -VirtualNetworkRuleName 'integrateASESubnet' -VirtualNetworkSubnetId $subnetObject.Id | Out-Null
    }
    else {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName are already integrated with SQL server: $SQLServerName - No action required"
    }
    #endregion SQL Server Vnet integration

    #region SQL Server IP rules
    Write-Output "Configuring SQL IP rules"
    Write-Output "Removing all present IP rules"
    Get-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName | Remove-AzSqlServerFirewallRule | Out-Null
    Write-Output "Creating SQL IP rule for Azure services integration"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -AllowAllAzureIPs | Out-Null
    Write-Output "Creating SQL IP rule for DEFRA EY Office IP range"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'DEFRAEYOfficeRange' -StartIpAddress $DEFRAOfficeRangeStart -EndIpAddress $DEFRAOfficeRangeEnd | Out-Null
    Write-Output "Creating SQL IP rule for DERUS EY Office IP range"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'DERUSEYOfficeRange' -StartIpAddress $DERUSOfficeRangeStart -EndIpAddress $DERUSOfficeRangeEnd | Out-Null
    Write-Output "Creating SQL IP rule for DEFRA EY Remote Connect IP range"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'DEFRARemoteConnectRange' -StartIpAddress $DEFRARemoteRangeStart -EndIpAddress $DEFRARemoteRangeEnd | Out-Null
    Write-Output "Creating SQL IP rule for DERUS EY Remote Connect IP range"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'DERUSRemoteConnectRange' -StartIpAddress $DERUSRemoteRangeStart -EndIpAddress $DERUSRemoteRangeEnd | Out-Null
    Write-Output "Creating SQL IP rule for EY GOLR Firewall 1"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'EYGOLRFirewall01' -StartIpAddress $GOLRFirewall01 -EndIpAddress $GOLRFirewall01 | Out-Null
    Write-Output "Creating SQL IP rule for EY GOLR Firewall 2"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'EYGOLRFirewall02' -StartIpAddress $GOLRFirewall02 -EndIpAddress $GOLRFirewall02 | Out-Null
    Write-Output "Creating SQL IP rule for Release Agents"
    New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName 'ReleaseAgents' -StartIpAddress $releaseAgnets -EndIpAddress $releaseAgnets | Out-Null
    [int]$counter = 1
    foreach ($workerIP in $workerIPs) {
        Write-Output "Creating SQL IP rule for App Service Plan WorkerProcessIP$($counter.ToString().PadLeft('2','0'))"
        New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $SQLServerName -FirewallRuleName "WorkerProcessIP$($counter.ToString().PadLeft('2','0'))" -StartIpAddress $workerIP -EndIpAddress $workerIP | Out-Null
        $counter++
    }
    #endregion SQL Server IP rules

    #endregion SQL Server

    #region CosmosDB
    Write-Output "Performing actions on CosmosDB"
    #region CosmosDB Vnet integration
    if ($integratedServices -notcontains 'Microsoft.AzureCosmosDB') {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName do not have enpoint for CosmosDB - endpoint will be created"
        Write-Output "Configuring endpoint for CosmosDB"
        $integratedServices = $integratedServices + 'Microsoft.AzureCosmosDB'
        $integrationSubnetAddressPrefix = (Get-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -VirtualNetwork $vnetObject).AddressPrefix
        $newVnetSettings = Set-AzVirtualNetworkSubnetConfig -Name $integrationSubnetName -AddressPrefix $integrationSubnetAddressPrefix -VirtualNetwork $vnetObject -ServiceEndpoint $integratedServices -WarningAction SilentlyContinue
        Set-AzVirtualNetwork -VirtualNetwork $newVnetSettings | Out-Null
    }
    else {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName already have endpoint for CosmosDB - No action required"
    }

    $currentCosmosDBProperties = Get-AzResource -ResourceType 'Microsoft.DocumentDB/databaseAccounts' -ResourceGroupName $resourceGroupName -ResourceName $cosmosDBName

    if ($null -eq ($currentCosmosDBProperties.Properties.virtualNetworkRules | Where-Object {($_.id).split('/')[-1] -match $integrationSubnetName})) {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName do not have integration for CosmosDB  - integration will be configured"
        Write-Output "Configuring integration for CosmosDB"
        $subnetId = ($vnetObject.Id) + "/subnets/" + $($integrationSubnetName)
        $vnetRule = New-AzCosmosDBVirtualNetworkRule -Id $subnetId
        Write-Output "Saving settings for CosmosDB Vnet integration"
        Update-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $cosmosDBName -EnableVirtualNetwork $true -VirtualNetworkRuleObject @($vnetRule) | Out-Null
    }
    else {
        Write-Output "Vnet: $integrationVnetName Subnet: $integrationSubnetName are already integrated with CosmosDB: $cosmosDBName - No action required"
    }
    Clear-Variable -Name 'currentCosmosDBProperties' -ErrorAction SilentlyContinue
    Clear-Variable -Name 'targetCosmosDBProperties' -ErrorAction SilentlyContinue
    #endregion CosmosDB Vnet integration

    #region CosmosDB IP rules
    Write-Output "Creating CosmosDB IP rules"
    Write-Output "Creating CosmosDB IP rule for Access from Azure Portal"
    $ipFilter += $azurePortal
    Write-Output "Creating CosmosDB IP rule for DEFRA EY Office IP range"
    $ipFilter += ',' + $DEFRAOfficeCIDR
    Write-Output "Creating CosmosDB IP rule for DERUS EY Office IP range"
    $ipFilter += ',' + $DERUSOfficeCIDR
    Write-Output "Creating CosmosDB IP rule for DEFRA EY Remote Connect IP range"
    $ipFilter += ',' + $DEFRARemoteCIDR
    Write-Output "Creating CosmosDB IP rule for DERUS EY Remote Connect IP range"
    $ipFilter += ',' + $DERUSRemoteCIDR
    Write-Output "Creating CosmosDB IP rule for EY GOLR Firewall 1"
    $ipFilter += ',' + $GOLRFirewall01
    Write-Output "Creating CosmosDB IP rule for EY GOLR Firewall 2"
    $ipFilter += ',' + $GOLRFirewall02
    Write-Output "Creating CosmosDB IP rule for Release Agents"
    $ipFilter += ',' + $releaseAgnets
    foreach ($workerIP in $workerIPs) {
        Write-Output "Creating CosmosDB IP rule for App Service Plan WorkerProcessIP: $workerIP"
        $ipFilter += ',' + $workerIP
    }
    Write-Output "Saving settings for CosmosDB IP rules"
    Update-AzCosmosDBAccount -ResourceGroupName $resourceGroupName -Name $cosmosDBName -IpRangeFilter $ipFilter | Out-Null
    #endregion CosmosDB IP rules

    #endregion CosmosDB
}

End {
    Write-Output "Script finished working"
}