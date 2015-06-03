# AwsWinSysOps

[AwsWinSysOps](http://github.com/akashawasthi/AwsWinSysOps "GitHub Repository") is a quick-start guide and package for monitoring AWS EC2 windows instances using AWS CloudWatch metrics.  

* **Action**: Download AwsWinSysOps and unzip, let's say, into `\\10.0.1.100\SharedFolder\AwsWinSysOps`
> Note: In order to maintain a single *installation* of AwsWinSysOps in your environment, it is recommended that you place AwsWinSysOps on a *shared folder* that is accessible from each instance that needs to be monitored. However, you can also place it on each of your instances if you wish.

## 1. AwsWinSysOps scripts
* **AwsWinSysOps_Config.bat**: contains Windows credentials and other settings  
 * **Action**: Edit the file to update your Windows Username and Password.  
* **awscreds.conf**: contains AWS credentials  
 * **Action**: Create an AWS Identity and Access Management (IAM) user with at least [CloudWatch PutMetricData permissions](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/UsingIAM.html "AWS Documentation").  
 * **Action**: Edit the file to update your AWS AccessKeyId and SecretKey.  
* **AwsWinSysOps_CreateTask.bat**: contains [schtasks](https://msdn.microsoft.com/en-us/library/windows/desktop/bb736357.aspx "Microsoft Windows Documentation") command to create a *Windows Scheduled Task* on each instance that needs to be monitored  
 * **Action**: On **each instance** that needs to be monitored, open command prompt (*Run as Administrator*) and run *AwsWinSysOps_CreateTask.bat*.  
* **AwsWinSysOps_Execute.bat**: contains *PowerShell* commands to execute the *.ps1* monitoring scripts that capture AWS CloudWatch metrics for the instance and send them to AWS CloudWatch. Later, these metrics can be used to create CloudWatch Alarms/Notifications.  
 * **Action**: None. This is executed every 5 minutes from the *Windows Scheduled Task* on each instance that is being monitored. 

## 2. Amazon CloudWatch Monitoring Windows scripts
* **awscreds.conf**: not used  
* **mon-get-instance-stats.ps1**: not used  
* **mon-put-metrics-disk.ps1**: monitor Disk metrics  
* **mon-put-metrics-mem.ps1**: monitor Memory metrics  
* **mon-put-metrics-perfmon.ps1**: monitor Perfmon metrics  
> These are provided bundled as-is in folder *AmazonCloudWatchMonitoringWindows*. Original package is made available by AWS [here](http://aws.amazon.com/code/7932034889155460 "AWS Sample Code & Libraries"). Refer to [Jeff Barr's blog post](http://aws.amazon.com/blogs/aws/amazon-cloudwatch-monitoring-scripts-for-microsoft-windows "AWS Official Blog") and [documentation](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/mon-scripts-powershell.html "AWS Documentation") for additional details.  

## 3. AwsWinSysOps CloudWatch Monitoring scripts
* **mon-windows-services.ps1**: monitor Windows Services  
> These are contained in the folder *Scripts*  

## 4. AwsWinSysOps Logs
* By default it creates one log file per day, named *YYYY-MM-DD.log*  
> These are contained in the folder *Logs*  

## 5. Alarms and Notifications


### 5.1 AWS Command Line Interface (CLI)
> AWS CLI is a unified tool to manage AWS services via a command line. [Learn more](http://aws.amazon.com/cli) about CLI or [install & configure](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-set-up.html) CLI to proceed setting up AWS CloudWatch Alarms and AWS AWS Simple Notification Service (SNS) notifications.

### 5.2 AWS Simple Notification Service (SNS)
> AWS SNS allows to create *topics* and *subscriptions* to them in order to send notifications for alarms  

* Create new SNS Topic:  
 * use AWS Console - refer [documentation](http://docs.aws.amazon.com/sns/latest/dg/CreateTopic.html)  
 * use AWS CLI via following template:  
SNS Topic Name|SNS Topic ARN|Comment|AWS CLI Template
--------------|-------------|-------|----------------
AwsWinSysOps-Check|SNS-TOPIC-ARN|Create 1 new SNS Topic, get SNS-TOPIC-ARN returned by AWS|`aws sns-create-topic AwsWinSysOps-Check`
* Subscribe to a Topic:  
 * use AWS Console - refer [documentation](http://docs.aws.amazon.com/sns/latest/dg/SubscribeTopic.html)  
 * use AWS CLI via following template:  
SNS Topic ARN|SNS Subscription Email|Comment|AWS CLI Template
-------------|----------------------|-------|----------------
SNS-TOPIC-ARN|EMAILS-IDS|Create new subscription for SNS TOPIC|`aws sns-subscribe <SNS-TOPIC-ARN> --protocol email --endpoint <EMAILS-IDS>`

### 5.3 AWS CloudWatch Alarms
> AWS CloudWatch allows to create Alarms at metric thresholds...  

* Create new CloudWatch Alarm:  
 * use AWS Console - refer [documentation](http://docs.aws.amazon.com/AmazonCloudWatch/latest/DeveloperGuide/US_AlarmAtThresholdEC2.html)  
 * use AWS CLI via following templates:  
CloudWatch Alarm Name|Threshold|Comment|AWS CLI Template
---------------------|---------|-------|----------------
`AwsWinSysOps_<INSTANCE-NAME>_StatusCheckFailed`|StatusCheckFailed >= 1 for 2 minutes|1 alarm for each instance|
 `aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_StatusCheckFailed --alarm-description "Alarm when Status Check fails" --metric-name StatusCheckFailed --namespace AWS/EC2 --statistic Maximum --dimensions Name=InstanceId,Value=<INSTANCE-ID> --period 60 --unit Count --evaluation-periods 2 --threshold 1 --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions <SNS-TOPIC-ARN>`
`AwsWinSysOps_<INSTANCE-NAME>_CPUUtilization`|CPUUtilization > 70 for 10 minutes|1 alarm for each instance|
 `aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_CPUUtilization --alarm-description "Alarm when CPU exceeds 70%" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=<INSTANCE-ID>  --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`
`AwsWinSysOps_<INSTANCE-NAME>_MemoryUtilization`|MemoryUtilization > 80 for 10 minutes|1 alarm for each instance|
 `aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_MemoryUtilization --alarm-description "Alarm when Memory exceeds 80%" --metric-name MemoryUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=<INSTANCE-ID>  --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`
`AwsWinSysOps_<INSTANCE-NAME>_<DRIVE-LETTER>_VolumeUtilization`|VolumeUtilization > 80 for 10 minutes|1 alarm for each drive|
 `aws cloudwatch put-metric-alarm --alarm-name AwsWinSysOps_<INSTANCE-NAME>_<DRIVE-LETTER>_VolumeUtilization --alarm-description "Alarm when Disk Space exceeds 80%" --metric-name VolumeUtilization --namespace System/Windows --statistic Average --period 300 --threshold 80 --comparison-operator GreaterThanThreshold  --dimensions  Name=InstanceId,Value=<INSTANCE-ID> Name=Drive-Letter,Value=<DRIVE-LETTER>:  --evaluation-periods 2 --unit Percent --alarm-actions <SNS-TOPIC-ARN>`




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
