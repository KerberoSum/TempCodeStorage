Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, Microsoft.VisualBasic

# Native Win32 API for robust window restoration and focus
$win32Api = @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class Win32Launcher {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    public static IntPtr GetMainWindow(int pid) {
        IntPtr bestHandle = IntPtr.Zero;
        EnumWindows((hWnd, lParam) => {
            uint windowPid;
            GetWindowThreadProcessId(hWnd, out windowPid);
            if (windowPid == pid && IsWindowVisible(hWnd)) {
                bestHandle = hWnd;
                return false; 
            }
            return true;
        }, IntPtr.Zero);
        return bestHandle;
    }

    // NEW: Searches for any visible window that contains the button's name
    public static int FindPidByTitleMatch(string titlePart) {
        if (string.IsNullOrEmpty(titlePart)) return 0;
        int outPid = 0;
        EnumWindows((hWnd, lParam) => {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    if (sb.ToString().IndexOf(titlePart, StringComparison.OrdinalIgnoreCase) >= 0) {
                        uint tempPid;
                        GetWindowThreadProcessId(hWnd, out tempPid);
                        outPid = (int)tempPid;
                        return false; 
                    }
                }
            }
            return true;
        }, IntPtr.Zero);
        return outPid;
    }
}
"@
Add-Type -TypeDefinition $win32Api -ErrorAction SilentlyContinue

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
if (-not $scriptDir) { $scriptDir = [Environment]::CurrentDirectory }

$configPath = Join-Path $scriptDir "Launcher_Config.csv"
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\WidgetControlPanel.lnk"

function Resolve-WidgetPath ($rawPath) {
    if (-not $rawPath) { return "" }
    $clean = $rawPath.Trim().Trim('"', "'").Trim()
    if (-not $clean) { return "" }

    if (-not [System.IO.Path]::IsPathRooted($clean)) {
        $combined = Join-Path $scriptDir $clean
        if (Test-Path -LiteralPath $combined) { return (Get-Item -LiteralPath $combined).FullName }
    }
    if (Test-Path -LiteralPath $clean) { return (Get-Item -LiteralPath $clean).FullName }
    return $clean
}

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

            <DockPanel Grid.Row="1" Margin="0,0,0,10">
                <Button Name="ModeToggleBtn" Content="⚙️ Backstage" Foreground="#11111B" Background="#89B4FA" 
                        BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,6,0" Cursor="Hand" DockPanel.Dock="Left">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="PinBtn" Content="📌 Pinned" Foreground="#11111B" Background="#89B4FA" 
                        BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Cursor="Hand" DockPanel.Dock="Left">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </DockPanel>

            <Grid Grid.Row="2">
                <ScrollViewer Name="NormalViewContainer" VerticalScrollBarVisibility="Auto">
                    <UniformGrid Name="TileWrapContainer" Columns="2" HorizontalAlignment="Stretch" VerticalAlignment="Top"/>
                </ScrollViewer>

                <ScrollViewer Name="BackstageViewContainer" VerticalScrollBarVisibility="Auto" Visibility="Collapsed">
                    <StackPanel Name="BackstageStackContainer">
                        <TextBlock Text="Manage Launch Buttons:" Foreground="#89B4FA" FontSize="12" FontWeight="Bold" Margin="0,0,0,8"/>
                        <StackPanel Name="BackstageItemRows"/>
                        
                        <Button Name="AddTileBtn" Content="+ Add New Widget Launcher" Foreground="#11111B" Background="#A6E3A1" BorderThickness="0" FontWeight="Bold" FontSize="12" Padding="0,7" Margin="0,10,0,0" Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <DockPanel Grid.Row="3" Margin="0,8,0,0">
                <Button Name="StartupBtn" Content="🚀 Startup: OFF" Foreground="#BAC2DE" Background="#313244" BorderThickness="0" FontSize="11" Padding="8,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}" Cursor="Hand">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <TextBlock Name="FooterText" Text="Click to launch, Hover to manage" Foreground="#585B70" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </DockPanel>
        </Grid>
    </Border>
</Window>
'@

$window = [System.Windows.Markup.XamlReader]::Parse($xaml)

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

