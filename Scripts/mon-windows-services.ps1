<#

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


.SYNOPSIS
Collects windows services status on an Amazon Windows EC2 instance and sends this data as custom metrics to Amazon CloudWatch.


.DESCRIPTION
This script is used to send custom metrics to Amazon Cloudwatch. This script pushes windows services status to cloudwatch. This script can be scheduled or run from a powershell prompt. 
When launched from scheduler you need to specify logfile and all messages will be logged to logfile. You can use whatif and verbose mode with this script.

.PARAMETER service_name_filter
		Specifies wildcard based filter for services, e.g. "my company*;MSMQ;SQL*;"
.PARAMETER from_scheduler          
		Specifies that this script is running from Task Scheduler.
.PARAMETER aws_access_id          
		Specifies the AWS access key ID to use to identify the caller.
.PARAMETER aws_secret_key          
		Specifies the AWS secret key to use to sign the request.
.PARAMETER aws_credential_file          
		Specifies the location of the file with AWS credentials. Uses "AWS_CREDENTIAL_FILE" Env variable as default.
.PARAMETER logfile          
		Logs all error messages to a log file. This is required when from_scheduler is set.

  
.NOTES
    PREREQUISITES:
    1) Download the SDK library from http://aws.amazon.com/sdkfornet/
    2) Obtain Secret and Access keys from https://aws-portal.amazon.com/gp/aws/developer/account/index.html?action=access-key

	API Reference:http://docs.amazonwebservices.com/AWSEC2/latest/APIReference/query-apis.html
	

.EXAMPLE	
	powershell.exe .\mon-windows-services.ps1 -service_name_filter 'my company*;MSMQ;SQL*;'
.EXAMPLE	
	powershell.exe .\mon-windows-services.ps1 -aws_credential_file C:\awscreds.conf -service_name_filter 'my company*;MSMQ;SQL*;' -from_scheduler -logfile C:\mylogfile.log

#>
[CmdletBinding(DefaultParametersetName="credsfromfile", supportsshouldprocess = $true) ]
param(
[string]$service_name_filter = "%",
[switch]$from_scheduler,
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_access_id = "",
[Parameter(Parametersetname ="credsinline",mandatory=$true)]
[string]$aws_secret_key = "",
[Parameter(Parametersetname ="credsfromfile")]
[string]$aws_credential_file = [Environment]::GetEnvironmentVariable("AWS_CREDENTIAL_FILE"),
[string]$logfile = $null,
[Switch]$version
)



$ErrorActionPreference = 'Stop'

### Initliaze common variables ###
$accountinfo = New-Object psobject
$wc = New-Object Net.WebClient
$time = Get-Date
[string]$aaid =""
[string]$ask =""
$invoc = (Get-Variable myinvocation -Scope 0).value
$currdirectory = Split-Path $invoc.mycommand.path
$scriptname = $invoc.mycommand.Name
$ver = '1.0.0'
$client_name = 'CloudWatch-PutInstanceDataWindows'
$useragent = "$client_name/$ver"

### Logs all messages to file or prints to console based on from_scheduler setting. ###
function report_message ([string]$message)
{
	if($from_scheduler)
	{	if ($logfile.Length -eq 0 )
		{
			$logfile = $currdirectory +"\" +$scriptname.replace('.ps1','.log')
		}
		$message | Out-File -Append -FilePath $logfile
	}
	else
	{
		Write-Host $message
	}
}

### Global trap for all exceptions for this script. All exceptions will exit the script.###
trap [Exception] {
report_message ($_.Exception.Message)
Exit
}
if ($version)
{
 report_message "$scriptname version $ver"
 exit 
}
####Test and load AWS sdk 
$ProgFilesLoc = (${env:ProgramFiles(x86)}, ${env:ProgramFiles} -ne $null)[0]
$SDKLoc = "$ProgFilesLoc\AWS SDK for .NET\bin\Net35"

