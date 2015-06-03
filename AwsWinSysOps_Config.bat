REM configure windows credentials (for Windows Scheduled Task)
set winUsr=YOUR_WINDOWS_USERNAME_GOES_HERE
set winPwd=YOUR_WINDOWS_PASSWORD_GOES_HERE

REM configure AWS credentials (for AWS CloudWatch) in awscreds.conf file

REM configure base folder location (default is the location of this file, including executions via unc paths)
set baseFolder=%~dp0

REM configure log file (default is Logs\YYYY-MM-DD.log)
For /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set todaysDate=%%c-%%a-%%b)
set logFile=%baseFolder%\Logs\%todaysDate%.log
