Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# Ensure paths resolve to the script's exact directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $scriptDir) { $scriptDir = $PSScriptRoot }
if (-not $scriptDir) { $scriptDir = [Environment]::CurrentDirectory }

$filePath = Join-Path $scriptDir "Widget_Data.csv"
$tagPath  = Join-Path $scriptDir "Widget_Tags.csv"
$startupShortcut = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\DesktopWidget.lnk"

# Main Window XAML
$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Daily Operations Assistant" Height="700" Width="400" MinHeight="500" MinWidth="340"
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
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            
            <!-- Header -->
            <Grid Grid.Row="0" Margin="0,0,0,12" Background="Transparent" Name="HeaderGrid">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="TitleText" Text="⚡ Daily Assistant" Foreground="#CDD6F4" FontSize="17" FontWeight="Bold"/>
                </StackPanel>
                
                <Button Name="CollapseBtn" Grid.Column="1" Content="🔼" Foreground="#CDD6F4" Background="Transparent" 
                        BorderThickness="0" FontSize="13" Margin="0,0,4,0" Cursor="Hand" Width="26" Height="26" ToolTip="Toggle Input Panel"/>

                <Button Name="ThemeBtn" Grid.Column="2" Content="🌙" Foreground="#CDD6F4" Background="Transparent" 
                        BorderThickness="0" FontSize="15" Margin="0,0,6,0" Cursor="Hand" Width="26" Height="26"/>

                <Button Name="PinBtn" Grid.Column="3" Content="📌 Pinned" Foreground="#11111B" Background="#89B4FA" 
                        BorderThickness="0" FontSize="12" FontWeight="Bold" Padding="8,4" Margin="0,0,8,0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="MinBtn" Grid.Column="4" Content="─" Foreground="#A6ADC8" Background="Transparent" BorderThickness="0" FontSize="14" FontWeight="Bold" Cursor="Hand" Width="24" Height="24"/>
                <Button Name="CloseBtn" Grid.Column="5" Content="✕" Foreground="#A6ADC8" Background="Transparent" BorderThickness="0" FontSize="15" FontWeight="Bold" Cursor="Hand" Width="24" Height="24"/>
            </Grid>

            <!-- Input Form Section -->
            <Border Name="InputBorder" Grid.Row="1" Background="#181825" CornerRadius="12" Padding="10" Margin="0,0,0,12">
                <StackPanel>
                    <Grid Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="85"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>

                        <TextBlock Name="DescLabel" Grid.Row="0" Grid.Column="0" Text="Description:" Foreground="#CDD6F4" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,4,6"/>
                        <TextBox Name="DescInput" Grid.Row="0" Grid.Column="1" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="13" Padding="8,6" Margin="0,0,0,6" CaretBrush="#89B4FA"/>

                        <TextBlock Name="LocLabel" Grid.Row="1" Grid.Column="0" Text="Location:" Foreground="#CDD6F4" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,4,6"/>
                        <TextBox Name="LocInput" Grid.Row="1" Grid.Column="1" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="13" Padding="8,6" Margin="0,0,0,6" CaretBrush="#89B4FA"/>

                        <TextBlock Name="RemLabel" Grid.Row="2" Grid.Column="0" Text="Remarks:" Foreground="#CDD6F4" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,4,6"/>
                        <TextBox Name="RemInput" Grid.Row="2" Grid.Column="1" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="13" Padding="8,6" Margin="0,0,0,6" CaretBrush="#89B4FA"/>

                        <TextBlock Name="TagsLabel" Grid.Row="3" Grid.Column="0" Text="Tags:" Foreground="#CDD6F4" FontSize="13" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,4,0"/>
                        <Button Name="SelectTagsBtn" Grid.Row="3" Grid.Column="1" Content="🏷️ Select Tags (0)" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="12" Padding="8,6" Cursor="Hand"/>
                        <Popup Name="TagPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=SelectTagsBtn}" Placement="Bottom">
                            <Border Name="TagPopupBorder" Background="#1E1E2E" BorderBrush="#45475A" BorderThickness="1" CornerRadius="8" Padding="8" MaxHeight="160">
                                <ScrollViewer VerticalScrollBarVisibility="Auto">
                                    <StackPanel Name="TagCheckboxContainer"/>
                                </ScrollViewer>
                            </Border>
                        </Popup>
                    </Grid>

                    <!-- Date & Time Row -->
                    <Grid Margin="0,0,0,8">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="1.25*"/>
                        </Grid.ColumnDefinitions>
                        
                        <Grid Grid.Column="0" Margin="0,0,4,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox Name="DateInput" Grid.Column="0" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="12" Padding="6,5" CaretBrush="#89B4FA"/>
                            <Button Name="CalBtn" Grid.Column="1" Content="📅" BorderThickness="0" FontSize="12" Padding="6,4" Cursor="Hand">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                            <Popup Name="CalPopup" StaysOpen="False" PlacementTarget="{Binding ElementName=CalBtn}" Placement="Bottom">
                                <Border Name="CalBorder" Background="#1E1E2E" BorderBrush="#45475A" BorderThickness="1" CornerRadius="8" Padding="4">
                                    <Calendar Name="CalCtrl"/>
                                </Border>
                            </Popup>
                        </Grid>

                        <Grid Grid.Column="1" Margin="4,0,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox Name="TimeInput" Grid.Column="0" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="12" Padding="6,5" CaretBrush="#89B4FA"/>
                            
                            <Button Name="TimeStepModeBtn" Grid.Column="1" Content="1h" BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="5,2" Margin="3,0,1,0" Cursor="Hand">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                            
                            <Button Name="TimeMinusBtn" Grid.Column="2" Content="-" BorderThickness="0" FontSize="13" FontWeight="Bold" Width="22" Margin="1,0,1,0" Cursor="Hand">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                            
                            <Button Name="TimePlusBtn" Grid.Column="3" Content="+" BorderThickness="0" FontSize="13" FontWeight="Bold" Width="22" Margin="1,0,0,0" Cursor="Hand">
                                <Button.Template>
                                    <ControlTemplate TargetType="Button">
                                        <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </Button.Template>
                            </Button>
                        </Grid>
                    </Grid>
                    
                    <Grid>
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button Name="AddBtn" Grid.Column="0" Content="+ Save Entry" Foreground="#11111B" Background="#89B4FA" BorderThickness="0" FontWeight="Bold" FontSize="13" Padding="0,7" Margin="0,0,4,0" Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                        <Button Name="BatchGenBtn" Grid.Column="1" Content="🔄 Batch / Routine" Foreground="#CDD6F4" Background="#45475A" BorderThickness="0" FontWeight="Bold" FontSize="12" Padding="10,7" Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="8" Padding="{TemplateBinding Padding}">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </Grid>
                </StackPanel>
            </Border>

            <!-- Auto-Wrapping Control Toolbar -->
            <WrapPanel Grid.Row="2" Margin="0,0,0,4">
                <Button Name="SortBtn" Content="⏳ Sort" BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,4,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="FilterBtn" Content="🔍 Filter" BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,4,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="ViewToggleBtn" Content="📅 Calendar View" BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,4,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>

                <Button Name="ManageTagsBtn" Content="🏷️ Manage Tags" BorderThickness="0" FontSize="11" FontWeight="Bold" Padding="8,5" Margin="0,0,0,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </WrapPanel>

            <!-- Lower Container -->
            <Grid Grid.Row="3" Margin="0,0,0,8">
                <ScrollViewer Name="FeedScrollViewer" VerticalScrollBarVisibility="Auto">
                    <StackPanel Name="TaskContainer"/>
                </ScrollViewer>

                <!-- Custom Month View Grid -->
                <Border Name="CalendarViewContainer" Background="#181825" CornerRadius="12" Padding="10" Visibility="Collapsed">
                    <Grid Name="CalGridMaster">
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                        </Grid.RowDefinitions>

                        <!-- Month Nav Header -->
                        <Grid Grid.Row="0" Margin="0,0,0,8">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>

                            <StackPanel Grid.Column="0" Orientation="Horizontal">
                                <Button Name="CalPrevYearBtn" Content="◄◄" ToolTip="Previous Year" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="11" Padding="6,4" Margin="0,0,2,0" Cursor="Hand"/>
                                <Button Name="CalPrevBtn" Content="◄" ToolTip="Previous Month" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="11" Padding="6,4" Cursor="Hand"/>
                            </StackPanel>

                            <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center">
                                <TextBlock Name="CalMonthTitle" Text="August 2026" Foreground="#CDD6F4" FontSize="13" FontWeight="Bold" VerticalAlignment="Center" Margin="0,0,6,0"/>
                                <Button Name="CalTodayBtn" Content="Today" Foreground="#11111B" Background="#89B4FA" BorderThickness="0" FontSize="10" FontWeight="Bold" Padding="6,2" Cursor="Hand" VerticalAlignment="Center">
                                    <Button.Template>
                                        <ControlTemplate TargetType="Button">
                                            <Border Background="{TemplateBinding Background}" CornerRadius="4" Padding="{TemplateBinding Padding}">
                                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                            </Border>
                                        </ControlTemplate>
                                    </Button.Template>
                                </Button>
                            </StackPanel>

                            <StackPanel Grid.Column="2" Orientation="Horizontal">
                                <Button Name="CalNextBtn" Content="►" ToolTip="Next Month" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="11" Padding="6,4" Margin="0,0,2,0" Cursor="Hand"/>
                                <Button Name="CalNextYearBtn" Content="►►" ToolTip="Next Year" Foreground="#CDD6F4" Background="#313244" BorderThickness="0" FontSize="11" Padding="6,4" Cursor="Hand"/>
                            </StackPanel>
                        </Grid>

                        <!-- Weekday Header -->
                        <UniformGrid Grid.Row="1" Columns="7" Margin="0,0,0,6">
                            <TextBlock Text="Sun" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Mon" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Tue" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Wed" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Thu" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Fri" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                            <TextBlock Text="Sat" Foreground="#7F849C" FontSize="11" FontWeight="Bold" HorizontalAlignment="Center"/>
                        </UniformGrid>

                        <!-- Month Days Grid -->
                        <UniformGrid Name="CalDaysGrid" Grid.Row="2" Rows="6" Columns="7"/>
                    </Grid>
                </Border>
            </Grid>

            <!-- Footer Controls -->
            <DockPanel Grid.Row="4" Margin="0,4,0,0">
                <Button Name="StartupBtn" Content="🚀 Startup: OFF" Foreground="#BAC2DE" Background="#313244" BorderThickness="0" FontSize="11" Padding="8,4" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <TextBlock Name="FooterText" Text="Drag header / Corner resize" Foreground="#585B70" FontSize="11" HorizontalAlignment="Right" VerticalAlignment="Center"/>
            </DockPanel>
        </Grid>
    </Border>
