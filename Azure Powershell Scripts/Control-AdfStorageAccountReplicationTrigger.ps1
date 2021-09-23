Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$DataFactoryName,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$TriggerName,

    [Parameter(Mandatory=$true,Position=3)]
    [ValidateSet('Start', 'Stop')]
    [string]$TriggerAction
)

Begin{
    Write-Output "Script started working"
}

Process{
    if ($TriggerAction -eq 'Stop') {
        $trigger = Get-AzDataFactoryV2Trigger -Name $TriggerName -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -ErrorAction SilentlyContinue
        if ($null -eq $trigger) {
            Write-Output "Trigger $($TriggerName) does not exist - nothing to do"
        }
        else {
            $currentTriggerState = Get-AzDataFactoryV2Trigger -Name $TriggerName -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName | Select-Object -ExpandProperty RuntimeState
            if ($currentTriggerState -eq 'Stopped') {
                Write-Output "Trigger $($TriggerName) is already stopped - nothing to do"
            }
            else {
                Write-Output "Trigger $($TriggerName) is not stopped - attempting stop"
                Get-AzDataFactoryV2Trigger -Name $TriggerName -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName | Stop-AzDataFactoryV2Trigger -Force | Out-Null
                Write-Output "Trigger $($TriggerName) is stopped"
            }
        }
    }
    else {
        $currentTriggerState = Get-AzDataFactoryV2Trigger -Name $TriggerName -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName | Select-Object -ExpandProperty RuntimeState
        if ($currentTriggerState -eq 'Started') {
            Write-Output "Trigger $($TriggerName) is already started - nothing to do"
        }
        else {
            Write-Output "Trigger $($TriggerName) is not started - attempting start"
            Get-AzDataFactoryV2Trigger -Name $TriggerName -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName | Start-AzDataFactoryV2Trigger -Force | Out-Null
            Write-Output "Trigger $($TriggerName) is started"
        }
    }
}

End{
    Write-Output "Script finished working"
}