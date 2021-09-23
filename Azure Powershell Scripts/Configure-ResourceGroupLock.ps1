Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$ResourceGroupName
)

Begin{
    Write-Output "Script started working"
}

Process{
    
    New-AzResourceLock -LockName GVRT-RGLock-DontDelete -LockLevel CanNotDelete -ResourceGroupName $ResourceGroupName -Force
		
}

End{
    Write-Output "Script finished working"
}