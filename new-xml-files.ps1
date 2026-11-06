param (
    [string] $BackupsetName,
    [string] $ClientName,
    [string] $BackupsetFile,
    [datetime] $StartDatetime,
    [datetime] $EndDatetime,
    [string] $DestinationPath,
    [int] $Interval,
    [string] $IntervalUnit
)

function new-xml-files {
    param (        
        [string] $BackupsetName,
        [string] $ClientName,
        [datetime] $StartDatetime,
        [datetime] $EndDatetime,
        [string] $DestinationPath,
        [int] $Interval,
        [string] $IntervalUnit
    )
    if ($IntervalUnit -eq "months") {
        $StartDatetime = get-date $StartDatetime -Day 1
    }
    [datetime] $batchStartDatetime = $StartDatetime
    
    while ($batchStartDatetime -le $EndDatetime) {

        if ($IntervalUnit -eq "days") {
            [datetime] $batchEndDatetime = $batchStartDatetime.AddDays($Interval)
            [string] $stringBatchStartDate = $batchStartDatetime.ToString("yyyy-MM-dd")
       } elseif ($IntervalUnit -eq "months") {
            [datetime] $batchEndDatetime = $batchStartDatetime.AddMonths($Interval)
            [string] $stringBatchStartDate = $batchStartDatetime.ToString("yyyy-MM")
        } else {
            throw "Critical Error: The interval unit '$IntervalUnit' is not available"
        }
        [string] $stringBatchStartDatetime = $batchStartDatetime.ToString("yyyy-MM-dd hh:mm:ss")
        [string] $stringBatchEndDatetime = $batchEndDatetime.ToString("yyyy-MM-dd hh:mm:ss")
        [string] $subDir = Join-Path -Path $PWD -ChildPath $stringBatchStartDate
        [string] $backusetSubPath = "$stringBatchStartDate.$ClientName.$BackupsetName"
        [string] $fullDestinationPath = Join-Path -Path $DestinationPath -ChildPath "$stringBatchStartDate\$ClientName.$BackupsetName"
        #write-host $fullDestinationPath

        # Create Directory if needed
        New-Item -Path $subDir -ItemType Directory -Force | Out-Null

        # Load the original XML file
        [xml] $xml = Get-Content -Path "$PWD\restore-template.xml"

        # Navigate to the node and replace the value
        $xml.TMMsg_CreateTaskReq.taskInfo.associations.backupsetName = $BackupsetName
        $xml.TMMsg_CreateTaskReq.taskInfo.associations.clientName = $ClientName 
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.clientName = $ClientName
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.backupset.backupSetName = $BackupsetName
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.timeRange.fromTimeValue = $stringBatchStartDatetime
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.browseOption.timerange.toTimeValue = $stringBatchEndDatetime
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.destination.destPath = $fullDestinationPath
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.destination.destClient.clientName = $ClientName
        $xml.TMMsg_CreateTaskReq.taskInfo.subTasks.options.restoreOptions.destination.destinationInstance.clientName = $ClientName

        # Save the modified object to a new destination file
        $xml.Save("$subDir\$ClientName-$BackupSetName-$stringBatchStartDate.xml")
        
        #Increment the start date
        [datetime] $batchStartDatetime = $batchEndDatetime

    }
}

if ($StartDatetime -and $EndDatetime) {
    Write-Host "BackupsetFile : $BackupsetFile"
    if ($BackupsetFile) {
        $data = Import-Csv -Path $BackupsetFile

        foreach ($row in $data) {
            Write-Host "Processing client: $($row.ClientName) Backupset: $($row.BackupsetName)"
            new-xml-files -ClientName $row.ClientName -BackupsetName $row.BackupsetName -StartDatetime $StartDatetime -EndDatetime $EndDatetime -DestinationPath $DestinationPath -IntervalUnit $IntervalUnit -Interval $Interval
        }

    } elseif ($BackupsetName -and $ClientName) {
        Write-Host "Processing client: $ClientName Backupset: $BackupsetName"
        new-xml-files -ClientName $ClientName -BackupsetName $BackupsetName -StartDatetime $StartDatetime -EndDatetime $EndDatetime -DestinationPath $DestinationPath -IntervalUnit $IntervalUnit -Interval $Interval
    } else {
        throw "Specify either a Backupset name and ClientName or a BackupSetFile (CSV format ClientName,BackupsetName)"
        exit
    }
} else {
    throw "You must specify a StartDatetime and EndDatetime."
    exit
}



