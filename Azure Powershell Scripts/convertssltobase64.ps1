Param( 
    [Parameter(Mandatory=$true)]
    [string]$certFileName,
    [Parameter(Mandatory=$true)]
    [string]$secureFilePath
)

$fileContentBytes = get-content  "$secureFilePath\$certFileName" -Encoding Byte 
    [System.Convert]::ToBase64String($fileContentBytes) | Out-File 2pfx-encoded-bytes.txt
$frontendsslCertificate= Get-Content '2pfx-encoded-bytes.txt'
write-host "##vso[task.setvariable variable=base64]$frontendsslCertificate" 
write-output $frontendsslCertificate
