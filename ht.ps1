# $opensslPath = "C:\Program Files\Git\usr\bin\openssl.exe"
# $keyfolder = "C:\Users\Aras\Documents\Newfolder1\openssl"
# $privateKeyPath = "${keyfolder}\ca-key.pem"
# $certificatePath = "${keyfolder}\ca.pem"
# $certKeyPath = "${keyfolder}\cert-key.pem"
# $csrPath = "${keyfolder}\cert.csr"
# $certPath = "${keyfolder}\cert.pem"
# $extfilePath = "${keyfolder}\extfile.cnf"
# $pfxPath = "${keyfolder}\cert.pfx"
# $bits = 4096
# $days = 365
# $commonName = "/CN=IISdirectoryServer"
# $pass = "novell"
# $Password = "novell"
# $sub = "/C=IN/ST=KR/L=BLR/O=MF/OU=NL/CN=Ashok/emailAddress=KAVI"
# $extsub = "[dn]
# C=IN
# ST=KR
# L=BLR
# O=MF
# OU=NL
# CN=Ashok
# emailAddress=KAVI"

$jsonConfig = Get-Content -Raw -Path config.json
$jsonObject1 = $jsonConfig | ConvertFrom-Json
$sitePath = $jsonObject1.autoyast.https_folder
$opensslPath = $jsonObject1.https.opensslPath
$keyfolder = $jsonObject1.https.keyfolder
$privateKeyPath = $jsonObject1.https.privateKeyPath
$certificatePath = $jsonObject1.https.certificatePath
$certKeyPath = $jsonObject1.https.certKeyPath
$csrPath = $jsonObject1.https.csrPath
$certPath = $jsonObject1.https.certPath
$extfilePath = $jsonObject1.https.extfilePath
$pfxPath = $jsonObject1.https.pfxPath
$bits = $jsonObject1.https.bits
$days = $jsonObject1.https.days
$commonName = $jsonObject1.https.commonName
$pass = $jsonObject1.https.pass
$Password = $jsonObject1.https.Password
$output = $jsonObject1.https.Output
$sub = $jsonObject1.https.sub
$extsub = $jsonObject1.https.extsub
$rootPrivateKeyPath = $jsonObject1.https.rootPrivateKeyPath
$rootCertificatePath = $jsonObject1.https.rootCertificatePath



if (-not (Test-Path $rootPrivateKeyPath) -or -not (Test-Path $rootCertificatePath)) {
Write-Host "Generating RSA private key for  CA..."
$arguments = "genrsa", "-aes256", "-passout", "pass:$pass", "-out", $rootPrivateKeyPath, $bits
Start-Process -FilePath $opensslPath -ArgumentList $arguments -NoNewWindow -Wait
Write-Host "RSA private key for  CA generated successfully."

# Generate Root CA certificate
Write-Host "Generating  CA certificate..."
$arguments = "req", "-new", "-x509", "-sha256", "-days", $days, "-key", $rootPrivateKeyPath, "-out", $rootCertificatePath, "-passin", "pass:$pass", "-subj", $sub
Start-Process -FilePath $opensslPath -ArgumentList $arguments -NoNewWindow -Wait
Write-Host " CA certificate generated successfully."


Import-Certificate -FilePath $rootCertificatePath -CertStoreLocation Cert:\LocalMachine\Root
Write-Host "CA certificate imported successfully."

$uri = "http://127.0.0.1:8000/create_new_crl"

$headers = @{
    "accept" = "application/json"
}

$response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers
$response | ConvertTo-Json > output.log

$uri1 = "http://127.0.0.1:8000/get_new_certificate"

$headers1 = @{
    "accept" = "application/json"
    "Content-Type" = "application/json"
}

$body = @{
    "generate_new" = $true
    "name" = "response"
    "hostname" = "response"
    "subject_name" = "response"
    "passphrase" = "response"
    "ip_address" = "127.0.0.1"
} | ConvertTo-Json

$response1 = Invoke-RestMethod -Uri $uri1 -Method POST -Headers $headers1 -Body $body
$response1 > output.log

Write-Host "Waiting for 5 seconds..."
Start-Sleep -Seconds 5
}
Write-Host "Calling script for generating certificate..."
& $sitePath\certcreate.ps1
Write-Host "certificate generated successfully."

$jsonConfig1 = Get-Content -Raw -Path config.json
$jsonObject2 = $jsonConfig1 | ConvertFrom-Json
$name = $jsonObject2.autoyast.host
$certkpath = $jsonObject2.https.certkpath + "\" + $name + "\" + $name + ".pem"
$cerpath = $jsonObject2.https.cerpath + "\" + $name + "\" + $name + "-cert.pem"

Write-Host "Exporting certificate and private key as PKCS12..."
$arguments = "pkcs12", "-inkey", $certkpath, "-in", $cerpath, "-export", "-out", $pfxPath, "-passout", "pass:$Password"
Start-Process -FilePath $opensslPath -ArgumentList $arguments -NoNewWindow -Wait
Write-Host "Certificate and private key exported as PKCS12 successfully."

# Import the PKCS12 certificate into LocalMachine Root store
Write-Host "Importing certificate into LocalMachine Root store..."


# Load the PKCS12 file
$certificateBytes = [System.IO.File]::ReadAllBytes($pfxPath)
$certificateCollection = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
$certificateCollection.Import($certificateBytes, $Password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)

# Open the LocalMachine root certificate store
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList "Root", "LocalMachine"
$store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)

# Add the imported certificate to the store
foreach ($certificate in $certificateCollection) {
    $store.Add($certificate)
}

# Close the certificate store
$store.Close()


# Import the PFX certificate into the IIS server certificates
$cert = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString -String $Password -Force -AsPlainText)
# Verify if the certificate was imported successfully
if ($cert) {
    Write-Host "Certificate imported successfully."
} else {
    Write-Host "Failed to import the certificate."
}

# Get the certificate thumbprint
$thumbprint = $cert.Thumbprint

# Load the JSON configuration from the file
$jsonConfig = Get-Content -Raw -Path "config.json" | ConvertFrom-Json

# Update the https_folder property with the thumbprint value
$jsonConfig.https.thumb = $thumbprint

# Convert the JSON object back to a JSON string
$jsonString = $jsonConfig | ConvertTo-Json -Depth 10

# Save the updated JSON string back to the file
$jsonString | Set-Content -Path "config.json"

Write-Host "Thumbprint added to the 'https_folder' property in config.json."


Write-Host "Waiting for 10 seconds..."
Start-Sleep -Seconds 10

#$arguments = "-Thumbprint", $thumbprint

Write-Host "Calling script with arguments..."
& $sitePath\iis_https.ps1 
Write-Host "Script executed successfully."
