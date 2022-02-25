# Azure Monitor for SAP solutions

Onboarding Guide

## What is Azure Monitor for SAP solutions?

Azure Monitor for SAP Solutions (AMS) is an Azure-native monitoring product for anyone running their SAP landscapes on Azure. It works with both SAP on Azure Virtual Machines and SAP on Azure Large Instances.

With Azure Monitor for SAP Solutions, you can collect telemetry data from Azure infrastructure and databases in one central location and visually correlate the data for faster troubleshooting.

You can monitor different components of an SAP landscape like SAP HANA database, SAP NetWeaver, and so on, by adding the corresponding provider for that component.

Azure Monitor for SAP Solutions uses the Azure Monitor capabilities of Log Analytics and Workbooks. With it, you can:

- Create custom visualizations by editing the default Workbooks provided by Azure Monitor for SAP Solutions.
- Write custom queries.
- Create custom alerts by using Azure Log Analytics workspace.
- Take advantage of the flexible retention period in Azure Monitor Logs/Log Analytics.
- Connect monitoring data with your ticketing system.

## How does it work?

![](RackMultipart20220225-4-1roua5j_html_5d7ece1732f2485f.png)

##

Once setup, Azure monitor for SAP solutions provisions azure function instance along with a managed resource group ( which contains azure log analytics, Azure Key vault , storage queue and other azure resources). And after monitor setup, different providers can be created to pull data form SAP components.

## Supported Regions

Azure monitor for SAP solutions preview will be available following regions:

- US
  - Central US
  - East US
  - East US 2
  - East US 3
  - North Central US
  - South Central US
  - West Central US
  - West US
  - West US 2
  - West US 3
- Europe –
  - North Europe
  - West Europe
- Australia and India (by April,22)

## Supported Scenarios

The following scenarios are supported in Azure Monitor for SAP solutions preview:

- Create AMS Monitor
- Create NetWeaver Provider
- Create HANA Provider
- Set Alerts for NetWeaver and HANA providers

The following providers will be available at later stages of preview. Please add these providers when available.

- Linux OS Provider (March)
- DB2 Provider (April)
- HA Provider (May)
- SQL Provider (May)

##

## What data is collected by providers ?

Data collection in Azure Monitor for SAP Solutions depends on the providers that you configure. During private preview, the following data is collected.

**SAP HANA telemetry:**

You can configure one or more providers of provider type SAP HANA to enable data collection from SAP HANA database. The SAP HANA provider connects to the SAP HANA database over SQL port, pulls telemetry data from the database, and pushes it to the Log Analytics workspace in your subscription. The SAP HANA provider collects data every 1 minute from the SAP HANA database.

In public preview, you can expect to see the following data with the SAP HANA provider:

- CPU, memory, disk, and network use
- HANA system replication (HSR)
- HANA backup
- HANA host status
- Index server and name server roles
- Database growth
- Top tables
- File system use
- Multi Version Concurrency Contro
- HANA IO SavePoint Count
- Delta Merge
- License Status and
- Statistic Alerts

**SAP NetWeaver telemetry:**

You can configure one or more providers of provider type SAP NetWeaver to enable data collection from SAP NetWeaver layer. AMS NetWeaver provider uses the existing SAPControl Web service interface to retrieve the appropriate telemetry information.

For the current release, the following SOAP web methods are the standard, out-of-box methods invoked by AMS.

![](RackMultipart20220225-4-1roua5j_html_85c348750269b9a5.png)

In public preview, you can expect to see the following data with the SAP NetWeaver provider:

- System and instance availability
- Work process usage
- Queue usage
- Enqueue lock statistics

Prerequisites

- Please ensure that your Azure Subscription is whitelisted, and you can use preview service. Please reach out to &quot;\*\*\*\*\*&quot; to get your subscription whitelisted.
- Register with New RP –
- AMS requires an unused subnet that&#39;s an IPv4/28 block or larger in an Azure Resource Manager virtual network. Please refer [this](https://docs.microsoft.com/en-us/azure/app-service/overview-vnet-integration) article for more details.

## Quick Start – Create AMS Monitor

![](RackMultipart20220225-4-1roua5j_html_1c15ff4116a7ba12.png)

## Quick Start – Create a provider

**NetWeaver Provider**

Prerequisites

To fetch specific metrics, you need to unprotect some methods for the current release. Follow these steps for each SAP system:

1. Open an SAP GUI connection to the SAP server.
2. Sign in by using an administrative account.
3. Execute transaction RZ10.
4. Select the appropriate profile (_DEFAULT.PFL_).
5. Select  **Extended Maintenance**  \&gt;  **Change**.
6. Select the profile parameter &quot;service/protectedwebmethods&quot; and modify to have the following value, then click Copy:

service/protectedwebmethodsCopy

SDEFAULT -GetQueueStatistic -ABAPGetWPTable -EnqGetStatistic -GetProcessList

