

$DT = New-Object System.Data.DataTable

$DT.Columns.Add('DBDriverName'     ,[String]) | Out-Null
$DT.Columns.Add('DBDriverFullName' ,[String]) | Out-Null
$DT.Columns.Add('CDWArea'          ,[String]) | Out-Null
$DT.Columns.Add('Database'         ,[String]) | Out-Null
$DT.Columns.Add('Step_Path'        ,[String]) | Out-Null


function Read-DBDriver {
    param(
        [string] $DBDriver,
        [string] $DBDriverFile,
        [string] $CDWArea,
        [string] $Database
    )


    #$DBDriverFile = 'C:\Git\CodeLibrary_PowerShell\Sample.DBDriver'
    #$DBDriverFile = 'C:\Git\CDW\vcrs-cdw-db\DataNode\CDW_DW\CDW_DW.dbdriver'

    if(-not(test-path $DBDriverFile)){
        Write-Host "Path to DBDriver [$DBDriver] file not valid" -ForegroundColor Red
        exit
    }

    $DBDriverFile = $DBDriverFile

    [xml] $DBDriverXML = Get-Content -Path $DBDriverFile -raw
    #[xml] $DBDriverXML = $XML

    # $Var_DeploymentDriver_Name        = ''
    # $Var_DeploymentDriver_Description = ''
    # $Var_DeploymentDriver_Version     = ''
    # $Var_CDWAreaDeployment_Name        = ''
    # $Var_CDWAreaDeployment_Description = ''
    # $Var_DeploymentType               = ''
    # $Var_DeploymentGroup_Name         = ''
    # $Var_DeploymentGroup_Description  = ''
    # $Var_Step_Type                    = ''
    
    # $Var_FileExists                   = ''
    
    $Var_Database                     = ''
    $Var_Step_Path                    = ''
    

    #$Var_Database = "EXAMPLE_DB"
    #$Var_RepoPath     = $RepoPath
    $Var_DBDriverName = $DBDriver
    $Var_DBDriverFile = $DBDriverFile
    $Var_CDWArea      = $CDWArea
    $Var_Database     = $Database


    foreach( $item_DeploymentDriver in $DBDriverXML.DeploymentDriver ){

        # $Var_DeploymentDriver_Name        = $item_DeploymentDriver.Name
        # $Var_DeploymentDriver_Description = $item_DeploymentDriver.Description
        # $Var_DeploymentDriver_Version     = $item_DeploymentDriver.Version

        foreach( $item_ServerDeployments in $item_DeploymentDriver.ServerDeployments )
        {

            foreach( $item_ServerDeployment in $item_ServerDeployments.ServerDeployment )
            {
                #$Var_CDWAreaDeployment_Name = $item_ServerDeployment.Name
                #$Var_CDWAreaDeployment_Description = $item_ServerDeployment.Description

                #If the node exists.
                if( $item_ServerDeployment.PreDeployment )
                {
                    #$Var_DeploymentType = 'PREDEPLOYMENT' #NEED THIS TO REBUILD THE XML.

                    foreach( $item_PreDeployment in $item_ServerDeployment.PreDeployment )
                    {

                        foreach( $item_DeploymentGroup in $item_PreDeployment.DeploymentGroup )
                        {

                            #$Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            #$Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                #$Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                               
                                $NR = $DT.NewRow()

                                $NR.DBDriverName     = $Var_DBDriverName       
                                $NR.DBDriverFullName = $Var_DBDriverFile
                                $NR.CDWArea          = $Var_CDWArea 
                                $NR.Database         = $Var_Database     
                                $NR.Step_Path        = $Var_Step_Path         
                       
                                $DT.Rows.Add($NR)            
                            }
                        }
                    }
                }


                #If the node exists.
                if( $item_ServerDeployment.Deployment )
                {
                    $Var_DeploymentType = 'DEPLOYMENT' #NEED THIS TO REBUILD THE XML.

                    foreach( $item_PreDeployment in $item_ServerDeployment.Deployment )
                    {

                        foreach( $item_DeploymentGroup in $item_PreDeployment.DeploymentGroup )
                        {

                            #$Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            #$Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                #$Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                               
                                $NR = $DT.NewRow()

                                $NR.DBDriverName     = $Var_DBDriverName       
                                $NR.DBDriverFullName = $Var_DBDriverFile
                                $NR.CDWArea          = $Var_CDWArea 
                                $NR.Database         = $Var_Database     
                                $NR.Step_Path        = $Var_Step_Path         
                       
                                $DT.Rows.Add($NR)                 
                            }
                        }
                    }
                }


                #If the node exists.
                if( $item_ServerDeployment.PostDeployment )
                {
                    $Var_DeploymentType = 'POSTDEPLOYMENT' #NEED THIS TO REBUILD THE XML.

                    foreach( $item_PreDeployment in $item_ServerDeployment.PostDeployment )
                    {

                        foreach( $item_DeploymentGroup in $item_PreDeployment.DeploymentGroup )
                        {

                            # $Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            # $Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                #$Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                               
                                $NR = $DT.NewRow()

                                $NR.DBDriverName     = $Var_DBDriverName       
                                $NR.DBDriverFullName = $Var_DBDriverFile
                                $NR.CDWArea          = $Var_CDWArea 
                                $NR.Database         = $Var_Database     
                                $NR.Step_Path        = $Var_Step_Path         
                       
                                $DT.Rows.Add($NR)           
                            }
                        }
                    }
                }
            }
        }
    }    


}

