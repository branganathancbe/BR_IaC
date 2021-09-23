Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$DataFactoryName
)
Begin{
    Write-Output "Script started working"    
}
Process{

    $ADF_Pipelines=Get-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName | Where-Object { $_.Name -like 'CDB_Bkp_*' } | foreach { $_ | Select-object -ExpandProperty Name }

    Foreach($ADF_Pipeline in $ADF_Pipelines)
{    
    
    #Write-Host "Pipeline" $ADF_Pipeline
    Invoke-AzDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -PipelineName $ADF_Pipeline
    
}
    	
}
End
{
    Write-Output "Script finished working"
}