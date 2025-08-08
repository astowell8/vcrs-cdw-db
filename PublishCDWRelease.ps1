#region  ~~  ABOUT  ~~

# DEVELOPER NOTES:
#
#   Control Prefixes:
#
#   (DG) Data Grid
#   (TB) Text Box
#   (BT) Button 
#   (LB) Label
#

# ASSUMES:
#   Version Tags are Annotated Tags. NOT LIGHTWEIGHT.
#

#endregion

#region  ~~  DATA STRUCTURES  ~~
Clear-Host

$GitFolder = 'C:\Git\MockRepo\vcrs-cdw-db'
$DBOpsFolder = 'C:\Git\vcrs-cdw-dbops'

$DT = New-Object System.Data.DataTable

$DT.Columns.Add('Release'  ,[Version]) | Out-Null
$DT.Columns.Add('Tag'      ,[String])  | Out-Null
$DT.Columns.Add('TagDate'  ,[String])  | Out-Null
$DT.Columns.Add('TagSHA'   ,[String])  | Out-Null
$DT.Columns.Add('CommitSHA',[String])  | Out-Null



#endregion


#region  ~~  WPF XAML  ~~
Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="CDW Release Version Tagger" Height="400" Width="600">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <Button x:Name="BT_Browse_CDWDb"  Content="Browse"  Width="60" Margin="0,0,0,0"/>                         
             <Label   Content="folder cdw-db:      " VerticalAlignment="Center"/>
            <TextBox x:Name="TB_PathGitCDW" Width="250" Margin="10,0,0,0"/>
        </StackPanel>       

        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,10">
            <Button x:Name="BT_Browse_CDWDbOps" Content="Browse"  Width="60" Margin="0,0,0,0"/>                 
            <Label   Content="Folder cdw-dbops: " VerticalAlignment="Center"/>            
            <TextBox x:Name="TB_PathGitDBOps" Width="250" Margin="10,0,0,0"/>
        </StackPanel>        

        <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="0,10,0,10">
            <Label   X:Name="LB_EnterVersion" Content="Enter Version:" VerticalAlignment="Center"/>
            <TextBox x:Name="TB_Version" Width="150" Margin="10,0"/>
        </StackPanel>
        
        <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,10,0,10">
            <Button x:Name="BT_Verify"  Content="Verify"  Width="120" Margin="0,0,10,0"/>
            <Button x:Name="BT_Publish" Content="Publish" Width="120"/>
        </StackPanel>
        
        <Label x:Name="LB_Status" Grid.Row="4" Foreground="Blue" FontWeight="Bold" Margin="0,0,0,10"/>

        <DataGrid x:Name="DG_TagHistory" Grid.Row="5" AutoGenerateColumns="True" CanUserAddRows="False">
            <!-- <DataGrid.Columns>                
                <DataGridTextColumn Header="Release"   Binding="{Binding}"/>  
                <DataGridTextColumn Header="Tag"       Binding="{Binding}"/>      
                <DataGridTextColumn Header="TagDate"   Binding="{Binding}"/>  
                <DataGridTextColumn Header="TagSHA"    Binding="{Binding}"/>   
                <DataGridTextColumn Header="CommitSHA" Binding="{Binding}"/>
            </DataGrid.Columns>  -->
        </DataGrid>
    </Grid>
</Window>
"@ -replace 'x:N','N'

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

#endregion


#region  ~~  CONTROLS  ~~
# Get Controls
$TB_Version    = $window.FindName("TB_Version")
$BT_Verify     = $window.FindName("BT_Verify")
$BT_Publish    = $window.FindName("BT_Publish")
$LB_Status     = $window.FindName("LB_Status")
$DG_TagHistory = $window.FindName("DG_TagHistory")

#endregion


#region  ~~  FUNCTIONS  ~~

# Get Tags
function Get-GitTags {

    Set-Location $GitFolder 

    git fetch --tags | Out-Null        

    $Tags = git for-each-ref --format='%(refname:short) TAG_SHA=%(objectname) TAG_DATE=%(taggerdate:iso) COMMIT_SHA=%(*objectname)' refs/tags

    foreach( $Item in $Tags)
    {

        $R = $Item -split ' '

        # REGEX EXPLANATION:
        #
        #   ^ ó start of string
        #   Release_ ó literal
        #   \d+ ó one or more digits
        #   \. ó literal period
        #   $ ó end of string

        #If the Tag matches the Release naming Convention. Add it.
        if( $R[0] -match '^Release_\d+\.\d+\.\d+$' )
        {

            $NR = $DT.NewRow()
            
            $NR.Release    = [Version]( $R[0] -replace 'Release_' )
            $NR.Tag        = $R[0]
            $NR.TagDate    = [String]($R[2] -replace 'TAG_DATE=')
            $NR.TagSHA     = [String]($R[1] -replace 'TAG_SHA=')
            $NR.CommitSHA  = [String]($R[5] -replace 'COMMIT_SHA=')
            
            $DT.Rows.Add($NR)

        }
    }

    #Want to keep a sorted list.
    #Get-ExistingVersions
    #$ExistingVersions

}

# Populate DataGrid
function Load-Tags {
    #$tags = Get-GitTags
    Get-GitTags
    $DG_TagHistory.ItemsSource = $DT.DefaultView #Automatically creates columns in Datagrid.
}

function Get-ExistingVersions {

    $ExistingVersions = @()      
    foreach( $Row in $DT.Rows ) {
        $ExistingVersions += $Row.Release
    }

    $ExistingVersions = $ExistingVersions | Sort-Object -Descending    
    
    return $ExistingVersions
}

function Verify-Tag {

}

#endregion


#region  ~~  EVENTS  ~~
# Check Version
$BT_Verify.Add_Click({
    
    $LB_Status.Foreground = 'Blue'


    #Version Info
    $ExistingVersions = @()
    $ExistingVersions = Get-ExistingVersions
    $version = $TB_Version.Text.Trim()
    
    # Check 1. Do we have an input version
    if (-not $version) {
        $LB_Status.Content = "Please enter a version number."
        return
    }
    elseif ( -not ($version -match '^\d+\.\d+\.\d+$') ) {  # Check 2. Are we given the correct version format?   ==> Major.Minor.Build
       $LB_Status.Content = "Please enter a valid version number. Expecting Major.Minor.Build format."
    } 
    elseif ( $ExistingVersions[0] -gt $version ){ # Check 3. Is the version number newer than the current version.
         $LB_Status.Content = ("Version number is older than " + $ExistingVersions[0] +". Please supply a newer version number.")
    } else {
       $LB_Status.Content = "VALID"
       $LB_Status.Foreground = 'Green'       
    }

})

# Submit Version
$BT_Publish.Add_Click({
    $version = $TB_Version.Text.Trim()
    if (-not $version) {
        $LB_Status.Content = "Please enter a version number."
        return
    }

    $tags = Get-GitTags
    if ($tags -contains $version) {
        $LB_Status.Content = "‚ö†Ô∏è Version already exists. Submission skipped."
    } else {
        try {
            git tag $version
            git push origin $version
            $LB_Status.Content = "‚úÖ Version $version submitted successfully."
            Load-Tags
        } catch {
            $LB_Status.Content = "‚ùå Failed to submit version: $_"
        }
    }
})

#endregion


# Load initial tag list
Load-Tags

# Show GUI
$window.ShowDialog() | Out-Null
$window.Close()

