param (
    [string] $XmlFilePath,
    [PScredential] $CvCred,
    [string] $CvServer
)

#get full path
$fullXmlFilePath = Resolve-Path $XmlFilePath


#Initialize Global Log File
$globalLogFile = Join-Path -Path $fullXmlFilePath -ChildPath "$(Split-Path $fullXmlFilePath -Leaf)-status-log.txt"
$null = New-Item -Path $globalLogFile -ItemType File -Force


Write-Host "Processing files in: $fullXmlFilePath" | Tee-Object -FilePath $globalLogFile -Append
Write-Host "Log file is: $globalLogFile" | Tee-Object -FilePath $globalLogFile -Append

# Create Job Status Tracking CSV
$restoreJobStatusCsv = Join-Path -Path $fullXmlFilePath -ChildPath restore-job-status.csv
Write-Host "Restore Job Status CSV is: $restoreJobStatusCsv" | Tee-Object -FilePath $globalLogFile -Append
$null | Set-Content -Path $restoreJobStatusCsv -Encoding UTF8

#get restore job csv file name
$restoreJobCsv = Join-Path -Path $fullXmlFilePath -ChildPath "restore-jobs.csv"
Write-Host "Restore Job CSV is: $restoreJobCsv" | Tee-Object -FilePath $globalLogFile -Append


# Log into Commvault Server
try {
    & qlogin.exe -csn $CvServer -u $CvCred.UserName -clp $CvCred.GetNetworkCredential().Password | Tee-Object -FilePath $globalLogFile -Append
if ($lastexitcode -ne 0) {        
        $errors = $errors -join "`n"
    }
}
catch {
    write-error "$_" | Tee-Object -FilePath $globalLogFile -Append
}

$restoreJobs = Import-Csv -Path $restoreJobCsv

$restoreJobStatus = foreach ($job in $restoreJobs) {
    $cvDate = $job.cvDate
    $clientName = $job.clientName
    $backupsetName = $job.backupsetName
    $jobId = $job.jobId

    Write-Host "Getting job status of job $jobId for $backupsetName on $clientName for date range starting $cvDate" | Tee-Object -FilePath $globalLogFile -Append
    [xml] $jobStatus = try {
        qlist job -j $job.jobId -co iosprdc -format xml | Tee-Object -FilePath $globalLogFile -Append
        
        if ($lastexitcode -ne 0) {
            $errors = $errors -join "`n"
        } else {
            $row = [PSCustomObject]@{
                cvDate = $cvDate
                clientName = $clientName
                backupsetName = $backupsetName
                jobId = $jobId
                status = $jobStatus.GalaxyUtilities_QgetJobsRespMsg.jobs.jobStatus
                completePercentage = $jobStatus.GalaxyUtilities_QgetJobsRespMsg.jobs.completePercentage
            }

            $row | ConvertTo-Csv -NoTypeInformation | ForEach-Object { $_ -replace '"', '' } | Out-File -FilePath $restoreJobStatusCsv -Encoding utf8

        }
    } catch {
        write-error "$_" | Tee-Object -FilePath $globalLogFile -Append
    }   

}

# Logout from Commvault
try{
    & qlogout.exe | Tee-Object -FilePath $globalLogFile -Append
if ($lastexitcode -ne 0) {        
        $errors = $errors -join "`n"
    }
}
catch {
    write-error "$_" | Tee-Object -FilePath $globalLogFile -Append
}


# Throw any errors
If ($errors) {
    Write-Host "The session included the following errors:`n"
    throw "$errors `n"
}
