# **Provider Onboarding Pre-requisites**

## Clone the Repository

```shell
git clone https://github.com/Azure/Azure-Monitor-for-SAP-solutions-preview.git
```

<br>

# Prometheus OS Provider Onboarding

Before creating Prometheus OS Provider we need to install node exporter on the Machine.
The below powershell commands will install the node exporter version 1.3.1 on all the virtual machines that you pass in the parameter.

```text
NOTE : Change the working directory and open Azure Monitor for SAP Solutions folder.
```

Execute the below script in powershell terminal, this script executes a bash script on all the virtual machines mentioned in the array and tries to install the node exporter and unblock the port 9100.

``` shell
# enter the virtual machine names.
$vmDetails = "<virtual machine 1>", "<virtual machine 2>"

# enter subscription id guid.
$subscriptionId = "<subscription id>"

# enter resource group name.
$resourceGroup = "<resource group name>"

$command = ".\Provider_Pre_Requisites\Prometheus_OS_Pre_Requisites\Prometheus_OS_Script.ps1 -vmDetails $vmDetails -subscriptionId $subscriptionId -resourceGroup $resourceGroup";
Invoke-Expression $command
```

<br>

Once the script completes you can test the node exporter by make a curl request to the ip address of the virtual machine.

```bash
curl http://<IP Address>:9100/metrics
```

<br>

## Setting up cron job to start Node exporter on VM restart

In case you Virtual machine restarts the node exporter will stop, to make the node exporter start automatically when the virtual machine reboots refer the below link to setup a cron job that starts the node exporter.
<https://learn.microsoft.com/en-us/azure/sap/monitor/provider-linux#setting-up-cron-job-to-start-node-exporter-on-vm-restart>

<br>
<br>

# Prometheus HA Cluster Provider Onboarding

Before creating Prometheus HA Cluster Provider we need to install node exporter on the Machine.
The below powershell commands will install the ha cluster node exporter on all the virtual machines that you pass in the parameter.

```text
NOTE : Change the working directory and open Azure Monitor for SAP Solutions folder.
```

Execute the below script in powershell terminal, this script executes a bash script on all the virtual machines mentioned in the array and tries to install the node exporter and unblock the port 44322 for RHEL systems and 9664 for SUSE Linux.

``` shell
# enter the virtual machine names.
$vmDetails = "<virtual machine 1>", "<virtual machine 2>"

# enter subscription id guid.
$subscriptionId = "<subscription id>"

# enter resource group name.
$resourceGroup = "<resource group name>"

$command = ".\Provider_Pre_Requisites\Prometheus_HA_Cluster_Pre_Requisites\Prometheus_HA_Script.ps1 -vmDetails $vmDetails -subscriptionId $subscriptionId -resourceGroup $resourceGroup";
Invoke-Expression $command
```

<br>

Once the script completes you can test the ha cluster node exporter by make a curl request to the ip address of the virtual machine.

``` shell
# for SUSE Linux
curl http://<IP Address>:9664/metrics

# for RHEL
curl http://<IP Address>:44322/metrics
```

<br>

# SAP Netweaver Provider Onboarding

Before creating SAP Netweaver Provider, please have a look at the nelow link to completer the configuration from SAP Control: <https://learn.microsoft.com/en-us/azure/sap/monitor/provider-netweaver>. Once these steps are complete run the below script which will restart the SAPStartSRV service on each instance in the SAP system.

```text
NOTE : Restarting the services doesn't restart the entire system. This process only restarts SAPStartSRV on Windows or the daemon process in Linux.
```

```text
NOTE : Before executing the below query, please navigate to Provider_Pre_Requisites\SAP_NetWeaver_Pre_Requisites\Netweaver_Restart_Service.sh and update the instance number for your System.
```


``` shell
# enter the virtual machine names.
$vmDetails = "<virtual machine 1>", "<virtual machine 2>"

# enter subscription id guid.
$subscriptionId = "<subscription id>"

# enter resource group name.
$resourceGroup = "<resource group name>"

$command = ".\Provider_Pre_Requisites\SAP_NetWeaver_Pre_Requisites\Netweaver_Restart_Script.ps1 -vmDetails $vmDetails -subscriptionId $subscriptionId -resourceGroup $resourceGroup";
Invoke-Expression $command
```

<br>

