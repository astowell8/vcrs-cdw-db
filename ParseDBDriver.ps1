$XML = 
'<DeploymentDriver Name="DbDriver" Description="DBDriver For System" Version="1.0.0">
	<ServerDeployments>
		<ServerDeployment Name="Example_Db" Description="Deployment for Example_DB">
			<PreDeployment>
				<DeploymentGroup Name="ExampleDB PreDeployment GRP" Description="Description of the Example_DB DeploymentGrP">
					<Step StepType="File" Path="..\..\Example_DB\PreDeployment\file1.sql" />
					<Step StepType="File" Path="..\..\Example_DB\PreDeployment\file2.sql" />
					<Step StepType="File" Path="..\..\Example_DB\PreDeployment\file3.sql" />
					<Step StepType="File" Path="..\..\Example_DB\PreDeployment\Other\Otherfile1.sql" />				
				</DeploymentGroup>
			</PreDeployment>
			<Deployment>
				<DeploymentGroup Name="Deployment ExampleDB Group">
					<Step StepType="File" Path="..\..\Example_DB\Deployment\file-D1.sql" />
					<Step StepType="File" Path="..\..\Example_DB\Deployment\file-D2.sql" />
					<Step StepType="File" Path="..\..\Example_DB\Deployment\file-D3.sql" />
					<Step StepType="File" Path="..\..\Example_DB\Deployment\More\Otherfile-D1.sql" />		
					<Step StepType="File" Path="..\..\Example_DB\Deployment\More\Otherfile-D2.sql" />						
				</DeploymentGroup>
			</Deployment>
			<PostDeployment>
				<DeploymentGroup Name="ExampleDB PostDeployment GRP">
					<Step StepType="File" Path="..\..\Example_DB\PostDeployment\file1.sql" />
					<Step StepType="File" Path="..\..\Example_DB\PostDeployment\file2.sql" />
					<Step StepType="File" Path="..\..\Example_DB\PostDeployment\file3.sql" />				
				</DeploymentGroup>
			</PostDeployment>
		</ServerDeployment> 		
	</ServerDeployments>	
</DeploymentDriver>'

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


$DriverRootFolder = 'C:\Git\CDW\vcrs-cdw-db'
$DBDrivers = @{}

$DBDrivers.Add('CDW_DW.dbdriver',@{
    IsRequired = $false; 
    Path = "$DriverRootFolder\DataNode\CDW_DW\CDW_DW.dbdriver" ;
    Database = 'CDW_DW'
})

$DBDrivers.Add('CDW_PHI.dbdriver',@{
    IsRequired = $false; 
    Path = "$DriverRootFolder\DataNode\CDW_PHI\CDW_PHI.dbdriver" ;
    Database = 'CDW_PHI'
})




#endregion

#$DBDrivers = ${}

#$DBDrivers.Add('CDW_DW.dbdriver',${'IsRequired' = $false; })

Clear-Host

function Read-DBDriver {
    param(
        [string] $DBDriverFile,
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
    $Var_Database = $Database


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

                                $DT.Rows.Add($NR)          
                            }
                        }
                    }
                }
            }
        }
    }    


}


# function Read-DBDriver {
#     param(
#         [string] $DBDriverFile,
#         [string] $Database,
#         [string] $DBDriver
#     )

foreach( $DBDriver in $DBDrivers.Keys){
    Read-DBDriver -DBDriverFile $DBDrivers[$DBDriver].Path -Database $DBDrivers[$DBDriver].Database -DBDriver $DBDriver
}



$DT | Out-GridView