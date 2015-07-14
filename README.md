[AwsWinSysOps](http://github.com/akashawasthi/AwsWinSysOps "GitHub Repository") is a quick-start guide and package for monitoring AWS EC2 windows instances using AWS CloudWatch metrics. For comprehensive infrastructure and application monitoring, take a look at [StackDriver](http://stackdriver.com), [DataDog](http://datadoghq.com/) or [NewRelic](http://newrelic.com/aws).  

# Configuring AwsWinSysOps

* ![Action](./etc/action01.png) **Action**: Download AwsWinSysOps and unzip, let's say, into `\\<SERVER_IP_OR_NAME>\<SHARED_FOLDER>\AwsWinSysOps`  

**Note**: In order to maintain a single *installation* of AwsWinSysOps in your environment, it is recommended that you place AwsWinSysOps in a *shared folder* that is accessible from each instance that needs to be monitored. However, you can also place it on each of your instances if you wish.  

## 1. AwsWinSysOps scripts
* **AwsWinSysOps_Config.bat**: contains Windows credentials and other settings  
 * ![Action](./etc/action01.png) **Action**: Edit the file to update your Windows Username and Password.  
* **awscreds.conf**: contains AWS credentials  
 * ![Action](./etc/action01.png) **Action**: Create an AWS Identity and Access Management (IAM) user with at least [CloudWatch PutMetricData](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/UsingIAM.html "AWS Documentation") permissions.  
 * ![Action](./etc/action01.png) **Action**: Edit the file to update your AWS AccessKeyId and SecretKey.  
* **AwsWinSysOps_CreateTask.bat**: contains [schtasks](https://msdn.microsoft.com/en-us/library/windows/desktop/bb736357.aspx "Microsoft Windows Documentation") command to create a *Windows Scheduled Task* on each instance that needs to be monitored  
 * ![Action](./etc/action01.png) **Action**: On **each instance** that needs to be monitored, open command prompt (*Run as Administrator*) and run `"\\<SERVER_IP_OR_NAME>\<SHARED_FOLDER>\AwsWinSysOps\AwsWinSysOps_CreateTask.bat"`.  
* **AwsWinSysOps_Execute.bat**: contains *PowerShell* commands to execute the *.ps1* monitoring scripts that capture instance metrics and send them to AWS CloudWatch. Later, these metrics can be used to create CloudWatch Alarms/Notifications.  
 * ![Action](./etc/action01.png) **Action**: None. This will be executed every 5 minutes from the *Windows Scheduled Task* on each instance that is being monitored.  
* **AwsWinSysOps_CreateAlarms.bat**: contains AWS CLI batch commands to create CloudWatch Alarms/Notifications using the instance metrics captured earlier. Review *#5* below before proceeding.  
 * ![Action](./etc/action01.png) **Action**: Edit the file to update your `SNS-TOPIC-ARN`. (See *#5.2* below)  
 * ![Action](./etc/action01.png) **Action**: From **an instance configured for AWS CLI**, open command prompt (*Run as Administrator*) and run `"\\<SERVER_IP_OR_NAME>\<SHARED_FOLDER>\AwsWinSysOps\AwsWinSysOps_CreateAlarms.bat"`. Note: This needs to be executed only **once** as it iterates through all instances and creates the alarms. See *#5* below for further reference to *AWS CLI*, *SNS* & *CloudWatch Alarms*.  

## 2. Amazon CloudWatch Monitoring Windows scripts
These are provided bundled as-is in folder *AmazonCloudWatchMonitoringWindows*. Original package is made available by AWS [here](http://aws.amazon.com/code/7932034889155460 "AWS Sample Code & Libraries"). Refer to [Jeff Barr's blog post](http://aws.amazon.com/blogs/aws/amazon-cloudwatch-monitoring-scripts-for-microsoft-windows "AWS Official Blog") and [documentation](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-powershell.html "AWS Documentation") for additional details.  

* **awscreds.conf**: not used  
* **mon-get-instance-stats.ps1**: not used  
* **mon-put-metrics-disk.ps1**: monitor Disk metrics  
* **mon-put-metrics-mem.ps1**: monitor Memory metrics  
* **mon-put-metrics-perfmon.ps1**: monitor Perfmon metrics  

## 3. AwsWinSysOps CloudWatch Monitoring scripts
These are contained in the folder *Scripts*.  

* **mon-windows-services.ps1**: monitor Windows Services. It monitors windows services configured as '*Auto*' start that are in '*Stopped*' state. By default, it monitors *all* services but you can control this via `service_name_filter` parameter specified in *AwsWinSysOps_Execute.bat* file.  


## 4. AwsWinSysOps Logs
These are contained in the folder *Logs*  

* By default it creates one log file per day, named *YYYY-MM-DD.log*  

## 5. Alarms and Notifications

### 5.1 AWS Command Line Interface (CLI)
AWS CLI is a unified tool to manage AWS services via a command line. [Learn more](http://aws.amazon.com/cli "AWS CLI - Get started") about AWS CLI.  

* ![Action](./etc/action01.png) **Action**: [Install & configure](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html "AWS Documentation") CLI in order to proceed setting up AWS CloudWatch Alarms and AWS AWS Simple Notification Service (SNS) notifications. You will need an AWS Identity and Access Management (IAM) user with at least [CloudWatch PutMetricAlarm](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/UsingIAM.html "AWS Documentation") permissions.  

### 5.2 AWS Simple Notification Service (SNS)
AWS SNS allows to create *topics* and *subscriptions* to them in order to send notifications for alarms  

#### 5.2.1 ![Action](./etc/action01.png) **Action**: Create new SNS Topic  
 * via AWS Console (refer [documentation...](http://docs.aws.amazon.com/sns/latest/dg/CreateTopic.html "AWS Documentation")) *or* via AWS CLI using following template:  

SNS Topic|AWS CLI Template  
--------------|----------------  
**Name**: `AwsWinSysOps-Check`; **Comment**: Create a new SNS Topic, get `SNS-TOPIC-ARN` returned by AWS|`aws sns-create-topic AwsWinSysOps-Check`

#### 5.2.2 ![Action](./etc/action01.png) **Action**: Subscribe to a Topic  
 * via AWS Console (refer [documentation...](http://docs.aws.amazon.com/sns/latest/dg/SubscribeTopic.html "AWS Documentation")) *or* via AWS CLI using following template:  

SNS Subscription|AWS CLI Template  
-------------|----------------  
**SNS Subscribers**: `EMAILS-IDS`; **Comment**: Create new subscription for SNS Topic `SNS-TOPIC-ARN` (`ARN` for `AwsWinSysOps-Check`)|`aws sns-subscribe <SNS-TOPIC-ARN> --protocol email --endpoint <EMAILS-IDS>`

### 5.3 AWS CloudWatch Alarms
AWS CloudWatch allows to create Alarms at metric thresholds...  

#### 5.3.1 Create new CloudWatch Alarms  
 * ![Action](./etc/action01.png) **Action**: None. This is handled in script `AwsWinSysOps_CreateAlarms.bat` above. Templates below are only for reference.  
 * via AWS Console (refer [documentation...](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/US_AlarmAtThresholdEC2.html "AWS Documentation")) *or* via AWS CLI using following templates:  

CloudWatch Alarm|AWS CLI Template  
---------------------|----------------  
**Name**: `AwsWinSysOps_<INSTANCE-NAME>_StatusCheckFailed`; **Threshold**: StatusCheckFailed >= 1 for 2 minutes; **Comment**: 1 alarm for each instance|`aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_StatusCheckFailed --alarm-description "Alarm when Status Check fails" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --dimensions Name=InstanceId,Value=<INSTANCE-ID> --period 60 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions <SNS-TOPIC-ARN>`  
**Name**: `AwsWinSysOps_<INSTANCE-NAME>_CPUUtilization`; **Threshold**: CPUUtilization > 70 for 10 minutes; **Comment**: 1 alarm for each instance|`aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_CPUUtilization --alarm-description "Alarm when CPU exceeds 70%" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=<INSTANCE-ID> --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`  
**Name**: `AwsWinSysOps_<INSTANCE-NAME>_MemoryUtilization`; **Threshold**: MemoryUtilization > 80 for 10 minutes; **Comment**: 1 alarm for each instance|`aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_MemoryUtilization --alarm-description "Alarm when Memory exceeds 80%" --metric-name MemoryUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=<INSTANCE-ID> --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`  
**Name**: `AwsWinSysOps_<INSTANCE-NAME>_WindowsServicesStopped`; **Threshold**: WindowsServicesStopped >= 1 for 10 minutes; **Comment**: 1 alarm for each instance|`aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_WindowsServicesStopped --alarm-description "Alarm when count of Stopped Windows Services exceeds 0" --metric-name WindowsServicesStopped --namespace System/Windows --statistic Maximum --dimensions Name=InstanceId,Value=<INSTANCE-ID> --period 300 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions <SNS-TOPIC-ARN>`  
**Name**: `AwsWinSysOps_<INSTANCE-NAME>_<DRIVE-LETTER>_VolumeUtilization`; **Threshold**: VolumeUtilization > 80 for 10 minutes; **Comment**: 1 alarm for each drive|`aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_<DRIVE-LETTER>_VolumeUtilization --alarm-description "Alarm when Disk Space exceeds 80%" --metric-name VolumeUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold --dimensions Name=InstanceId,Value=<INSTANCE-ID> Name=Drive-Letter,Value=<DRIVE-LETTER>: --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`  

## License

    Copyright 2015 Akash Awasthi (github.com/akashawasthi)
    
    Licensed under the Apache License, Version 2.0 (the "License");
    You may not use this software except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    or in the "license" file accompanying this software package.
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