Clear-Host

$Git_CDW_Root = 'C:\Git\CDW\vcrs-cdw-db'
Set-Location $Git_CDW_Root

#################################
# Four DBDriver Areas
#################################
# MasterNode
# DataNode
# Common
# Consumers

$DBDrivers = @{}

$CDWArea = 'DataNode'

$DBDrivers.Add('CDW_DW.dbdriver'       ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_DW\CDW_DW.dbdriver");               CDWArea = $CDWArea; Database = 'CDW_DW'})
$DBDrivers.Add('CDW_PHI.dbdriver'      ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_PHI\CDW_PHI.dbdriver");             CDWArea = $CDWArea; Database = 'CDW_PHI'})
$DBDrivers.Add('CDW_Scratch.dbdriver'  ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_Scratch\CDW_Scratch.dbdriver");     CDWArea = $CDWArea; Database = 'CDW_Scratch'})
$DBDrivers.Add('CDW_SDK.dbdriver'      ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_SDK\CDW_SDK.dbdriver");             CDWArea = $CDWArea; Database = 'CDW_SDK'})
$DBDrivers.Add('CDW_STG.dbdriver'      ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_STG\CDW_STG.dbdriver");             CDWArea = $CDWArea; Database = 'CDW_STG'})
$DBDrivers.Add('CDW_TERM.dbdriver'     ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_TERM\CDW_TERM.dbdriver");           CDWArea = $CDWArea; Database = 'CDW_TERM'})
$DBDrivers.Add('CDW_Transfer.dbdriver' ,@{Path = ($Git_CDW_Root+"\DataNode\CDW_Transfer\CDW_Transfer.dbdriver");   CDWArea = $CDWArea; Database = 'CDW_Transfer'})


#MASTERNODE
$CDWArea = 'MasterNode'

$DBDrivers.Add('CDW_Master.dbdriver'   ,@{ Path = ($Git_CDW_Root+"\MasterNode\CDW_Master\CDW_Master.dbdriver");    CDWArea = $CDWArea; Database = 'CDW_Master'})


#COMMON
$CDWArea = 'Common'

$DBDrivers.Add('CDW_DM.dbdriver'       ,@{ Path = ($Git_CDW_Root+"\Common\CDW_DM\CDW_DM.dbdriver");                CDWArea = $CDWArea; Database = 'CDW_DM'})
$DBDrivers.Add('CDWSDK.dbdriver'       ,@{ Path = ($Git_CDW_Root+"\Common\CDW_DM\CDWSDK.dbdriver");                CDWArea = $CDWArea; Database = 'CDWSDK'})


#CONSUMMER
$CDWArea = 'Consummer'

$DBDrivers.Add('ALLPMCPM.dbdriver'     ,@{ Path = ($Git_CDW_Root+"\Consumers\ALLPMCPM\ALLPMCPM.dbdriver");           CDWArea = $CDWArea; Database = ''})
$DBDrivers.Add('CareInsights.dbdriver' ,@{ Path = ($Git_CDW_Root+"\Consumers\CareInsights\CareInsights.dbdriver"); CDWArea = $CDWArea; Database = ''})
$DBDrivers.Add('CDWE_STG.dbdriver'     ,@{ Path = ($Git_CDW_Root+"\Consumers\CDWE_STG\CDWE_STG.dbdriver");         CDWArea = $CDWArea; Database = ''})
$DBDrivers.Add('DE.dbdriver'           ,@{ Path = ($Git_CDW_Root+"\Consumers\DE\DE.dbdriver");                     CDWArea = $CDWArea; Database = ''})
$DBDrivers.Add('PHA.dbdriver'          ,@{ Path = ($Git_CDW_Root+"\Consumers\PHA\PHA.dbdriver");                   CDWArea = $CDWArea; Database = ''})


# function Read-DBDriver {
#     param(
#         [string] $DBDriver,
#         [string] $DBDriverFile,
#         [string] $CDWArea,
#         [string] $Database
#     )

foreach( $DBDriver in $DBDrivers.Keys){
    Read-DBDriver -DBDriver     $DBDriver `
                  -DBDriverFile $DBDrivers[$DBDriver].Path `
                  -CDWArea      $DBDrivers[$DBDriver].CDWArea `
                  -Database     $DBDrivers[$DBDriver].Database                    
                  
}

$DT | Out-GridView