Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Ensure paths resolve to the script's exact directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
if (-not $scriptDir) { $scriptDir = [Environment]::CurrentDirectory }

$configPath = Join-Path $scriptDir "Launcher_Config.csv"
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WidgetControlPanel.lnk"

# Main Launcher Window XAML
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Widget Control Panel" Height="520" Width="360" MinHeight="380" MinWidth="300"
        WindowStyle="None" AllowsTransparency="True" 
        Background="Transparent" Topmost="True" 
        ResizeMode="CanResizeWithGrip" WindowStartupLocation="CenterScreen">
    <Border Name="MainBorder" Background="#CC1E1E2E" CornerRadius="20" BorderBrush="#45475A" BorderThickness="1.5" Margin="10">
        <Border.Effect>
            <DropShadowEffect BlurRadius="25" Color="#000000" Opacity="0.6" ShadowDepth="6"/>
        </Border.Effect>
        <Grid Margin="16">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Header Bar -->
            <Grid Grid.Row="0" Margin="0,0,0,10" Background="Transparent" Name="HeaderGrid">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TitleText" Text="🎛️ Control Panel" Foreground="#CDD6F4" FontSize="16" FontWeight="Bold"/>
                </StackPanel>

                <Button Name="MinBtn" Grid.Column="1" Content="─" Foreground="#A6ADC8" Background="Transparent" BorderThickness="0" FontSize="14" FontWeight="Bold" Cursor="Hand" Width="22" Height="22" Margin="0,0,2,0"/>
                <Button Name="CloseBtn" Grid.Column="2" Content="✕" Foreground="#A6ADC8" Background="Transparent" BorderThickness="0" FontSize="15" FontWeight="Bold" Cursor="Hand" Width="22" Height="22"/>
            </Grid>

            <!-- Sub-Header Toolbar (Below Header Bar) -->
            <DockPanel Grid.Row="1" Margin="0,0,0,10">
                <Button Name="ModeToggleBtn" Content="⚙️ Backstage" Foreground="#11111B" Background="#89B4FA" 
                        BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,6,0" Cursor="Hand" DockPanel.Dock="Left">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="PinBtn" Content="📌 Pinned" Foreground="#11111B" Background="#89B4FA" 
                        BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Cursor="Hand" DockPanel.Dock="Left">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </DockPanel>

            <!-- Main Content Area -->
            <Grid Grid.Row="2">
                <!-- Normal View: 2 Buttons Per Row Grid -->
                <ScrollViewer Name="NormalViewContainer" VerticalScrollBarVisibility="Auto">
                    <UniformGrid Name="TileWrapContainer" Columns="2" HorizontalAlignment="Stretch" VerticalAlignment="Top"/>
                </ScrollViewer>

                <!-- Backstage View: Settings and Configuration Management -->
                <ScrollViewer Name="BackstageViewContainer" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Name="BackstageStackContainer">
                        <TextBlock Text="Manage Launch Buttons:" Foreground="#89B4FA" FontSize="12" FontWeight="Bold" Margin="0,0,0,8"/>
                        <StackPanel Name="BackstageItemRows"/>
                        
                        <Button Name="AddTileBtn" Content="+ Add New Widget Launcher" Foreground="#11111B" Background="#A6E3A1" BorderThickness="0" FontWeight="Bold" FontSize="12" Padding="0,7" Margin="0,10,0,0" Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- Footer Controls -->
            <DockPanel Grid.Row="3" Margin="0,8,0,0">
                <Button Name="StartupBtn" Content="🚀 Startup: OFF" Foreground="#BAC2DE" Background="#313244" BorderThickness="0" FontSize="11" Padding="8,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <TextBlock Name="FooterText" Text="Click tiles to toggle widgets" Foreground="#585B70" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </DockPanel>
        </Grid>
    </Border>
</Window>
'@

# Direct WPF Window Loading
$window = [System.Windows.Markup.XamlReader]::Parse($xaml)

# Element References
$mainBorder             = $window.FindName('MainBorder')
$headerGrid             = $window.FindName('HeaderGrid')
$titleText              = $window.FindName('TitleText')
$modeToggleBtn          = $window.FindName('ModeToggleBtn')
$pinBtn                 = $window.FindName('PinBtn')
$minBtn                 = $window.FindName('MinBtn')
$closeBtn               = $window.FindName('CloseBtn')
$normalViewContainer    = $window.FindName('NormalViewContainer')
$tileWrapContainer      = $window.FindName('TileWrapContainer')
$backstageViewContainer = $window.FindName('BackstageViewContainer')
$backstageItemRows      = $window.FindName('BackstageItemRows')
$addTileBtn             = $window.FindName('AddTileBtn')
$startupBtn             = $window.FindName('StartupBtn')
$footerText             = $window.FindName('FooterText')

