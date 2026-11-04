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


$files = Get-ChildItem -Path $XmlFilePath -Filter *.xml -File -Recurse

# Start thread jobs and track their handles
$jobs = foreach ($file in $files) {
    Start-ThreadJob -ScriptBlock {
        qlogin.exe -cs $CvServer -u $CvCred.UserName -clp $CvCred.GetNetworkCredential().Password |Tee-Object -FilePath "$XmlFilePath\$clientName-$backupsetName-restore-log.txt" -Append

        [xml]$xml = Get-Content -Path $_.FullName
        [string] $clientName = $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.clientName
        [string] $backupsetName = $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.backupSetName
        Write-Host "Processing: $($_.FullName)" | Tee-Object -FilePath "$XmlFilePath\$clientName-$backupsetName-restore-log.txt" -Append
        qoperation.exe execute -af $_.FullName | Tee-Object -FilePath "$XmlFilePath\$clientName-$backupsetName-restore-log.txt" -Append
        qlogout.exe | Tee-Object -FilePath "$XmlFilePath\$clientName-$backupsetName-restore-log.txt" -Append
    }
}

# Wait for all parallel threads to finish
$jobs | Wait-Job | Out-Null

# Retrieve the results and clean up memory
$results = $jobs | Receive-Job
$jobs | Remove-Job

# Display output
$results
