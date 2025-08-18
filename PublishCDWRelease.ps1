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
#   Applying a version tag to the most recent commit

#endregion

#region  ~~  DATA STRUCTURES  ~~
Clear-Host

#Calculating Diff
$Global:StartTag = $null
$Global:EndingTag = $null

#DEBUG
#$GitFolder = 'C:\Git\MockRepo\vcrs-cdw-db'
#$GitFolder = 'C:\Git\vcrs-cdw-db'
$Global:GitFolder = $null

$DBOpsFolder = 'C:\Git\vcrs-cdw-dbops'

$DT = New-Object System.Data.DataTable

$DT.Columns.Add('Diff'     ,[String])  | Out-Null
$DT.Columns.Add('Version'  ,[Version]) | Out-Null
$DT.Columns.Add('Tag'      ,[String])  | Out-Null
$DT.Columns.Add('TagDate'  ,[String])  | Out-Null
$DT.Columns.Add('TagSHA'   ,[String])  | Out-Null
$DT.Columns.Add('CommitSHA',[String])  | Out-Null

$Diff = New-Object System.Data.DataTable

$Diff.Columns.Add('FileName',[String]) | Out-Null
$Diff.Columns.Add('FullName',[String]) | Out-Null

#endregion


#region  ~~  WPF XAML  ~~
Add-Type -AssemblyName PresentationFramework

Add-Type -AssemblyName System.Windows.Forms

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="CDW Release Version Tagger" Height="500" Width="800">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <GroupBox  Grid.Row="0" Header="Git Folders - CDW / DBOps" Padding="10">
        
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>       

                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
                    <Button x:Name="BT_Browse_CDWDb"  Content="Browse"  Width="60" Margin="0,0,0,0"/>                         
                     <Label   Content="CDW:   " VerticalAlignment="Center"/>
                    <TextBox x:Name="TB_PathGitCDW" Width="250" Margin="10,0,0,0"/>
                </StackPanel>       

                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,10,0,10">
                    <Button x:Name="BT_Browse_CDWDbOps" Content="Browse"  Width="60" Margin="0,0,0,0"/>                 
                    <Label   Content="DBOps: " VerticalAlignment="Center"/>            
                    <TextBox x:Name="TB_PathGitDBOps" Width="250" Margin="10,0,0,0"/>
                </StackPanel>        

            </Grid>

        </GroupBox>

        <GroupBox  Grid.Row="1" Header="New Release Tag" Padding="10">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>       
                
                <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,0">
                <Label   X:Name="LB_EnterVersion" Content="Enter Version:" VerticalAlignment="Center"/>
                <TextBox x:Name="TB_Version" Width="150" Margin="10,0"/>
                <Button x:Name="BT_AddVersion"  Content="Add Version"  Width="120" Margin="0,0,10,0"/>
                <Button x:Name="BT_Publish" Content="Publish" Width="120" IsEnabled="True" />           

                </StackPanel>

                <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,0">
                    <Label x:Name="LB_Status" Grid.Row="4" Foreground="Blue" FontWeight="Bold" Margin="0,0,0,0"/> 
                </StackPanel>

            </Grid>
        </GroupBox>        

<!--        <GroupBox Grid.Row="3" Header="Diff Tags" Padding="10">        
            <StackPanel Orientation="Horizontal" Margin="0,10,0,10">
                <Label   X:Name="LB_StartTag" Content="Start Tag:" VerticalAlignment="Center"/>
                <TextBox x:Name="TB_StartTag" Width="150" Margin="10,0"/>               
                <Label   X:Name="LB_EndTag" Content="End Tag:" VerticalAlignment="Center"/>            
                <TextBox x:Name="TB_EndTag" Width="150" Margin="10,0"/> 
                <Button x:Name="BT_FindDiff" Content="Find Diff" Width="120"/>                                   
            </StackPanel>
        </GroupBox>        
-->
        

        <DataGrid x:Name="DG_TagHistory" Grid.Row="5" AutoGenerateColumns="True" CanUserAddRows="False">
            <!-- <DataGrid.Columns>                
                <DataGridTextColumn Header="Version"   Binding="{Binding}"/>  
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


# Buttons
$BT_Browse_CDWDb    = $window.FindName("BT_Browse_CDWDb") 
$BT_Browse_CDWDbOps = $window.FindName("BT_Browse_CDWDbOps")
$BT_AddVersion          = $window.FindName("BT_AddVersion")
$BT_Publish         = $window.FindName("BT_Publish")
#$BT_FindDiff        = $window.FindName("BT_FindDiff")

# TextBox
$TB_PathGitCDW   = $window.FindName("TB_PathGitCDW")
$TB_PathGitDBOps = $window.FindName("TB_PathGitDBOps")
$TB_Version      = $window.FindName("TB_Version")

# Labels
$LB_Status       = $window.FindName("LB_Status")

# DataGrid
$DG_TagHistory   = $window.FindName("DG_TagHistory")

#endregion


#region  ~~  FUNCTIONS  ~~

