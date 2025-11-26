$DestinationHost = "dca-genrep-p01.genesis.co.nz"
$SourceHost = "thetatools-p01.genesis.co.nz"

# Latency and Packet Loss
$pingCount = 10
$pingResults = Test-Connection -ComputerName $DestinationHost -Count $pingCount -ErrorAction SilentlyContinue

if ($pingResults) {
    $successfulPings = $pingResults.Count
    $latency = ($pingResults | Measure-Object ResponseTime -Average).Average
    $packetLoss = 100 - (($successfulPings / $pingCount) * 100)
} else {
    $latency = $null
    $packetLoss = 100
}

# Connection Status
$connectionStatus = if ($latency -ne $null) { 1 } else { 0 }

# Function to send metrics to DogStatsD
function Send-Metric {
    param (
        [string]$MetricName,
        [float]$Value
    )
    if ($Value -ne $null) {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $endpoint = New-Object System.Net.IPEndPoint ([System.Net.IPAddress]::Parse("127.0.0.1"), 8125)
        $message = "${MetricName}:${Value}|g|#source:${SourceHost},destination:${DestinationHost}"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($message)
        $udpClient.Send($bytes, $bytes.Length, $endpoint)
        $udpClient.Close()
    }
}

# Send metrics
Send-Metric -MetricName "custom.network.latency" -Value $latency
Send-Metric -MetricName "custom.network.packet_loss" -Value $packetLoss
Send-Metric -MetricName "custom.network.connection_status" -Value $connectionStatus

