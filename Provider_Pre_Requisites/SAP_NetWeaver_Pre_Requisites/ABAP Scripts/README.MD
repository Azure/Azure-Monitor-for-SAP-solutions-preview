# **NetWeaver Provider Onboarding Pre-requisites**

Import the data and cofiles into the SAP system using CG3Z TCODE.

# Execute the program in SE38 : 

1. Execute SE38 TCODE and enter Z_AMS_RFC_PREREQUISITES as program name.
2. Execute the program in SAP.
3. Select the steps you want to execute the program.
    a. Select "Create AMS Role in PFCG" to create a new role by entering the new role name and uploading the 
    role file "Z_AMS_ROLES.xlsx" file.
    b. Select "Create a new user for AMS" to create a new dedicated user for AMS monitoring and assigning this 
    user to the role we created in previous step.
    c. Select "Activate WSDL11 and RFC in SICF" to active WSDL11 and RFC in SICF service.
4. After entering the details as mentioned in step 3, execute the program.
5. Navigate to TCODE PFCG and enter the role name you provided and check the following: 
    a. New role is created with the name you provided in step 3.
    b. New user is created and assigned to the role.
    c. Authorization and User tab in PFCG is Green and profile is generated.

After the above steps are completed, you can navigate to azure portal to create NetWeaver provider with the 
user credentials you created.
