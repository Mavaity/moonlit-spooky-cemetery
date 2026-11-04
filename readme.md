**Prerequisite:**

`Set-ExecutionPolicy RemoteSigned`
`Install-Module Thread-Jobs -scope CurrentUser

**Example to build weekly xml files for mass restores:**

.\new-xml-files.ps1 -BackupsetFile .\backupsetfile.csv -StartDatetime "11-01-2026 06:00:00" -EndDatetime "11-05-2026 06:00:00" -Interval 7 -IntervalUnit "days" -DestinationPath "C:\restores"

**Example to build monthly xml files for mass restores:**

.\new-xmlfiles.ps1 -BackupsetFile .\test-input\test-BackupsetFile.csv -StartDatetime "01-01-2026 06:00:00" -EndDatetime "02-02-2026 06:00:00" -DestinationPath . - IntervalUnit "months" -Interval 1

**Example restore script**

.\restore-cv-backups.ps1 -XmlFilePath ".\2026-11-04\" -CvCred $cred -CvFqdn WinSvr19-Svr01 -CvServer WinSvr19-Svr0

