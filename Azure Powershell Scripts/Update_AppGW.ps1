Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$AppGWName
)

Begin{
    Write-Output "Script started working"
    Write-Output $ResourceGroupName $AppGWName
}

Process{

# get an application gateway resource
$gatewaycfg = Get-AzApplicationGateway -Name $AppGWName -ResourceGroup $ResourceGroupName

# set the SSL policy on the application gateway
Set-AzApplicationGatewaySslPolicy -ApplicationGateway $gatewaycfg -PolicyType Custom -MinProtocolVersion TLSv1_2 -CipherSuite "TLS_RSA_WITH_AES_128_CBC_SHA256","TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256","TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384","TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA","TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256","TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384","TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA","TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA","TLS_RSA_WITH_AES_256_GCM_SHA384","TLS_RSA_WITH_AES_128_GCM_SHA256","TLS_RSA_WITH_AES_256_CBC_SHA256","TLS_RSA_WITH_AES_256_CBC_SHA","TLS_RSA_WITH_AES_128_CBC_SHA","TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"

# validate the SSL policy locally
Get-AzApplicationGatewaySslPolicy -ApplicationGateway $gatewaycfg

# update the gateway with validated SSL policy
Set-AzApplicationGateway -ApplicationGateway $gatewaycfg


    }

End{
    Write-Output "Script finished working"
}