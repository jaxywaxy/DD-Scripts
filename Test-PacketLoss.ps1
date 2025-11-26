# Packet Loss Testing Script
# Demonstrates various packet loss scenarios for network metrics testing

param(
    [string]$DestinationHost = "google.com",
    [double]$PacketLossPercent = 25.0,
    [string]$LossType = "random",
    [int]$DurationSeconds = 30,
    [int]$PingCount = 10,
    [switch]$RunAllScenarios,
    [switch]$Interactive
)

# Load test utilities
. .\Test-Utilities.ps1

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"
$Magenta = "Magenta"

function Show-PacketLossMenu {
    do {
        Write-Host "`n" -NoNewline
        Write-Host "🔴 PACKET LOSS SIMULATION MENU" -ForegroundColor $Red
        Write-Host "=" * 40 -ForegroundColor $Red
        Write-Host "1. Random Packet Loss (10-50%)"
        Write-Host "2. High Packet Loss (60-90%)"
        Write-Host "3. Burst Packet Loss"
        Write-Host "4. Intermittent Loss"
        Write-Host "5. Custom Packet Loss"
        Write-Host "6. Test All Scenarios"
        Write-Host "7. Continuous Monitoring"
        Write-Host "8. Exit"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-8)"
        
        switch ($choice) {
            "1" { 
                Start-PacketLossSimulation -DestinationHost $DestinationHost -PacketLossPercent 25.0 -LossType "random" -DurationSeconds $DurationSeconds -PingCount $PingCount
            }
            "2" { 
                Start-PacketLossSimulation -DestinationHost $DestinationHost -PacketLossPercent 75.0 -LossType "high" -DurationSeconds $DurationSeconds -PingCount $PingCount
            }
            "3" { 
                Start-PacketLossSimulation -DestinationHost $DestinationHost -LossType "burst" -DurationSeconds $DurationSeconds -PingCount $PingCount
            }
            "4" { 
                Start-PacketLossSimulation -DestinationHost $DestinationHost -LossType "intermittent" -DurationSeconds $DurationSeconds -PingCount $PingCount
            }
            "5" { 
                $customLoss = Read-Host "Enter packet loss percentage (0-100)"
                $customDuration = Read-Host "Enter duration in seconds (default: 30)"
                if (-not $customDuration) { $customDuration = 30 }
                Start-PacketLossSimulation -DestinationHost $DestinationHost -PacketLossPercent [double]$customLoss -LossType "random" -DurationSeconds [int]$customDuration -PingCount $PingCount
            }
            "6" { 
                Test-PacketLossScenarios
            }
            "7" { 
                $monitorDuration = Read-Host "Enter monitoring duration in seconds (default: 60)"
                if (-not $monitorDuration) { $monitorDuration = 60 }
                Start-ContinuousMonitoring -DurationSeconds [int]$monitorDuration
            }
            "8" { 
                Write-Host "Exiting packet loss simulation..." -ForegroundColor $Yellow
                break 
            }
            default { 
                Write-Host "Invalid option. Please select 1-8." -ForegroundColor $Red 
            }
        }
    } while ($choice -ne "8")
}

