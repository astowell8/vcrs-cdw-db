#region  ~~  ABOUT  ~~

# Andy Stowell
# Reads DBDRiver, comparies to diff export, dynamically makes a new one

#endregion

#SETTING

$Target_DBDriver_Folder = 'C:\Git\CDW\vcrs-cdw-dbops'

#region  ~~  DATASTRUCTURES  ~~

$DT = New-Object System.Data.DataTable

$DT.Columns.Add('Database'                    ,[String]) | Out-Null
$DT.Columns.Add('DeploymentDriver_Name'       ,[String]) | Out-Null
$DT.Columns.Add('DeploymentDriver_Description',[String]) | Out-Null
$DT.Columns.Add('DeploymentDriver_Version'    ,[String]) | Out-Null
$DT.Columns.Add('ServerDeployment_Name'       ,[String]) | Out-Null
$DT.Columns.Add('ServerDeployment_Description',[String]) | Out-Null
$DT.Columns.Add('DeploymentType'              ,[String]) | Out-Null #PreDeployment,Deployment,PostDeployment
$DT.Columns.Add('DeploymentGroup_Name'        ,[String]) | Out-Null
$DT.Columns.Add('DeploymentGroup_Description' ,[String]) | Out-Null
$DT.Columns.Add('Step_Type'                   ,[String]) | Out-Null
$DT.Columns.Add('Step_Path'                   ,[String]) | Out-Null
$DT.Columns.Add('FileExists'                  ,[String]) | Out-Null #There are three states: (UNKNOWN, YES, NO)
$DT.Columns.Add('FileSys_Repo'                ,[String]) | Out-Null #FileSys fields used to help identiy if file exists.
$DT.Columns.Add('FileSys_Server'              ,[String]) | Out-Null 
$DT.Columns.Add('FileSys_Database'            ,[String]) | Out-Null 
$DT.Columns.Add('FileSys_DBDriverFile'        ,[String]) | Out-Null 



$CDWRepoRoot = 'C:\Git\CDW\vcrs-cdw-db'
$DBDrivers = @{}

# How to understand the logic.

# IsRequired = Used Later On to flag if this DBDriver needs to be included in the diff build. 
# Path       = File System literal path to the dbdriver file.
# RepoPath   = FileSystem Path to the Git Repo vcrs-cdw-db
# Server     = next folder under the "RepoPath". one of four (Common, Consumer, DataNode, MasterName)
# Database   = next folder under "Server"

# The following Key/Value pairs RepoPath, Server, Database will be used to help identify if the FileStep is included in the differential.
# 

#DATANODE DBDRIVERS
$CDWServer = 'DataNode'

$DBDrivers.Add('CDW_DW.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_DW\CDW_DW.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;
    Database   = 'CDW_DW'
})

$DBDrivers.Add('CDW_PHI.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_PHI\CDW_PHI.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_PHI'
})

$DBDrivers.Add('CDW_Scratch.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_Scratch\CDW_Scratch.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_Scratch'
})

$DBDrivers.Add('CDW_SDK.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_SDK\CDW_SDK.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_SDK'
})

$DBDrivers.Add('CDW_STG.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_STG\CDW_STG.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_STG'
})

$DBDrivers.Add('CDW_TERM.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_TERM\CDW_TERM.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_TERM'
})

$DBDrivers.Add('CDW_Transfer.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\DataNode\CDW_Transfer\CDW_Transfer.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_Transfer'
})

#MASTERNODE
$CDWServer = 'MasterNode'

$DBDrivers.Add('CDW_Master.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\MasterNode\CDW_Master\CDW_Master.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_Master'
})


#COMMON
$CDWServer = 'Common'

$DBDrivers.Add('CDW_DM.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\Common\CDW_DM\CDW_DM.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDW_DM'
})

