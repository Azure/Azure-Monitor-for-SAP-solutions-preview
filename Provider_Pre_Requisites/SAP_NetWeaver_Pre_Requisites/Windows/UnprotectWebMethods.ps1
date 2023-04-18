#<summary>
# Unprotect the webmethods in default.pfl file and run restart service command in windows VM.
# </summary>
class UnprotectWebMethods 
{    
    [string]$filepath
    [string]$instance

    Invoke([string]$filepath,[string]$instance) 
    {
        #change drive to where default.pfl file is saved

        Write-Host "Filepath is" $filepath
        Write-Host "instance" $instance
        #change the script execution path to default.pfl file location

        # Set-Location $filepath
        $content = Get-Content $filepath
        #Write-Host $content

        # Read the file and filter the line with the service/protectedwebmethods value 
        $value = Get-Content $filepath | Where-Object { $_ -like "service/protectedwebmethods*" } 
        # Extract the value from the line
        $value = $value.Split("=")[1].Trim()
        # Output the value
        Write-Host "The service/protectedwebmethods value is: $value"
        $new_value = "service/protectedwebmethods = SDEFAULT -GetQueueStatistic -ABAPGetWPTable -EnqGetStatistic -GetProcessList"
        #update the default.pfl file SDEFAULT parameter to unprotect the SAP Webmethods
        $content = $content -replace "^(service/protectedwebmethods\s*=\s*).*", $new_value
        Set-Content $filepath $content
        # Output the updated value
        Write-Host "The service/protectedwebmethods value was updated to" + $new_value

        #change the script execution path to sapcontrol file location
        Set-Location "C:\Program Files\SAP\hostctrl\exe"
        $SapControlExecArgsPrefix = "./sapcontrol -nr " + $instance + "-function "
        $RestartService = $SapControlExecArgsPrefix +  "RestartService"
        #run the restartservice command
        Invoke-Expression $RestartService
        Write-Host "RestartService command executed successfully"
    }
}

$classinstance = [UnprotectWebMethods]::new()
$classinstance.path = $args[0]
$classinstance.instance = $args[1]
$classinstance.Invoke($args[0], $args[1])

# Example for input argument: .\UnprotectWebmethods.ps1 "H:\usr\sap\SID\SYS\profile\DEFAULT.pfl" "11"
