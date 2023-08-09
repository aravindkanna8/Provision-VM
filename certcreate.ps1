
# Prompt the user for certificate name
$cername = Read-Host -Prompt "Enter the name for the certificate"

$https_Path = $jsonObject1.autoyast.https_folder
$configPath = "$https_Path\config.json"

$jsonConfig = Get-Content -Raw -Path $configPath | ConvertFrom-Json

# Check if the autoyast object exists, and create it if necessary
if (-not $jsonConfig.autoyast) {
    $jsonConfig | Add-Member -NotePropertyName "autoyast" -NotePropertyValue @{}
}


# Update the host property within the autoyast object
$jsonConfig.autoyast.host = $cername

# Convert the JSON object back to a JSON string
$jsonString = $jsonConfig | ConvertTo-Json -Depth 10

# Save the updated JSON string back to the config.json file
$jsonString | Set-Content -Path $configPath



$uri = "http://127.0.0.1:8000/get_new_certificate"

$headers = @{
    "accept" = "application/json"
    "Content-Type" = "application/json"
}

$body = @{
    "generate_new" = $true
    "name" = $cername
    "hostname" = $cername
    "subject_name" = $cername
    "passphrase" = $cername
    "ip_address" = "127.0.0.1"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers -Body $body
$response > output.log

$uri = "http://127.0.0.1:8000/get_serial_no?data=$cername%2F$cername-cert.pem"

$headers = @{
    "accept" = "application/json"
}

$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$response | ConvertTo-Json 