1. Go back and select  **Profile**  \&gt;  **Save**.
2. After saving the changes for this parameter, please restart the SAPStartSRV service on each of the instances in the SAP system. (Restarting the services will not restart the SAP system; it will only restart the SAPStartSRV service (in Windows) or daemon process (in Unix/Linux)) 8a. On Windows systems, this can be done in a single window using the SAP Microsoft Management Console (MMC) / SAP Management Console(MC). Right-click on each instance and choose All Tasks -\&gt; Restart Service.  ![](RackMultipart20220225-4-1roua5j_html_125bf40fdc1672bb.png)

8b. On Linux systems, use the below command where NN is the SAP instance number to restart the host which is logged into.

RestartServiceCopy

sapcontrol -nr \&lt;NN\&gt; -function RestartService

1. Once the SAP service is restarted, please check to ensure the updated web method protection exclusion rules have been applied for each instance by running the following command:

**Logged as \&lt;sidadm\&gt;**  sapcontrol -nr \&lt;NN\&gt; -function ParameterValue service/protectedwebmethods

**Logged as different user**  sapcontrol -nr \&lt;NN\&gt; -function ParameterValue service/protectedwebmethods -user &quot;\&lt;adminUser\&gt;&quot; &quot;\&lt;adminPassword\&gt;&quot;

The output should look like :-  ![](RackMultipart20220225-4-1roua5j_html_da7e47bc2510f4dc.png)

1. To conclude and validate, a test query can be done against web methods to validate ( replace the hostname , instance number and method name ) leverage the below powershell script

PowershellCopy

$SAPHostName = &quot;\&lt;hostname\&gt;&quot;

$InstanceNumber = &quot;\&lt;instancenumber\&gt;&quot;

$Function = &quot;ABAPGetWPTable&quot;

[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$sapcntrluri = &quot;https://&quot; + $SAPHostName + &quot;:5&quot; + $InstanceNumber + &quot;14/?wsdl&quot;

$sapcntrl = New-WebServiceProxy -uri $sapcntrluri -namespace WebServiceProxy -class sapcntrl

$FunctionObject = New-Object ($sapcntrl.GetType().NameSpace + &quot;.$Function&quot;)

$sapcntrl.$Function($FunctionObject)

1. \*\*Repeat Steps 3-10 for each instance profile \*\*.

  **Important**

It is critical that the sapstartsrv service is restarted on each instance of the SAP system for the SAPControl web methods to be unprotected. These read-only SOAP API are required for the NetWeaver provider to fetch metric data from the SAP System and failure to unprotect these methods will lead to empty or missing visualizations on the NetWeaver metric workbook.

**Add SAP NetWeaver Provider Steps (Using Portal UI):**

1. Click on the Providers Tab in the left column of the AMS Resource Page, then click on &quot;Add&quot; button to go to the &quot;Add Provider&quot; Page
 ![](RackMultipart20220225-4-1roua5j_html_ea678cc2f23a9faa.png)

1. Select Type as SAP NetWeaver
 ![](RackMultipart20220225-4-1roua5j_html_67aa4cdc13006d05.png)

1. System ID (SID)- Provide the unique SAP system identifier which is a three-character identifier of an SAP system.
2. Application Server- Provide the IP address or the fully qualified domain name (FQDN) of the SAP NetWeaver system to be monitored. For example - sapservername.contoso.com where sapservername is the hostname and contoso.com is the subdomain. When using a hostname, please ensure connectivity from within the similar vnet which you used while creating the AMS resource.
3. Instance Number- Specify the instance number of the SAP NetWeaver [00-99]
4. Host file Entries- In case the SAP system is using virtual hostnames, enter the host file mappings, each comma separated, in the format [IP HOSTNAME FQDN].
 For example: 192.X.X.X sapservername sapservername.contoso.com,192.X.X.X sapservername2 sapservername2.contoso.com.

**HANA Provider**

**Add SAP HANA Provider Steps (Using Portal UI):**

1. Click on the Providers Tab in the left column of the AMS Resource Page, then click on &quot;Add&quot; button to go to the &quot;Add Provider&quot; Page
 ![](RackMultipart20220225-4-1roua5j_html_ea678cc2f23a9faa.png)

1. Select Type as SAP HANA
 ![](RackMultipart20220225-4-1roua5j_html_4246064950895182.png)

1. IP address- Prov the IP address or hostname of the server running the SAP HANA instance to be monitored; when using a hostname, please ensure connectivity from within the Vnet.
2. Database tenant- Provider the HANA database to connect against (we strongly recommend using SYSTEMDB, since tenant databases don&#39;t have all monitoring views). Leave this field blank for legacy single-container HANA 1.0 instances.
3. SQL port- For MDC HANA instances, provider the port as 3xx15; for legacy single-container HANA instances, enter the port as port 3xx13 (with xx being the SAP HANA instance number).
4. Database username- Provide the dedicated SAP HANA database user with MONITORING role assigned (alternatively, use SYSTEM for non-production SAP HANA instances)
5. Database password- Provide the password corresponding to the database username.

## Quick Start – Create Monitor using PowerShell

## Known Issues

## Support Model

Mention what are we going to give and what are we expecting from customers?
