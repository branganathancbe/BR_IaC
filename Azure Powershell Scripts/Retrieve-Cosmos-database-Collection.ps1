Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$CosmosDBAccountName
)
Begin{
    Write-Output "Script started working"
    Write-Output $ResourceGroupName $CosmosDBAccountName
}
Process{

$resourceNameDB = $CosmosDBAccountName + "/sql/"

$databaseNameArray = Get-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/databases" `
    -ApiVersion "2015-04-08" -ResourceGroupName $ResourceGroupName `
    -Name $resourceNameDB | Sort-Object Name |  foreach { $_ | Select-object -ExpandProperty Name }

$dbPipelineName = $databaseNameArray.replace(',','')
$dbPipelineName = $dbPipelineName.replace('.','')
$dbPipelineName = $dbPipelineName | Foreach-Object{'"' + $_ + '"'}
$dbPipelineName = $dbPipelineName -join ','
$dbPipelineName = $dbPipelineName | Foreach-Object{'[' + $_ + ']'}


$databaseName = $databaseNameArray | Foreach-Object{'"' + $_ + '"'}
$databaseName = $databaseName -join ','
$databaseName = $databaseName | Foreach-Object{'[' + $_ + ']'}
    Write-Output "DB Output is" $databaseName

    Write-Output "DB Output is" $dbPipelineName

    write-host "##vso[task.setvariable variable=cdbnames]$databaseName" 
    write-host "##vso[task.setvariable variable=dbpplname]$dbPipelineName"
	
}
End{
    Write-Output "Script finished working"
}