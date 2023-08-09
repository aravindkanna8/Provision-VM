Import-Module WebAdministration

function Test-WebPage {
    param(
        [string]$Url
    )

    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $response = $request.GetResponse()
        $statusCode = $response.StatusCode
        $response.Close()

        if ($statusCode -eq "OK") {
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

$directoryPath = Join-Path -Path $PWD -ChildPath "Vms"

if (-not (Test-Path $directoryPath -PathType Container)) {
    New-Item -Path $directoryPath -ItemType Directory | Out-Null
    Write-Host "Directory 'Vms' created."
} else {
    Write-Host "Directory 'Vms' already exists."
}



$jsonConfig = Get-Content -Raw -Path config.json
$jsonObject1 = $jsonConfig | ConvertFrom-Json
$sitePath = $jsonObject1.autoyast.site_folder
$siteName = $jsonObject1.autoyast.site_name
$thumb = $jsonObject1.https.thumb
$name = $jsonObject1.autoyast.host
$revokedSerialNumberFile = $jsonObject1.https.keyfolder + "\" + "revoked_serial_numbers.txt"
$stringSerialNumberFile = $jsonObject1.https.keyfolder + "\" + $name + "\" + $name + "_sr_no.txt"
$webConfigPath = $jsonObject1.autoyast.site_folder+ "\" + "web.config"
# $webConfigPath = $jsonObject1.
# Define the content of the web.config file
$webConfigContent = @"
<configuration>
  <system.webServer>
    <directoryBrowse enabled="true" />
    <staticContent>
      <mimeMap fileExtension=".pem" mimeType="application/octet-stream" />
      <mimeMap fileExtension=".config" mimeType="application/octet-stream" />
      <mimeMap fileExtension=".*" mimeType="application/octet-stream" />
    </staticContent>
  </system.webServer>
</configuration>
"@

# Create the web.config file
$webConfigContent | Set-Content -Path $webConfigPath


Write-Host "'$thumb'"
$existingSite = Get-Website $siteName -ErrorAction SilentlyContinue
if ($existingSite -ne $null) {
    # Prompt the user to choose whether to delete the existing website and create a new one or use the existing website
    $userChoice = Read-Host "A website with the name '$siteName' already exists. Do you want to delete the existing website and create a new one? (Y/N)"

    if ($userChoice -eq "Y" -or $userChoice -eq "y") {
        # Stop the existing website
        Stop-Website $siteName

        # Remove the existing website
        Remove-Website $siteName
    } else {
        # Use the existing website
        Write-Host "Using the existing website '$siteName'."
        return
    }
}

$website = Get-Website -Name $siteName
if ($website -ne $null) {
    $siteId = $website.ID
    Stop-Website -Id $siteId
} else {
    Write-Host "Website '$siteName' does not exist."
}

$bindingPort = "8443"
Write-Host "The selected binding port is: $bindingPort"

$bindingIP = "*"

$webConfigPath = Join-Path $sitePath "web.config"

# Create a new access control list (ACL) object
$folderAcl = New-Object System.Security.AccessControl.DirectorySecurity

# Create a new access rule
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAndExecute,Read,ListDirectory", "ContainerInherit,ObjectInherit", "None", "Allow")

# Add the access rule to the ACL object
$folderAcl.AddAccessRule($rule)

# Set the ACL object to the site path
Set-Acl -Path $sitePath -AclObject $folderAcl

# Create the website
$site = New-WebSite -Name $siteName -PhysicalPath $sitePath -Port $bindingPort -Force

# Import the certificate
$certificateThumbprint = $thumb
$certificateStoreName = "My"

# # Add MIME map for all file types
# Add-WebConfigurationProperty -pspath "IIS:\Sites\$siteName" -filter "system.webServer/staticContent/mimeMap" -name "." -value @{fileExtension='*'; mimeType='application/octet-stream'} -Force

# # Add MIME map for .pem file
# Add-WebConfigurationProperty -pspath "IIS:\Sites\$siteName" -filter "system.webServer/staticContent/mimeMap" -name "." -value @{fileExtension='.pem'; mimeType='application/octet-stream'} -Force

# # Enable directory browsing
# Set-WebConfigurationProperty -pspath "IIS:\Sites\$siteName" -filter "system.webServer/directoryBrowse" -name "enabled" -value $true



$certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$certificateThumbprint"

if ($certificate) {
    # Remove the HTTP binding for the website
 
    $bindings = Get-WebBinding -Name $siteName
    $bindings | Where-Object { $_.Protocol -eq "http" } | Remove-WebBinding

    # Create the HTTPS binding
    $bindingInformation = "${bindingIP}:${bindingPort}:"
    $sslFlags = 1  # Enable SNI support

    $binding = $bindings | Where-Object { $_.Protocol -eq "https" -and $_.BindingInformation -eq $bindingInformation }
    if (!$binding) {
        Write-Host "Creating HTTPS binding for port $bindingPort and IP address $bindingIP..."

        # Create the HTTPS binding
        $binding = New-WebBinding -Name $siteName -Protocol "https" -Port $bindingPort -IPAddress $bindingIP
        # Set the SSL certificate binding
        $bindingString = "IP:${bindingIP}:${bindingPort}"
        $certHash = $certificate.Thumbprint
        $appId = "{4dc3e181-e14b-4a21-b022-59fc669b0914}"

        # Remove any existing SSL certificate binding for the specified IP and port
        Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\SslBindingInfo" -Name $bindingString -ErrorAction SilentlyContinue

        # Add the new SSL certificate binding
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\HTTP\Parameters\SslBindingInfo" -Name $bindingString -Value "$certHash $appId" -PropertyType "String" | Out-Null


        Write-Host "HTTPS binding created successfully."
    } else {
        Write-Host "HTTPS binding already exists for port $bindingPort and IP address $bindingIP."
    }

    # Configure SSL certificate for the binding
    $binding = Get-WebBinding -Name $siteName -Protocol "https" -Port $bindingPort -IPAddress $bindingIP
    $binding.AddSslCertificate($certificate.Thumbprint, "My")




    # Read the revoked serial numbers file
    $revokedSerialNumbers = Get-Content $revokedSerialNumberFile

    # Read the string serial numbers file
    $stringSerialNumbers = Get-Content $stringSerialNumberFile

    # Iterate through each string serial number
    foreach ($serialNumber in $stringSerialNumbers) {
        # Check if the serial number is in the revoked list
        if ($revokedSerialNumbers -contains $serialNumber) {
            # Serial number is revoked
            Write-Output "Serial Number $serialNumber is REVOKED"
            
            $websitePath = Join-Path $sitePath "index.html"
    $forbiddenContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>403 Forbidden</title>
</head>
<body>
    <h1>403 Forbidden</h1>
    <p>The certificate for this website is revoked. Access is forbidden.</p>
</body>
</html>
"@
    $forbiddenContent | Set-Content -Path $websitePath
      # Remove the index.html file in subdirectories
        $subDirectories = Get-ChildItem -Path $sitePath -Directory -Recurse
        foreach ($subDirectory in $subDirectories) {
            $subWebsitePath = Join-Path $subDirectory.FullName "index.html"
           $forbiddenContent | Set-Content -Path $subWebsitePath
        }
        
    Write-Host "Website started with a revoked certificate. Access is forbidden."

    break  # Stop iterating through other serial numbers
            
         }
        else {
            # Remove the index.html file from every directory and subdirectory
        $directories = Get-ChildItem -Path $sitePath -Directory -Recurse
        foreach ($directory in $directories) {
            $subWebsitePath = Join-Path $directory.FullName "index.html"
            if (Test-Path $subWebsitePath) {
                Remove-Item -Path $subWebsitePath -Force
            }
        }
           
            # Serial number is not revoked
            Write-Output "Serial Number $serialNumber is GOOD"

        }
    }
$ipconfigOutput = ipconfig /all

$ipv4Regex = [regex]::Matches($ipconfigOutput, 'Ethernet.*?IPv4 Address.*?:\s+(\d+\.\d+\.\d+\.\d+)')
$ethernetIPv4 = $ipv4Regex.Groups[1].Value

Write-Host "Ethernet IPv4 Address: $ethernetIPv4"



    $websiteUrl = "https://$($ethernetIPv4):$($bindingPort)/"

    Start-Process $websiteUrl -ErrorAction SilentlyContinue

    Write-Host "Website '$siteName' started successfully."
    Write-Host "Website URL: $websiteUrl"
    $websiteUrl > $sitePath\$siteName.txt
#  # Check if the website started successfully
# $website = Get-Website $siteName -ErrorAction SilentlyContinue
# if ($website.State -eq "Started") {
#     if ((Test-WebPage -Url $websiteUrl) -eq $true) {
#         Write-Host "Website '$siteName' started successfully."
#         Write-Host "Website URL: $websiteUrl"
#         $websiteUrl > $sitePath\$siteName.txt
#     } else {
#         Write-Host "Failed to show content after starting the website."
#     }
# } else {
#     Write-Host "Failed to start the website '$siteName'."
# }


} else {
    Write-Host "Failed to find the specified certificate with thumbprint '$certificateThumbprint' in the '$certificateStoreName' certificate store."
}
