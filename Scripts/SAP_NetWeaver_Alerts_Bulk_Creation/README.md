# **NetWeaver Alerts Bulk Creation**

## Clone the Repository

```shell
git clone https://github.com/Azure/Azure-Monitor-for-SAP-solutions-preview.git
```

## Prerequisites
- Either have Azure PowerShell locally installed (https://learn.microsoft.com/powershell/azure/install-azure-powershell), or use Azure Cloud Shell (https://learn.microsoft.com/azure/cloud-shell/overview)
- Connect to your Azure account using the Connect-AzAccount (https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount) cmdlet.
- Make sure you have at least contributor role on the Azure Monitor for SAP solutions resource and the associated managed Resource Group.

## Usage
- Open NetweaverAlertsBulkCreation.ps1 with a text editor. Set the following variables related to your Azure Monitor for SAP solutions resource at the top of the script: *subscriptionId*, *tenantId*, *rgName*, *amsResourceName*. Also, set the *alertSuppressionInMinutes* variable to the amount of time to wait before alerting again (by default it is 0).
- Set the *actionGroupResourceId* variable to the resource ID of the action group you want to use for the alerts. For getting the resource ID of an action group from the portal, follow these steps:
    - Go to the Azure portal and navigate to the Alerts resource page.
    - Click on Action groups in the command bar at the top.
    - Navigate to the action group you want to use and click on it.
    - Click on JSON view and copy the Resource ID.
- Navigate to the directory where the script is located and execute it - `.\NetweaverAlertsBulkCreation.ps1`. The script automatically installs the required PowerShell modules. Agree to the prompts to install the modules in case they are not already installed.
- The script will through all the NetWeaver providers created under your AMS resource and set up the pre-configured alerts. Review the ALERTS_CONFIG variable to see the alerts that will be created. Edit/Remove any alerts as per your requirements.
- Some alerts require an additional Aggregate input. The available values will be output as a table. Please copy and enter one of these values when prompted. You can also enter `skip` to skip the creation of that particular alert.
- The alerts will be created in the managed RG associated with your AMS resource. Verify that they are created successfully after the script completes execution.

## Resources
- https://learn.microsoft.com/powershell/azure/install-azure-powershell
- https://learn.microsoft.com/azure/cloud-shell/overview
- https://learn.microsoft.com/powershell/module/az.accounts/connect-azaccount