# Application State
$global:launcherItems = [System.Collections.Generic.List[PSObject]]::new()
$global:isBackstageMode = $false

# Load Config
function Load-Config {
    if (-not (Test-Path $configPath)) {
        $defaultPath = Join-Path $scriptDir "RunWidget.bat"
        $defaultItems = @(
            [PSCustomObject]@{ Id = [Guid]::NewGuid().ToString(); Name = "Daily Assistant"; Path = $defaultPath; Icon = "⚡" }
        )
        $defaultItems | Export-Csv -Path $configPath -NoTypeInformation -Encoding utf8
    }

    try {
        $items = Import-Csv -Path $configPath -Encoding utf8 -ErrorAction Stop
        $global:launcherItems.Clear()
        if ($items) {
            foreach ($i in @($items)) { $global:launcherItems.Add($i) }
        }
    } catch { }
}

function Save-Config {
    try {
        $global:launcherItems | Export-Csv -Path $configPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
    } catch { }
}

# Run Target File
function Launch-Target ($targetPath) {
    if (-not (Test-Path $targetPath)) {
        [System.Windows.MessageBox]::Show("Specified file path does not exist:`n$targetPath", "File Not Found")
        return
    }

    $ext = [System.IO.Path]::GetExtension($targetPath).ToLower()
    try {
        if ($ext -eq ".ps1") {
            Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File `"$targetPath`"" -WorkingDirectory (Split-Path -Parent $targetPath)
        } elseif ($ext -eq ".bat" -or $ext -eq ".cmd") {
            Start-Process cmd -ArgumentList "/c `"$targetPath`"" -WorkingDirectory (Split-Path -Parent $targetPath) -WindowStyle Hidden
        } else {
            Start-Process $targetPath -WorkingDirectory (Split-Path -Parent $targetPath)
        }
    } catch {
        [System.Windows.MessageBox]::Show("Failed to launch file:`n$_", "Execution Error")
    }
}

# Render Normal View Tiles (2 Per Row)
function Render-NormalView {
    $tileWrapContainer.Children.Clear()
    $bc = [System.Windows.Media.BrushConverter]::new()

    if ($global:launcherItems.Count -eq 0) {
        $emptyText = New-Object System.Windows.Controls.TextBlock
        $emptyText.Text = "No widget tiles configured.`nClick '⚙️ Backstage' to add buttons."
        $emptyText.Foreground = $bc.ConvertFromString("#7F849C")
        $emptyText.FontSize = 12
        $emptyText.TextAlignment = [System.Windows.TextAlignment]::Center
        $emptyText.Margin = New-Object System.Windows.Thickness(0,30,0,0)
        [System.Windows.Controls.Grid]::SetColumnSpan($emptyText, 2)
        $tileWrapContainer.Children.Add($emptyText) | Out-Null
        return
    }

    foreach ($item in $global:launcherItems) {
        $btn = New-Object System.Windows.Controls.Button
        $btn.Height = 80
        $btn.Margin = New-Object System.Windows.Thickness(4)
        $btn.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Stretch
        $btn.Background = $bc.ConvertFromString("#181825")
        $btn.Foreground = $bc.ConvertFromString("#CDD6F4")
        $btn.BorderThickness = 0
        $btn.Cursor = [System.Windows.Input.Cursors]::Hand
        $btn.Tag = $item.Path

        $btnTemplate = @"
<ControlTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" TargetType="Button">
    <Border Name="bd" Background="{TemplateBinding Background}" CornerRadius="12" Padding="8">
        <Border.Effect>
            <DropShadowEffect BlurRadius="8" Color="#000000" Opacity="0.3" ShadowDepth="2"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <TextBlock Text="$($item.Icon)" FontSize="22" HorizontalAlignment="Center" VerticalAlignment="Center"/>
            <TextBlock Grid.Row="1" Text="$($item.Name)" FontSize="12" FontWeight="Bold" Foreground="#CDD6F4" HorizontalAlignment="Center" TextTrimming="CharacterEllipsis"/>
        </Grid>
    </Border>
</ControlTemplate>
"@
        $btn.Template = [System.Windows.Markup.XamlReader]::Parse($btnTemplate)

        $btn.Add_Click({
            Launch-Target $this.Tag
        })

        $tileWrapContainer.Children.Add($btn) | Out-Null
    }
}

# Render Backstage Management View
function Render-BackstageView {
    $backstageItemRows.Children.Clear()
    $bc = [System.Windows.Media.BrushConverter]::new()

    foreach ($item in $global:launcherItems) {
        $card = New-Object System.Windows.Controls.Border
        $card.Background = $bc.ConvertFromString("#181825")
        $card.CornerRadius = New-Object System.Windows.CornerRadius(10)
        $card.Padding = New-Object System.Windows.Thickness(8)
        $card.Margin = New-Object System.Windows.Thickness(0,0,0,8)

        $stack = New-Object System.Windows.Controls.StackPanel

        # Row 1: Icon + Name Input + Delete
        $row1 = New-Object System.Windows.Controls.Grid
        $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = [System.Windows.GridLength]::Auto
        $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = [System.Windows.GridLength]::Auto
        $row1.ColumnDefinitions.Add($col1); $row1.ColumnDefinitions.Add($col2); $row1.ColumnDefinitions.Add($col3)

        $iconBox = New-Object System.Windows.Controls.TextBox
        $iconBox.Text = $item.Icon
        $iconBox.Width = 30
        $iconBox.Background = $bc.ConvertFromString("#313244")
        $iconBox.Foreground = $bc.ConvertFromString("#CDD6F4")
        $iconBox.BorderThickness = 0
        $iconBox.Padding = New-Object System.Windows.Thickness(4,3,4,3)
        $iconBox.Margin = New-Object System.Windows.Thickness(0,0,6,4)
        $iconBox.Tag = $item
        $iconBox.Add_TextChanged({ $this.Tag.Icon = $this.Text; Save-Config })
        [System.Windows.Controls.Grid]::SetColumn($iconBox, 0)

        $nameBox = New-Object System.Windows.Controls.TextBox
        $nameBox.Text = $item.Name
        $nameBox.Background = $bc.ConvertFromString("#313244")
        $nameBox.Foreground = $bc.ConvertFromString("#CDD6F4")
        $nameBox.BorderThickness = 0
        $nameBox.FontSize = 12
        $nameBox.FontWeight = [System.Windows.FontWeights]::Bold
        $nameBox.Padding = New-Object System.Windows.Thickness(6,3,6,3)
        $nameBox.Margin = New-Object System.Windows.Thickness(0,0,6,4)
        $nameBox.Tag = $item
        $nameBox.Add_TextChanged({ $this.Tag.Name = $this.Text; Save-Config })
        [System.Windows.Controls.Grid]::SetColumn($nameBox, 1)

        $delBtn = New-Object System.Windows.Controls.Button
        $delBtn.Content = "🗑"
        $delBtn.Foreground = $bc.ConvertFromString("#E64553")
        $delBtn.Background = [System.Windows.Media.Brushes]::Transparent
        $delBtn.BorderThickness = 0
        $delBtn.FontSize = 12
        $delBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $delBtn.Tag = $item
        $delBtn.Add_Click({
            $global:launcherItems.Remove($this.Tag) | Out-Null
            Save-Config
            Render-BackstageView
        })
        [System.Windows.Controls.Grid]::SetColumn($delBtn, 2)

        $row1.Children.Add($iconBox) | Out-Null
        $row1.Children.Add($nameBox) | Out-Null
        $row1.Children.Add($delBtn) | Out-Null

        # Row 2: Path Input + File Browser
        $row2 = New-Object System.Windows.Controls.Grid
        $pCol1 = New-Object System.Windows.Controls.ColumnDefinition; $pCol1.Width = New-Object System.Windows.GridLength(1, [System.Windows.GridUnitType]::Star)
        $pCol2 = New-Object System.Windows.Controls.ColumnDefinition; $pCol2.Width = [System.Windows.GridLength]::Auto
        $row2.ColumnDefinitions.Add($pCol1); $row2.ColumnDefinitions.Add($pCol2)

        $pathBox = New-Object System.Windows.Controls.TextBox
        $pathBox.Text = $item.Path
        $pathBox.Background = $bc.ConvertFromString("#313244")
        $pathBox.Foreground = $bc.ConvertFromString("#BAC2DE")
        $pathBox.BorderThickness = 0
        $pathBox.FontSize = 11
        $pathBox.Padding = New-Object System.Windows.Thickness(6,3,6,3)
        $pathBox.Margin = New-Object System.Windows.Thickness(0,0,4,0)
        $pathBox.Tag = $item
        $pathBox.Add_TextChanged({ $this.Tag.Path = $this.Text; Save-Config })
        [System.Windows.Controls.Grid]::SetColumn($pathBox, 0)

        $browseBtn = New-Object System.Windows.Controls.Button
        $browseBtn.Content = "📂"
        $browseBtn.Foreground = $bc.ConvertFromString("#CDD6F4")
        $browseBtn.Background = $bc.ConvertFromString("#45475A")
        $browseBtn.BorderThickness = 0
        $browseBtn.FontSize = 11
        $browseBtn.Padding = New-Object System.Windows.Thickness(6,2,6,2)
        $browseBtn.Cursor = [System.Windows.Input.Cursors]::Hand
        $browseBtn.Tag = $pathBox
        $browseBtn.Add_Click({
            $ofd = New-Object System.Windows.Forms.OpenFileDialog
            $ofd.Filter = "Script & Executable Files (*.bat;*.ps1;*.exe)|*.bat;*.ps1;*.exe|All Files (*.*)|*.*"
            if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $this.Tag.Text = $ofd.FileName
            }
        })
        [System.Windows.Controls.Grid]::SetColumn($browseBtn, 1)

        $row2.Children.Add($pathBox) | Out-Null
        $row2.Children.Add($browseBtn) | Out-Null

        $stack.Children.Add($row1) | Out-Null
        $stack.Children.Add($row2) | Out-Null
        $card.Child = $stack

        $backstageItemRows.Children.Add($card) | Out-Null
    }
}