</Window>
'@

# Direct WPF Window Loading
$window = [System.Windows.Markup.XamlReader]::Parse($xaml)

# Element References
$mainBorder      = $window.FindName('MainBorder')
$inputBorder     = $window.FindName('InputBorder')
$headerGrid      = $window.FindName('HeaderGrid')
$titleText       = $window.FindName('TitleText')
$closeBtn        = $window.FindName('CloseBtn')
$minBtn          = $window.FindName('MinBtn')
$pinBtn          = $window.FindName('PinBtn')
$themeBtn        = $window.FindName('ThemeBtn')
$collapseBtn     = $window.FindName('CollapseBtn')
$descLabel       = $window.FindName('DescLabel')
$descInput       = $window.FindName('DescInput')
$locLabel        = $window.FindName('LocLabel')
$locInput        = $window.FindName('LocInput')
$remLabel        = $window.FindName('RemLabel')
$remInput        = $window.FindName('RemInput')
$tagsLabel       = $window.FindName('TagsLabel')
$selectTagsBtn   = $window.FindName('SelectTagsBtn')
$tagPopup        = $window.FindName('TagPopup')
$tagPopupBorder  = $window.FindName('TagPopupBorder')
$tagCheckboxContainer = $window.FindName('TagCheckboxContainer')
$dateInput       = $window.FindName('DateInput')
$calBtn          = $window.FindName('CalBtn')
$calPopup        = $window.FindName('CalPopup')
$calBorder       = $window.FindName('CalBorder')
$calCtrl         = $window.FindName('CalCtrl')
$timeInput       = $window.FindName('TimeInput')
$timeStepModeBtn = $window.FindName('TimeStepModeBtn')
$timeMinusBtn    = $window.FindName('TimeMinusBtn')
$timePlusBtn     = $window.FindName('TimePlusBtn')
$addBtn          = $window.FindName('AddBtn')
$batchGenBtn     = $window.FindName('BatchGenBtn')
$sortBtn         = $window.FindName('SortBtn')
$filterBtn       = $window.FindName('FilterBtn')
$viewToggleBtn   = $window.FindName('ViewToggleBtn')
$manageTagsBtn   = $window.FindName('ManageTagsBtn')
$feedScrollViewer = $window.FindName('FeedScrollViewer')
$calendarViewContainer = $window.FindName('CalendarViewContainer')
$calPrevYearBtn  = $window.FindName('CalPrevYearBtn')
$calPrevBtn      = $window.FindName('CalPrevBtn')
$calNextBtn      = $window.FindName('CalNextBtn')
$calNextYearBtn  = $window.FindName('CalNextYearBtn')
$calTodayBtn     = $window.FindName('CalTodayBtn')
$calMonthTitle   = $window.FindName('CalMonthTitle')
$calDaysGrid     = $window.FindName('CalDaysGrid')
$taskContainer   = $window.FindName('TaskContainer')
$startupBtn      = $window.FindName('StartupBtn')
$footerText      = $window.FindName('FooterText')

