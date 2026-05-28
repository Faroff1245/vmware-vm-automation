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
$vCenter = "192.168.22.72"
$username = "kc@esxi.crp"
$password = "vhtv!HcY!wqm9q4%H!q*"

Write-Host ""
Write-Host "Connecting to vSphere..." -ForegroundColor Cyan

# Connect to vSphere
Connect-VIServer `
    -Server $vCenter `
    -User $username `
    -Password $password

Write-Host ""
Write-Host "Connected Successfully!" -ForegroundColor Green