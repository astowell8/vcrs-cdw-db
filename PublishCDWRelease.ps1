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

#end

Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Git Version Tagger" Height="400" Width="600">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,10">
            <Label   X:Name="LB_EnterVersion" Content="Enter Version:" VerticalAlignment="Center"/>
            <TextBox x:Name="TB_Version" Width="150" Margin="10,0"/>
        </StackPanel>
        
        <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,10">
            <Button x:Name="BT_Verify"  Content="Verify"  Width="120" Margin="0,0,10,0"/>
            <Button x:Name="BT_Publish" Content="Publish" Width="120"/>
        </StackPanel>
        
        <Label x:Name="LB_StatusMessage" Grid.Row="2" Foreground="Blue" FontWeight="Bold" Margin="0,0,0,10"/>

        <DataGrid x:Name="DG_TagHistory" Grid.Row="3" AutoGenerateColumns="False" CanUserAddRows="False">
            <DataGrid.Columns>
                <DataGridTextColumn Header="Git Tags" Binding="{Binding}"/>
            </DataGrid.Columns>
        </DataGrid>
    </Grid>
</Window>
"@ -replace 'x:N','N'

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$TB_Version    = $window.FindName("TB_Version")
$BT_Verify     = $window.FindName("BT_Verify")
$BT_Publish    = $window.FindName("BT_Publish")
$LB_Status     = $window.FindName("LB_Status")
$DG_TagHistory = $window.FindName("DG_TagHistory")

# Get Tags
function Get-GitTags {
    git fetch --tags | Out-Null
    git tag
}

# Populate DataGrid
function Load-Tags {
    $tags = Get-GitTags
    $DG_TagHistory.ItemsSource = $tags
}

# Check Version
$BT_Verify.Add_Click({
    $version = $TB_Version.Text.Trim()
    if (-not $version) {
        $LB_Status.Content = "Please enter a version number."
        return
    }

    $tags = Get-GitTags
    if ($tags -contains $version) {
        $LB_Status.Content = "✅ Version $version exists."
    } else {
        $LB_Status.Content = "❌ Version $version does not exist."
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
        $LB_Status.Content = "⚠️ Version already exists. Submission skipped."
    } else {
        try {
            git tag $version
            git push origin $version
            $LB_Status.Content = "✅ Version $version submitted successfully."
            Load-Tags
        } catch {
            $LB_Status.Content = "❌ Failed to submit version: $_"
        }
    }
})

# Load initial tag list
#Load-Tags

# Show GUI
$window.ShowDialog() | Out-Null
$window.Close()