#under the same folder as CDW_DM
$DBDrivers.Add('CDWSDK.dbdriver',@{
    IsRequired = $false; 
    Path       = "$CDWRepoRoot\Common\CDW_DM\CDWSDK.dbdriver";
    RepoPath   = $CDWRepoRoot;
    Server     = $CDWServer;    
    Database   = 'CDWSDK'
})


#endregion

#$DBDrivers = ${}

#$DBDrivers.Add('CDW_DW.dbdriver',${'IsRequired' = $false; })

Clear-Host

function Read-DBDriver {
    param(
        [string] $DBDriverFile,
        [string] $RepoPath,
        [string] $Server,
        [string] $Database,
        [string] $DBDriver
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

    $Var_Database                     = ''
    $Var_DeploymentDriver_Name        = ''
    $Var_DeploymentDriver_Description = ''
    $Var_DeploymentDriver_Version     = ''
    $Var_ServerDeployment_Name        = ''
    $Var_ServerDeployment_Description = ''
    $Var_DeploymentType               = ''
    $Var_DeploymentGroup_Name         = ''
    $Var_DeploymentGroup_Description  = ''
    $Var_Step_Type                    = ''
    $Var_Step_Path                    = ''

    $Var_FileExists                   = ''
    

    #$Var_Database = "EXAMPLE_DB"
    $Var_RepoPath     = $RepoPath
    $Var_Server       = $Server
    $Var_Database     = $Database
    $Var_DBDriverFile = $DBDriverFile


    foreach( $item_DeploymentDriver in $DBDriverXML.DeploymentDriver ){

        $Var_DeploymentDriver_Name        = $item_DeploymentDriver.Name
        $Var_DeploymentDriver_Description = $item_DeploymentDriver.Description
        $Var_DeploymentDriver_Version     = $item_DeploymentDriver.Version

        foreach( $item_ServerDeployments in $item_DeploymentDriver.ServerDeployments )
        {

            foreach( $item_ServerDeployment in $item_ServerDeployments.ServerDeployment )
            {
                $Var_ServerDeployment_Name = $item_ServerDeployment.Name
                $Var_ServerDeployment_Description = $item_ServerDeployment.Description

                #If the node exists.
                if( $item_ServerDeployment.PreDeployment )
                {
                    $Var_DeploymentType = 'PREDEPLOYMENT' #NEED THIS TO REBUILD THE XML.

                    foreach( $item_PreDeployment in $item_ServerDeployment.PreDeployment )
                    {

                        foreach( $item_DeploymentGroup in $item_PreDeployment.DeploymentGroup )
                        {

                            $Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            $Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                $Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                                $Var_FileExists = 'UNKNOWN'

                                $NR = $DT.NewRow()

                                $NR.Database                     = $Var_Database                     
                                $NR.DeploymentDriver_Name        = $Var_DeploymentDriver_Name        
                                $NR.DeploymentDriver_Description = $Var_DeploymentDriver_Description 
                                $NR.DeploymentDriver_Version     = $Var_DeploymentDriver_Version     
                                $NR.ServerDeployment_Name        = $Var_ServerDeployment_Name        
                                $NR.ServerDeployment_Description = $Var_ServerDeployment_Description 
                                $NR.DeploymentType               = $Var_DeploymentType               
                                $NR.DeploymentGroup_Name         = $Var_DeploymentGroup_Name         
                                $NR.DeploymentGroup_Description  = $Var_DeploymentGroup_Description  
                                $NR.Step_Type                    = $Var_Step_Type                    
                                $NR.Step_Path                    = $Var_Step_Path 
                                $NR.FileExists                   = $Var_FileExists
                                $NR.FileSys_Repo                 = $Var_RepoPath
                                $NR.FileSys_Server               = $Var_Server
                                $NR.FileSys_Database             = $Var_Database 
                                $NR.FileSys_DBDriverFile         = $Var_DBDriverFile 

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

                            $Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            $Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                $Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                                $Var_FileExists = 'UNKNOWN'

                                $NR = $DT.NewRow()

                                $NR.Database                     = $Var_Database                     
                                $NR.DeploymentDriver_Name        = $Var_DeploymentDriver_Name        
                                $NR.DeploymentDriver_Description = $Var_DeploymentDriver_Description 
                                $NR.DeploymentDriver_Version     = $Var_DeploymentDriver_Version     
                                $NR.ServerDeployment_Name        = $Var_ServerDeployment_Name        
                                $NR.ServerDeployment_Description = $Var_ServerDeployment_Description 
                                $NR.DeploymentType               = $Var_DeploymentType               
                                $NR.DeploymentGroup_Name         = $Var_DeploymentGroup_Name         
                                $NR.DeploymentGroup_Description  = $Var_DeploymentGroup_Description  
                                $NR.Step_Type                    = $Var_Step_Type                    
                                $NR.Step_Path                    = $Var_Step_Path 
                                $NR.FileExists                   = $Var_FileExists

                                $NR.FileSys_Repo                 = $Var_RepoPath
                                $NR.FileSys_Server               = $Var_Server
                                $NR.FileSys_Database             = $Var_Database 
                                $NR.FileSys_DBDriverFile         = $Var_DBDriverFile                                 

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

                            $Var_DeploymentGroup_Name = $item_DeploymentGroup.Name
                            $Var_DeploymentGroup_Description = $item_DeploymentGroup.Description

                            foreach( $item_Step in $item_DeploymentGroup.Step)
                            {
                                $Var_Step_Type  = $item_Step.StepType
                                $Var_Step_Path  = $item_Step.Path
                                $Var_FileExists = 'UNKNOWN'

                                $NR = $DT.NewRow()

                                $NR.Database                     = $Var_Database                     
                                $NR.DeploymentDriver_Name        = $Var_DeploymentDriver_Name        
                                $NR.DeploymentDriver_Description = $Var_DeploymentDriver_Description 
                                $NR.DeploymentDriver_Version     = $Var_DeploymentDriver_Version     
                                $NR.ServerDeployment_Name        = $Var_ServerDeployment_Name        
                                $NR.ServerDeployment_Description = $Var_ServerDeployment_Description 
                                $NR.DeploymentType               = $Var_DeploymentType               
                                $NR.DeploymentGroup_Name         = $Var_DeploymentGroup_Name         
                                $NR.DeploymentGroup_Description  = $Var_DeploymentGroup_Description  
                                $NR.Step_Type                    = $Var_Step_Type                    
                                $NR.Step_Path                    = $Var_Step_Path 
                                $NR.FileExists                   = $Var_FileExists

                                $NR.FileSys_Repo                 = $Var_RepoPath
                                $NR.FileSys_Server               = $Var_Server
                                $NR.FileSys_Database             = $Var_Database 
                                $NR.FileSys_DBDriverFile         = $Var_DBDriverFile                                 

                                $DT.Rows.Add($NR)          
                            }
                        }
                    }
                }
            }
        }
    }    


}


foreach( $DBDriver in $DBDrivers.Keys){
    Read-DBDriver -DBDriverFile $DBDrivers[$DBDriver].Path `
                  -RepoPath     $DBDrivers[$DBDriver].RepoPath `
                  -Server       $DBDrivers[$DBDriver].Server `
                  -Database     $DBDrivers[$DBDriver].Database `
                  -DBDriver     $DBDriver 
                  
}

#region  ~~  IDENTIFY FILES  ~~

$Target_DBDriver_Folder = $Target_DBDriver_Folder

#If It needs to expand beyond SQL Files.
$ExtentionList = @( '.SQL' )

$Files = Get-ChildItem -Path $Target_DBDriver_Folder -File -Recurse | Where-Object { $_.Extension.ToUpper() -in $ExtentionList }

$Files | ForEach-Object {
    Write-Host $_
}


#endregion

$DT | Out-GridView