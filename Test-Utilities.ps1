# Test Utilities for Network Metrics Script
# Additional helper functions and mock objects for testing

# Mock Test-Connection function with configurable responses
function New-MockTestConnection {
    param(
        [string]$ComputerName,
        [int]$Count = 10,
        [string]$Scenario = "success",
        [double]$PacketLossPercent = 0.0
    )
    
    switch ($Scenario) {
        "success" {
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 10 -Maximum 50
                    Address = "8.8.8.8"
                    Status = "Success"
                }
            }
            return $results
        }
        "timeout" {
            return $null
        }
        "partial" {
            $results = @()
            $successCount = [math]::Floor($Count * 0.7)  # 70% success rate
            for ($i = 1; $i -le $successCount; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 20 -Maximum 100
                    Address = "1.2.3.4"
                    Status = "Success"
                }
            }
            return $results
        }
        "slow" {
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 200 -Maximum 1000
                    Address = "192.168.1.1"
                    Status = "Success"
                }
            }
            return $results
        }
        "unstable" {
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $responseTime = if ((Get-Random -Minimum 1 -Maximum 10) -le 3) {
                    Get-Random -Minimum 1000 -Maximum 5000  # High latency
                } else {
                    Get-Random -Minimum 10 -Maximum 50     # Normal latency
                }
                $results += [PSCustomObject]@{
                    ResponseTime = $responseTime
                    Address = "10.0.0.1"
                    Status = "Success"
                }
            }
            return $results
        }
        "packet_loss" {
            $results = @()
            $packetLossRate = if ($PacketLossPercent -gt 0) { $PacketLossPercent } else { Get-Random -Minimum 10 -Maximum 50 }
            $successCount = [math]::Floor($Count * (1 - $packetLossRate / 100))
            
            Write-Host "Simulating $packetLossRate% packet loss - $successCount successful pings out of $Count" -ForegroundColor Yellow
            
            for ($i = 1; $i -le $successCount; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 15 -Maximum 80
                    Address = "203.0.113.1"
                    Status = "Success"
                }
            }
            return $results
        }
        "high_packet_loss" {
            $results = @()
            $packetLossRate = if ($PacketLossPercent -gt 0) { $PacketLossPercent } else { Get-Random -Minimum 60 -Maximum 90 }
            $successCount = [math]::Floor($Count * (1 - $packetLossRate / 100))
            
            Write-Host "Simulating $packetLossRate% packet loss - $successCount successful pings out of $Count" -ForegroundColor Red
            
            for ($i = 1; $i -le $successCount; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 50 -Maximum 200
                    Address = "198.51.100.1"
                    Status = "Success"
                }
            }
            return $results
        }
        "intermittent_loss" {
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                # Randomly drop packets (30% chance of loss)
                if ((Get-Random -Minimum 1 -Maximum 100) -le 30) {
                    # Packet lost - don't add to results
                    continue
                } else {
                    $results += [PSCustomObject]@{
                        ResponseTime = Get-Random -Minimum 20 -Maximum 120
                        Address = "192.0.2.1"
                        Status = "Success"
                    }
                }
            }
            return $results
        }
        "burst_loss" {
            $results = @()
            $burstStart = Get-Random -Minimum 1 -Maximum ($Count - 3)
            $burstLength = Get-Random -Minimum 2 -Maximum 5
            
            Write-Host "Simulating burst packet loss from ping $burstStart to $($burstStart + $burstLength - 1)" -ForegroundColor Yellow
            
            for ($i = 1; $i -le $Count; $i++) {
                if ($i -ge $burstStart -and $i -lt ($burstStart + $burstLength)) {
                    # Burst loss - don't add to results
                    continue
                } else {
                    $results += [PSCustomObject]@{
                        ResponseTime = Get-Random -Minimum 15 -Maximum 60
                        Address = "203.0.113.2"
                        Status = "Success"
                    }
                }
            }
            return $results
        }
    }
}

# Mock UDP Client for testing metric sending
class MockUdpClient {
    [System.Collections.ArrayList]$SentMessages
    [string]$Host
    [int]$Port
    
    MockUdpClient([string]$Host = "127.0.0.1", [int]$Port = 8125) {
        $this.Host = $Host
        $this.Port = $Port
        $this.SentMessages = [System.Collections.ArrayList]::new()
    }
    
    [bool] Send([string]$Message) {
        $this.SentMessages.Add($Message)
        Write-Host "MOCK UDP SEND: $Message" -ForegroundColor Yellow
        return $true
    }
    
    [string[]] GetSentMessages() {
        return $this.SentMessages.ToArray()
    }
    
    [void] ClearMessages() {
        $this.SentMessages.Clear()
    }
    
