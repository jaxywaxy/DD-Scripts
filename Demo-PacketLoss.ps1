# Demo Script for Packet Loss Simulation
# This script demonstrates the packet loss simulation capabilities

Write-Host "🔴 PACKET LOSS SIMULATION DEMO" -ForegroundColor Red
Write-Host "=" * 50 -ForegroundColor Red
Write-Host "This demo shows how to simulate various packet loss scenarios" -ForegroundColor Yellow
Write-Host "for testing your network metrics script." -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Red

# Load test utilities
. .\Test-Utilities.ps1

Write-Host "`n📚 Available Packet Loss Scenarios:" -ForegroundColor Cyan
Write-Host "1. Random Packet Loss (10-50%)" -ForegroundColor Green
Write-Host "2. High Packet Loss (60-90%)" -ForegroundColor Yellow
Write-Host "3. Burst Packet Loss (consecutive packet drops)" -ForegroundColor Yellow
Write-Host "4. Intermittent Loss (random intermittent drops)" -ForegroundColor Yellow
Write-Host "5. Complete Loss (100% packet loss)" -ForegroundColor Red

Write-Host "`n🧪 Testing Different Scenarios:" -ForegroundColor Cyan

# Demo 1: Random Packet Loss
Write-Host "`nDemo 1: Random Packet Loss (25%)" -ForegroundColor Yellow
$results1 = New-MockTestConnection -ComputerName "demo.example.com" -Count 10 -Scenario "packet_loss" -PacketLossPercent 25.0
if ($results1) {
    $successfulPings = $results1.Count
    $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
    $latency = ($results1 | Measure-Object ResponseTime -Average).Average
    Write-Host "  ✅ Successful Pings: $successfulPings/10" -ForegroundColor Green
    Write-Host "  📊 Actual Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
    Write-Host "  ⏱️  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
} else {
    Write-Host "  ❌ All packets lost" -ForegroundColor Red
}

# Demo 2: Burst Packet Loss
Write-Host "`nDemo 2: Burst Packet Loss" -ForegroundColor Yellow
$results2 = New-MockTestConnection -ComputerName "demo.example.com" -Count 10 -Scenario "burst_loss"
if ($results2) {
    $successfulPings = $results2.Count
    $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
    $latency = ($results2 | Measure-Object ResponseTime -Average).Average
    Write-Host "  ✅ Successful Pings: $successfulPings/10" -ForegroundColor Green
    Write-Host "  📊 Actual Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
    Write-Host "  ⏱️  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
} else {
    Write-Host "  ❌ All packets lost" -ForegroundColor Red
}

# Demo 3: Intermittent Loss
Write-Host "`nDemo 3: Intermittent Loss" -ForegroundColor Yellow
$results3 = New-MockTestConnection -ComputerName "demo.example.com" -Count 10 -Scenario "intermittent_loss"
if ($results3) {
    $successfulPings = $results3.Count
    $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
    $latency = ($results3 | Measure-Object ResponseTime -Average).Average
    Write-Host "  ✅ Successful Pings: $successfulPings/10" -ForegroundColor Green
    Write-Host "  📊 Actual Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
    Write-Host "  ⏱️  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
} else {
    Write-Host "  ❌ All packets lost" -ForegroundColor Red
}

# Demo 4: High Packet Loss
Write-Host "`nDemo 4: High Packet Loss (75%)" -ForegroundColor Yellow
$results4 = New-MockTestConnection -ComputerName "demo.example.com" -Count 10 -Scenario "high_packet_loss" -PacketLossPercent 75.0
if ($results4) {
    $successfulPings = $results4.Count
    $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
    $latency = ($results4 | Measure-Object ResponseTime -Average).Average
    Write-Host "  ✅ Successful Pings: $successfulPings/10" -ForegroundColor Green
    Write-Host "  📊 Actual Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
    Write-Host "  ⏱️  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
} else {
    Write-Host "  ❌ All packets lost" -ForegroundColor Red
}

Write-Host "`n📡 Metrics that would be sent to DogStatsD:" -ForegroundColor Magenta
Write-Host "  custom.network.latency:<value>|g|#source:test-server,destination:demo.example.com" -ForegroundColor Gray
Write-Host "  custom.network.packet_loss:<value>|g|#source:test-server,destination:demo.example.com" -ForegroundColor Gray
Write-Host "  custom.network.connection_status:<value>|g|#source:test-server,destination:demo.example.com" -ForegroundColor Gray

Write-Host "`n🚀 How to run your own simulations:" -ForegroundColor Cyan
Write-Host "  .\Test-PacketLoss.ps1 -Interactive" -ForegroundColor White
Write-Host "  .\Test-PacketLoss.ps1 -PacketLossPercent 30 -LossType random -DurationSeconds 60" -ForegroundColor White
Write-Host "  .\Test-PacketLoss.ps1 -RunAllScenarios" -ForegroundColor White

Write-Host "`n✅ Demo completed!" -ForegroundColor Green
Write-Host "Use the interactive menu to explore more scenarios." -ForegroundColor Yellow

