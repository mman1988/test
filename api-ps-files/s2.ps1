
try {
    # Make the API call to a non-existing endpoint (simulated failure)
    $url = "https://jsonplaceholder.typicode.com/invalid-endpoint"
    $response = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 10

    # If successful, print the response content
    Write-Host " API call succeeded"
    Write-Host "Response content: $($response | ConvertTo-Json -Depth 10)"
} 
catch {
    # If an error occurs, catch the exception and print the error message
    Write-Host " ERROR: API call failed"
    Write-Host "Error message: $_"
    exit 1
}