    [int] GetMessageCount() {
        return $this.SentMessages.Count
    }
}

# Test Data Generator
function New-TestData {
    param(
        [string]$Scenario = "normal"
    )
    
    switch ($Scenario) {
        "normal" {
            return @{
                DestinationHost = "google.com"
                SourceHost = "test-server"
                ExpectedLatency = 25.5
                ExpectedPacketLoss = 0.0
                ExpectedConnectionStatus = 1
            }
        }
        "timeout" {
            return @{
                DestinationHost = "timeout.example.com"
                SourceHost = "test-server"
                ExpectedLatency = $null
                ExpectedPacketLoss = 100.0
                ExpectedConnectionStatus = 0
            }
        }
        "slow" {
            return @{
                DestinationHost = "slow.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 500.0
                ExpectedPacketLoss = 0.0
                ExpectedConnectionStatus = 1
            }
        }
        "unstable" {
            return @{
                DestinationHost = "unstable.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 150.0
                ExpectedPacketLoss = 30.0
                ExpectedConnectionStatus = 1
            }
        }
        "packet_loss" {
            return @{
                DestinationHost = "lossy.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 45.0
                ExpectedPacketLoss = 25.0
                ExpectedConnectionStatus = 1
            }
        }
        "high_packet_loss" {
            return @{
                DestinationHost = "very-lossy.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 80.0
                ExpectedPacketLoss = 75.0
                ExpectedConnectionStatus = 1
            }
        }
        "intermittent_loss" {
            return @{
                DestinationHost = "intermittent.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 60.0
                ExpectedPacketLoss = 30.0
                ExpectedConnectionStatus = 1
            }
        }
        "burst_loss" {
            return @{
                DestinationHost = "bursty.example.com"
                SourceHost = "test-server"
                ExpectedLatency = 35.0
                ExpectedPacketLoss = 40.0
                ExpectedConnectionStatus = 1
            }
        }
    }
}

