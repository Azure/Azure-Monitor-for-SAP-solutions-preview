param(
    [Parameter(Mandatory=$true)][string]$SubscriptionId,
    [Parameter(Mandatory=$true)][string]$RgName,
    [Parameter(Mandatory=$true)][string]$AmsResourceName,
    [Parameter(Mandatory=$true)][string]$ActionGroupResourceId
)

$ALERTS_CONFIG = @"
[
    {
        "name": "[SOAP] SAP Netweaver System Availability",
        "description": "Fired when SAP NetWeaver Message Server is not available or all servers are not available.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-system-availability",
        "severity": "1",
        "alertTemplate": {
            "query": "let TotalInstanceAvailability = SapNetweaver_GetSystemInstanceList_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | extend Status = iff(dispstatus_s == 'SAPControl-GREEN', 1, 0) | summarize available=countif(Status == 1), total=count() by PROVIDER_INSTANCE_s, serverTimestamp_t;TotalInstanceAvailability | join kind = leftouter SapNetweaver_GetSystemInstanceList_CL on `$left.PROVIDER_INSTANCE_s == `$right.PROVIDER_INSTANCE_s and `$left.serverTimestamp_t == `$right.serverTimestamp_t | extend Status = iff(dispstatus_s == 'SAPControl-GREEN', 1, 0) | extend ServiceStatus = iff(available == 0, 0, iff(features_s contains 'MESSAGESERVER' and Status == 0, 0, 1)), AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | summarize AggregatedValue = min(ServiceStatus) by bin(TimeGenerated, 1m), PROVIDER_INSTANCE_s, AppServer, dispstatus_s, serverTimestamp_t, features_s | where AggregatedValue == 0",
            "thresholdOperator": "LessThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "1",
                "metricTriggerType": "Consecutive",
                "metricColumn": "PROVIDER_INSTANCE_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SOAP] SAP Netweaver Instance Availability",
        "description": "Fired when SAP Netweaver ABAP, J2EE, JEE instances are not available.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-instance-availability",
        "severity": "2",
        "alertTemplate": {
            "query": "let TotalInstanceAvailability = SapNetweaver_GetSystemInstanceList_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | extend Status = iff(dispstatus_s == 'SAPControl-GREEN', 1, 0) | summarize available=countif(Status == 1), total=count() by PROVIDER_INSTANCE_s, serverTimestamp_t; TotalInstanceAvailability | join kind = leftouter SapNetweaver_GetSystemInstanceList_CL on `$left.PROVIDER_INSTANCE_s == `$right.PROVIDER_INSTANCE_s and `$left.serverTimestamp_t == `$right.serverTimestamp_t | where features_s contains 'J2EE' or features_s contains 'JEE' or features_s contains 'ABAP' | extend InstanceStatus = iff(available != 0 and dispstatus_s == 'SAPControl-GREEN', 1, 0), AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | summarize AggregatedValue = min(InstanceStatus) by bin(TimeGenerated, 1m), PROVIDER_INSTANCE_s, AppServer, dispstatus_s, serverTimestamp_t, features_s | where AggregatedValue == 0",
            "thresholdOperator": "LessThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "1",
                "metricTriggerType": "Consecutive",
                "metricColumn": "PROVIDER_INSTANCE_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SOAP] SAP Netweaver EnqueueServer Availability",
        "description": "Fired when SAP Netweaver EnqueueServer is not available.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-enqueue-server",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_GetProcessList_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' and description_s contains 'EnqueueServer' | extend Status = iff(dispstatus_s == 'SAPControl-GREEN', 1, 0), AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | summarize AggregatedValue = min(Status) by bin(TimeGenerated, 1m), PROVIDER_INSTANCE_s, AppServer, dispstatus_s, description_s, serverTimestamp_t | where AggregatedValue == 0",
            "thresholdOperator": "LessThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "1",
                "metricTriggerType": "Consecutive",
                "metricColumn": "PROVIDER_INSTANCE_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SOAP] SAP Netweaver EnqueueReplicationServer Availability",
        "description": "Fired when SAP Netweaver EnqueueReplicationServer is not available.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-enqueue-replicator-server",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_GetProcessList_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' and description_s contains 'EnqueueReplicator' | extend Status = iff(dispstatus_s == 'SAPControl-GREEN', 1, 0), AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | summarize AggregatedValue = min(Status) by bin(TimeGenerated, 1m), PROVIDER_INSTANCE_s, AppServer, dispstatus_s, description_s, serverTimestamp_t | where AggregatedValue == 0",
            "thresholdOperator": "LessThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "1",
                "metricTriggerType": "Consecutive",
                "metricColumn": "PROVIDER_INSTANCE_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SOAP] SAP Netweaver Instance Work Process Utilization",
        "description": "Fired when SAP Netweaver Instance with DIA or BTC Usage breaches specified threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-instance-work-process-utilization",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_ABAPGetWPTable_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where Typ_s has '{Aggregate}' | summarize totalWP = count(), freeWP = countif(Status_s == 'Wait') by TimeGenerated, Typ_s, serverTimestamp_t, AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | extend UtilizationPctWP = round(toreal(totalWP - freeWP) / toreal(totalWP) * 100, 3) | summarize AggregatedValue = max(UtilizationPctWP) by bin(TimeGenerated, 1m), AppServer, Typ_s, serverTimestamp_t | where AggregatedValue > {AlertThreshold}",
            "aggregateName": "WorkType",
            "aggregateDropDownQuery": "SapNetweaver_ABAPGetWPTable_CL | where Typ_s has 'DIA' or Typ_s has 'BTC' | distinct Typ_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "70",
            "alertUnit": "percent",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "2",
                "metricTriggerType": "Consecutive",
                "metricColumn": "AppServer",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SOAP] SAP Netweaver Instance Queue Wait",
        "description": "Fired when SAP Netweaver Instance with DIA or BTC Queue Wait breaches specified threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-instance-queue-wait",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_GetQueueStatistic_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where Typ_s has '{Aggregate}' | summarize QueueLimit=max(Max_d)/7 by hostname_s, instanceNr_d, Typ_s, serverTimestamp_t, Now_d, TimeGenerated | extend QueueWaitPct = iff(QueueLimit != 0, (toreal(Now_d) / toreal(QueueLimit)) * 100, 0.0), AppServer = strcat(hostname_s, '_', tostring(toint(instanceNr_d))) | summarize AggregatedValue = max(QueueWaitPct) by bin(TimeGenerated, 1m), AppServer, Typ_s, serverTimestamp_t | where AggregatedValue > {AlertThreshold}",
            "aggregateName": "WorkType",
            "aggregateDropDownQuery": "SapNetweaver_GetQueueStatistic_CL | where Typ_s has 'DIA' or Typ_s has 'BTC' | distinct Typ_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "5",
            "alertUnit": "percent",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "2",
                "metricTriggerType": "Consecutive",
                "metricColumn": "AppServer",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SMON] SAP Netweaver Memory Utilization",
        "description": "Fired when the memory utilization reaches a threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-memory-utilization",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SMON_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | summarize AggregatedValue = avg(FREE_MEM_PERC_d) by hostname_s, bin(TimeGenerated, 1m) | where AggregatedValue < {AlertThreshold}",
            "thresholdOperator": "LessThan",
            "defaultThreshold": "20",
            "alertUnit": "percent",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "hostname_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SMON] SAP Netweaver CPU System Utilization",
        "description": "Fired when CPU system utilization reaches a threshold value.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-cpu-system-utilization",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SMON_CL| where PROVIDER_INSTANCE_s == '{ProviderInstance}' | extend TOTAL_CPU = (100 - IDLE_TOTAL_d)| summarize AggregatedValue = avg(TOTAL_CPU) by bin(TimeGenerated, 30m),SYS_TOTAL_d, hostname_s | where AggregatedValue > {AlertThreshold} ",
            "aggregateName": "SystemCPUUtilization",
            "aggregateDropDownQuery": "SapNetweaver_SMON_CL| where isnotempty(hostname_s)| distinct hostname_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "severity",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "hostname_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SMON] SAP Netweaver CPU User Utilization",
        "description": "Fired when CPU user utilization reaches a threshold value.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-cpu-user-utilization",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SMON_CL| where PROVIDER_INSTANCE_s == '{ProviderInstance}' | extend TOTAL_CPU = (100 - IDLE_TOTAL_d)| summarize AggregatedValue = avg(TOTAL_CPU) by bin(TimeGenerated, 30m),USR_TOTAL_d, hostname_s | where AggregatedValue > {AlertThreshold} ",
            "aggregateName": "UserCPUUtilization",
            "aggregateDropDownQuery": "SapNetweaver_SMON_CL| where isnotempty(hostname_s)| distinct hostname_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "severity",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "hostname_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SMQ1] SAP Netweaver Outbound Queue length more than threshold",
        "description": "Fired when a desired outbound queue is active and length is greater than equal to the threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-outbound-queue-length",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_OutboundQueues_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where QNAME_s has '{Aggregate}' | summarize AggregatedValue  = max(QDEEP_d) by QNAME_s, bin(TimeGenerated, 1m) | where AggregatedValue > {AlertThreshold}",
            "aggregateName": "QNAME",
            "aggregateDropDownQuery": "SapNetweaver_OutboundQueues_CL | distinct QNAME_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "5",
            "alertUnit": "count",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "2",
                "metricTriggerType": "Consecutive",
                "metricColumn": "QDEEP_d",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SMQ2] SAP Netweaver Inbound Queue length more than threshold",
        "description": "Fired when a desired inbound queue is active and length is greater than equal to the threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-inbound-queue-length",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_InboundQueues_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where QNAME_s has '{Aggregate}' | summarize AggregatedValue  = max(QDEEP_d) by QNAME_s, bin(TimeGenerated, 1m) | where AggregatedValue > {AlertThreshold}",
            "aggregateName": "QNAME",
            "aggregateDropDownQuery": "SapNetweaver_InboundQueues_CL | distinct QNAME_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "5",
            "alertUnit": "count",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "2",
                "metricTriggerType": "Consecutive",
                "metricColumn": "QDEEP_d",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SM12] SAP Netweaver Enqueue Entry Volume",
        "description": "Fired when count of enqueue entries are more than the threshold value.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-enqueue-read-volume",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_EnqueueRead_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | summarize AggregatedValue = dcount(GARG_s) by GNAME_s, bin(TimeGenerated, 1m) | where AggregatedValue > {AlertThreshold}",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "5",
            "alertUnit": "count",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "2",
                "metricTriggerType": "Consecutive",
                "metricColumn": "GNAME_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    },
    {
        "name": "[SM12] SAP Netweaver Aging Enqueue Entries",
        "description": "Fired when a to enqueue entries are active for more than 1 day.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-enqueue-read-aging",
        "severity": "2",
        "alertTemplate": {
            "query": "let base = SapNetweaver_EnqueueRead_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where bin(now() - 1d, 1d) == bin(serverTimestamp_t, 1d) | summarize by GNAME_s, GARG_s, GTWP_s, bin(TimeGenerated, 1d); SapNetweaver_EnqueueRead_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where bin(now() - 60min, 1h) == bin(serverTimestamp_t, 1h) | join kind = inner base on GNAME_s | summarize by GNAME_s, GARG_s, GTWP_s, bin(TimeGenerated, 1d) | summarize AggregatedValue = count() by GNAME_s, bin(TimeGenerated, 1d) | where AggregatedValue > {AlertThreshold}",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "GNAME_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "2880"
            }
        }
    },
    {
        "name": "[SM13] SAP Netweaver Failed Updates",
        "description": "Fired when SAP Netweaver Instance has any type of failed updates.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-instance-failed-update-any",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_FailedUpdates_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | summarize AggregatedValue = count() by VBKEY_g, VBTCODE_s, VBREPORT_s, bin(TimeGenerated, 5m) | where AggregatedValue > {AlertThreshold}",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "1",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "VBKEY_g",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[ST22] SAP Netweaver Short Dump",
        "description": "Fired when SAP Netweaver Instance raises any type of short dump",
        "author": "Microsoft",
        "templateId": "sapnetweaver-instance-short-dump_any",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_ShortDumps_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | summarize AggregatedValue = count() by Runtime_Error_s, bin(TimeGenerated, 5m) | where AggregatedValue > {AlertThreshold}",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "2",
            "alertUnit": "count",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "metricTriggerType": "Consecutive",
                "metricColumn": "Runtime_Error_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "10"
            }
        }
    },
    {
        "name": "[SM21] SAP Netweaver Alert for a Specific Message ID And Severity Error",
        "description": "Fired when a desired inbound queue is active and length is greater than equal to the threshold.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-system-log-by-message-id",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SysLogs_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where Msg_area_Msd_Id_s has '{Aggregate}' | where toint(E2E_SEVERITY_s) > {AlertThreshold} | extend datevalue = format_datetime(serverTimestamp_t, 'dd-MM-yy') | extend timevalue = format_datetime(serverTimestamp_t, 'HH:mm:ss') | summarize AggregatedValue = count() by Msg_area_Msd_Id_s, instanceNr_s, Problem_Class_s, Application_Comp_s, Program_s, bin(TimeGenerated, 1h) | where AggregatedValue  > 0",
            "aggregateName": "MessageID",
            "aggregateDropDownQuery": "SapNetweaver_SysLogs_CL | distinct Msg_area_Msd_Id_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "severity",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "Msg_area_Msd_Id_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "1440"
            }
        }
    },
    {
        "name": "[SM21] SAP Netweaver Alert for a Specific User And Severity Error",
        "description": "Fired when a system log with severity is raised for a specific user.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-system-log-by-user",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SysLogs_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | where E2E_USER_s has '{Aggregate}' | where toint(E2E_SEVERITY_s) > {AlertThreshold} | extend datevalue = format_datetime(serverTimestamp_t, 'dd-MM-yy') | extend timevalue = format_datetime(serverTimestamp_t, 'HH:mm:ss') | summarize AggregatedValue = count() by E2E_USER_s, instanceNr_s, Problem_Class_s, Application_Comp_s, Program_s, bin(TimeGenerated, 1h) | where AggregatedValue  > 0",
            "aggregateName": "UserID",
            "aggregateDropDownQuery": "SapNetweaver_SysLogs_CL | distinct E2E_USER_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "severity",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "E2E_USER_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "1440"
            }
        }
    },
    {
        "name": "[SM37] SAP Netweaver Long Running Job",
        "description": "Fired when a job takes more than the threshold value.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-batch-job-jobname",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_BatchJobs_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | extend startdatetime = todatetime(strcat(STRTDATE_s,STRTTIME_s))| extend enddatetime = todatetime(strcat(ENDDATE_s,ENDTIME_s))| extend runtime = enddatetime - startdatetime| extend min = runtime / 1s | summarize AggregatedValue = countif(min > 600) by JOBNAME_s, bin(TimeGenerated, 1m) | where AggregatedValue > {AlertThreshold} ",
            "aggregateName": "JobName",
            "aggregateDropDownQuery": "SapNetweaver_BatchJobs_CL | where isnotempty(JOBNAME_s )| distinct JOBNAME_s",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "severity",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "JOBNAME_s",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "5"
            }
        }
    },
    {
        "name": "[ST03] SAP Netweaver High Response Time",
        "description": "Fired when the average response time reaches or exceeds the configured threshold value.",
        "author": "Microsoft",
        "templateId": "sapnetweaver-response-time",
        "severity": "2",
        "alertTemplate": {
            "query": "SapNetweaver_SWNC_CL | where PROVIDER_INSTANCE_s == '{ProviderInstance}' | summarize AggregatedValue = avg(ST03_Avg_Resp_Time_d) by bin(TimeGenerated, 30m) | where AggregatedValue > {AlertThreshold} ",
            "thresholdOperator": "GreaterThan",
            "defaultThreshold": "0",
            "alertUnit": "milliseconds",
            "metricMeasurement": {
                "thresholdOperator": "GreaterThan",
                "threshold": "0",
                "metricTriggerType": "Consecutive",
                "metricColumn": "",
                "frequencyInMinutes": "5",
                "timeWindowInMinutes": "30"
            }
        }
    }
]
"@ | ConvertFrom-Json

