param (
    [string] $XmlFilePath,
    [PScredential] $CvCred,
    [string] $CvFqdn,
    [string] $CvServer
)

if (!$env:GALAXY_BASE) {
    $env:GALAXY_BASE = "C:\Program Files\Commvault\ContentStore\Base"
}
$env:Path += ";$env.GALAXY_BASE"

qlogin.exe -cs $CvServer -u $CvCred.UserName -p $CvCred.GetNetworkCredential().Password |Tee-Object -FilePath "$XmlFilePath\restore-log.txt" -Append

Get-ChildItem -Path $XmlFilePath -Filter *.xml -File -Recurse | ForEach-Object { 
    [xml]$xml = Get-Content -Path $_.FullName
    [string] $clientName = $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.clientName
    [string] $backupsetName = $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.backupSetName
    Write-Host "Processing: $($_.FullName)" | Tee-Object -FilePath "$XmlFilePath\restore-log.txt" -Append
    Start-Process qoperation.exe execute -af $_.FullName | Tee-Object -FilePath "$XmlFilePath\$clientName-$backupsetName-restore-log.txt" -Append
}

qlogout.exe | Tee-Object -FilePath "$XmlFilePath\restore-log.txt" -Append
