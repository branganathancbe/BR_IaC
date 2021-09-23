Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$resourceGroupName,
	
	[Parameter(Mandatory=$false,Position=1)]
    [string]$prodResourceGroupName, #used in DR environment only for CosmosDb and Storage Account

    [Parameter(Mandatory=$true,Position=2)]
    [string]$keyVaultName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$cosmosDBName,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$SQLServerName,

    [Parameter(Mandatory=$true,Position=5)]
    [string]$importDatabaseName,

    [Parameter(Mandatory=$true,Position=6)]
    [string]$maintDatabaseName,

    [Parameter(Mandatory=$true,Position=7)]
    [string]$pbiDatabaseName,

    [Parameter(Mandatory=$true,Position=8)]
    [string]$storageAccountName, #storage account number 2, PPROD Storage Account number 2 for DR environment

    [Parameter(Mandatory=$true,Position=9)]
    [string]$redisCacheName,

    [Parameter(Mandatory=$true,Position=10)]
    [string]$environment,

    [Parameter(Mandatory=$true,Position=11)]
    [string]$aadClientId,

    [Parameter(Mandatory=$true,Position=12)]
    [string]$aadClientSecret,

    [Parameter(Mandatory=$true,Position=13)]
    [string]$pbiUsername,

    [Parameter(Mandatory=$true,Position=14)]
    [string]$pbiPassword,

    [Parameter(Mandatory=$true,Position=15)]
    [string]$pbiAuthClientId,

    [Parameter(Mandatory=$true,Position=16)]
    [string]$pbiAuthClientSecret,
<#
    [Parameter(Mandatory=$true,Position=17)]
    [string]$serviceBusName
#>
)

Begin {
    Write-Output "Script started working"
}

