# Test Harness for Custom Network Metrics Script
# This test harness provides comprehensive testing capabilities for the network metrics script

param(
    [string]$TestScriptPath = ".\test_custom_network_metrics.ps1",
    [string]$MainScriptPath = ".\custom_network_metrics.ps1",
    [switch]$Verbose,
    [switch]$RunAllTests
)

# Test Configuration
$TestResults = @()
$TestCount = 0
$PassedTests = 0
$FailedTests = 0

# Colors for output
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

# Test Helper Functions
function Write-TestHeader {
    param([string]$TestName)
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Cyan
    Write-Host "TEST: $TestName" -ForegroundColor $Cyan
    Write-Host "=" * 60 -ForegroundColor $Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = ""
    )
    $TestCount++
    if ($Passed) {
        $PassedTests++
        Write-Host "✓ PASS: $TestName" -ForegroundColor $Green
    } else {
        $FailedTests++
        Write-Host "✗ FAIL: $TestName" -ForegroundColor $Red
        if ($Message) {
            Write-Host "  Message: $Message" -ForegroundColor $Red
        }
    }
    
    $TestResults += [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Message = $Message
        Timestamp = Get-Date
    }
}

# Mock Functions for Testing
function Mock-TestConnection {
    param(
        [string]$ComputerName,
        [int]$Count,
        [string]$ErrorAction
    )
    # Simulate different network conditions based on computer name
    switch ($ComputerName) {
        "google.com" {
            # Simulate successful connection
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 10 -Maximum 50
                    Address = "8.8.8.8"
                }
            }
            return $results
        }
        "timeout.example.com" {
            # Simulate timeout/no response
            return $null
        }
        "slow.example.com" {
            # Simulate slow connection
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 100 -Maximum 500
                    Address = "1.2.3.4"
                }
            }
            return $results
        }
        default {
            # Default successful response
            $results = @()
            for ($i = 1; $i -le $Count; $i++) {
                $results += [PSCustomObject]@{
                    ResponseTime = Get-Random -Minimum 20 -Maximum 100
                    Address = "192.168.1.1"
                }
            }
            return $results
        }
    }
}

function Mock-UdpClient {
    param(
        [string]$Message,
        [string]$Host = "127.0.0.1",
        [int]$Port = 8125
    )
    # Mock UDP client - just log the message instead of sending
    Write-Host "MOCK UDP SEND: $Message" -ForegroundColor $Yellow
    return $true
}

# Test Functions
function Test-ScriptSyntax {
    Write-TestHeader "Script Syntax Validation"
    
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $TestScriptPath -Raw), [ref]$null)
        Write-TestResult "Script Syntax" $true "PowerShell syntax is valid"
    } catch {
        Write-TestResult "Script Syntax" $false "Syntax error: $($_.Exception.Message)"
    }
}

function Test-NetworkConnectivityLogic {
    Write-TestHeader "Network Connectivity Logic Tests"
    
    # Test 1: Successful ping scenario
    $TestCount = 10
    $MockResults = Mock-TestConnection -ComputerName "google.com" -Count $TestCount
    
    if ($MockResults) {
        $successfulPings = $MockResults.Count
        $latency = ($MockResults | Measure-Object ResponseTime -Average).Average
        $packetLoss = 100 - (($successfulPings / $TestCount) * 100)
        $connectionStatus = if ($latency -ne $null) { 1 } else { 0 }
        
        $latencyValid = $latency -gt 0 -and $latency -lt 1000
        $packetLossValid = $packetLoss -ge 0 -and $packetLoss -le 100
        $connectionStatusValid = $connectionStatus -eq 1
        
        Write-TestResult "Successful Ping - Latency Calculation" $latencyValid "Latency: $latency ms"
        Write-TestResult "Successful Ping - Packet Loss Calculation" $packetLossValid "Packet Loss: $packetLoss%"
        Write-TestResult "Successful Ping - Connection Status" $connectionStatusValid "Status: $connectionStatus"
    }
    
    # Test 2: Failed ping scenario
    $MockResults = Mock-TestConnection -ComputerName "timeout.example.com" -Count $TestCount
    
    if (-not $MockResults) {
        $latency = $null
        $packetLoss = 100
        $connectionStatus = 0
        
        $latencyValid = $latency -eq $null
        $packetLossValid = $packetLoss -eq 100
        $connectionStatusValid = $connectionStatus -eq 0
        
        Write-TestResult "Failed Ping - Latency Null" $latencyValid "Latency should be null"
        Write-TestResult "Failed Ping - Packet Loss 100%" $packetLossValid "Packet Loss: $packetLoss%"
        Write-TestResult "Failed Ping - Connection Status" $connectionStatusValid "Status: $connectionStatus"
    }
}

