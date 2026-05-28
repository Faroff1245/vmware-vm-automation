# ==========================================
# VMware PowerCLI Setup
# ==========================================

$env:PSModulePath += ";C:\Users\User\vm_Automation_config\Modules"

Import-Module VMware.PowerCLI

# PowerCLI Configuration
Set-PowerCLIConfiguration `
    -InvalidCertificateAction Ignore `
    -DefaultVIServerMode Multiple `
    -Confirm:$false | Out-Null

# ==========================================
# vSphere Connection
# ==========================================

$vCenter = "192.168.22.72"
$username = "kc@esxi.crp"
$password = "vhtv!HcY!wqm9q4%H!q*"

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
# Datastore Configuration
# ==========================================

$datastore = Get-Datastore -Name "NAS4"

if (-not $datastore) {

    Write-Host ""
    Write-Host "Datastore 'NAS4' not found!" -ForegroundColor Red

    exit
}

# Create datastore PSDrive
New-PSDrive `
    -Location $datastore `
    -Name DS `
    -PSProvider VimDatastore `
    -Root "\" `
    -ErrorAction SilentlyContinue | Out-Null

# ==========================================
# Select Windows Family
# ==========================================

Write-Host ""
Write-Host "Select Windows Version Family" -ForegroundColor Cyan
Write-Host "--------------------------------"

Write-Host "1. Windows 10"
Write-Host "2. Windows 11"

$osChoice = Read-Host "`nEnter Choice"

switch ($osChoice) {

    "1" {

        $osFolder = "Windows 10/64Bit"
        $osName   = "Windows 10"
    }

    "2" {

        $osFolder = "Windows 11/64 Bit"
        $osName   = "Windows 11"
    }

    default {

        Write-Host ""
        Write-Host "Invalid Selection!" -ForegroundColor Red

        exit
    }
}

# ==========================================
# Fetch Available Versions
# ==========================================

Write-Host ""
Write-Host "Fetching available versions..." -ForegroundColor Yellow

try {

    $versionFolders = Get-ChildItem "DS:\$osFolder" |
                      Where-Object { $_.PSIsContainer }
}
catch {

    Write-Host ""
    Write-Host "Failed to fetch Windows versions!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow

    exit
}

if ($versionFolders.Count -eq 0) {

    Write-Host ""
    Write-Host "No Windows versions found!" -ForegroundColor Red

    exit
}

# ==========================================
# Display Available Versions
# ==========================================

Write-Host ""
Write-Host "Available $osName Versions" -ForegroundColor Green
Write-Host "--------------------------------"

$index = 1

foreach ($folder in $versionFolders) {

    Write-Host "$index. $($folder.Name)"

    $index++
}

# ==========================================
# User Selects Version
# ==========================================

$versionChoice = Read-Host "`nSelect Version Number"

$selectedFolder = $versionFolders[$versionChoice - 1]

if (-not $selectedFolder) {

    Write-Host ""
    Write-Host "Invalid Version Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# Find ISO Inside Selected Folder
# ==========================================

$selectedFolderPath = "DS:\$osFolder\$($selectedFolder.Name)"

$isoFiles = Get-ChildItem $selectedFolderPath |
            Where-Object { $_.Name -like "*.iso" }

if ($isoFiles.Count -eq 0) {

    Write-Host ""
    Write-Host "No ISO found inside selected version folder!" -ForegroundColor Red

    exit
}

$selectedISO = $isoFiles[0]

# ==========================================
# Final Output
# ==========================================

Write-Host ""
Write-Host "Selected Details" -ForegroundColor Cyan
Write-Host "--------------------------------"

Write-Host "OS Family  : $osName"
Write-Host "Version    : $($selectedFolder.Name)"
Write-Host "ISO File   : $($selectedISO.Name)"
Write-Host "ISO Path   : $($selectedISO.DatastoreFullPath)"

Write-Host ""
Write-Host "ISO Discovery Completed Successfully!" -ForegroundColor Green