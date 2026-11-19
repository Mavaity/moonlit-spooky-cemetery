param (
    [string] $XmlFilePath,
    [PScredential] $CvCred,
    [string] $CvFqdn,
    [string] $CvServer
)


#get full path
$fullXmlFilePath = Resolve-Path $XmlFilePath

#Initialize Global Log File
$globalLogFile = Join-Path -Path $fullXmlFilePath -ChildPath "$(Split-Path $fullXmlFilePath -Leaf)-log.txt"
$null = New-Item -Path $globalLogFile -ItemType File -Force
Write-Host "Processing files in: $fullXmlFilePath" | Tee-Object -FilePath $globalLogFile -Append

# Create Job Tracking CSV
$restoreJobCsv = Join-Path -Path $fullXmlFilePath -ChildPath restore-jobs.csv
'"taskId","jobId","clientName","backupsetName"' | Set-Content -Path $restoreJobCsv -Encoding UTF8

# Get XML Files in $fullXmlFilePath
$files = Get-ChildItem -Path $fullXmlFilePath -Filter *.xml -File -Recurse
Write-Host "XML File Path: $fullXmlFilePath" | Tee-Object -FilePath $globalLogFile -Append

# Set Commvault Path
if (!$env:GALAXY_BASE) {
    $env:GALAXY_BASE = "C:\Program Files\Commvault\ContentStore\Base"
}
$env:Path += ";$env.GALAXY_BASE"

# Log into Commvault Server
try {
    & qlogin.exe -cs $CvServer -u $CvCred.UserName -clp $CvCred.GetNetworkCredential().Password | Tee-Object -FilePath $globalLogFile -Append 
if ($lastexitcode -ne 0) {        
        $errors = $errors -join "`n"
    }
}
catch {
    write-error "$_" | Tee-Object -FilePath $globalLogFile -Append    
}

# Add a job for each XML file
foreach ($file in $files) {
    
    #Initialize Local Log File
    $localLogFile = Join-Path -Path $fullXmlFilePath -ChildPath "$($file.BaseName)-log.txt"
    $null = New-Item -Path $localLogFile -ItemType File -Force

    [string] $return = ""
    Write-Host "Processing: $($file.FullName)" | Tee-Object -FilePath $localLogFile -Append | Tee-Object -FilePath $globalLogFile -Append

    # Load the XML file
    [xml] $xml = Get-Content -Path $file.fullname

    # Navigate to the node and get the value
    $backupsetName = $xml.TMMsg_CreateTaskReq.taskInfo.associations.backupsetName
    $sourceClientName = $xml.TMMsg_CreateTaskReq.taskInfo.associations.clientName

    try{
        & qoperation.exe execute -af $file.FullName | Tee-Object -Variable return | Tee-Object -FilePath $localLogFile -Append | Tee-Object -FilePath $globalLogFile -Append 
    if ($lastexitcode -ne 0) {        
            $errors = $errors -join "`n"
        } else {
            # create an object with the header names
            $returnXml = [xml]$return
            $row = [pscustomobject]@{
                taskId     = $returnXml.TMMsg_CreateTaskResp.taskId
                jobId = $returnXml.TMMsg_CreateTaskResp.jobIds.val
                clientName = $sourceClientName
                backupsetName = $backupsetName
            }

            # Append the row to job tracking CSV
            $row | Export-Csv -Path $restoreJobCsv -Append -NoTypeInformation -Encoding UTF8
        }
    
    
    }
    catch {
        write-error "$_" | Tee-Object -FilePath $localLogFile -Append | Tee-Object -FilePath $globalLogFile -Append
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

