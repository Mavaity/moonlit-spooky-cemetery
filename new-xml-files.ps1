param (
    [string] $BackupsetName,
    [string] $ClientName,
    [string] $BackupsetFile,
    [datetime] $StartDatetime,
    [datetime] $EndDatetime,
    [string] $DestinationPath,
    [int] $IntervalDays
)

function new-xml-files {
    param (        
        [string] $BackupsetName,
        [string] $ClientName,
        [datetime] $StartDatetime,
        [datetime] $EndDatetime,
        [string] $DestinationPath,
        [int] $IntervalDays
    )
    [datetime] $batchStartDatetime = $StartDatetime
    while ($batchStartDatetime -le $EndDatetime) {
            
        [string] $stringBatchStartDatetime = $batchStartDatetime.ToString("yyyy-MM-dd hh:mm:ss")
        [datetime] $batchEndDatetime = $batchStartDatetime.AddDays($IntervalDays)
        [string] $stringBatchEndDate = $batchEndDatetime.ToString("yyyy-MM-dd")
        [string] $stringBatchEndDatetime = $batchEndDatetime.ToString("yyyy-MM-dd hh:mm:ss")
        [string] $subDir = Join-Path -Path $PWD -ChildPath $stringBatchEndDate

        # Create Directory if needed
        New-Item -Path $subDir -ItemType Directory -Force | Out-Null

        # Load the original XML file
        [xml] $xml = Get-Content -Path "$PWD\restore-template.xml"

        # Navigate to the node and replace the value
        $xml.TMMsg_CreateTaskReq.taskInfo.associations.backupsetName = $BackupsetName
        $xml.TMMsg_CreateTaskReq.taskInfo.associations.clientName = $ClientName 
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.clientName = $BackupsetName
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.backupSetName = $ClientName
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.timeRange.fromTimeValue = $stringBatchStartDatetime
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.timerange.toTimeValue = $stringBatchEndDatetime
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.destination.destPath = "$DestinationPath\$stringBatchEndDate"

        # Save the modified object to a new destination file
        $xml.Save("$subDir\$ClientName-$BackupSetName-$stringBatchEnddate.xml")
        
        #Increment the start date
        [datetime] $batchStartDatetime = $batchEndDatetime

    }
}

if ($StartDatetime -and $EndDatetime) {
    if ($BackupsetFile) {
        $data = Import-Csv -Path $BackupsetFile

        foreach ($row in $data) {
            Write-Host "Processing client: $($row.ClientName) Backupset: $($row.BackupsetName)"
            new-xml-files -ClientName $row.ClientName -BackupsetName $row.BackupsetName -StartDatetime $StartDatetime -EndDatetime $EndDatetime -DestinationPath $DestinationPath -IntervalDays $IntervalDays
        }

    } elseif ($BackupsetName -and $ClientName) {
        Write-Host "Processing client: $($row.ClientName) Backupset: $($row.BackupsetName)"
        new-xml-files -ClientName $ClientName -BackupsetName $BackupsetName -StartDatetime $StartDatetime -EndDatetime $EndDatetime -DestinationPath $DestinationPath -IntervalDays $IntervalDays
    } else {
        Write-Host "Specify either a Backupset name and ClientName or a BackupSetFile (CSV format ClientName,BackupsetName)"
        exit
    }
} else {
    Write-Host "You must specify a StartDatetime and EndDatetime."
    exit
}



