

$env:PSModulePath += ";C:\Users\User\vm_Automation_config\Modules"

Import-Module VMware.PowerCLI

Set-PowerCLIConfiguration `
    -InvalidCertificateAction Ignore `
    -DefaultVIServerMode Multiple `
    -Confirm:$false | Out-Null

# ==========================================
# vSphere Connection
# ==========================================

$vCenter = "192.168.22.72"
$username = "your_username_here"
$password = "your_password_here"

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
# FIXED TEST CONFIG
# ==========================================

$vmName = "Testing_New_Vm"

$cpuCount = 2

$ramMB = 2060

$diskGB = 45

$networkName = "Private-AV-Network"

# ==========================================
# WINDOWS VERSION SELECTION
# ==========================================

$isoDatastore = Get-Datastore -Name "nas4"

New-PSDrive `
    -Location $isoDatastore `
    -Name DS `
    -PSProvider VimDatastore `
    -Root "\" `
    -ErrorAction SilentlyContinue | Out-Null

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
        $guestId  = "windows9_64Guest"
    }

    "2" {

        $osFolder = "Windows 11/64 Bit"
        $osName   = "Windows 11"
        $guestId  = "windows9_64Guest"
    }

    default {

        Write-Host ""
        Write-Host "Invalid Selection!" -ForegroundColor Red

        exit
    }
}

# ==========================================
# FETCH WINDOWS VERSIONS
# ==========================================

$versionFolders = Get-ChildItem "DS:\$osFolder" |
                  Where-Object { $_.PSIsContainer }

if ($versionFolders.Count -eq 0) {

    Write-Host ""
    Write-Host "No Windows versions found!" -ForegroundColor Red

    exit
}

Write-Host ""
Write-Host "Available $osName Versions" -ForegroundColor Green
Write-Host "--------------------------------"

$index = 1

foreach ($folder in $versionFolders) {

    Write-Host "$index. $($folder.Name)"

    $index++
}

$versionChoice = Read-Host "`nSelect Version Number"

$selectedFolder = $versionFolders[$versionChoice - 1]