Install-Module -Name Az.Workloads
Install-Module -Name Az.OperationalInsights

Set-AzContext -Subscription $SubscriptionId

$monitor = Get-AzWorkloadsMonitor -ResourceGroupName $RgName -Name $AmsResourceName
$monitor.LogAnalyticsWorkspaceArmId -match "/subscriptions/(?<subscriptionId>.*)/resourcegroups/(?<laWorkspaceRgName>.*)/providers/microsoft.operationalinsights/workspaces/(?<laWorkspaceName>.*)" | Out-Null
$laWorkspaceRgName = $matches["laWorkspaceRgName"]
$laWorkspaceName = $matches["laWorkspaceName"]
$laWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $laWorkspaceRgName -Name $laWorkspaceName

$providers = Get-AzWorkloadsProviderInstance -ResourceGroupName $RgName -MonitorName $AmsResourceName
$netweaverProviders = $providers | Where-Object { $_.ProvisioningState -eq "Succeeded" -and $_.ProviderSetting.ProviderType -eq "SapNetWeaver" }
$selection = ""
if ($netweaverProviders.Count -gt 0) {
    Write-Host "Available providers:"
    for ($i = 0; $i -lt $netweaverProviders.Count; $i++) {
        Write-Host "$($i) - $($netweaverProviders[$i].Name)"
    }
    Write-Host "Select the provider indices to create alerts for (comma separated without spaces) or enter '*' to create alerts for all providers"
    $selection = Read-Host "Enter your choice (eg. 0,2,15)"
}
$selection = "," + $selection + ","
$selectedProviders = New-Object System.Collections.Generic.List[System.Object]
for ($i = 0; $i -lt $netweaverProviders.Count; $i++) {
    if ($selection -eq ",*," -or $selection.Contains(",$($i),")) {
        $selectedProviders.Add($netweaverProviders[$i])
    }
}
Write-Host "You have selected the following providers:"
foreach ($provider in $selectedProviders) {
    Write-Host $provider.Name
}
$confirmation = Read-Host "Enter 'Y' to confirm"
if ($confirmation -ne "Y") {
    Write-Host "Exiting..."
    Exit
}

