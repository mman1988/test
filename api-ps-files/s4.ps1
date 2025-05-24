
# failing-api.ps1

$uri = "https://nonexistent-api.example.com/fake-endpoint"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 5
    Write-Host "API call succeeded: $($response | ConvertTo-Json -Depth 5)"
} catch {
    throw "API call failed: $($_.Exception.Message)"
}