if (-not $selectedFolder) {

    Write-Host ""
    Write-Host "Invalid Version Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# FIND ISO
# ==========================================

$selectedFolderPath = "DS:\$osFolder\$($selectedFolder.Name)"

$isoFiles = Get-ChildItem $selectedFolderPath |
            Where-Object { $_.Name -like "*.iso" }

if ($isoFiles.Count -eq 0) {

    Write-Host ""
    Write-Host "No ISO found!" -ForegroundColor Red

    exit
}

$selectedISO = $isoFiles[0]

Write-Host ""
Write-Host "ISO Selected:" -ForegroundColor Cyan
Write-Host $selectedISO.DatastoreFullPath

# ==========================================
# ESXi HOST SELECTION
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
    Write-Host "Invalid Host Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# DATASTORE SELECTION
# ==========================================

switch ($selectedHost) {

    "av1.esxi.corp" {

        $allowedDatastores = @(
            "datastore1.av1",
            "datastore2.av1",
            "datastore3.av1"
        )
    }

    "av2.esxi.corp" {

        $allowedDatastores = @(
            "datastore1.av2",
            "datastore2.av2"
        )
    }

    "av3.esxi.corp" {

        $allowedDatastores = @(
            "datastore2.av3",
            "datastore3.av3"
        )
    }
}

$datastores = Get-Datastore |
              Where-Object {
                    $_.Name -in $allowedDatastores
              }

Write-Host ""
Write-Host "Available Datastores" -ForegroundColor Green
Write-Host "-----------------------------"

for ($i = 0; $i -lt $datastores.Count; $i++) {

    $freeGB = [math]::Round($datastores[$i].FreeSpaceGB, 2)

    Write-Host "$($i + 1). $($datastores[$i].Name) | Free: $freeGB GB"
}

$dsChoice = Read-Host "`nSelect Datastore"

$selectedDatastore = $datastores[$dsChoice - 1]

if (-not $selectedDatastore) {

    Write-Host ""
    Write-Host "Invalid Datastore Selection!" -ForegroundColor Red

    exit
}

# ==========================================
# GET HOST OBJECT
# ==========================================

$vmHost = Get-VMHost -Name $selectedHost

if (-not $vmHost) {

    Write-Host ""
    Write-Host "Failed to find ESXi Host!" -ForegroundColor Red

    exit
}

# ==========================================
# CREATE VM
# ==========================================

Write-Host ""
Write-Host "Creating VM..." -ForegroundColor Yellow

try {

    $vm = New-VM `
        -Name $vmName `
        -VMHost $vmHost `
        -Datastore $selectedDatastore `
        -NumCpu $cpuCount `
        -MemoryMB $ramMB `
        -DiskGB $diskGB `
        -GuestId $guestId `
        -NetworkName $networkName `
        -Version v18

    Write-Host ""
    Write-Host "VM Created Successfully!" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "VM Creation Failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow

    exit
}

# ==========================================
# ADD DATASTORE ISO CD/DVD
# ==========================================

Write-Host ""
Write-Host "Adding Datastore ISO CD/DVD..." -ForegroundColor Yellow

try {

    $cdspec = New-Object VMware.Vim.VirtualDeviceConfigSpec
    $cdspec.Operation = "add"

    $cdrom = New-Object VMware.Vim.VirtualCdrom
    $cdrom.Key = -1
    $cdrom.ControllerKey = 200
    $cdrom.UnitNumber = 0
    $cdrom.Connectable = New-Object VMware.Vim.VirtualDeviceConnectInfo
    $cdrom.Connectable.StartConnected = $true
    $cdrom.Connectable.AllowGuestControl = $true
    $cdrom.Connectable.Connected = $true

    $backing = New-Object VMware.Vim.VirtualCdromIsoBackingInfo
    $backing.FileName = $selectedISO.DatastoreFullPath

    $cdrom.Backing = $backing

    $cdspec.Device = $cdrom

    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.DeviceChange = @($cdspec)

    $vm.ExtensionData.ReconfigVM($spec)

    Write-Host ""
    Write-Host "Datastore ISO CD/DVD Added Successfully!" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "Failed to Attach ISO!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow

    exit
}

# ==========================================
# CONFIGURE CD/DVD FIRST BOOT
# ==========================================

Write-Host ""
Write-Host "Configuring Boot Options..." -ForegroundColor Yellow

try {

    $vmView = Get-View $vm.Id

    $bootOptions = New-Object VMware.Vim.VirtualMachineBootOptions

    $cdBoot = New-Object VMware.Vim.VirtualMachineBootOptionsBootableCdromDevice

    $bootOptions.BootOrder = @($cdBoot)

    $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
    $spec.BootOptions = $bootOptions

    $vmView.ReconfigVM($spec)

    Write-Host ""
    Write-Host "CD/DVD Boot Priority Configured Successfully!" -ForegroundColor Green
}
catch {

    Write-Host ""
    Write-Host "Failed to Configure Boot Options!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
}

# ==========================================
# POWER ON VM
# ==========================================

Write-Host ""
Write-Host "Powering ON VM..." -ForegroundColor Yellow

Start-VM -VM $vm -Confirm:$false | Out-Null

Write-Host ""
Write-Host "VM Powered ON Successfully!" -ForegroundColor Green

# ==========================================
# FINAL OUTPUT
# ==========================================

Write-Host ""
Write-Host "VM Provisioning Completed!" -ForegroundColor Cyan
Write-Host "--------------------------------"

Write-Host "VM Name     : $vmName"
Write-Host "OS Family   : $osName"
Write-Host "Version     : $($selectedFolder.Name)"
Write-Host "ESXi Host   : $selectedHost"
Write-Host "Datastore   : $($selectedDatastore.Name)"
Write-Host "Disk Size   : $diskGB GB"
Write-Host "Network     : $networkName"
Write-Host "ISO Mounted : $($selectedISO.Name)"