function Start-ContinuousMonitoring {
    param(
        [int]$DurationSeconds = 60
    )
    
    Write-Host "`n🔄 CONTINUOUS PACKET LOSS MONITORING" -ForegroundColor $Cyan
    Write-Host "=" * 50 -ForegroundColor $Cyan
    Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor $Yellow
    Write-Host "Monitoring various packet loss scenarios..." -ForegroundColor $Yellow
    Write-Host "=" * 50 -ForegroundColor $Cyan
    
    $scenarios = @(
        @{Name="Normal"; Loss=0; Type="success"},
        @{Name="Light Loss"; Loss=10; Type="packet_loss"},
        @{Name="Moderate Loss"; Loss=25; Type="packet_loss"},
        @{Name="Heavy Loss"; Loss=50; Type="high_packet_loss"},
        @{Name="Burst Loss"; Loss=0; Type="burst_loss"},
        @{Name="Intermittent"; Loss=0; Type="intermittent_loss"}
    )
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    $scenarioIndex = 0
    
    while ((Get-Date) -lt $endTime) {
        $scenario = $scenarios[$scenarioIndex % $scenarios.Count]
        $scenarioIndex++
        
        Write-Host "`n📊 Scenario: $($scenario.Name)" -ForegroundColor $Magenta
        Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor $Yellow
        
        $results = New-MockTestConnection -ComputerName $DestinationHost -Count $PingCount -Scenario $scenario.Type -PacketLossPercent $scenario.Loss
        
        if ($results) {
            $successfulPings = $results.Count
            $actualPacketLoss = 100 - (($successfulPings / $PingCount) * 100)
            $latency = ($results | Measure-Object ResponseTime -Average).Average
            $connectionStatus = if ($latency -ne $null) { 1 } else { 0 }
            
            Write-Host "  ✅ Successful: $successfulPings/$PingCount" -ForegroundColor $Green
            Write-Host "  📊 Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor $Yellow
            Write-Host "  ⏱️  Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor $Cyan
            Write-Host "  🔗 Status: $connectionStatus" -ForegroundColor $(if ($connectionStatus -eq 1) { $Green } else { $Red })
        } else {
            Write-Host "  ❌ Complete failure - 100% packet loss" -ForegroundColor $Red
        }
        
        Start-Sleep -Seconds 10
    }
    
    Write-Host "`n✅ Continuous monitoring completed." -ForegroundColor $Green
}

function Test-PacketLossWithRealScript {
    param(
        [string]$ScriptPath = ".\test_custom_network_metrics.ps1"
    )
    
    Write-Host "`n🧪 TESTING PACKET LOSS WITH REAL SCRIPT" -ForegroundColor $Cyan
    Write-Host "=" * 50 -ForegroundColor $Cyan
    
    if (-not (Test-Path $ScriptPath)) {
        Write-Host "❌ Script not found: $ScriptPath" -ForegroundColor $Red
        return
    }
    
    Write-Host "Testing script: $ScriptPath" -ForegroundColor $Yellow
    
    # Test with different packet loss scenarios
    $testScenarios = @(
        @{Name="No Loss"; ExpectedLoss=0},
        @{Name="Light Loss"; ExpectedLoss=10},
        @{Name="Moderate Loss"; ExpectedLoss=25},
        @{Name="Heavy Loss"; ExpectedLoss=50},
        @{Name="Complete Loss"; ExpectedLoss=100}
    )
    
    foreach ($scenario in $testScenarios) {
        Write-Host "`nTesting: $($scenario.Name)" -ForegroundColor $Yellow
        Write-Host "-" * 30 -ForegroundColor $Yellow
        
        # Simulate the packet loss scenario
        $mockResults = New-MockTestConnection -ComputerName "test.example.com" -Count 10 -Scenario "packet_loss" -PacketLossPercent $scenario.ExpectedLoss
        
        if ($mockResults) {
            $successfulPings = $mockResults.Count
            $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
            $latency = ($mockResults | Measure-Object ResponseTime -Average).Average
            $connectionStatus = if ($latency -ne $null) { 1 } else { 0 }
            
            Write-Host "  Simulated Results:" -ForegroundColor $Cyan
            Write-Host "    Successful Pings: $successfulPings/10" -ForegroundColor $Green
            Write-Host "    Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor $Yellow
            Write-Host "    Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor $Blue
            Write-Host "    Connection Status: $connectionStatus" -ForegroundColor $(if ($connectionStatus -eq 1) { $Green } else { $Red })
            
            # Show what metrics would be sent
            Write-Host "  Metrics that would be sent:" -ForegroundColor $Magenta
            Write-Host "    custom.network.latency:$([math]::Round($latency, 1))|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
            Write-Host "    custom.network.packet_loss:$([math]::Round($actualPacketLoss, 1))|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
            Write-Host "    custom.network.connection_status:$connectionStatus|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
        } else {
            Write-Host "  Simulated Results: Complete failure (100% packet loss)" -ForegroundColor $Red
            Write-Host "  Metrics that would be sent:" -ForegroundColor $Magenta
            Write-Host "    custom.network.latency:null|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
            Write-Host "    custom.network.packet_loss:100.0|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
            Write-Host "    custom.network.connection_status:0|g|#source:test-server,destination:test.example.com" -ForegroundColor $Gray
        }
    }
}