# Application State
$global:tasks = [System.Collections.Generic.List[PSObject]]::new()
$global:tags  = [System.Collections.Generic.List[PSObject]]::new()
$global:selectedTagIds = [System.Collections.Generic.List[string]]::new()
$global:filterTagIds   = [System.Collections.Generic.List[string]]::new()
$global:filterDesc = ""
$global:filterLoc  = ""
$global:filterRem  = ""
$global:isDarkMode = $true
$global:timeStepMode = "1h"
$global:isCalendarView = $false
$global:calDisplayDate = Get-Date
$global:draggedTask = $null
$global:dragStartPoint = [System.Windows.Point]::new(0, 0)

# Attempt to parse current TimeInput text (HH:mm)
$now = Get-Date
$timeText = $timeInput.Text -as [string]
$parsed = $null
$formats = @("HH:mm", "H:mm", "HHmm", "H:mm:ss")

foreach ($f in $formats) {
    if ([DateTime]::TryParseExact($timeText, $f, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsed)) {
        break
    }
}
if (-not $parsed) {
    # fallback to now
    $parsed = $now
} else {
    # Use today's date with parsed time so AddMinutes/AddHours works predictably
    $parsed = Get-Date -Hour $parsed.Hour -Minute $parsed.Minute -Second 0
}

# Determine step size from mode string (examples: "5m", "15m", "30m", "1h")
$mode = $global:timeStepMode -as [string]
if (-not $mode) { $mode = "1h" }

$stepMinutes = 0
if ($mode -match '^\s*(\d+)\s*[mM]\s*$') {
    $stepMinutes = [int]$matches[1]
} elseif ($mode -match '^\s*(\d+)\s*[hH]\s*$') {
    $stepMinutes = [int]$matches[1] * 60
} elseif ($mode -match '^\s*(\d+)\s*$') {
    # numeric only: treat as minutes
    $stepMinutes = [int]$matches[1]
} else {
    # if mode like "5m/1h", prefer first numeric+unit
    if ($mode -match '(\d+)([mMhH])') {
        $n = [int]$matches[1]
        $u = $matches[2]
        if ($u -match '[hH]') {
            $stepMinutes = $n * 60
        } else {
            $stepMinutes = $n
        }
    } else {
        $stepMinutes = 60
    }
}

if ($stepMinutes -eq 0) { $stepMinutes = 60 }

# Compute new time and write back in HH:mm
$newTime = $parsed.AddMinutes($Direction * $stepMinutes)
$timeInput.Text = $newTime.ToString("HH:mm")
