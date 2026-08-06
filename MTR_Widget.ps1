Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- WIDGET CONFIGURATION ---
$favoriteLine = "TWL"      # e.g., TWL (Tsuen Wan), ISL (Island), KTL (Kwun Tong)
$favoriteStation = "TST"   # e.g., TST (Tsim Sha Tsui), ADM (Admiralty)
$refreshIntervalSeconds = 30
# ----------------------------

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MTR Tracker" Height="260" Width="280" 
        WindowStyle="None" AllowsTransparency="True" Background="Transparent" 
        Topmost="True" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
    <Border Name="MainBorder" Background="#CC1E1E2E" CornerRadius="16" BorderBrush="#89B4FA" BorderThickness="1.5" Margin="10">
        <Border.Effect>
            <DropShadowEffect BlurRadius="15" Color="#000000" Opacity="0.6" ShadowDepth="4"/>
        </Border.Effect>
        <Grid Margin="12">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Header -->
            <Grid Grid.Row="0" Name="HeaderGrid" Background="Transparent" Cursor="SizeAll" Margin="0,0,0,10">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Text="🚇 $favoriteLine - $favoriteStation" Foreground="#CDD6F4" FontSize="14" FontWeight="Bold" VerticalAlignment="Center"/>
                <Button Name="CloseBtn" Grid.Column="1" Content="✕" Foreground="#F38BA8" Background="Transparent" BorderThickness="0" FontSize="14" FontWeight="Bold" Cursor="Hand" Width="20" Height="20"/>
            </Grid>

            <!-- Delay Status Banner -->
            <Border Name="StatusBorder" Grid.Row="1" Background="#A6E3A1" CornerRadius="6" Padding="4" Margin="0,0,0,10">
                <TextBlock Name="StatusTxt" Text="Checking status..." Foreground="#11111B" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
            </Border>

            <!-- UP Direction -->
            <StackPanel Name="UpPanel" Grid.Row="2" Margin="0,0,0,8" Visibility="Collapsed">
                <TextBlock Name="UpDestTxt" Text="Towards: ---" Foreground="#89B4FA" FontSize="12" FontWeight="Bold"/>
                <TextBlock Name="UpEtaTxt" Text="--- min, --- min" Foreground="#BAC2DE" FontSize="12" Margin="0,2,0,0"/>
            </StackPanel>

            <!-- DOWN Direction -->
            <StackPanel Name="DownPanel" Grid.Row="3" Margin="0,0,0,8" Visibility="Collapsed">
                <TextBlock Name="DownDestTxt" Text="Towards: ---" Foreground="#F9E2AF" FontSize="12" FontWeight="Bold"/>
                <TextBlock Name="DownEtaTxt" Text="--- min, --- min" Foreground="#BAC2DE" FontSize="12" Margin="0,2,0,0"/>
            </StackPanel>

            <!-- Footer / Last Update -->
            <TextBlock Name="TimeTxt" Grid.Row="4" Text="Last Update: ---" Foreground="#585B70" FontSize="10" HorizontalAlignment="Right"/>
        </Grid>
    </Border>
</Window>
"@

$window = [System.Windows.Markup.XamlReader]::Parse($xaml)

# Find Elements
$headerGrid = $window.FindName("HeaderGrid")
$closeBtn   = $window.FindName("CloseBtn")
$statusBdr  = $window.FindName("StatusBorder")
$statusTxt  = $window.FindName("StatusTxt")
$upPanel    = $window.FindName("UpPanel")
$upDestTxt  = $window.FindName("UpDestTxt")
$upEtaTxt   = $window.FindName("UpEtaTxt")
$downPanel  = $window.FindName("DownPanel")
$downDestTxt= $window.FindName("DownDestTxt")
$downEtaTxt = $window.FindName("DownEtaTxt")
$timeTxt    = $window.FindName("TimeTxt")
$bc = [System.Windows.Media.BrushConverter]::new()

# Drag to move
$headerGrid.Add_MouseDown({
    if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) { $window.DragMove() }
})

# Close Button
$closeBtn.Add_Click({ $window.Close() })

# Main Data Fetch Function
function Update-MTRData {
    $url = "https://rt.data.gov.hk/v1/transport/mtr/getSchedule.php?line=$favoriteLine&sta=$favoriteStation"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Method Get -ErrorAction Stop
        
        # UI Updates must be on the Dispatcher thread
        $window.Dispatcher.Invoke([Action]{
            if ($response.status -eq 0) {
                $statusBdr.Background = $bc.ConvertFromString("#F38BA8") # Red
                $statusTxt.Text = "API Error or Major Disruption"
                return
            }

            # Update Delay Status
            if ($response.isdelay -eq "Y") {
                $statusBdr.Background = $bc.ConvertFromString("#F38BA8") # Red
                $statusTxt.Text = "🚨 DELAY ON $favoriteLine"
            } else {
                $statusBdr.Background = $bc.ConvertFromString("#A6E3A1") # Green
                $statusTxt.Text = "✅ Normal Service"
            }

            $stationKey = "$favoriteLine-$favoriteStation"
            $stationData = $response.data.$stationKey

            # UP Direction Update
            if ($null -ne $stationData.UP -and $stationData.UP.Count -gt 0) {
                $upPanel.Visibility = [System.Windows.Visibility]::Visible
                $upDestTxt.Text = "Towards: $($stationData.UP[0].dest)"
                $etaStr = "$($stationData.UP[0].ttnt) min"
                if ($stationData.UP.Count -gt 1) { $etaStr += ", $($stationData.UP[1].ttnt) min" }
                $upEtaTxt.Text = $etaStr
            } else {
                $upPanel.Visibility = [System.Windows.Visibility]::Collapsed
            }

            # DOWN Direction Update
            if ($null -ne $stationData.DOWN -and $stationData.DOWN.Count -gt 0) {
                $downPanel.Visibility = [System.Windows.Visibility]::Visible
                $downDestTxt.Text = "Towards: $($stationData.DOWN[0].dest)"
                $etaStr = "$($stationData.DOWN[0].ttnt) min"
                if ($stationData.DOWN.Count -gt 1) { $etaStr += ", $($stationData.DOWN[1].ttnt) min" }
                $downEtaTxt.Text = $etaStr
            } else {
                $downPanel.Visibility = [System.Windows.Visibility]::Collapsed
            }

            $timeTxt.Text = "Last Update: $($response.curr_time)"
        })
    } catch {
        $window.Dispatcher.Invoke([Action]{
            $statusBdr.Background = $bc.ConvertFromString("#F9E2AF") # Yellow
            $statusTxt.Text = "Connection Error... Retrying"
        })
    }
}

# Timer for Auto-Refresh
$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromSeconds($refreshIntervalSeconds)
$timer.Add_Tick({ Update-MTRData })

# Initial fetch and start
Update-MTRData
$timer.Start()

$window.ShowDialog() | Out-Null