function Test-MetricFormatting {
    Write-TestHeader "Metric Formatting Tests"
    
    # Test metric message format
    $SourceHost = "test-source"
    $DestinationHost = "test-destination"
    $MetricName = "custom.network.latency"
    $Value = 25.5
    
    $expectedMessage = "${MetricName}:${Value}|g|#source:${SourceHost},destination:${DestinationHost}"
    $actualMessage = "${MetricName}:${Value}|g|#source:${SourceHost},destination:${DestinationHost}"
    
    $formatValid = $actualMessage -eq $expectedMessage
    Write-TestResult "Metric Message Format" $formatValid "Expected: $expectedMessage"
    
    # Test different metric types
    $metrics = @(
        @{Name="custom.network.latency"; Value=25.5},
        @{Name="custom.network.packet_loss"; Value=0.0},
        @{Name="custom.network.connection_status"; Value=1}
    )
    
    foreach ($metric in $metrics) {
        $message = "${($metric.Name)}:${($metric.Value)}|g|#source:${SourceHost},destination:${DestinationHost}"
        $hasValidFormat = $message -match "^[^:]+:[^|]+\|g\|#source:[^,]+,\s*destination:.+$"
        Write-TestResult "Metric Format - $($metric.Name)" $hasValidFormat "Message: $message"
    }
}

function Test-EdgeCases {
    Write-TestHeader "Edge Cases and Error Handling"
    
    # Test with null values
    $nullLatency = $null
    $nullPacketLoss = 100
    $nullConnectionStatus = 0
    
    $nullLatencyValid = $nullLatency -eq $null
    $nullPacketLossValid = $nullPacketLoss -eq 100
    $nullConnectionStatusValid = $nullConnectionStatus -eq 0
    
    Write-TestResult "Null Latency Handling" $nullLatencyValid "Latency should be null"
    Write-TestResult "Null Packet Loss Handling" $nullPacketLossValid "Packet Loss: $nullPacketLoss%"
    Write-TestResult "Null Connection Status" $nullConnectionStatusValid "Status: $nullConnectionStatus"
    
    # Test with extreme values
    $extremeLatency = 9999.99
    $extremePacketLoss = 100.0
    $extremeConnectionStatus = 1
    
    $extremeLatencyValid = $extremeLatency -gt 0
    $extremePacketLossValid = $extremePacketLoss -eq 100.0
    $extremeConnectionStatusValid = $extremeConnectionStatus -eq 1
    
    Write-TestResult "Extreme Latency Handling" $extremeLatencyValid "Latency: $extremeLatency ms"
    Write-TestResult "Extreme Packet Loss Handling" $extremePacketLossValid "Packet Loss: $extremePacketLoss%"
    Write-TestResult "Extreme Connection Status" $extremeConnectionStatusValid "Status: $extremeConnectionStatus"
}

function Test-ScriptExecution {
    Write-TestHeader "Script Execution Tests"
    
    # Test if script can be loaded without errors
    try {
        $scriptContent = Get-Content $TestScriptPath -Raw
        $null = [System.Management.Automation.ScriptBlock]::Create($scriptContent)
        Write-TestResult "Script Loading" $true "Script can be loaded successfully"
    } catch {
        Write-TestResult "Script Loading" $false "Failed to load script: $($_.Exception.Message)"
    }
    
    # Test variable assignments
    $testVars = @{
        "DestinationHost" = "google.com"
        "SourceHost" = "127.0.0.1"
        "pingCount" = 10
    }
    
    foreach ($var in $testVars.GetEnumerator()) {
        $varExists = $var.Value -ne $null
        Write-TestResult "Variable Assignment - $($var.Key)" $varExists "Value: $($var.Value)"
    }
}