if ((Test-Path -PathType Container -Path $SDKLoc) -eq $false) {
    $SDKLoc = "C:\Windows\Assembly"
}

$SDKLibraryLocation = dir $SDKLoc -Recurse -Filter "AWSSDK.dll"
if ($SDKLibraryLocation -eq $null)
{
	throw "Please Install .NET sdk for this script to work."
}
else 
{
	$SDKLibraryLocation = $SDKLibraryLocation.FullName
	Add-Type -Path $SDKLibraryLocation
	Write-Verbose "Assembly Loaded"
}

### Process parameterset for credentials and adds them to a powershell object ###
switch ($PSCmdlet.Parametersetname)
{
	"credsinline" {
					Write-Verbose "Using credentials passed as arguments"
					
					if (!($aws_access_id.Length -eq 0 )) 
						{
							$aaid = $aws_access_id
						}
					else
						{
							throw ("Value of AWS access key id is not specified.")
						}
						
						if (!($aws_secret_key.Length -eq 0 ))
							{
								$ask = $aws_secret_key
							}
						else
							{
								throw "Value of AWS secret key is not specified."
							}
					}
	"credsfromfile"{
					
					if ( Test-Path $aws_credential_file)
						{
							Write-Verbose "Using AWS credentials file $aws_credential_file"
							Get-Content $aws_credential_file | ForEach-Object { 
															if($_ -match '.*=.*'){$text = $_.split("=");
															switch ($text[0].trim())
															{
																"AWSAccessKeyId" 	{$aaid= $text[1].trim()}
																"AWSSecretKey" 		{ $ask = $text[1].trim()}
															}}}
						}
						else {throw "Failed to open AWS credentials file $aws_credential_file"}
					}	
}
if (($aaid.length -eq 0) -or ($ask.length -eq 0))
{
	throw "Provided incomplete AWS credential set"
}
else 
{
	
	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSSecretKey" -value $ask
	Add-Member -membertype noteproperty -inputobject $accountinfo -name "AWSAccessKeyId" -value $aaid 
	Remove-Variable ask; Remove-Variable aaid
}
### Check if service_name_filter is specified to filter windows services.###
if ( !$service_name_filter)
{
	throw "Please specify a service name filter, e.g. 'my company*;MSMQ;SQL*;' , to monitor windows services" 
}

### Avoid a storm of calls at the beginning of a minute.###
if ($from_scheduler)
{
	$rand = new-object system.random
	start-sleep -Seconds $rand.Next(20)
}

### Functions that interact with metadata to get data required for dimenstion calculation and endpoint for cloudwatch api. ###
function get-metadata {
	$extendurl = $args
	$baseurl = "http://169.254.169.254/latest/meta-data"
	$fullurl = $baseurl + $extendurl
	return ($wc.DownloadString($fullurl))
}

function get-region {
	$az = get-metadata("/placement/availability-zone")
	return ($az.Substring(0, ($az.Length -1)))
}

function get-endpoint {
	$region = get-region
	return "https://monitoring." + $region + ".amazonaws.com/"
}

### Function that creates metric data which will be added to metric list that will be finally pushed to cloudwatch. ###
function append_metric   {
	$metricdata = New-Object Amazon.Cloudwatch.Model.MetricDatum
	$metricdata.metricname, $metricdata.Unit, $metricdata.value, $metricdata.Dimensions = $args
	$metricdata.Timestamp = $time.ToUniversalTime()
	return $metricdata
}

