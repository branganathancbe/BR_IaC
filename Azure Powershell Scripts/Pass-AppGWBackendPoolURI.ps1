Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$WebAppName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$AppServiceEnvName
)
Begin{
    Write-Output "Script started working"
}
Process{

$AppGwBackendPoolName = $WebAppName.ToLower() + "." + $AppServiceEnvName.ToLower() + ".p.azurewebsites.net"
Write-Output $AppGwBackendPoolName

write-host "##vso[task.setvariable variable=appgwbkendpooluri]$AppGwBackendPoolName"

}
End{
    Write-Output "Script finished working"
}