Process {
    $generatedSecrets = @{}

    #region get sql username/pass from keyvault
    Write-Output 'Getting sql server credentials'
    [string]$sqlUsername = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "$($SQLServerName)-sqlServerAdminUsername").SecretValueText
    [string]$sqlUserPassword = (Get-AzKeyVaultSecret -VaultName $keyVaultName -Name "$($SQLServerName)-sqlServerAdminPassword").SecretValueText
    #endregion get sql username/pass from keyvault

    #region ConnectionStrings--ImportDbConnectionString
    Write-Output 'Generating secret: ConnectionStrings--ImportDbConnectionString'
    [string]${ConnectionStrings--ImportDbConnectionString} = "Server=tcp:$($SQLServerName).database.windows.net,1433;Initial Catalog=$($importDatabaseName);Persist Security Info=False;User ID=$($sqlUsername);Password=$($sqlUserPassword);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    $generatedSecrets.Add('ConnectionStrings--ImportDbConnectionString',${ConnectionStrings--ImportDbConnectionString})
    #endregion ConnectionStrings--ImportDbConnectionString

    #region ConnectionStrings--PowerBIDbConnectionString
    Write-Output 'Generating secret: ConnectionStrings--PowerBIDbConnectionString'
    [string]${ConnectionStrings--PowerBIDbConnectionString} = "Server=tcp:$($SQLServerName).database.windows.net,1433;Initial Catalog=$($pbiDatabaseName);Persist Security Info=False;User ID=$($sqlUsername);Password=$($sqlUserPassword);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    $generatedSecrets.Add('ConnectionStrings--PowerBIDbConnectionString',${ConnectionStrings--PowerBIDbConnectionString})
    #endregion ConnectionStrings--PowerBIDbConnectionString

    #region StorageTable--ConnectionString
    Write-Output 'Generating secret: StorageTable--ConnectionString'
    if ($environment -eq 'DR') {
        $RGNameSA = $prodResourceGroupName #Storage Account #2 is in PROD Resource Group for DR Environment
    }
    else {
        $RGNameSA = $resourceGroupName
    }
    [string]$saKey1 = Get-AzStorageAccountKey -ResourceGroupName $RGNameSA -Name $storageAccountName | Where-Object {$_.KeyName -eq 'key1'} | Select-Object -ExpandProperty Value

    [string]${StorageTable--ConnectionString} = "DefaultEndpointsProtocol=https;AccountName=$($storageAccountName);AccountKey=$($saKey1);EndpointSuffix=core.windows.net"
    $generatedSecrets.Add('StorageTable--ConnectionString',${StorageTable--ConnectionString})
    #endregion StorageTable--ConnectionString

    #region CosmosDbAuthKey
    Write-Output 'Generating secret: CosmosDbAuthKey'
    if ($environment -eq 'DR') {
        $RGNameCDB = $prodResourceGroupName #CosmosDB is in PROD Resource Group for DR Environment
    }
    else {
        $RGNameCDB = $resourceGroupName
    }
    [string]$cosmosDbAuthKey = Invoke-AzResourceAction -Action listKeys -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $RGNameCDB -Name $cosmosDBName -Force | Select-Object -ExpandProperty primaryMasterKey
    $generatedSecrets.Add('CosmosDbAuthKey',$cosmosDbAuthKey)
    #endregion CosmosDbAuthKey

    #region CosmosDbEndpoint
    if ($environment -eq 'DR') {
        $RGNameCDB = $prodResourceGroupName #CosmosDB is in PROD Resource Group for DR Environment
    }
    else {
        $RGNameCDB = $resourceGroupName
    }
    Write-Output 'Generating secret: CosmosDbEndpoint'
    [string]$cosmosDbEndpoint = (Invoke-AzResourceAction -Action listConnectionStrings -ResourceType "Microsoft.DocumentDb/databaseAccounts" -ApiVersion "2015-04-08" -ResourceGroupName $RGNameCDB -Name $cosmosDBName -Force | Select-Object -ExpandProperty connectionStrings | Select-Object -First 1 -ExpandProperty connectionString).split('=|;')[1]
    $generatedSecrets.Add('CosmosDbEndpoint',$cosmosDbEndpoint)
    #endregion CosmosDbEndpoint

    #region FileStorageConnectionString
    Write-Output 'Generating secret: FileStorageConnectionString'
    [string]$fileStorageConnectionString = ${StorageTable--ConnectionString}
    $generatedSecrets.Add('FileStorageConnectionString',$fileStorageConnectionString)
    #endregion FileStorageConnectionString

    #region Queue--ConnectionString
    Write-Output 'Generating secret: Queue--ConnectionString'
    [string]${Queue--ConnectionString} = ${StorageTable--ConnectionString}
    $generatedSecrets.Add('Queue--ConnectionString',${Queue--ConnectionString})
    #endregion Queue--ConnectionString

    #region sqlDbConnection
    Write-Output 'Generating secret: sqlDbConnection'
    [string]$sqlDbConnection = "Server=tcp:$($SQLServerName).database.windows.net,1433;Initial Catalog=$($maintDatabaseName);Persist Security Info=False;User ID=$($sqlUsername);Password=$($sqlUserPassword);MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    $generatedSecrets.Add('sqlDbConnection',$sqlDbConnection)
    #endregion sqlDbConnection

    #region Redis--ConnectionString
    Write-Output 'Generating secret: Redis--ConnectionString'
    $redisHostName = Get-AzRedisCache -ResourceGroupName $resourceGroupName -Name $redisCacheName | Select-Object -ExpandProperty HostName
    $redisPrimaryKey = Get-AzRedisCacheKey -ResourceGroupName $resourceGroupName -Name $redisCacheName | Select-Object -ExpandProperty PrimaryKey
    
    [string]${RedisCache-ConnectionString} = "$($redisHostName):6380,password=$($redisPrimaryKey),ssl=True,abortConnect=False"
    $generatedSecrets.Add('Redis--ConnectionString',${RedisCache-ConnectionString})
    #endregion Redis--ConnectionString

    #region Cosmos--UseSeparateDbs PROD/DR only
    Write-Output 'Generating secret: Cosmos--UseSeparateDbs for PROD/DR'
    if ($environment -in @('Production','DR')) {
        ${Cosmos--UseSeparateDbs} = 'true'
        $generatedSecrets.Add('Cosmos--UseSeparateDbs',${Cosmos--UseSeparateDbs})
    }
    #endregion Cosmos--UseSeparateDbs PROD/DR only

    #region AzureAd--ClientId
    Write-Output 'Generating secret: AzureAd--ClientId'
    $generatedSecrets.Add('AzureAd--ClientId',$aadClientId)
    #endregion AzureAd--ClientId

    #region AzureAd--ClientSecret
    Write-Output 'Generating secret: AzureAd--ClientSecret'
    $generatedSecrets.Add('AzureAd--ClientSecret',$aadClientSecret)
    #endregion AzureAd--ClientSecret

    #region PBIAuth--ClientId
    Write-Output 'Generating secret: PBIAuth--ClientId'
    $generatedSecrets.Add('PBIAuth--ClientId',$pbiAuthClientId)
    #endregion PBIAuth--ClientId

    #region PBIAuth--ClientSecret
    Write-Output 'Generating secret: PBIAuth--ClientSecret'
    $generatedSecrets.Add('PBIAuth--ClientSecret',$pbiAuthClientSecret)
    #endregion PBIAuth--ClientSecret

    #region PBIAuth--Username
    Write-Output 'Generating secret: PBIAuth--Username'
    $generatedSecrets.Add('PBIAuth--Username',$pbiUsername)
    #endregion PBIAuth--Username

    #region PBIAuth--Password
    Write-Output 'Generating secret: PBIAuth--Password'
    $generatedSecrets.Add('PBIAuth--Password',$pbiPassword)
    #endregion PBIAuth--Password
<#
    #region ServiceBus--ConnectionString
    Write-Output 'Generating secret: ServiceBus--ConnectionString'
    ${ServiceBus--ConnectionString} = Get-AzServiceBusKey -ResourceGroupName $resourceGroupName -Name 'GeneralSharedAccessKey' -Namespace $serviceBusName | Select-Object -ExpandProperty PrimaryConnectionString
    $generatedSecrets.Add('ServiceBus--ConnectionString',${ServiceBus--ConnectionString})
    #endregion ServiceBus--ConnectionString
#>
    foreach ($secret in $generatedSecrets.GetEnumerator()) {
        $writeToKeyVault = $false
        $currentSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $($secret.Name) -ErrorAction SilentlyContinue

        if ($null -eq $currentSecret) {
            Write-Output "KeyVault secret: $($secret.Name) doesn't exist and have to be created"
            $writeToKeyVault = $true
        }
        elseif ($currentSecret.SecretValueText -ne $($secret.Value)) {
            Write-Output "KeyVault secret: $($secret.Name) has a wrong value and will be updated"
            $writeToKeyVault = $true
        }
        else {
            Write-Output "KeyVault secret: $($secret.Name) is present and has a proper value"
        }

        if ($writeToKeyVault) {
            $secureSecretValue = ConvertTo-SecureString -String $($secret.Value) -AsPlainText -Force
            Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $($secret.Name) -SecretValue $secureSecretValue | Out-Null
        }

        Clear-Variable -Name 'currentSecret', 'secureSecretValue' -ErrorAction SilentlyContinue
    }
}

End {
    Write-Output "Script finished working"
}