### Function that gets stopped windows services using WMI
function get-stopped-windows-services {
 begin {}
 process {
			### create string array with wildcards
			[string[]]$service_name_filters = $service_name_filter.Split(';',[System.StringSplitOptions]::RemoveEmptyEntries)
			Write-Verbose ("Finding Windows Services that are Auto / Stopped / " + $service_name_filter)
			Write-Verbose ("service_name_filters: " + $service_name_filters)

			### get all windows services that are in 'Stopped' state and are set as 'Auto' start
			$stopped_windows_services = @{}
			###gwmi Win32_Service -Filter {Name LIKE '$service_name_filter' AND StartMode='Auto' AND State='Stopped'} | ForEach-Object{$stopped_windows_services[$_.Name]=$_.State}
			###gwmi Win32_Service -Filter {StartMode='Auto' AND State='Stopped'} | Where-Object {$_.Name -like $service_name_filter} | ForEach-Object{$stopped_windows_services[$_.Name]=$_.State}
			gwmi Win32_Service -Filter {StartMode='Auto' AND State='Stopped'} | ForEach-Object{$stopped_windows_services[$_.Name]=$_.State}

			### expand the wildcards into a second string array with the full matching names from the items we wanted to match against
			$expanded = $service_name_filters |
				Select-Object @{ Name="ExpandedItem"; Expression={ $stopped_windows_services -Like $_ }} |
				Select-Object -ExpandProperty ExpandedItem -Unique
			### look for objects with certain properties
			$stopped_windows_services | Where-Object { $_ -in $expanded }
			Write-Verbose ("WindowsServicesStopped Count1=" + $stopped_windows_services.count)
	
			write $stopped_windows_services
 		}
 end{}
}

### Function that writes metrics to be piped to next fucntion to push to cloudwatch
function create-metriclist {
 param (
  		[parameter(Valuefrompipeline=$true)] $stopped_windows_services)
 begin{
 			$dims = New-Object Amazon.Cloudwatch.Model.Dimension
			$dims.Name = "InstanceId"
			$dims.value = get-metadata("/instance-id")
			$dimlist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.Dimension]
			$dimlist.Add($dims)
		}
 process{
			if ($service_name_filter) {
				write (append_metric "WindowsServicesStopped" "Count" ("{0:N2}" -f ([long]($stopped_windows_services.count))) $dimlist)
			}
 		}
 end{}
}
 
### Uses AWS sdk to push metrics to cloudwatch. This finally prints a requestid
function put-instancemem {
 param (
  		[parameter(Valuefrompipeline=$true)] $metlist)
 begin{
 		$cwconfig = New-Object Amazon.CloudWatch.AmazonCloudWatchConfig
		$cwconfig.serviceURL = get-endpoint
		$cwconfig.UserAgent = $useragent
		$monputrequest  = new-object Amazon.Cloudwatch.Model.PutMetricDataRequest
		$response = New-Object psobject
		$metricdatalist = New-Object Collections.Generic.List[Amazon.Cloudwatch.Model.MetricDatum]
		
	}
 process{
 			if ($PSCmdlet.shouldprocess($metlist.metricname,"The metric data "+$metlist.value.tostring() +" "+ $metlist.unit.tostring()+" will be pushed to cloudwatch")){
				$metricdatalist.add($metlist)
				Write-Verbose ("Metricname= " +$metlist.metricname+" Metric Value= "+ $metlist.value.tostring()+" Metric Units= "+$metlist.unit.tostring())
			}
 		}
 end{
 		$monputrequest.namespace = "System/Windows" 
		if ($metricdatalist.count -gt 0 ) {
				$cwclient = New-Object Amazon.Cloudwatch.AmazonCloudWatchClient($accountinfo.AWSAccessKeyId,$accountinfo.AWSSecretKey,$cwconfig)
				$monputrequest.metricdata = $metricdatalist
				$monresp =  $cwclient.PutMetricData($monputrequest)
				Add-Member -Name "RequestId" -MemberType NoteProperty -Value $monresp.ResponseMetadata.RequestId -InputObject $response
			}
			else {throw "No metric data to push to CloudWatch exiting script" }
		Write-Verbose ("RequestID: " +  $response.RequestId)
 	}
}
 
### Pipelined call of functions that pushes metrics to cloudwatch
get-stopped-windows-services | create-metriclist | put-instancemem
 