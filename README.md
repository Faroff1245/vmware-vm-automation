# VMware VM Automation using PowerCLI

Automated VMware VM provisioning using PowerShell and VMware PowerCLI.

## Features

- Connect to vSphere automatically
- Discover Windows ISO files dynamically
- Select ESXi host
- Scan datastore free space
- Create virtual machine automatically
- Attach Windows ISO automatically
- Configure VM network
- Configure VM storage
- Configure CD/DVD boot priority

## Tech Stack

- PowerShell
- VMware PowerCLI
- VMware ESXi
- vSphere

## Project Structure

```text
VM-Automation/
│
├── config/
├── logs/
├── scripts/
│   ├── connect-vsphere.ps1
│   ├── create-vm.ps1
│   ├── get-isos.ps1
│   └── select-esxi-datastore.ps1
│
└── README.md
```

## Future Improvements

- Autounattend.xml integration
- Fully unattended Windows installation
- Snapshot automation
- VMware Tools automation
- VM deletion automation

## Screenshots

(Add screenshots here later)