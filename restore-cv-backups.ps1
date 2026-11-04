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
        param(
            [string] $XmlFilePath,
            $file,
            [PScredential] $CvCred = $using:CvCred,
            [string] $CvFqdn = $using:CvFqdn,
            [string] $CvServer = $using:CvServer            
        )
        Write-Host "XML File Path: $XmlFilePath"
        Write-Host $file.basename
        & qlogin.exe -cs $CvServer -u $CvCred.UserName -clp $CvCred.GetNetworkCredential().Password |Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append

        Write-Host "Processing: $($file.FullName)" | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append
        & qoperation.exe execute -af $file.FullName | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append
        & qlogout.exe | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append
    } -ArgumentList $XmlFilePath,$file
}

# Wait for all parallel threads to finish
$jobs | Wait-Job | Out-Null

# Retrieve the results and clean up memory
$results = $jobs | Receive-Job
$jobs | Remove-Job

# Display output
$results
