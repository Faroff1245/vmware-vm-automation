# ==========================================
# VMware PowerCLI Setup
# ==========================================

$env:PSModulePath += ";C:\Users\User\vm_Automation_config\Modules"

Import-Module VMware.PowerCLI

Set-PowerCLIConfiguration `
    -InvalidCertificateAction Ignore `
    -DefaultVIServerMode Multiple `
    -Confirm:$false | Out-Null

# ==========================================
# vSphere Connection
# ==========================================

$vCenter = "0.0.0.0"
$username = "your_username"
$password = "your_password"

try {

    Connect-VIServer `
        -Server $vCenter `
        -User $username `
        -Password $password `
        -ErrorAction Stop | Out-Null

    Write-Host ""
    Write-Host "Connected to vSphere Successfully!" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "vSphere Connection Failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow

    exit
}

# ==========================================
# ESXi Hosts
# ==========================================

$esxiHosts = @(
    "av1.esxi.corp",
    "av2.esxi.corp",
    "av3.esxi.corp"
)

Write-Host ""
Write-Host "Select ESXi Host" -ForegroundColor Cyan
Write-Host "-----------------------------"

for ($i = 0; $i -lt $esxiHosts.Count; $i++) {

    Write-Host "$($i + 1). $($esxiHosts[$i])"
}

$hostChoice = Read-Host "`nEnter Choice"

$selectedHost = $esxiHosts[$hostChoice - 1]

if (-not $selectedHost) {

    Write-Host ""
    Write-Host "Invalid ESXi Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# Allowed Datastores Mapping
# ==========================================

$datastoreMap = @{

    "av1.esxi.corp" = @(
        "datastore1.av1",
        "datastore2.av1",
        "datastore3.av1"
    )

    "av2.esxi.corp" = @(
        "datastore1.av2",
        "datastore2.av2"
    )

    "av3.esxi.corp" = @(
        "datastore2.av3",
        "datastore3.av3"
    )
}

# ==========================================
# Fetch Datastore Details
# ==========================================

Write-Host ""
Write-Host "Fetching Datastore Details..." -ForegroundColor Yellow

$allowedDatastores = $datastoreMap[$selectedHost]

$datastoreObjects = @()

foreach ($dsName in $allowedDatastores) {

    $ds = Get-Datastore -Name $dsName -ErrorAction SilentlyContinue

    if ($ds) {

        $datastoreObjects += $ds
    }
}

if ($datastoreObjects.Count -eq 0) {

    Write-Host ""
    Write-Host "No valid datastores found!" -ForegroundColor Red

    exit
}

# ==========================================
# Display Datastores
# ==========================================

Write-Host ""
Write-Host "Available Datastores" -ForegroundColor Green
Write-Host "---------------------------------------------"

$index = 1

foreach ($ds in $datastoreObjects) {

    $freeGB = [math]::Round($ds.FreeSpaceGB, 2)

    Write-Host "$index. $($ds.Name)  |  Free Space: $freeGB GB"

    $index++
}

# ==========================================
# Select Datastore
# ==========================================

$dsChoice = Read-Host "`nSelect Datastore Number"

$selectedDatastore = $datastoreObjects[$dsChoice - 1]

if (-not $selectedDatastore) {

    Write-Host ""
    Write-Host "Invalid Datastore Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# Final Output
# ==========================================

Write-Host ""
Write-Host "Selected Infrastructure" -ForegroundColor Cyan
Write-Host "---------------------------------------------"

Write-Host "ESXi Host   : $selectedHost"
Write-Host "Datastore   : $($selectedDatastore.Name)"
Write-Host "Free Space  : $([math]::Round($selectedDatastore.FreeSpaceGB,2)) GB"

Write-Host ""
Write-Host "Infrastructure Selection Completed Successfully!" -ForegroundColor Green
