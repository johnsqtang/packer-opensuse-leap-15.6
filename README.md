# Packer Templates for openSUSE Leap 15.6
## Introduction
This repository provides packer templates to build [openSUSE Leap 15.6](https://get.opensuse.org/leap/15.6/) virtual machines for the following hypervisors/providers:
* Windows Hyper-V
* Vmware Workstation (v17.6+)
* Oracle Virtualbox (v7.16+)
* Proxmox (v8.0.2)
* QEMU .qcow2 images
  * Build on Windows using QEMU for Windows (v9.2.0) 
  * Build on Linux with QEMU/KVM installed

The above versions have been tested and other versions of the hypervisors may or may not work.

## Prerequisites

* [Packer](https://www.packer.io/downloads.html)
  * <https://www.packer.io/intro/getting-started/install.html>
* Hypervisors
  * Windows Hyper-V: Windows feature enabled (optional)
  * [VMware Workstation](https://www.vmware.com/products/workstation-pro.html) (optional)
  * [Oracle VirtualBox](https://www.virtualbox.org/) (optional)
  * [QEMU for Windows (MSYS2 UCRT64)](https://www.qemu.org/download/#windows) (optional)
* Install ISO maker (used by packer)
  * On Linux: install mkisofs. See https://github.com/marcinbojko/hv-packer/
  * On Windows 10+: it is suggested to install **oscdimg.exe**
    * Visit https://go.microsoft.com/fwlink/?linkid=2271337 to download *adksetup.exe*
    * Run *Windows Assessment and Deployment Kit* (adksetup.exe)
    * Take the default installation path *C:\Program Files (x86)\Windows Kits\10\*
    * Uncheck all other except the *Deployment Tools* option
    * Add *C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\x86\Oscdimg* (working for both 32 and 64 bits) or *C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg* (working for 64 bit only) to your System or User PATH.
    * Go to DOS and type **oscdimg.exe** followed by RETURN to test whether oscdimg.exe can be run successfully.
* Open firewall ports 8000-9000 (default ports used by packer when building a http server on the fly).
  * On Windows: go to powershell in admin mode and then run (credits to [marcinbojko/hv-packer](https://github.com/marcinbojko/hv-packer/)):
    ```powershell
    Remove-NetFirewallRule -DisplayName "Packer_http_server" -Verbose
    New-NetFirewallRule -DisplayName "Packer_http_server" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8000-9000
    ```
    If *Remove-NetFirewallRule : No MSFT_NetFirewallRule objects found with property 'DisplayName' equal to 'Packer_http_server'.  Verify the value of the property and retry.* is seen, it is ok; just ignore it.

    Something similar to the below should be displayed:
  
    ```console
    Name                          : {902192a6-72d8-49ff-b178-2598cbefa8be}
    DisplayName                   : Packer_http_server
    Description                   :
    DisplayGroup                  :
    Group                         :
    Enabled                       : True
    Profile                       : Any
    Platform                      : {}
    Direction                     : Inbound
    Action                        : Allow
    EdgeTraversalPolicy           : Block
    LooseSourceMapping            : False
    LocalOnlyMapping              : False
    Owner                         :
    PrimaryStatus                 : OK
    Status                        : The rule was parsed successfully from the store. (65536)
    EnforcementStatus             : NotApplicable
    PolicyStoreSource             : PersistentStore
    PolicyStoreSourceType         : Local
    RemoteDynamicKeywordAddresses : {}
    PolicyAppId                   :
    ```
## Get Started

### Step 1 - Clone the Repository

Clone the project repository.
  ```console
  git clone https://github.com/johnsqtang/packer-opensuse-leap-15.6
  ```
### Step 2 - Update Input Variables
The following *.auto.pkrvars.hcl file must be updated/created before doing packer build:
* opensuse-leap.auto.pkrvars.hcl: contains most basic variables for all providers
* proxmox.auto.pkrvars.hcl: create this file from provided proxmox.auto.pkrvars.hcl.EXAMPLE which contains minimum variables for building Proxmox VMs.
* virtualbox.auto.pkrvars.hcl: contains variables for Oracle Virtualbox VMs.

#### opensuse-leap.auto.pkrvars.hcl
This file provides basic variable settings.

#### proxmox.auto.pkrvars.hcl.EXAMPLE
This file must be renamed to proxmox.auto.pkrvars.hcl and then each variable must be checked and/or updated before starting to build a Proxmox VM template.

#### virtualbox.auto.pkrvars.hcl
The settubgs in this file works for Oracle Virtualbox v7.16 in my Windows environment. If one got a different version, this file needs to be updated accordingly.

### Step 3 - Initialize Packer plugins
Go to the packer-opensuse-leap-15.6 folder and then issue the following command:
  ```console
  packer init opensuse-leap.pkr.hcl
  ```

## Build
The output for Hyper-V, VMware Workstation, Oracle Virtualbox and QEMU goes to the *output/* sub folder. The output of the template for Proxmox, of cause, goes to Proxmox server.

### Basic Usage
#### Build Hyper-v VM
  ```console
  packer build -only 'hyperv-iso.*' .
  ```
  This will build a generation 2 with 50G disk, which is equivalent to the following command:

  ```console
  packer build -only 'hyperv-iso.*' --var environment=server --var firmware=efi .
  ```

  Other environment options are gnome, kde and xfce. If we would like to build a Gnome environment, we could issue the following command:
  ```console
  packer build -only 'hyperv-iso.*' --var environment=gnome --var firmware=efi .
  ```

  When building a Hyper-V with graphic envionrment (i.e. environment is gnome, kde, and xfce), Hyper-V enhanced session related settings (i.e. installing and configuring xrdp, setting up firewall etc) will also be installed on the VM automatically. The only remaining thing one still need to do is to run Set-VM powershell command after the build. See scripts/hyperv-enhanced-session.sh.

#### Build VMware Workstation VM
  ```console
  packer build -only 'vmware-iso.*' .
  ```
#### Build Oracle Virtualbox VM
  ```console
  packer build -only 'virtualbox-iso.*' .
  ```
During the build,  

#### Build Proxmox VM Template
  ```console
  packer build -only 'proxmox-iso.*' .
  ```
During the build process, fix-vmwgfx-errors.sh is invoked to fix the *vmwgfx 0000:00:02.0: [drm]* error.

#### Build QEMU .qcow2 VM Image
  ```console
  packer build -only 'qemu.*' .
  ```
Then we could launch the built VM image like below using qemu-system-x86_64:

On Linux:
  ```console
  qemu-system-x86_64 -m size=2048m \
    -enable-kvm -cpu host \
    -drive file=output/qemu/photon-minimal-5.0-dde71ec57.x86_64.iso.qcow2,format=qcow2 \
    -device scsi-hd,drive=disk0
  ```
On Windows (including WSYS2) console:
  ```console
  qemu-system-x86_64 -m size=2048m  \
    -machine type=pc,accel=whpx,kernel-irqchip=off \
    -cpu Nehalem \
    -drive file=output/qemu/opensuse-leap-15.6-server.qcow2,format=qcow2,if=virtio \
    -vga virtio -display sdl,gl=off -usbdevice tablet
  ```

#### Build for All Supported Hypervisor Providers
  ```console
  packer build .
  ```
This would takes quite a while depending on the speed of the build machine.

### Advanced Usage
We could pass variable values from command line to fine-tune VM to be built. For example, if we would like to build a Hyper-V vm with disk size of 20G, we could do this:
  ```console
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 .
  ```

If we would also like the virtual machine name to be 'openSUSE Leap 15.6 built by Packer', we could do this:
  ```console
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 -var 'vm_name=openSUSE Leap 15.6 built by Packer' .

  # or
  packer build -only 'hyperv-iso.*' -var vm_disk_size 20000 -var vm_name='openSUSE Leap 15.6 built by Packer' 20000 .
  ```
Note that we have to put quotes as the value contains spaces.

Those input variables defined in *opensuse-leap.auto.pkrvars.hcl* but not in .auto.pkrvars.hcl files can be passed in form of *-var variable_name=value*.

## bios or uefi (Hyper-v's Generation 1 or 2)?

|Hypervisor| bios/MBR | efi/uefi/gpt (Hyper-v's Generation 2) |
|----------|----------|---------------------------------------|
|Hyper-V|Yes (but not suggested)|Yes|
|VMware workstation|Yes|Yes|
|Oracle VirtualBox|Yes|Yes|
|Proxmox|Yes|Yes|
|QEMU|Yes|Yes (but OVMF_CODE.fd must be placed in ./OVMF/ |

In the case both bios and efi are supported, we could pass *firmware* variable to the packer build command line to get what we want. 

## Default credentials

The default credentials for built VM image are:

|Username|Password|
|--------|--------|
|root|password|
|packer|password|

## References
* [openSUSE Leap 15.6 AutoYaST Guide](https://doc.opensuse.org/projects/autoyast/)
