# **NetWeaver Provider Onboarding Pre-requisites**
# This customizing transport request will be used to create the Z_AMS_NETWEAVER_MONITORING in the SAP system and generate the profile

1. Transfer the data and cofiles into the SAP system application server using CG3Z TCODE.
2. Run STMS TCODE and import the customizing request into the SAP system by providing the appropriate client id 
where you want the roles to be created.
3. Once the TR is imported in SAP System, navigate to TCODE PFCG and enter the role name as Z_AMS_NETWEAVER_MONITORING 
and click edit and validate the following: 
    a. Authorization tab is Green and profile is generated.
    b. User tab will be empty and you need to associate the ams monitoring user to this newly created role.