# Packet Loss Simulation Functions
function Start-PacketLossSimulation {
    param(
        [string]$DestinationHost = "google.com",
        [int]$PingCount = 10,
        [double]$PacketLossPercent = 25.0,
        [string]$LossType = "random",
        [int]$DurationSeconds = 30
    )
    
    Write-Host "`n🔴 PACKET LOSS SIMULATION" -ForegroundColor Red
    Write-Host "=" * 50 -ForegroundColor Red
    Write-Host "Destination: $DestinationHost" -ForegroundColor Yellow
    Write-Host "Ping Count: $PingCount" -ForegroundColor Yellow
    Write-Host "Packet Loss: $PacketLossPercent%" -ForegroundColor Yellow
    Write-Host "Loss Type: $LossType" -ForegroundColor Yellow
    Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Yellow
    Write-Host "=" * 50 -ForegroundColor Red
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    $iteration = 0
    
    while ((Get-Date) -lt $endTime) {
        $iteration++
        Write-Host "`nIteration $iteration - $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Cyan
        
        # Simulate packet loss based on type
        switch ($LossType) {
            "random" {
                $results = New-MockTestConnection -ComputerName $DestinationHost -Count $PingCount -Scenario "packet_loss" -PacketLossPercent $PacketLossPercent
            }
            "burst" {
                $results = New-MockTestConnection -ComputerName $DestinationHost -Count $PingCount -Scenario "burst_loss"
            }
            "intermittent" {
                $results = New-MockTestConnection -ComputerName $DestinationHost -Count $PingCount -Scenario "intermittent_loss"
            }
            "high" {
                $results = New-MockTestConnection -ComputerName $DestinationHost -Count $PingCount -Scenario "high_packet_loss" -PacketLossPercent $PacketLossPercent
            }
        }
        
        if ($results) {
            $successfulPings = $results.Count
            $actualPacketLoss = 100 - (($successfulPings / $PingCount) * 100)
            $latency = ($results | Measure-Object ResponseTime -Average).Average
            $connectionStatus = if ($latency -ne $null) { 1 } else { 0 }
            
            Write-Host "  ✅ Successful Pings: $successfulPings/$PingCount" -ForegroundColor Green
            Write-Host "  📊 Actual Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
            Write-Host "  ⏱️  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
            Write-Host "  🔗 Connection Status: $connectionStatus" -ForegroundColor $(if ($connectionStatus -eq 1) { "Green" } else { "Red" })
            
            # Simulate sending metrics
            Write-Host "  📡 Sending metrics to DogStatsD..." -ForegroundColor Magenta
            Write-Host "    custom.network.latency:$([math]::Round($latency, 1))|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
            Write-Host "    custom.network.packet_loss:$([math]::Round($actualPacketLoss, 1))|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
            Write-Host "    custom.network.connection_status:$connectionStatus|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
        } else {
            Write-Host "  ❌ All packets lost - 100% packet loss" -ForegroundColor Red
            Write-Host "  📡 Sending metrics to DogStatsD..." -ForegroundColor Magenta
            Write-Host "    custom.network.latency:null|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
            Write-Host "    custom.network.packet_loss:100.0|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
            Write-Host "    custom.network.connection_status:0|g|#source:test-server,destination:$DestinationHost" -ForegroundColor Gray
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-Host "`n✅ Packet loss simulation completed." -ForegroundColor Green
}

function Test-PacketLossScenarios {
    Write-Host "`n🧪 TESTING PACKET LOSS SCENARIOS" -ForegroundColor Cyan
    Write-Host "=" * 50 -ForegroundColor Cyan
    
    $scenarios = @(
        @{Name="Light Packet Loss"; Percent=10.0; Type="random"},
        @{Name="Moderate Packet Loss"; Percent=25.0; Type="random"},
        @{Name="Heavy Packet Loss"; Percent=50.0; Type="random"},
        @{Name="Burst Packet Loss"; Percent=0.0; Type="burst"},
        @{Name="Intermittent Loss"; Percent=0.0; Type="intermittent"},
        @{Name="High Packet Loss"; Percent=75.0; Type="high"}
    )
    
    foreach ($scenario in $scenarios) {
        Write-Host "`nTesting: $($scenario.Name)" -ForegroundColor Yellow
        Write-Host "-" * 30 -ForegroundColor Yellow
        
        $results = New-MockTestConnection -ComputerName "test.example.com" -Count 10 -Scenario $scenario.Type -PacketLossPercent $scenario.Percent
        
        if ($results) {
            $successfulPings = $results.Count
            $actualPacketLoss = 100 - (($successfulPings / 10) * 100)
            $latency = ($results | Measure-Object ResponseTime -Average).Average
            
            Write-Host "  Successful Pings: $successfulPings/10" -ForegroundColor Green
            Write-Host "  Packet Loss: $([math]::Round($actualPacketLoss, 1))%" -ForegroundColor Yellow
            Write-Host "  Average Latency: $([math]::Round($latency, 1)) ms" -ForegroundColor Blue
        } else {
            Write-Host "  All packets lost (100% loss)" -ForegroundColor Red
        }
    }
}

# Network Simulation Functions
function Start-NetworkSimulation {
    param(
        [string]$Scenario = "normal",
        [int]$DurationSeconds = 60
    )
    
    Write-Host "Starting network simulation: $Scenario" -ForegroundColor Cyan
    Write-Host "Duration: $DurationSeconds seconds" -ForegroundColor Yellow
    
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($DurationSeconds)
    
    while ((Get-Date) -lt $endTime) {
        $testData = New-TestData -Scenario $Scenario
        $mockResults = New-MockTestConnection -ComputerName $testData.DestinationHost -Count 10 -Scenario $Scenario
        
        if ($mockResults) {
            $latency = ($mockResults | Measure-Object ResponseTime -Average).Average
            $packetLoss = 100 - (($mockResults.Count / 10) * 100)
            $connectionStatus = if ($latency -ne $null) { 1 } else { 0 }
            
            Write-Host "Simulation - Latency: $latency ms, Packet Loss: $packetLoss%, Status: $connectionStatus" -ForegroundColor Green
        } else {
            Write-Host "Simulation - Connection failed" -ForegroundColor Red
        }
        
        Start-Sleep -Seconds 5
    }
    
    Write-Host "Network simulation completed." -ForegroundColor Cyan
}

# Performance Benchmarking
function Measure-ScriptPerformance {
    param(
        [string]$ScriptPath,
        [int]$Iterations = 10
    )
    
    Write-Host "Performance Benchmarking: $ScriptPath" -ForegroundColor Cyan
    Write-Host "Iterations: $Iterations" -ForegroundColor Yellow
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        $startTime = Get-Date
        
        try {
            # Simulate script execution
            $scriptContent = Get-Content $ScriptPath -Raw
            $null = [System.Management.Automation.ScriptBlock]::Create($scriptContent)
            
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalMilliseconds
            
            $results += [PSCustomObject]@{
                Iteration = $i
                ExecutionTime = $executionTime
                Success = $true
            }
            
            Write-Host "Iteration $i`: $executionTime ms" -ForegroundColor Green
        } catch {
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalMilliseconds
            
            $results += [PSCustomObject]@{
                Iteration = $i
                ExecutionTime = $executionTime
                Success = $false
                Error = $_.Exception.Message
            }
            
            Write-Host "Iteration $i`: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Calculate statistics
    $successfulResults = $results | Where-Object { $_.Success }
    if ($successfulResults) {
        $avgTime = ($successfulResults | Measure-Object ExecutionTime -Average).Average
        $minTime = ($successfulResults | Measure-Object ExecutionTime -Minimum).Minimum
        $maxTime = ($successfulResults | Measure-Object ExecutionTime -Maximum).Maximum
        
        Write-Host "`nPerformance Summary:" -ForegroundColor Cyan
        Write-Host "Average Time: $([math]::Round($avgTime, 2)) ms" -ForegroundColor Green
        Write-Host "Minimum Time: $([math]::Round($minTime, 2)) ms" -ForegroundColor Green
        Write-Host "Maximum Time: $([math]::Round($maxTime, 2)) ms" -ForegroundColor Green
        Write-Host "Success Rate: $([math]::Round(($successfulResults.Count / $Iterations) * 100, 2))%" -ForegroundColor Green
    }
    
    return $results
}

# Load Testing
function Start-LoadTest {
    param(
        [string]$ScriptPath,
        [int]$ConcurrentUsers = 5,
        [int]$TestDurationSeconds = 30
    )
    
    Write-Host "Load Testing: $ScriptPath" -ForegroundColor Cyan
    Write-Host "Concurrent Users: $ConcurrentUsers" -ForegroundColor Yellow
    Write-Host "Duration: $TestDurationSeconds seconds" -ForegroundColor Yellow
    
    $jobs = @()
    $startTime = Get-Date
    $endTime = $startTime.AddSeconds($TestDurationSeconds)
    
    # Start concurrent jobs
    for ($i = 1; $i -le $ConcurrentUsers; $i++) {
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $EndTime)
            
            $results = @()
            while ((Get-Date) -lt $EndTime) {
                $iterationStart = Get-Date
                
                try {
                    # Simulate script execution
                    $scriptContent = Get-Content $ScriptPath -Raw
                    $null = [System.Management.Automation.ScriptBlock]::Create($scriptContent)
                    
                    $iterationEnd = Get-Date
                    $executionTime = ($iterationEnd - $iterationStart).TotalMilliseconds
                    
                    $results += [PSCustomObject]@{
                        Timestamp = Get-Date
                        ExecutionTime = $executionTime
                        Success = $true
                    }
                } catch {
                    $iterationEnd = Get-Date
                    $executionTime = ($iterationEnd - $iterationStart).TotalMilliseconds
                    
                    $results += [PSCustomObject]@{
                        Timestamp = Get-Date
                        ExecutionTime = $executionTime
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
                
                Start-Sleep -Milliseconds 100
            }
            
            return $results
        } -ArgumentList $ScriptPath, $endTime
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $jobs | Wait-Job | Out-Null
    
    # Collect results
    $allResults = @()
    foreach ($job in $jobs) {
        $jobResults = Receive-Job -Job $job
        $allResults += $jobResults
        Remove-Job -Job $job
    }
    
    # Analyze results
    $successfulResults = $allResults | Where-Object { $_.Success }
    $failedResults = $allResults | Where-Object { -not $_.Success }
    
    Write-Host "`nLoad Test Results:" -ForegroundColor Cyan
    Write-Host "Total Executions: $($allResults.Count)" -ForegroundColor Yellow
    Write-Host "Successful: $($successfulResults.Count)" -ForegroundColor Green
    Write-Host "Failed: $($failedResults.Count)" -ForegroundColor Red
    Write-Host "Success Rate: $([math]::Round(($successfulResults.Count / $allResults.Count) * 100, 2))%" -ForegroundColor Green
    
    if ($successfulResults) {
        $avgTime = ($successfulResults | Measure-Object ExecutionTime -Average).Average
        $minTime = ($successfulResults | Measure-Object ExecutionTime -Minimum).Minimum
        $maxTime = ($successfulResults | Measure-Object ExecutionTime -Maximum).Maximum
        
        Write-Host "Average Execution Time: $([math]::Round($avgTime, 2)) ms" -ForegroundColor Green
        Write-Host "Minimum Execution Time: $([math]::Round($minTime, 2)) ms" -ForegroundColor Green
        Write-Host "Maximum Execution Time: $([math]::Round($maxTime, 2)) ms" -ForegroundColor Green
    }
    
    return $allResults
}

# Export functions for use in other scripts
Export-ModuleMember -Function @(
    'New-MockTestConnection',
    'New-TestData',
    'Start-NetworkSimulation',
    'Start-PacketLossSimulation',
    'Test-PacketLossScenarios',
    'Measure-ScriptPerformance',
    'Start-LoadTest'
)
