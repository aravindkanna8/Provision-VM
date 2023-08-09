# Prompt the user for certificate name
$cername = Read-Host -Prompt "Enter the name for the certificate"

# Update Revocation List
$uri = "http://127.0.0.1:8000/update_revocation_list?name=$cername%2F$cername-cert.pem"

$headers = @{
    "accept" = "application/json"
}

$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$response | ConvertTo-Json

# Get Revoked Certificate List
$uri = "http://127.0.0.1:8000/get_revoked_cert_list"

$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$response | ConvertTo-Json


# Perform OCSP Request
$uri = "http://127.0.0.1:8000/ocsp?ocsp_req=$cername%2F$cername-cert.pem"

$headers = @{
    "accept" = "*/*"
}

try {
    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
    $response | ConvertTo-Json
} catch {
    Write-Host "Failed to perform the OCSP request. Error: $($_.Exception.Message)"
}