$global:launcherItems = [System.Collections.Generic.List[PSObject]]::new()
$global:tileControls  = [System.Collections.Generic.List[PSObject]]::new()
$global:isBackstageMode = $false

function Load-Config {
    if (-not (Test-Path -LiteralPath $configPath)) {
        $defaultPath = Join-Path $scriptDir "RunWidget.bat"
        $defaultItems = @([PSCustomObject]@{ Id = [Guid]::NewGuid().ToString(); Name = "Daily Assistant"; Path = $defaultPath; Icon = "⚡" })
        $defaultItems | Export-Csv -Path $configPath -NoTypeInformation -Encoding utf8
    }
    try {
        $items = Import-Csv -Path $configPath -Encoding utf8 -ErrorAction Stop
        $global:launcherItems.Clear()
        if ($items) { foreach ($i in @($items)) { $global:launcherItems.Add($i) } }
    } catch { }
}

function Save-Config {
    try { $global:launcherItems | Export-Csv -Path $configPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop } catch { }
}

function Start-WidgetFile ($resolvedPath) {
    $ext = [System.IO.Path]::GetExtension($resolvedPath).ToLower()
    $psi = New-Object System.Diagnostics.ProcessStartInfo

    if ($ext -eq ".ps1") {
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-ExecutionPolicy Bypass -NoProfile -WindowStyle Normal -File `"$resolvedPath`""
        $psi.UseShellExecute = $false
    } elseif ($ext -eq ".bat" -or $ext -eq ".cmd") {
        $psi.FileName = "cmd.exe"
        $psi.Arguments = "/c `"$resolvedPath`""
        $psi.UseShellExecute = $false
    } else {
        $psi.FileName = $resolvedPath
        $psi.UseShellExecute = $true
    }

    $psi.WorkingDirectory = Split-Path -Parent $resolvedPath
    try { return [System.Diagnostics.Process]::Start($psi) } catch { return $null }
}

function Activate-Target ($ctrlData) {
    $resolvedPath = Resolve-WidgetPath $ctrlData.Item.Path
    if (-not $resolvedPath -or -not (Test-Path -LiteralPath $resolvedPath)) { return }

    $activated = $false
    $myPid = $PID

    # 1. Bring to front if we already know the process ID
    if ($ctrlData.Pids -and $ctrlData.Pids.Count -gt 0) {
        foreach ($pid in $ctrlData.Pids) {
            $hwnd = [Win32Launcher]::GetMainWindow($pid)
            if ($hwnd -ne [IntPtr]::Zero) {
                if ([Win32Launcher]::IsIconic($hwnd)) { [Win32Launcher]::ShowWindow($hwnd, 9) }
                [Win32Launcher]::SetForegroundWindow($hwnd)
                $activated = $true
                break
            }
        }
    }

    # 2. If known PIDs failed, search for a window with the exact Button Name
    if (-not $activated -and $ctrlData.Item.Name) {
        $titlePid = [Win32Launcher]::FindPidByTitleMatch($ctrlData.Item.Name)
        if ($titlePid -gt 0 -and $titlePid -ne $myPid) {
            $hwnd = [Win32Launcher]::GetMainWindow($titlePid)
            if ($hwnd -ne [IntPtr]::Zero) {
                if ([Win32Launcher]::IsIconic($hwnd)) { [Win32Launcher]::ShowWindow($hwnd, 9) }
                [Win32Launcher]::SetForegroundWindow($hwnd)
                $activated = $true
                if ($titlePid -notin $ctrlData.Pids) { $ctrlData.Pids += $titlePid }
            }
        }
    }

    # 3. Launch new instance ONLY if not already activated
    if (-not $activated) {
        $proc = Start-WidgetFile $resolvedPath
        if ($proc -and $proc.Id) {
            $ctrlData.Pids += $proc.Id
        }
    }

    Start-Sleep -Milliseconds 300
    Check-WidgetStatus
}

function Close-Target ($ctrlData) {
    $myPid = $PID

    # 1. Kill known PIDs and their children using Taskkill
    if ($ctrlData.Pids) {
        foreach ($pid in $ctrlData.Pids) { 
            if ($pid -ne $myPid) { & taskkill.exe /PID $pid /T /F 2>$null }
        }
    }
    
    # 2. Sweep by Window Title Match (kills child processes that detached)
    if ($ctrlData.Item.Name) {
        $titlePid = [Win32Launcher]::FindPidByTitleMatch($ctrlData.Item.Name)
        if ($titlePid -gt 0 -and $titlePid -ne $myPid) {
            & taskkill.exe /PID $titlePid /T /F 2>$null
        }
    }
    
    # 3. Fallback Sweep by script filename
    $resolvedPath = Resolve-WidgetPath $ctrlData.Item.Path
    if ($resolvedPath -and (Test-Path -LiteralPath $resolvedPath)) {
        $ext = [System.IO.Path]::GetExtension($resolvedPath).ToLower()
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($resolvedPath)
        
        if ($ext -eq ".exe") {
            Stop-Process -Name $baseName -Force -ErrorAction SilentlyContinue
        } else {
            $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe' OR Name='pwsh.exe' OR Name='cmd.exe'" -Property ProcessId, CommandLine -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                if ($p.ProcessId -ne $myPid -and $p.CommandLine -and $p.CommandLine.Contains($baseName)) {
                    & taskkill.exe /PID $p.ProcessId /T /F 2>$null
                }
            }
        }
    }

    $ctrlData.Pids = @()
    Start-Sleep -Milliseconds 300
    Check-WidgetStatus
}

function Check-WidgetStatus {
    $myPid = $PID
    $bc = [System.Windows.Media.BrushConverter]::new()

    foreach ($ctrl in $global:tileControls) {
        $foundPids = @()

        # 1. Check if explicitly tracked PIDs are still alive
        if ($ctrl.Pids) {
            foreach ($pid in $ctrl.Pids) {
                $p = Get-Process -Id $pid -ErrorAction SilentlyContinue
                if ($p -and -not $p.HasExited) { $foundPids += $pid }
            }
        }

        # 2. Check if a window exists matching the button name
        if ($foundPids.Count -eq 0 -and $ctrl.Item.Name) {
            $titlePid = [Win32Launcher]::FindPidByTitleMatch($ctrl.Item.Name)
            if ($titlePid -gt 0 -and $titlePid -ne $myPid) {
                $foundPids += $titlePid
            }
        }

        # Keep unique PIDs
        $uniquePids = @()
        foreach ($p in $foundPids) { if ($p -notin $uniquePids) { $uniquePids += $p } }
        $ctrl.Pids = $uniquePids

        # Update UI Colors
        $window.Dispatcher.Invoke([Action]{
            if ($uniquePids.Count -gt 0) {
                $ctrl.Border.Background = $bc.ConvertFromString("#A6E3A1")
                $ctrl.NameTxt.Foreground = $bc.ConvertFromString("#11111B")
                $ctrl.IconTxt.Foreground = $bc.ConvertFromString("#11111B")
            } else {
                $ctrl.Border.Background = $bc.ConvertFromString("#181825")
                $ctrl.NameTxt.Foreground = $bc.ConvertFromString("#CDD6F4")
                $ctrl.IconTxt.Foreground = $bc.ConvertFromString("#CDD6F4")
                $ctrl.Overlay.Visibility = [System.Windows.Visibility]::Collapsed
            }
        }) | Out-Null
    }
}

function Render-NormalView {
    $tileWrapContainer.Children.Clear()
    $global:tileControls.Clear()
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
        $tileXaml = @"
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Name="MainBorder" Background="#181825" CornerRadius="12" Margin="4" Height="85" Cursor="Hand">
    <Border.Effect>
        <DropShadowEffect BlurRadius="8" Color="#000000" Opacity="0.3" ShadowDepth="2"/>
    </Border.Effect>
    <Grid Name="TileGrid" Background="Transparent">
        <StackPanel VerticalAlignment="Center" IsHitTestVisible="False">
            <TextBlock Name="IconTxt" Text="$($item.Icon)" FontSize="24" HorizontalAlignment="Center"/>
            <TextBlock Name="NameTxt" Text="$($item.Name)" FontSize="12" FontWeight="Bold" Foreground="#CDD6F4" HorizontalAlignment="Center" Margin="0,4,0,0" TextTrimming="CharacterEllipsis"/>
        </StackPanel>
        
        <Border Name="OverlayBorder" Background="#F01E1E2E" CornerRadius="12" Visibility="Collapsed" Cursor="Hand">
            <Grid Margin="6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                
                <Button Name="ActivateBtn" Grid.Column="0" Content="▶ Show" Background="#89B4FA" Foreground="#11111B" FontWeight="Bold" FontSize="11" Margin="0,0,3,0" BorderThickness="0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Cursor="Hand">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                
                <Button Name="CloseBtn" Grid.Column="1" Content="✕ Close" Background="#E64553" Foreground="#FFFFFF" FontWeight="Bold" FontSize="11" Margin="3,0,0,0" BorderThickness="0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Cursor="Hand">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </Grid>
        </Border>
    </Grid>
</Border>
"@
        $parsedTile = [System.Windows.Markup.XamlReader]::Parse($tileXaml)
        
        $mainBdr    = $parsedTile.FindName("MainBorder")
        $iconTxt    = $parsedTile.FindName("IconTxt")
        $nameTxt    = $parsedTile.FindName("NameTxt")
        $overlay    = $parsedTile.FindName("OverlayBorder")
        $actBtn     = $parsedTile.FindName("ActivateBtn")
        $clsBtn     = $parsedTile.FindName("CloseBtn")

        $ctrlData = [PSCustomObject]@{
            Item     = $item
            Border   = $mainBdr
            IconTxt  = $iconTxt
            NameTxt  = $nameTxt
            Overlay  = $overlay
            Pids     = @()
        }
        $global:tileControls.Add($ctrlData)

        $mainBdr.Tag = $ctrlData
        $actBtn.Tag  = $ctrlData
        $clsBtn.Tag  = $ctrlData

        # Hover Events: Overlay ONLY shows if the target is currently running
        $mainBdr.Add_MouseEnter({
            if ($this.Tag.Pids.Count -gt 0) {
                $this.Tag.Overlay.Visibility = [System.Windows.Visibility]::Visible
            }
        })
        $mainBdr.Add_MouseLeave({
            $this.Tag.Overlay.Visibility = [System.Windows.Visibility]::Collapsed
        })

        # Clicks
        $mainBdr.Add_MouseLeftButtonDown({ Activate-Target $this.Tag })
        $actBtn.Add_Click({ Activate-Target $this.Tag })
        $clsBtn.Add_Click({ Close-Target $this.Tag })

        $tileWrapContainer.Children.Add($parsedTile) | Out-Null
    }

    Check-WidgetStatus
}

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
            $ofd.Filter = "Script and Executable Files (*.bat;*.ps1;*.exe)|*.bat;*.ps1;*.exe|All Files (*.*)|*.*"
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
        $footerText.Text = "Click to launch, Hover to manage"
        Render-NormalView
    }
})

$addTileBtn.Add_Click({
    $newItem = [PSCustomObject]@{
        Id   = [Guid]::NewGuid().ToString()
        Name = "New Widget"
        Path = "RunWidget.bat"
        Icon = "🚀"
    }
    $global:launcherItems.Add($newItem)
    Save-Config
    Render-BackstageView
})

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
    if (Test-Path -LiteralPath $startupShortcut) {
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
    if (Test-Path -LiteralPath $startupShortcut) {
        Remove-Item -LiteralPath $startupShortcut -Force
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

$headerGrid.Add_MouseDown({
    if ($_.ChangedButton -eq [System.Windows.Input.MouseButton]::Left) { $window.DragMove() }
})

$minBtn.Add_Click({ $window.WindowState = [System.Windows.WindowState]::Minimized })
$closeBtn.Add_Click({ $window.Close() })

$statusTimer = New-Object System.Windows.Threading.DispatcherTimer
$statusTimer.Interval = [TimeSpan]::FromSeconds(2)
$statusTimer.Add_Tick({ if (-not $global:isBackstageMode) { Check-WidgetStatus } })

Load-Config
Render-NormalView
Update-PinStatus
Update-StartupStatus
$statusTimer.Start()

$window.ShowDialog() | Out-Null
