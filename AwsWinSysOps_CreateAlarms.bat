REM This script iterates through EC2 instances and creates CloudWatch Alarms for specific metrics
@echo off

REM Configure the SNS-TOPIC-ARN to be used for CloudWatch Alarm notifications
set sns_topic_arn=xyz-sns-xyz-topic-xyz-arn
set test_only_dont_create_alarms=true

REM Get all instance ids and names
REM e.g. aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value]"
REM Optionally apply any filters as required
REM e.g. --filters 'Name=vpc-id,Values=vpc-a9a9a9a9'
REM e.g. --filters 'Name=tag:Name,Values=prod-server-*'
set AwsCliCommandGetEC2Instances=aws ec2 describe-instances --query "Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value]" --output text

REM Setup CreateAlarm templates for alarms
set AwsCliCommandCreateAlarmTemplate1_StatusCheckFailed=aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_StatusCheckFailed_[INSTANCE-NAME] --alarm-description 'Alarm when Status Check fails' --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --dimensions Name=InstanceId,Value=[INSTANCE-ID] --period 60 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions [SNS-TOPIC-ARN]
set AwsCliCommandCreateAlarmTemplate2_CPUUtilization=aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_CPUUtilization_[INSTANCE-NAME] --alarm-description 'Alarm when CPU exceeds 70%' --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=[INSTANCE-ID]  --evaluation-periods 2 --unit Percent --alarm-actions [SNS-TOPIC-ARN]
set AwsCliCommandCreateAlarmTemplate3_MemoryUtilization=aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_MemoryUtilization_[INSTANCE-NAME] --alarm-description 'Alarm when Memory exceeds 80%' --metric-name MemoryUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=[INSTANCE-ID]  --evaluation-periods 2 --unit Percent --alarm-actions [SNS-TOPIC-ARN]
set AwsCliCommandCreateAlarmTemplate4_WindowsServicesStopped=aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_WindowsServicesStopped_[INSTANCE-NAME] --alarm-description 'Alarm when count of Stopped Windows Services exceeds 0' --metric-name WindowsServicesStopped --namespace System/Windows --statistic Maximum --dimensions Name=InstanceId,Value=[INSTANCE-ID] --period 300 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions [SNS-TOPIC-ARN]
rem set AwsCliCommandCreateAlarmTemplate5_VolumeUtilization=aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_VolumeUtilization_[INSTANCE-NAME]_[DRIVE-LETTER] --alarm-description 'Alarm when Disk Space exceeds 80%' --metric-name VolumeUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=[INSTANCE-ID] Name=Drive-Letter,Value=[DRIVE-LETTER]:  --evaluation-periods 2 --unit Percent --alarm-actions [SNS-TOPIC-ARN]

setlocal EnableDelayedExpansion
set /a counter=1
set instance_id=none
set instance_name=none
for /F "tokens=*" %%A in ('%AwsCliCommandGetEC2Instances%') do (
  set /a modulo="!counter! %% 2"
  set /a counterBy2="!counter!/2"
  set value=%%A
  rem echo counter=!counter!; line=%%A; 
  rem echo modulo=!modulo!; value=!value!
  
  if !modulo!==0 (
    rem Even numbered lines have instance Names
	set instance_name=!value!
	
	rem Now we have both instance id and name
	echo ::::
    echo INSTANCE !counterBy2!: instance_id=!instance_id!; instance_name=!instance_name!
	echo TEST_ONLY_DONT_CREATE_ALARMS is set as %test_only_dont_create_alarms%
	echo ::::
	CALL :CreateAlarms !instance_id! !instance_name!
	pause
  ) else (
    rem Odd numbered lines have instance Ids
	set instance_id=!value!
  )

  set /a counter+=1
)
GOTO :eof

:CreateAlarms
	rem echo In CreateAlarms

	SETLOCAL
	SET instance_id=%1
	SET instance_name=%2

	REM Create alarm for each specified template
	CALL :CreateAlarm !instance_id! !instance_name! "!AwsCliCommandCreateAlarmTemplate1_StatusCheckFailed!"
	CALL :CreateAlarm !instance_id! !instance_name! "!AwsCliCommandCreateAlarmTemplate2_CPUUtilization!"
	CALL :CreateAlarm !instance_id! !instance_name! "!AwsCliCommandCreateAlarmTemplate3_MemoryUtilization!"
	CALL :CreateAlarm !instance_id! !instance_name! "!AwsCliCommandCreateAlarmTemplate4_WindowsServicesStopped!"
ENDLOCAL & SET _result=1
GOTO :eof

:CreateAlarm
	rem echo In CreateAlarm
	
	SETLOCAL
	SET instance_id=%1
	SET instance_name=%2
	SET create_alarm_template=%3

	REM Get CreateAlarm template and set it up for this instance
	set AwsCliCommandCreateAlarm=!create_alarm_template!

	set "to_replace=!instance_name!"
	for %%i in ("!to_replace!") do set "AwsCliCommandCreateAlarm=!AwsCliCommandCreateAlarm:[INSTANCE-NAME]=%%~i!"
	rem set AwsCliCommandCreateAlarm=!AwsCliCommandCreateAlarm:[INSTANCE-NAME]=%instance_name%!

	set "to_replace=!instance_id!"
	for %%j in ("!to_replace!") do set "AwsCliCommandCreateAlarm=!AwsCliCommandCreateAlarm:[INSTANCE-ID]=%%~j!"
	rem set AwsCliCommandCreateAlarm=!AwsCliCommandCreateAlarm:[INSTANCE-ID]=%instance_id%!

	set AwsCliCommandCreateAlarm=!AwsCliCommandCreateAlarm:[SNS-TOPIC-ARN]=%sns_topic_arn%!

	echo EXECUTING: !AwsCliCommandCreateAlarm!
	REM Execute CreateAlarm for this instance
	if %test_only_dont_create_alarms%=='false' (
	  rem !AwsCliCommandCreateAlarm!
	)
ENDLOCAL & SET _result=1
GOTO :eof