foreach ($provider in $selectedProviders) {
    $providerName = $provider.Name
    Write-Host "Creating alerts for $($providerName)..."

    foreach ($alertConfig in $ALERTS_CONFIG) {
        Write-Host "Creating alert $($alertConfig.name)..."
        Write-Host "Alert description: $($alertConfig.description)"
        $query = $alertConfig.alertTemplate.query

        if ($aggregateName = $alertConfig.alertTemplate.PSObject.Properties.Item("aggregateName")) {
            $aggregateName = $alertConfig.alertTemplate.aggregateName
            $aggregateQuery = $alertConfig.alertTemplate.aggregateDropDownQuery
            $aggregateValue = "skip"
            $queryResult = Invoke-AzOperationalInsightsQuery -WorkspaceId $laWorkspace.CustomerId -Query $aggregateQuery -ErrorAction SilentlyContinue
            if ($queryResult) {
                Write-Host "Possible $($aggregateName) values:"
                $queryResult | Select-Object -ExpandProperty Results | Format-Table
                $aggregateValue = Read-Host "Choose a $($aggregateName) to use for the alert or enter 'skip' to skip this alert"
            } else {
                Write-Host "Required data related to $($aggregateName) was not found."
            }
            if ($aggregateValue -eq "skip") {
                Write-Host "Skipping alert $($alertConfig.name)..."
                continue
            }
            $query = $query.replace("{Aggregate}", $aggregateValue)
        }
        $query = $query.replace("{ProviderInstance}", $providerName)
        $query = $query.replace("{AlertThreshold}", $alertConfig.alertTemplate.defaultThreshold)
        $alertName = "[" + $providerName + "] " + $alertConfig.name

        $alertRule = Get-AzScheduledQueryRule -ResourceGroupName $monitor.ManagedResourceGroupConfigurationName -Name $alertName -ErrorAction SilentlyContinue
        if ($alertRule) {
            Write-Host "Alert '$($alertConfig.name)' already exists. Skipping..."
            continue
        }

        $template = @{
            "`$schema" = "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#"
            "contentVersion" = "1.0.0.0"
            "resources" = @(
                @{
                    "name" = $alertName
                    "type" = "Microsoft.Insights/scheduledQueryRules"
                    "apiVersion" = "2018-04-16"
                    "tags" = @{
                        "profile-id" = $providerName
                        "alert-template-id" = $alertConfig.templateId
                        "CreatedUsingAutomationScript" = $true
                    }
                    "location" = $laWorkspace.Location
                    "properties" = @{
                        "description" = $alertConfig.description
                        "enabled" = "true"
                        "autoMitigate" = $true
                        "source" = @{
                            "query" = $query
                            "dataSourceId" = $laWorkspace.ResourceId
                            "queryType" = "ResultCount"
                        }
                        "schedule" = @{
                            "frequencyInMinutes" = $alertConfig.alertTemplate.metricMeasurement.frequencyInMinutes
                            "timeWindowInMinutes" = $alertConfig.alertTemplate.metricMeasurement.timeWindowInMinutes
                        }
                        "action" = @{
                            "odata.type" = "Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.Microsoft.AppInsights.Nexus.DataContracts.Resources.ScheduledQueryRules.AlertingAction"
                            "severity" = $alertConfig.severity
                            "aznsAction" = @{
                                "actionGroup" = @(
                                    [Parameter(Mandatory=$true)][string]$ActionGroupResourceId
                                )
                                "emailSubject" = "[concat('Alert Triggered - ', '$alertName')]"
                            }
                            "trigger" = @{
                                "thresholdOperator" = $alertConfig.alertTemplate.thresholdOperator
                                "threshold" = $alertConfig.alertTemplate.defaultThreshold
                                "metricTrigger" = @{
                                    "thresholdOperator" = $alertConfig.alertTemplate.metricMeasurement.thresholdOperator
                                    "threshold" = $alertConfig.alertTemplate.metricMeasurement.threshold
                                    "metricColumn" = $alertConfig.alertTemplate.metricMeasurement.metricColumn
                                    "metricTriggerType" = $alertConfig.alertTemplate.metricMeasurement.metricTriggerType
                                }
                            }
                        }
                    }
                }
            )
            "outputs" = @{
                "scheduledQueryRules" = @{
                    "type" = "string"
                    "value" = "[resourceId('Microsoft.Insights/scheduledQueryRules', '$alertName')]"
                }
            }
        }

        New-AzResourceGroupDeployment -ResourceGroupName $monitor.ManagedResourceGroupConfigurationName -TemplateObject $template
    }
}