function Show-PacketLossHelp {
    Write-Host "`n📚 PACKET LOSS SIMULATION HELP" -ForegroundColor $Cyan
    Write-Host "=" * 40 -ForegroundColor $Cyan
    Write-Host ""
    Write-Host "This script simulates various packet loss scenarios to test your" -ForegroundColor $Yellow
    Write-Host "network metrics script under different network conditions." -ForegroundColor $Yellow
    Write-Host ""
    Write-Host "Available Loss Types:" -ForegroundColor $Green
    Write-Host "  • Random: Random packet loss at specified percentage" -ForegroundColor $White
    Write-Host "  • Burst: Bursts of packet loss followed by normal operation" -ForegroundColor $White
    Write-Host "  • Intermittent: Random intermittent packet loss" -ForegroundColor $White
    Write-Host "  • High: High percentage packet loss (60-90%)" -ForegroundColor $White
    Write-Host ""
    Write-Host "Usage Examples:" -ForegroundColor $Green
    Write-Host "  .\Test-PacketLoss.ps1 -PacketLossPercent 25 -LossType random" -ForegroundColor $White
    Write-Host "  .\Test-PacketLoss.ps1 -RunAllScenarios" -ForegroundColor $White
    Write-Host "  .\Test-PacketLoss.ps1 -Interactive" -ForegroundColor $White
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor $Green
    Write-Host "  -DestinationHost: Target hostname (default: google.com)" -ForegroundColor $White
    Write-Host "  -PacketLossPercent: Loss percentage 0-100 (default: 25)" -ForegroundColor $White
    Write-Host "  -LossType: random, burst, intermittent, high (default: random)" -ForegroundColor $White
    Write-Host "  -DurationSeconds: Simulation duration (default: 30)" -ForegroundColor $White
    Write-Host "  -PingCount: Number of pings per test (default: 10)" -ForegroundColor $White
    Write-Host "  -RunAllScenarios: Test all packet loss scenarios" -ForegroundColor $White
    Write-Host "  -Interactive: Show interactive menu" -ForegroundColor $White
    Write-Host ""
}

# Main execution logic
if ($RunAllScenarios) {
    Write-Host "🚀 Running all packet loss scenarios..." -ForegroundColor $Cyan
    Test-PacketLossScenarios
    Test-PacketLossWithRealScript
} elseif ($Interactive) {
    Show-PacketLossMenu
} else {
    Write-Host "🔴 PACKET LOSS SIMULATION" -ForegroundColor $Red
    Write-Host "=" * 30 -ForegroundColor $Red
    Write-Host "Destination: $DestinationHost" -ForegroundColor $Yellow
    Write-Host "Packet Loss: $PacketLossPercent%" -ForegroundColor $Yellow
    Write-Host "Loss Type: $LossType" -ForegroundColor $Yellow
    Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor $Yellow
    Write-Host "Ping Count: $PingCount" -ForegroundColor $Yellow
    Write-Host "=" * 30 -ForegroundColor $Red
    
    Start-PacketLossSimulation -DestinationHost $DestinationHost -PacketLossPercent $PacketLossPercent -LossType $LossType -DurationSeconds $DurationSeconds -PingCount $PingCount
}

# Show help if no parameters provided
if ($args.Count -eq 0 -and -not $RunAllScenarios -and -not $Interactive) {
    Show-PacketLossHelp
}

