# ==========================================
# VMware vSphere Connection Script
# ==========================================

# Load VMware PowerCLI module
Import-Module VMware.PowerCLI

# Ignore SSL certificate warnings
Set-PowerCLIConfiguration `
    -InvalidCertificateAction Ignore `
    -Confirm:$false

# vSphere / vCenter details
$vCenter = "0.0.0.0"
$username = "your_username"
$password = "your_password"

Write-Host ""
Write-Host "Connecting to vSphere..." -ForegroundColor Cyan

# Connect to vSphere
Connect-VIServer `
    -Server $vCenter `
    -User $username `
    -Password $password

Write-Host ""
Write-Host "Connected Successfully!" -ForegroundColor Green
