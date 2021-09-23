param (
    [Parameter(Mandatory=$true)][string]$ARMOutput
)

$json = $ARMOutput | ConvertFrom-Json
$value = $json.instrumentationKey.value

Write-Output "Saving instrumentation key for further use as variable: appInsInstrumentationKey"
Write-Host "##vso[task.setvariable variable=appInsInstrumentationKey;issecret=true]$value"