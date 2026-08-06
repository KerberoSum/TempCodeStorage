# 1. Set Your Favorite Station (Line Code and Station Code)
# Common Line Codes: TWL (Tsuen Wan), KTL (Kwun Tong), ISL (Island), TKL (Tseung Kwan O), EAL (East Rail), TML (Tuen Ma), TCL (Tung Chung), AEL (Airport Express)
$favoriteLine = "TWL"
$favoriteStation = "TST" # Tsim Sha Tsui

# 2. Function to fetch and display the ETA and Delay Status
function Get-MtrStatus {
    param (
        [string]$Line,
        [string]$Station
    )

    $url = "https://rt.data.gov.hk/v1/transport/mtr/getSchedule.php?line=$Line&sta=$Station"
    
    try {
        # Fetch data from the API
        $response = Invoke-RestMethod -Uri $url -Method Get
        
        # Check if the API returned a successful status (1 = Success, 0 = Error/Delay)
        if ($response.status -eq 0) {
            Write-Host "⚠️ API Error or Major Disruption: $($response.message)" -ForegroundColor Red
            return
        }

        # 3. Check for Delays
        # The API provides an 'isdelay' flag (Y = Yes, N = No)
        if ($response.isdelay -eq "Y") {
            Write-Host "🚨 ONGOING DELAY DETECTED ON LINE: $Line" -ForegroundColor Red
        } else {
            Write-Host "✅ Service on $Line is operating normally." -ForegroundColor Green
        }

        Write-Host "------------------------------------------------"
        Write-Host "Next Trains for Station: $Station"
        Write-Host "------------------------------------------------"

        # 4. Parse Next Train Data
        # The data is nested under data -> "LINE-STATION" -> UP / DOWN
        $stationKey = "$Line-$Station"
        $stationData = $response.data.$stationKey

        # Process 'UP' Direction
        if ($null -ne $stationData.UP) {
            $destination = $stationData.UP[0].dest
            $nextTrainMins = $stationData.UP[0].ttnt
            $secondTrainMins = if ($stationData.UP.Count -gt 1) { $stationData.UP[1].ttnt } else { "N/A" }
            
            Write-Host "Towards $destination :" -ForegroundColor Cyan
            Write-Host "  -> Next train: $nextTrainMins min(s)"
            Write-Host "  -> Following train: $secondTrainMins min(s)"
        }

        # Process 'DOWN' Direction
        if ($null -ne $stationData.DOWN) {
            $destination = $stationData.DOWN[0].dest
            $nextTrainMins = $stationData.DOWN[0].ttnt
            $secondTrainMins = if ($stationData.DOWN.Count -gt 1) { $stationData.DOWN[1].ttnt } else { "N/A" }
            
            Write-Host "Towards $destination :" -ForegroundColor Yellow
            Write-Host "  -> Next train: $nextTrainMins min(s)"
            Write-Host "  -> Following train: $secondTrainMins min(s)"
        }

        Write-Host "------------------------------------------------"
        Write-Host "Last Updated: $($response.curr_time)"
        Write-Host "------------------------------------------------"

    } catch {
        Write-Host "Failed to connect to MTR API. Please check your internet connection." -ForegroundColor Red
    }
}

# Run the function
Get-MtrStatus -Line $favoriteLine -Station $favoriteStation
