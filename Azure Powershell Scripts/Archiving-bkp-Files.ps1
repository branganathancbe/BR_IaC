Param(
    [Parameter(Mandatory=$true,Position=0)]
    [string]$storageAccountName,

    [Parameter(Mandatory=$true,Position=1)]
    [string]$storageAccountKey,

    [Parameter(Mandatory=$true,Position=2)]
    [string]$containerName
)
Begin{
    Write-Output "Script started working"    
}
Process{
# If script throws an error "Server failed to authenticate".The StorageAccountKey might be changed.    
$Context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageAccountKey  
$blob_names=Get-AzStorageBlob -Container $containerName -Context $Context | Select-object Name,LastModified

    # To Rename the Blob File and move it to the Archive Folder
    Write-Output "To Rename the Blob File and move it to the Archive Folder"
    Foreach($srcblob in $blob_names)
    {
        
        if($srcblob.Name.Contains('Archive')) 
        {
            Write-Host "**** Blob file already Archived Hence Skipped" $srcblob.Name
        }
        else
        {
            #Write-Host $srcblob
            $TimeStamp= $srcblob.LastModified.Date | Get-Date -Format yyyy_MM_dd_hh:mm
            $dstTime=$srcblob.Name.Replace($('.' + $srcblob.Name.Split('.')[-1]),$('_' + $TimeStamp + '.' + $($srcblob.Name.Split('.')[-1])))
            $dstBlob=$dstTime.Insert($dstTime.LastIndexOf('/'), "/Archive")
            Start-AzStorageBlobCopy -SrcContainer $containerName -DestContainer $containerName -SrcBlob $srcblob.Name -DestBlob $dstBlob -Context $Context -DestContext $Context -Force
            #Write-Host "****************"
            #Write-Host $dstBlob
        }
    }

    # Removing the Blob File after archiving.
    Write-Output "Removing the Blob File after archiving."
    Foreach($srcblobs in $blob_names)
    {
        
        if($srcblobs.Name.Contains('Archive')) 
        {
            Write-Host "**** Blob file already Archived Hence Skipped" $srcblobs.Name
        }
        else
        {
            Remove-AzStorageBlob -Container $containerName -Context $Context -Blob $srcblobs.Name -Force
        }
    }	
}
End
{
    Write-Output "Script finished working"
}