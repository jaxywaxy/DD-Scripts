# Network Metrics Script Test Harness

This test harness provides comprehensive testing capabilities for the custom network metrics PowerShell script that sends network connectivity data to Datadog's DogStatsD.

## Files Overview

- **`Test-NetworkMetrics.ps1`** - Main test harness with comprehensive test suites
- **`Test-Utilities.ps1`** - Additional testing utilities and mock functions
- **`test_custom_network_metrics.ps1`** - Test version of the network metrics script
- **`custom_network_metrics.ps1`** - Production network metrics script

## Quick Start

### Run All Tests
```powershell
.\Test-NetworkMetrics.ps1 -RunAllTests
```

### Interactive Test Menu
```powershell
.\Test-NetworkMetrics.ps1
```

### Run Specific Test Categories
```powershell
# Test script syntax only
.\Test-NetworkMetrics.ps1 -TestScriptPath ".\test_custom_network_metrics.ps1"
```

## Test Categories

### 1. Script Syntax Tests
- Validates PowerShell syntax
- Checks for parsing errors
- Ensures script can be loaded

### 2. Network Connectivity Logic Tests
- Tests successful ping scenarios
- Tests failed ping scenarios
- Validates latency calculations
- Validates packet loss calculations
- Tests connection status logic

### 3. Metric Formatting Tests
- Validates metric message format
- Tests different metric types
- Ensures proper DogStatsD format

### 4. Edge Cases Tests
- Tests null value handling
- Tests extreme values
- Tests error conditions

### 5. Script Execution Tests
- Tests script loading
- Validates variable assignments
- Tests execution flow

### 6. Performance Tests
- Measures execution time
- Validates performance thresholds
- Tests under load

### 7. Configuration Tests
- Validates default settings
- Tests configuration parameters

## Advanced Testing Features

### Mock Functions
The test harness includes mock functions to simulate network conditions:

```powershell
# Mock successful network test
$results = Mock-TestConnection -ComputerName "google.com" -Count 10

# Mock failed network test
$results = Mock-TestConnection -ComputerName "timeout.example.com" -Count 10
```

### Network Simulation
Simulate different network conditions:

```powershell
# Import test utilities
. .\Test-Utilities.ps1

# Simulate normal network conditions
Start-NetworkSimulation -Scenario "normal" -DurationSeconds 60

# Simulate slow network
Start-NetworkSimulation -Scenario "slow" -DurationSeconds 60

# Simulate unstable network
Start-NetworkSimulation -Scenario "unstable" -DurationSeconds 60
```

### Performance Benchmarking
Measure script performance:

```powershell
# Benchmark script performance
$results = Measure-ScriptPerformance -ScriptPath ".\test_custom_network_metrics.ps1" -Iterations 10
```

### Load Testing
Test script under concurrent load:

```powershell
# Load test with 5 concurrent users for 30 seconds
$results = Start-LoadTest -ScriptPath ".\test_custom_network_metrics.ps1" -ConcurrentUsers 5 -TestDurationSeconds 30
```

## Test Scenarios

### Normal Operation
- Successful ping to destination
- Low latency (< 100ms)
- Zero packet loss
- Connection status = 1

### Network Issues
- Failed ping to destination
- Null latency
- 100% packet loss
- Connection status = 0

### Slow Network
- Successful ping but high latency (> 200ms)
- Zero packet loss
- Connection status = 1

### Unstable Network
- Partial ping success
- Variable latency
- Some packet loss
- Connection status = 1

## Test Results

### Console Output
The test harness provides color-coded output:
- 🟢 Green: Passed tests
- 🔴 Red: Failed tests
- 🟡 Yellow: Warnings/Info
- 🔵 Cyan: Headers/Summary

### CSV Export
Test results are automatically exported to CSV files with timestamps:
```
test_results_20231201_143022.csv
```

### Test Summary
Each test run provides:
- Total test count
- Passed/Failed counts
- Success rate percentage
- Failed test details

## Customization

### Adding New Tests
To add new test categories, create a function following this pattern:

```powershell
function Test-YourNewCategory {
    Write-TestHeader "Your New Test Category"
    
    # Your test logic here
    $testResult = $true  # or $false
    Write-TestResult "Your Test Name" $testResult "Optional message"
}
```

### Modifying Test Data
Update the `New-TestData` function in `Test-Utilities.ps1` to add new test scenarios:

```powershell
function New-TestData {
    param([string]$Scenario = "normal")
    
    switch ($Scenario) {
        "your_new_scenario" {
            return @{
                DestinationHost = "your-host.com"
                SourceHost = "test-server"
                ExpectedLatency = 50.0
                ExpectedPacketLoss = 5.0
                ExpectedConnectionStatus = 1
            }
        }
    }
}
```

## Troubleshooting

### Common Issues

1. **Script Path Issues**
   - Ensure script paths are correct
   - Use absolute paths if needed
   - Check file permissions

2. **PowerShell Execution Policy**
   - May need to set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

3. **Mock Functions Not Working**
   - Ensure `Test-Utilities.ps1` is loaded
   - Check function names and parameters

### Debug Mode
Enable verbose output:
```powershell
.\Test-NetworkMetrics.ps1 -Verbose
```

## Integration with CI/CD

### Automated Testing
The test harness can be integrated into CI/CD pipelines:

```powershell
# Run tests and capture exit code
$testResults = .\Test-NetworkMetrics.ps1 -RunAllTests
$exitCode = if ($testResults | Where-Object { -not $_.Passed }) { 1 } else { 0 }
exit $exitCode
```

### Scheduled Testing
Set up scheduled testing using Windows Task Scheduler or cron:

```powershell
# Daily test run
.\Test-NetworkMetrics.ps1 -RunAllTests | Out-File "daily_test_results_$(Get-Date -Format 'yyyyMMdd').log"
```

## Best Practices

1. **Regular Testing**: Run tests before deploying changes
2. **Test Coverage**: Ensure all code paths are tested
3. **Mock External Dependencies**: Use mock functions for external services
4. **Document Test Scenarios**: Keep test documentation updated
5. **Monitor Performance**: Track test execution times
6. **Version Control**: Include test files in version control

## Support

For issues or questions about the test harness:
1. Check the console output for error messages
2. Review the CSV test results for detailed information
3. Verify script paths and permissions
4. Test individual components using the interactive menu

