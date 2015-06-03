REM invoke AwsWinSysOps_Config.bat to initialize all variables
call %~dp0\AwsWinSysOps_Config.bat



REM configure scripts folder location
set scriptsFolder=%baseFolder%\AmazonCloudWatchMonitoringWindows

REM execute mon-put-metrics-mem.ps1
Powershell.exe -ExecutionPolicy ByPass -command "'--> ' + $env:COMPUTERNAME + ' / mon-put-metrics-mem.ps1 / ' + (Get-Date).ToUniversalTime() | out-file -filepath %logFile% -append"
Powershell.exe -ExecutionPolicy ByPass -command "%scriptsFolder%\mon-put-metrics-mem.ps1 -aws_credential_file %baseFolder%\awscreds.conf -mem_util -mem_used -mem_avail -page_avail -page_used -page_util -memory_units Megabytes -from_scheduler -logfile %logFile%"

REM execute mon-put-metrics-disk.ps1
Powershell.exe -ExecutionPolicy ByPass -command "'--> ' + $env:COMPUTERNAME + ' / mon-put-metrics-disk.ps1 / ' + (Get-Date).ToUniversalTime() | out-file -filepath %logFile% -append"
Powershell.exe -ExecutionPolicy ByPass -command "%scriptsFolder%\mon-put-metrics-disk.ps1 -aws_credential_file %baseFolder%\awscreds.conf -disk_drive C:,D:,E:,F:,G: -disk_space_util -disk_space_used -disk_space_avail -disk_space_units Gigabytes -from_scheduler -logfile %logFile%"

REM execute mon-put-metrics-perfmon.ps1
Powershell.exe -ExecutionPolicy ByPass -command "'--> ' + $env:COMPUTERNAME + ' / mon-put-metrics-perfmon.ps1 / ' + (Get-Date).ToUniversalTime() | out-file -filepath %logFile% -append"
Powershell.exe -ExecutionPolicy ByPass -command "%scriptsFolder%\mon-put-metrics-perfmon.ps1 -aws_credential_file %baseFolder%\awscreds.conf -pages_input -processor_queue -from_scheduler -logfile %logFile%"



REM configure scripts folder location
set scriptsFolder=%baseFolder%\Scripts

REM execute mon-windows-services.ps1
Powershell.exe -ExecutionPolicy ByPass -command "'--> ' + $env:COMPUTERNAME + ' / mon-windows-services.ps1 / ' + (Get-Date).ToUniversalTime() | out-file -filepath %logFile% -append"
Powershell.exe -ExecutionPolicy ByPass -command "%scriptsFolder%\mon-windows-services.ps1 -aws_credential_file %baseFolder%\awscreds.conf  -service_name_filter '*' -from_scheduler -logfile %logFile%"