# Toggle Between Dashboard Mode and Backstage Mode
$modeToggleBtn.Add_Click({
    $global:isBackstageMode = -not $global:isBackstageMode
    $bc = [System.Windows.Media.BrushConverter]::new()

    if ($global:isBackstageMode) {
        $normalViewContainer.Visibility = [System.Windows.Visibility]::Collapsed
        $backstageViewContainer.Visibility = [System.Windows.Visibility]::Visible
        $modeToggleBtn.Content = "📋 Normal View"
        $modeToggleBtn.Background = $bc.ConvertFromString("#A6E3A1")
        $footerText.Text = "Backstage: Configure paths and titles"
        Render-BackstageView
    } else {
        $backstageViewContainer.Visibility = [System.Windows.Visibility]::Collapsed
        $normalViewContainer.Visibility = [System.Windows.Visibility]::Visible
        $modeToggleBtn.Content = "⚙️ Backstage"
        $modeToggleBtn.Background = $bc.ConvertFromString("#89B4FA")
        $footerText.Text = "Click tiles to toggle widgets"
        Render-NormalView
    }
})

# Add New Launcher Tile Action
$addTileBtn.Add_Click({
    $newItem = [PSCustomObject]@{
        Id   = [Guid]::NewGuid().ToString()
        Name = "New Widget"
        Path = "C:\Path\To\Widget.bat"
        Icon = "🚀"
    }
    $global:launcherItems.Add($newItem)
    Save-Config
    Render-BackstageView
})

