Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$StorageAccountName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$ContainerName,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$KeyVaultName
)

Begin {
    Write-Output "Script started working"
}

Process {
    $SASTokenSecretName = "SASToken-" + $StorageAccountName + '-' + $ContainerName

    $currentSASToken = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SASTokenSecretName -ErrorAction SilentlyContinue

    if ($null -eq $currentSASToken) {
        Write-Output "SAS token $($SASTokenSecretName) does not exist in keyvault $($KeyVaultName) - generating new one"
        $StorageAccount = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
        $SASToken = Get-AzStorageContainer -Container $ContainerName -Context $StorageAccount.Context | New-AzStorageContainerSASToken -Permission rwdl -ExpiryTime $(Get-Date).AddYears(10) -FullUri
        $SASTokenSecret  = ConvertTo-SecureString -String $($SASToken) -AsPlainText -Force
        Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $($SASTokenSecretName) -SecretValue $SASTokenSecret
    }
    else {
        Write-Output "SAS token $($SASTokenSecretName) exists in keyvault $($KeyVaultName) - will use existing one"
        $SASToken = $currentSASToken.SecretValueText
    }

    Write-Output "Saving storage account token for $($StorageAccountName) container $($ContainerName) for further use as variable: storageAccountSASToken"
    Write-Host "##vso[task.setvariable variable=storageAccountSASToken;issecret=true]$SASToken"
}

End {
    Write-Output "Script finished working"
}