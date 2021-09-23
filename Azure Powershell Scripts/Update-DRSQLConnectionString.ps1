Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ProdResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$ProdKeyVaultName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$DRKeyVaultName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$ProdSQLServerName,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$DRSQLServerName
)

Begin {
    Write-Output "Script started working"
}

Process {
    [array]$SQLSecretNames = 'sqlDbConnection', 'ConnectionStrings--ImportDbConnectionString'
    [array]$KeyVaultNames = $ProdKeyVaultName, $DRKeyVaultName

    $FailoverGroupName = Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $ProdResourceGroupName -ServerName $ProdSQLServerName | Select-Object -ExpandProperty FailoverGroupName
    $FailoverGroupFQDN = $FailoverGroupName + '.database.windows.net'
    $ProdSQLFQDN = $ProdSQLServerName + '.database.windows.net'
    $DRSQLFQDN = $DRSQLServerName + '.database.windows.net'

    foreach ($KeyVaultName in $KeyVaultNames) {
        Write-Output "Starting update for $KeyVaultName"

        foreach ($SQLSecretName in $SQLSecretNames) {
            $writeToKeyVault = $false
            $currentSecret = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SQLSecretName

            if ($null -eq $currentSecret) {
                Write-Output "KeyVault secret: $SQLSecretName doesn't exist in $KeyVaultName"
                Write-Error "Unable to continue due to lack of required secret"
                Throw "Unable to continue due to lack of required secret"
            }
            elseif ($currentSecret.SecretValueText -notmatch $FailoverGroupFQDN) {
                Write-Output "KeyVault secret: $SQLSecretName has a wrong value in $KeyVaultName and will be updated"
                $writeToKeyVault = $true
            }
            else {
                Write-Output "KeyVault secret: $SQLSecretName is present in $KeyVaultName and has a proper value"
            }

            if ($writeToKeyVault) {
                [string]$newSecretValue = ($currentSecret.SecretValueText).Replace("$ProdSQLFQDN", "$FailoverGroupFQDN")
                $newSecretValue = $newSecretValue.Replace("$DRSQLFQDN", "$FailoverGroupFQDN")
                $secureSecretValue = ConvertTo-SecureString -String $newSecretValue -AsPlainText -Force
                Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SQLSecretName -SecretValue $secureSecretValue | Out-Null
            }

            Clear-Variable -Name 'currentSecret', 'secureSecretValue', 'newSecretValue' -ErrorAction SilentlyContinue
        }

    }   
}

End {
    Write-Output "Script finished working"
}