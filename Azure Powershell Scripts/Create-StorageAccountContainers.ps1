Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$StorageAccountName1,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$StorageAccountName2,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$ContainerName1,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$ContainerName2
)

Begin{
    Write-Output "Script started working"
}

Process{
    #region Storage Account 1
    $StorageAccount1 = Get-AzStorageAccount -Name $StorageAccountName1 -ResourceGroupName $ResourceGroupName
    $StorageContainer1 = Get-AzStorageContainer -Context $StorageAccount1.Context -Name $ContainerName1 -ErrorAction SilentlyContinue | Select-Object *

    if (!($StorageContainer1)) {
        Write-Output "Container: $ContainerName1 does not exist in storage account: $StorageAccountName1"
        Write-Output "Creating container: $ContainerName1 in storage account: $StorageAccountName1"
        New-AzStorageContainer -Name $ContainerName1 -Context $StorageAccount1.Context -Permission Off
    }
    else {
        Write-Output "Container: $ContainerName1 already exists in storage account: $StorageAccountName1"
    }
    #endregion Storage Account 1

    #region Storage Account 2
    $StorageAccount2 = Get-AzStorageAccount -Name $StorageAccountName2 -ResourceGroupName $ResourceGroupName
    $StorageContainer2 = Get-AzStorageContainer -Context $StorageAccount2.Context -Name $ContainerName2 -ErrorAction SilentlyContinue | Select-Object *

    if (!($StorageContainer2)) {
        Write-Output "Container: $ContainerName2 does not exist in storage account: $StorageAccountName2"
        Write-Output "Creating container: $ContainerName2 in storage account: $StorageAccountName2"
        New-AzStorageContainer -Name $ContainerName2 -Context $StorageAccount2.Context -Permission Off
    }
    else {
        Write-Output "Container: $ContainerName2 already exists in storage account: $StorageAccountName2"
    }
    #endregion Storage Account 2
}

End{
    Write-Output "Script finished working"
}