# Pin & Startup Helpers
function Update-PinStatus {
    $bc = [System.Windows.Media.BrushConverter]::new()
    if ($window.Topmost) {
        $pinBtn.Content = "📌 Pinned"
        $pinBtn.Background = $bc.ConvertFromString("#89B4FA")
    } else {
        $pinBtn.Content = "📌 Unpinned"
        $pinBtn.Background = $bc.ConvertFromString("#45475A")
    }
}

function Update-StartupStatus {
    $bc = [System.Windows.Media.BrushConverter]::new()
    if (Test-Path $startupShortcut) {
        $startupBtn.Content = "🚀 Startup: ON"
        $startupBtn.Background = $bc.ConvertFromString("#A6E3A1")
        $startupBtn.Foreground = $bc.ConvertFromString("#11111B")
    } else {
        $startupBtn.Content = "🚀 Startup: OFF"
        $startupBtn.Background = $bc.ConvertFromString("#313244")
        $startupBtn.Foreground = $bc.ConvertFromString("#BAC2DE")
    }
}

$pinBtn.Add_Click({
    $window.Topmost = -not $window.Topmost
    Update-PinStatus
})

$startupBtn.Add_Click({
    if (Test-Path $startupShortcut) {
        Remove-Item $startupShortcut -Force
    } else {
        $batPath = Join-Path $scriptDir "RunLauncher.bat"
        $wsh = New-Object -ComObject WScript.Shell
        $sc = $wsh.CreateShortcut($startupShortcut)
        $sc.TargetPath = $batPath
        $sc.WorkingDirectory = $scriptDir
        $sc.Save()
    }
    Update-StartupStatus
})

# Basic Window Controls
$headerGrid.Add_MouseDown({
    if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) { $window.DragMove() }
})

$minBtn.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$closeBtn.Add_Click({ $window.Close() })

# Initialization Sequence
Load-Config
Render-NormalView
Update-PinStatus
Update-StartupStatus

$window.ShowDialog() | Out-Null
