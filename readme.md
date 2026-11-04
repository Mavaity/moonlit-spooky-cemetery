Example to build weekly xml files for mass restores:
.\new-xmlfiles.ps1 -BackupsetFile .\test-input\test-BackupsetFile.csv -StartDatetime "01-01-2026 06:00:00" -EndDatetime "02-02-2026 06:00:00" -DestinationPath . -IntervalUnit "days" -Interval 7

Example to build monthly xml files for mass restores:
.\new-xmlfiles.ps1 -BackupsetFile .\test-input\test-BackupsetFile.csv -StartDatetime "01-01-2026 06:00:00" -EndDatetime "02-02-2026 06:00:00" -DestinationPath . - IntervalUnit "months" -Interval 1

Exam