# Get Tags
function Get-GitTags {

    $Global:StartTag = $null
    $Global:EndingTag = $null

    Set-Location $Global:GitFolder 

    git fetch --tags | Out-Null        

    $Tags = git for-each-ref --format='%(refname:short) TAG_SHA=%(objectname) TAG_DATE=%(taggerdate:iso) COMMIT_SHA=%(*objectname)' refs/tags

    foreach( $Item in $Tags)
    {

        $R = $Item -split ' '

        # REGEX EXPLANATION:
        #
        #   ^ � start of string
        #   Release_ � literal
        #   \d+ � one or more digits
        #   \. � literal period
        #   $ � end of string

        #If the Tag matches the Release naming Convention. Add it.
        if( $R[0] -match '^Release_\d+\.\d+\.\d+$' )
        {

            $NR = $DT.NewRow()
            
            $NR.Version    = [Version]( $R[0] -replace 'Release_' )
            $NR.Tag        = $R[0]
            $NR.TagDate    = [String]($R[2] -replace 'TAG_DATE=')
            $NR.TagSHA     = [String]($R[1] -replace 'TAG_SHA=')
            $NR.CommitSHA  = [String]($R[5] -replace 'COMMIT_SHA=')
            
            $DT.Rows.Add($NR)

        }
    }

    #Sorted Descending
    $VersionList = Get-ExistingVersions


    $Global:EndingTag = $VersionList[0]
    $Global:StartTag  = $VersionList[1]

    foreach($row in $DT){
       If( $row.Version -eq $Global:EndingTag ){$row.Diff = 'END'}
       If( $row.Version -eq $Global:StartTag ){$row.Diff = 'START'}
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
        $ExistingVersions += $Row.Version
    }

    $ExistingVersions = $ExistingVersions | Sort-Object -Descending    
    
    return $ExistingVersions
}

function Verify-Tag {

}


# Passing the TextBox Control to the Function.
function browse-folder {
    param(
        [System.Windows.Controls.TextBox] $TB
    )

    $SelectedFolder = $null

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {

        $SelectedFolder = $( $dialog.SelectedPath )
        if( Check-GitFolder $SelectedFolder)
        {
            $TB.Text = $( $dialog.SelectedPath )
        } else {
            $TB.Text = "SELECTED A NON GIT REPO FOLDER"
            $SelectedFolder = $null
        }
    }

    return $SelectedFolder
}

#Verifies that the path is a Git repo.
function Check-GitFolder {
    param(
        [String] $path
    )

    [Bool] $IsGitFolder = $null

    $path = $($Path + '\.git') -replace '\\','\'
    If( Test-Path $Path ){ $IsGitFolder = $true } else { $IsGitFolder = $false }

    return $IsGitFolder
}

function Clear-GitFolder {
    param(
        [System.Windows.Controls.TextBox] $TB
    )

    if( Test-Path $TB.Text) {
        $TargetFolder = $TB.Text
    } else {
        $TargetFolder = ""
        $LB_Status.Content = "No Target Git Folder Select."
    }

    if($TargetFolder -ne ""){
        Set-Location $TargetFolder

        Get-ChildItem | 
            Where-Object { $_.Name.ToUpper() -notin '.GITHUB', '.GIT' } |
            ForEach-Object {
                Write-Host $("Removing: " + $_.FullName)
                Remove-Item -Path $_.FullName -Recurse -Force
            }    

        git add .
        git commit -m "Cleared Repo"
    }

}

function Calculate-Diff {
    param (
        [String] $StartTag,
        [String] $EndingTag
    )
    

    $Files = ( git diff  $StartTag $EndingTag )

    Write-Host $Files

}

#endregion


#region  ~~  EVENTS  ~~


# BUTTON CLICKS
$BT_AddVersion.Add_Click({
    
    $LB_Status.Foreground = 'Blue'

    $IsNewVersion = $false
    $NewVersionTag = 'Release_'

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
       #$LB_Status.Content = "VALID"
       $LB_Status.Foreground = 'Green'   
       $IsNewVersion = $true    
    }

    #If New Version, create version tag then push to github.
    if($IsNewVersion){
        $NewVersionTag += $version

        $LB_Status.Content = "Pushing new tag."     

        git tag -a $NewVersionTag -m $NewVersionTag        
        git push origin $NewVersionTag
        
        $LB_Status.Content = "New Version " + $version + " Added."

        Load-Tags

    }

})

# Submit Version
$BT_Publish.Add_Click({

    Clear-GitFolder $TB_PathGitDBOps
    Write-Host ("Clearing Git Folder: " + $TB_PathGitDBOps.Text)

})

#Browse to the source git folder.
#  If valid, assign the path to the GitFolder Variable.
#  Then Load version history.
$BT_Browse_CDWDb.Add_Click({
    $Global:GitFolder = browse-folder $TB_PathGitCDW
     # Load initial tag list
    Load-Tags

})

$BT_Browse_CDWDbOps.Add_Click({browse-folder $TB_PathGitDBOps})

#$BT_FindDiff.Add_Click({})
#endregion



# Show GUI
$window.ShowDialog() | Out-Null
$window.Close()

