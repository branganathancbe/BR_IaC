Param (
    [Parameter(Mandatory=$true,Position=0)]
    [string]$PrimaryResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$DRResourceGroupName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$PrimarySQLServerName,

    [Parameter(Mandatory=$true,Position=3)]
    [string]$DRSQLServerName,

    [Parameter(Mandatory=$true,Position=4)]
    [string]$FailoverGroupName,

    [Parameter(Mandatory=$true,Position=5)]
    [string]$FailoverPolicy,

    [Parameter(Mandatory=$true,Position=6)]
    [array]$DatabaseNames,

    [Parameter(Mandatory=$true,Position=7)]
    [string]$ElasticPoolName
)

Begin {
    Write-Output "Script started working"
}

Process {
    #region check for failover group existence
    $createFailoverGroup = $false
    $checkCorrectSettings = $false
    Write-Output "Getting current failover group configuration"
    $currentFailoverGroups = Get-AzSqlDatabaseFailoverGroup -ResourceGroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName | Select-Object *
    if ($null -eq $currentFailoverGroups) {
        Write-Output "Failover group does not exist and will be created."
        $createFailoverGroup = $true
    }
    else {
        if (($currentFailoverGroups | Measure-Object | Select-Object -ExpandProperty count) -gt 1) {
            Write-Output "Found multiple failover groups - this is not desired state"
            Write-Output "All failover groups wiil be removed and single group will be created"
            foreach ($currentFailoverGroup in $currentFailoverGroups) {
                Write-Output "Removing failover group: $($currentFailoverGroup.FailoverGroupName)"
                Remove-AzSqlDatabaseFailoverGroup -ResourceGroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName -FailoverGroupName $($currentFailoverGroup.FailoverGroupName) | Out-Null
            }
            $createFailoverGroup = $true
            Write-Output "Going to sleep for 2 minutes"
            Start-Sleep -Seconds 120
        }
        else {
            $checkCorrectSettings = $true
        }
    }
    #endregion check for failover group existence

    #region check settings of failover group
    if ($checkCorrectSettings) {
        Write-Output "Found failover group: $($currentFailoverGroups.FailoverGroupName)"
        Write-Output "Checking settings of failover group: $($currentFailoverGroups.FailoverGroupName)"

        if ($currentFailoverGroups.ReadWriteFailoverPolicy -ne $FailoverPolicy) {
            Write-Output "FailoverPolicy is: $($currentFailoverGroups.ReadWriteFailoverPolicy) should be: $FailoverPolicy"
            $createFailoverGroup = $true
        }
        elseif ($currentFailoverGroups.PartnerServerName -ne $DRSQLServerName) {
            Write-Output "Partner SQL server is: $($currentFailoverGroups.PartnerServerName) should be: $DRSQLServerName"
            $createFailoverGroup = $true
        }
        elseif ($null -ne (Compare-Object -ReferenceObject $DatabaseNames -DifferenceObject $currentFailoverGroups.DatabaseNames)) {
            Write-Output "Missisng configuration for databases"
            $createFailoverGroup = $true
        }
        else {
            Write-Output "All failover group settings are correct - no action required"
        }

        if ($createFailoverGroup) {
            Write-Output "Configuration of failover group: $($currentFailoverGroups.FailoverGroupName) is incorrect"
            Write-Output "Failover group wiil be removed and recreated with correct settings"
            Write-Output "Removing failover group: $($currentFailoverGroups.FailoverGroupName)"
            Remove-AzSqlDatabaseFailoverGroup -ResourceGroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName -FailoverGroupName $($currentFailoverGroups.FailoverGroupName) | Out-Null
            Write-Output "Going to sleep for 2 minutes"
            Start-Sleep -Seconds 120
        }
    }
    #endregion check settings of failover group

    #region create failover group
    if ($createFailoverGroup) {
        Write-Output "Creating failover group: $FailoverGroupName on SQL server: $PrimarySQLServerName"
        New-AzSqlDatabaseFailoverGroup -ResourceGroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName -PartnerResourceGroupName $DRResourceGroupName -PartnerServerName $DRSQLServerName -FailoverGroupName $FailoverGroupName -FailoverPolicy $FailoverPolicy | Out-Null
        foreach ($DatabaseName in $DatabaseNames) {
            Write-Output "Adding database: $DatabaseName to failover group: $FailoverGroupName"
            Get-AzSqlElasticPoolDatabase -ResourceGroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName -ElasticPoolName $ElasticPoolName -DatabaseName $DatabaseName | Add-AzSqlDatabaseToFailoverGroup -ResourcegroupName $PrimaryResourceGroupName -ServerName $PrimarySQLServerName -FailoverGroupName $FailoverGroupName | Out-Null
        }
    }
    #endregion create failover group
}

End {
    Write-Output "Script finished working"
}