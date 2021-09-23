Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$KeyVaultName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$AzureSPNId,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$ApplicationId
)

Begin {
    Write-Output "Script started working"
}

Process {
    Write-Output "Setting policy for Azure Service Principal: $AzureSPNId"
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ObjectId $AzureSPNId `
    -PermissionsToSecrets Get,List,Set `
    -PermissionsToKeys Get,List,Update,Create,Import `
    -PermissionsToCertificates Get,List,Create,Update

    Write-Output "Setting policy for Azure application identity: $ApplicationId"
    Set-AzKeyVaultAccessPolicy -ResourceGroupName $ResourceGroupName -VaultName $KeyVaultName -ObjectId $ApplicationId -BypassObjectIdValidation `
    -PermissionsToSecrets Get,List
}

End {
    Write-Output "Script finished working"
}