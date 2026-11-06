param (
    [string] $XmlFilePath,
    [PScredential] $CvCred,
    [string] $CvFqdn,
    [string] $CvServer
)

#get full path
$XmlFilePath = Resolve-Path $XmlFilePath
Write-Host "Processing files in: $XmlFilePath"

#Initialize Log File
$logFilePath = "$XmlFilePath\$(Split-Path $XmlFilePath -Leaf)-log.txt"
$null = New-Item -Path $logFilePath -ItemType File -Force


# Set Commvault Path
if (!$env:GALAXY_BASE) {
    $env:GALAXY_BASE = "C:\Program Files\Commvault\ContentStore\Base"
}
$env:Path += ";$env.GALAXY_BASE"

# Get XML Files in $XmlFilePath
$files = Get-ChildItem -Path $XmlFilePath -Filter *.xml -File -Recurse
Write-Host "XML File Path: $XmlFilePath" | Tee-Object -FilePath "$XmlFilePath\$($XmlFilePath.BaseName)-log.txt" -Append


# # Write Job Tracking CSV
# $outfile = "$XmlFilePath\job-tracking.csv"
# $null = New-Item -Path $outfile -ItemType File -Force

# Log into Commvault Server
try {
    & qlogin.exe -cs $CvServer -u $CvCred.UserName -clp $CvCred.GetNetworkCredential().Password | Tee-Object -FilePath $logFilePath -Append 
if ($lastexitcode -ne 0) {        
        $errors = $errors -join "`n"
    }
}
catch {
    write-error "$_" | Tee-Object -FilePath "$XmlFilePath\$($XmlFilePath.BaseName)-log.txt" -Append    
}

# Add a job for each XML file
foreach ($file in $files) {
    Write-Host "Processing: $($file.FullName)" | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append | Tee-Object -FilePath $logFilePath -Append

    try{
        & qoperation.exe execute -af $file.FullName | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append | Tee-Object -FilePath $logFilePath -Append
    if ($lastexitcode -ne 0) {        
            $errors = $errors -join "`n"
        }
    }
    catch {
        write-error "$_" | Tee-Object -FilePath "$XmlFilePath\$($file.BaseName)-log.txt" -Append | Tee-Object -FilePath $logFilePath -Append
    }

# $outputRowData = [PsCustomObject]@{
#     "" = 
# }

}

# Logout from Commvault
try{
    & qlogout.exe | Tee-Object -FilePath $logFilePath -Append
if ($lastexitcode -ne 0) {        
        $errors = $errors -join "`n"
    }
}
catch {
    write-error "$_" | Tee-Object -FilePath $logFilePath -Append    
}

# Throw any errors
If ($errors) {
    Write-Host "The session included the following errors:`n"
    throw "$errors `n"
}