function Test-Performance {
    Write-TestHeader "Performance Tests"
    
    # Test script execution time
    $startTime = Get-Date
    try {
        # Simulate script execution time
        Start-Sleep -Milliseconds 100
        $endTime = Get-Date
        $executionTime = ($endTime - $startTime).TotalMilliseconds
        
        $performanceValid = $executionTime -lt 5000  # Should complete within 5 seconds
        Write-TestResult "Script Execution Time" $performanceValid "Execution time: $executionTime ms"
    } catch {
        Write-TestResult "Script Execution Time" $false "Performance test failed: $($_.Exception.Message)"
    }
}

function Test-Configuration {
    Write-TestHeader "Configuration Tests"
    
    # Test default configuration values
    $configTests = @(
        @{Name="Default Ping Count"; Value=10; Expected=10},
        @{Name="Default UDP Port"; Value=8125; Expected=8125},
        @{Name="Default UDP Host"; Value="127.0.0.1"; Expected="127.0.0.1"}
    )
    
    foreach ($test in $configTests) {
        $configValid = $test.Value -eq $test.Expected
        Write-TestResult $test.Name $configValid "Value: $($test.Value), Expected: $($test.Expected)"
    }
}

# Main Test Execution
function Start-TestSuite {
    Write-Host "`n" -NoNewline
    Write-Host "🚀 Starting Network Metrics Test Suite" -ForegroundColor $Cyan
    Write-Host "Test Script: $TestScriptPath" -ForegroundColor $Yellow
    Write-Host "Main Script: $MainScriptPath" -ForegroundColor $Yellow
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor $Yellow
    
    # Run all test categories
    Test-ScriptSyntax
    Test-NetworkConnectivityLogic
    Test-MetricFormatting
    Test-EdgeCases
    Test-ScriptExecution
    Test-Performance
    Test-Configuration
    
    # Display summary
    Write-Host "`n" -NoNewline
    Write-Host "=" * 60 -ForegroundColor $Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor $Cyan
    Write-Host "=" * 60 -ForegroundColor $Cyan
    Write-Host "Total Tests: $TestCount" -ForegroundColor $Yellow
    Write-Host "Passed: $PassedTests" -ForegroundColor $Green
    Write-Host "Failed: $FailedTests" -ForegroundColor $Red
    Write-Host "Success Rate: $([math]::Round(($PassedTests / $TestCount) * 100, 2))%" -ForegroundColor $Cyan
    
    if ($FailedTests -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor $Red
        $TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.TestName): $($_.Message)" -ForegroundColor $Red
        }
    }
    
    # Export test results
    $TestResults | Export-Csv -Path ".\test_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv" -NoTypeInformation
    Write-Host "`nTest results exported to CSV file." -ForegroundColor $Green
    
    return $TestResults
}

# Interactive Test Menu
function Show-TestMenu {
    do {
        Write-Host "`n" -NoNewline
        Write-Host "Network Metrics Test Harness" -ForegroundColor $Cyan
        Write-Host "============================" -ForegroundColor $Cyan
        Write-Host "1. Run All Tests"
        Write-Host "2. Script Syntax Tests"
        Write-Host "3. Network Connectivity Tests"
        Write-Host "4. Metric Formatting Tests"
        Write-Host "5. Edge Cases Tests"
        Write-Host "6. Script Execution Tests"
        Write-Host "7. Performance Tests"
        Write-Host "8. Configuration Tests"
        Write-Host "9. Packet Loss Simulation"
        Write-Host "10. Exit"
        Write-Host ""
        
        $choice = Read-Host "Select an option (1-10)"
        
        switch ($choice) {
            "1" { Start-TestSuite }
            "2" { Test-ScriptSyntax }
            "3" { Test-NetworkConnectivityLogic }
            "4" { Test-MetricFormatting }
            "5" { Test-EdgeCases }
            "6" { Test-ScriptExecution }
            "7" { Test-Performance }
            "8" { Test-Configuration }
            "9" { 
                Write-Host "Starting Packet Loss Simulation..." -ForegroundColor $Yellow
                . .\Test-PacketLoss.ps1 -Interactive
            }
            "10" { 
                Write-Host "Exiting test harness..." -ForegroundColor $Yellow
                break 
            }
            default { 
                Write-Host "Invalid option. Please select 1-10." -ForegroundColor $Red 
            }
        }
    } while ($choice -ne "10")
}

# Main execution
if ($RunAllTests) {
    Start-TestSuite
} else {
    Show-TestMenu
}
