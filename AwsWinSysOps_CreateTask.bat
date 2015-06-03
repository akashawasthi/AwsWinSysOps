REM invoke AwsWinSysOps_Config.bat to initialize all variables
call %~dp0\AwsWinSysOps_Config.bat



REM create a windows scheduled task on the server
schtasks ^
 /create /sc minute /mo 5 ^
 /ru "%winUsr%" /rp "%winPwd%" /rl HIGHEST ^
 /tn "AwsWinSysOps\CloudWatchMonitor" ^
 /tr "%baseFolder%\AwsWinSysOps_Execute.bat"
