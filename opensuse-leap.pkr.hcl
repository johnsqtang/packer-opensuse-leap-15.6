packer {
  required_plugins {
    hyperv = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/hyperv"
    }

    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }
	
    vmware = {
      version = "~> 1"
      source  = "github.com/hashicorp/vmware"
    }
	
	# setting cpu_type is only working in v1.2.1 or below.  There are bugs in v1.2.2 or above in this regard.
	# https://github.com/hashicorp/packer-plugin-proxmox/issues/307 - Downgrading to v1.2.1 does the trick for me.
    proxmox = {
      # version = ">= 1.1.3"
      version = "= 1.2.1"
      source  = "github.com/hashicorp/proxmox"
    }
	
    virtualbox = {
      version = ">= v1.1.1"
      source  = "github.com/hashicorp/virtualbox"
    }	
  }
}

variable "lang" {
  type    = string # e.g. "en_US"  
}

variable "timezone" {
  type    = string # e.g. "America/New_York"
}

variable "iso_url" {
  type    = string
}

variable "iso_checksum" {
  type    = string
}

variable "headless" {
  type        = bool
  description = "Headless"
  default     = false
}

variable "vm_name" {
  type    = string
  default = ""
}

variable "cpus" {
  type    = number
  default = 2
}

variable "cpus_sockets" {
  type    = number
  default = 1
}

variable "vm_memory" {
  type    = number
  default = 4096
}

# in MB
variable "disk_size" {
  type    = number
  default = 50000
}

variable "output_directory" {
  type    = string
  default = "output"
}

variable "hostname" {
  type    = string
}

variable "root_password" {
  type    = string
}

variable "normal_username" {
  type    = string
  default = "john"
}

variable "normal_user_password" {
  type    = string
}

variable "switch_name" {
  type    = string
  default = "Default Switch"
}

variable "vlan_id" {
  type    = string
  default = ""
}

variable "skip_export" {
  type        = bool
  description = "Skip export"
  default     = false
}

variable "keep_registered" {
  type    = bool
  default = false
}

# "bios" or "efi". should always leave as "efi" to simplify dev work.
variable "firmware" {
  type    = string
  # Allowed values are bios, efi, and efi-secure (for secure boot)
  default = ""
  validation {
    condition     = length(var.firmware) == 0 || var.firmware == "bios" || var.firmware == "efi"
    error_message = "The firmware must be 'bios' or 'efi' or blank (in which case the code will default based on provider)."
  }  
}

variable "environment" {
  type = string
  default = "server" # server gnome kde or xfce
  validation {
    condition     = var.environment == "server" || var.environment == "gnome" || var.environment == "kde" || var.environment == "xfce"
    error_message = "The environment must be 'server', 'gnome', 'kde' or 'xfce'."
  }
}

variable "proxmox_node" {
  type    = string
  # default = "pve"
}

variable "proxmox_host" {
  type = string
  default = env("PROXMOX_HOST")
}

variable "proxmox_api_token_id" {
  type = string
  default = env("PROXMOX_API_TOKEN_ID")
}

variable "proxmox_api_token" {
  type = string
  default = env("PROXMOX_API_TOKEN")
}

variable "proxmox_disk_storage_pool" {
  type    = string
  # default = "local-lvm"
}

variable "proxmox_cloudinit_storage_pool" {
  type    = string
  # default = "local-lvm"
}

# used by proxmox only
variable "proxmox_disk_format" {
  type    = string
  default = "raw"
}

variable "proxmox_cpu_type" {
  type    = string
  default = "x86-64-v2-AES"   # or kvm64
  # The CPU type to emulate. See the Proxmox API documentation for the complete list of accepted values. 
  # For best performance, set this to host. Defaults to kvm64.
}

variable "proxmox_iso_images_loc_prefix" {
  type    = string
}

variable "http_bind_address" {
  type    = string
}

variable "windir" {
  type    = string
  default = env("windir")
}

variable "use_lvm" {
  type        = bool
  default     = false
}

#
# variables specific to hyper-v <-- start
#
variable "enable_virtualization_extensions" {
  type    = bool
  default = false
}

variable "enable_mac_spoofing" {
  type    = bool
  default = false
}

variable "enable_dynamic_memory" {
  type    = bool
  default = false
}
#
# variables specific to hyper-v <-- end
#

#
# variables specific to virtual box --> start
#
variable "virtualbox_guest_additions_url" {
  type    = string
}

variable "virtualbox_guest_additions_sha256" {
  type    = string
}

variable "gfx_vram_size" {
  type    = number
  default = 128
}
#
# variables specific to virtual box <-- end
#

locals {
  vm_name = coalesce(var.vm_name, "OpenSUSE Leap 15.6 - ${var.environment}")
  ssh_username = "root"
  ssh_password = var.root_password
  
  # if firmware is not provided, default to generation 2 for hyper-v
  hyperv_generation = coalesce(var.firmware, "efi") == "bios" ? 1 : 2
  
  # for vmware, if no firmware is given, treat as "bios"
  vmware_firmware = coalesce(var.firmware, "bios")

  qemu_firmware = coalesce(var.firmware, "bios")
  
  command_core  = " biosdevname=0 net.ifnames=0 netdevice=eth0 netsetup=dhcp lang=${var.lang} textmode=1 autoyast=http://{{ .HTTPIP }}:{{ .HTTPPort }}/autoinst.xml"
  boot_commands = {
	bios = ["<down><wait>",                         local.command_core, "<wait5s><enter><wait>"]
	efi  = ["e<down><down><down><down><end><wait>", local.command_core, "<wait5s><f10>"]
  }
  boot_wait = "5s"
  
  use_network_manager  = var.environment == "server" ? "no" : "yes"
  
  qcow2_filename = "opensuse-leap-15.6-${var.environment}.qcow2"

  is_windows = length(var.windir) > 0
  
  qemuargs_base = [
    ["-m", "${var.vm_memory}M"],
    ["-smp", "${var.cpus}"]
  ]
  qemuargs = concat(local.qemuargs_base, 
                    (local.is_windows ? 
                      [["-cpu", "Nehalem"], ["-machine", "type=pc,accel=whpx,kernel-irqchip=off"], ["-vga", "virtio"], ["-display", "sdl,gl=off"], ["-usbdevice", "tablet"]] : 
			          [["-enable-kvm"], ["-cpu", "host"]]))
}

source "hyperv-iso" "vm-hyperv" {
	# show up when being built
	headless         = var.headless

	# boot related
	iso_url               = var.iso_url
	iso_checksum          = var.iso_checksum

	first_boot_device = local.hyperv_generation == 2 ? "DVD" : null
	boot_order        = local.hyperv_generation == 2 ? ["SCSI:0:0"] : null
  
	boot_wait    = local.boot_wait
	boot_command = local.boot_commands[local.hyperv_generation == 1 ? "bios" : "efi"]
	http_content = {
		"/autoinst.xml" = templatefile("./http/autoinst.xml.pkrtpl", { 
			environment = var.environment
			hostname = var.hostname
			bootmode = local.hyperv_generation == 1 ? "bios" : "efi"
			timezone = var.timezone
			root_password = var.root_password
			normal_user_password = var.normal_user_password
			normal_username      = var.normal_username
			use_network_manager  = local.use_network_manager
			provider = "hyperv"
		})
	}
  
	# vm profile
	vm_name        = local.vm_name
	generation     = local.hyperv_generation
	enable_secure_boot    = false
	guest_additions_mode  = "disable"
 
	cpus           = var.cpus
	memory         = var.vm_memory
	disk_size      = var.disk_size

	# network
	switch_name  = var.switch_name
	vlan_id      = var.vlan_id
  
	# nested virtualization  
	# when enable_virtualization_extensions = true
	#   enable_mac_spoofing must be set to true
	#   enable_dynamic_memory must be set to false
	enable_virtualization_extensions = var.enable_virtualization_extensions
	enable_mac_spoofing = var.enable_mac_spoofing || var.enable_virtualization_extensions
	enable_dynamic_memory = var.enable_dynamic_memory && !var.enable_virtualization_extensions
  
	shutdown_command = "shutdown -P now"
	shutdown_timeout      = "1h"

	# ssh
	communicator          = "ssh"
	ssh_username     = local.ssh_username
	ssh_password     = local.ssh_password
	ssh_timeout               = "30m"
  
	# post build
	# keep the VM in Hyper-V manager.
	keep_registered = var.keep_registered

	output_directory = "${var.output_directory}/hyperv/${local.vm_name}"
}

source "vmware-iso" "vm-vmware" {
  // ISO configuration
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  firmware = local.vmware_firmware

  boot_wait    = "10s"  # local.boot_wait
  boot_command = local.boot_commands[local.vmware_firmware]
  http_content = {
		"/autoinst.xml" = templatefile("./http/autoinst.xml.pkrtpl", { 
			environment = var.environment
			hostname = var.hostname
			bootmode = local.vmware_firmware
			timezone = var.timezone
			root_password = var.root_password
			normal_user_password = var.normal_user_password
			normal_username      = var.normal_username
			use_network_manager  = local.use_network_manager
			provider = "vmware"
		})
	}
	
  // Driver configuration
  cleanup_remote_cache = false

  // Hardware configuration
  vm_name   = local.vm_name
  vmdk_name = local.vm_name

  version       = "21"
  guest_os_type = "opensuse-64"

  cpus      = var.cpus
  memory    = var.vm_memory
  disk_size = var.disk_size

  disk_adapter_type = "scsi"
  disk_type_id      = "1"

  network = "nat"
  sound   = false
  usb     = false

  // Run configuration
  headless = var.headless

  // Shutdown configuration
  shutdown_command = "shutdown -P now"


  // Communicator configuration
  communicator     = "ssh"
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
  ssh_timeout      = "30m"

  keep_registered = var.keep_registered
  
  // Export configuration
  # format          = "vmx"
  skip_compaction = false
  skip_export     = var.skip_export
  
  output_directory = "${var.output_directory}/vmware/${local.vm_name}"
}

source "qemu" "vm-qemu" {
  accelerator = "kvm"

  # show up when being built
  headless         = var.headless

  # boot related
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  boot_wait    = "10s"  # local.boot_wait
  boot_command = local.boot_commands[local.vmware_firmware]
  http_content = {
		"/autoinst.xml" = templatefile("./http/autoinst.xml.pkrtpl", { 
			environment = var.environment
			hostname = var.hostname
			bootmode = local.vmware_firmware
			timezone = var.timezone
			root_password = var.root_password
			normal_user_password = var.normal_user_password
			normal_username      = var.normal_username
			use_network_manager  = local.use_network_manager
			provider = "qemu"
		})
	}
  
  firmware   = local.qemu_firmware == "bios" ? null : "./OVMF/OVMF_CODE.fd"
  
  vm_name = local.qcow2_filename

  # disk_cache       = "none" # JT: must not set, otherwise got errors
  disk_compression = true
  # disk_discard     = "unmap" # JT: must not set, otherwise got errors
  # ide, sata, scsi, virtio or virtio-scsi
  # disk_interface = "virtio" # /dev/vda
  disk_interface = "virtio-scsi" # /dev/sda?
  disk_size      = var.disk_size
  format         = "qcow2"
  
  # cdrom_interface = "ide" # ok
  # cdrom_interface = "ide" # null or "virtio" (by default)

  # use_pflash = false

  net_device = "virtio-net"
  
  qemuargs    = local.qemuargs

  # shutdown_command = "echo '${local.ssh_password}' | sudo -S /sbin/halt -h -p"
  shutdown_command = "shutdown -P now"

  communicator     = "ssh"
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
  ssh_timeout      = "30m"
  
  output_directory = "${var.output_directory}/qemu"
}

source "proxmox-iso" "vm-proxmox" {
  # proxmox credentials
  proxmox_url = "https://${var.proxmox_host}/api2/json"
  username    = "${var.proxmox_api_token_id}"
  token       = "${var.proxmox_api_token}"
  insecure_skip_tls_verify = true
  node        = var.proxmox_node
  
  bios = coalesce(var.firmware, "bios") == "bios" ? "seabios" : "ovmf"
  
  boot_wait    = "10s"  # local.boot_wait
  boot_command   = coalesce(var.firmware, "bios") == "bios" ? local.boot_commands.bios : local.boot_commands.efi
  http_content = {
		"/autoinst.xml" = templatefile("./http/autoinst.xml.pkrtpl", { 
			environment = var.environment
			hostname = var.hostname
			bootmode = local.vmware_firmware
			timezone = var.timezone
			root_password = var.root_password
			normal_user_password = var.normal_user_password
			normal_username      = var.normal_username
			use_network_manager  = local.use_network_manager
			provider = "proxmox"
		})
	}
  
  boot_iso {
    type = "scsi"
    iso_file = "${var.proxmox_iso_images_loc_prefix}/${basename(var.iso_url)}"
    unmount = true
  }
  
  # important for Windows. this IP must be accessible to the proxmox server
  http_bind_address = var.http_bind_address
  # http_port_min = 8802
  # http_port_max = 8802  

  network_adapters {
    bridge   = "vmbr0"
    firewall = true
    model    = "virtio"
    vlan_tag = var.vlan_id
  }
  
  disks {
    disk_size    = "${var.disk_size}M"
    format       = var.proxmox_disk_format
    io_thread    = true
    storage_pool = var.proxmox_disk_storage_pool
    type         = "scsi"
  }
  scsi_controller = "virtio-scsi-single"

  cloud_init              = true
  cloud_init_storage_pool = var.proxmox_cloudinit_storage_pool

  template_description = "Built from ${basename(var.iso_url)} on ${formatdate("YYYY-MM-DD hh:mm:ss ZZZ", timestamp())}"
  vm_name  = "opensuse-leap-15.6-${var.environment}-template" # trimsuffix(basename(var.iso_url), ".iso")
  
  # vm_id = 8089
  
#  variable "proxmox_cpu_type" {
#  type    = string
#  default = "x86-64-v2-AES"   # or kvm64

  os       = "l26" # 2.6+
  memory   = var.vm_memory
  cores    = var.cpus
  sockets  = var.cpus_sockets

  # JT: even I explicitly set it to x86-64-v2-AES. When I use proxmox interface to check, it always show as the default "kvm64"!
  #
  # only working in v1.2.1 or below. Not working in the current 1.2.2     
  # https://github.com/hashicorp/packer-plugin-proxmox/issues/307
  # packer can not set cpu_type - downgrade to v1.2.1 is working.
  cpu_type = "x86-64-v2-AES" # "x86-64-v2-AES" "Nehalem" or "host" all should work fine.
  
  # machine  = "" # Default (i440fx)
  
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
  ssh_timeout      = "60m"
}

source "virtualbox-iso" "vm-virtualbox" {
  headless               = var.headless

  # boot related
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  boot_wait = "10s"
  boot_command   = coalesce(var.firmware, "bios") == "bios" ? local.boot_commands.bios : local.boot_commands.efi
  http_content = {
		"/autoinst.xml" = templatefile("./http/autoinst.xml.pkrtpl", { 
			environment = var.environment
			hostname = var.hostname
			bootmode = local.vmware_firmware
			timezone = var.timezone
			root_password = var.root_password
			normal_user_password = var.normal_user_password
			normal_username      = var.normal_username
			use_network_manager  = local.use_network_manager
			provider = "virtualbox"
		})
	}
  
  vm_name                = local.vm_name
  firmware                = coalesce(var.firmware, "bios")
  guest_os_type          = "openSUSE_64"
  guest_additions_path   = "/root/VBoxGuestAdditions.iso"
  
  guest_additions_url    = var.virtualbox_guest_additions_url
  guest_additions_sha256 = var.virtualbox_guest_additions_sha256
  
  cpus                   = var.cpus
  memory                 = var.vm_memory
  disk_size              = var.disk_size
  hard_drive_interface   = "scsi"     # var.disk_adapter_vbx
  gfx_controller         = "vmsvga"   # vboxsvga" # var.gfx_controller_vbx
  gfx_vram_size          = var.gfx_vram_size

  iso_interface = "sata"
  
  # boot_keygroup_interval = "10ms"  # var.boot_key_interval
  
  # ssh
  ssh_username     = local.ssh_username
  ssh_password     = local.ssh_password
  ssh_timeout      = "30m"
  ssh_wait_timeout = "15m"
  shutdown_command = "echo '${local.ssh_password}' | sudo -S /sbin/halt -h -p"

  # post build
  keep_registered = var.keep_registered
  skip_export     = var.skip_export
  
  output_directory = "${var.output_directory}/virtualbox/${local.vm_name}"
}

build {
    sources = ["source.hyperv-iso.vm-hyperv", "source.vmware-iso.vm-vmware", "source.qemu.vm-qemu", "source.proxmox-iso.vm-proxmox", "source.virtualbox-iso.vm-virtualbox"]

	provisioner "shell" {
		execute_command = "echo '${local.ssh_password}'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
		script          = "./scripts/wait-for-installation.sh"
		expect_disconnect = true
	}

	provisioner "shell" {
		environment_vars = [
			"PACKER_BASE_ENVIRONMENT=${var.environment}"
		]
		execute_command = "echo '${local.ssh_password}'|{{ .Vars }} sudo -S -E bash '{{ .Path }}'"
	 
		scripts = [
			"./scripts/install-qemu-quest-agent.sh",
			"./scripts/hyperv-enhanced-session.sh",
			"./scripts/fix-vmwgfx-errors.sh",       # for virtualbox only
			"./scripts/set-graphical-target.sh",
			"./scripts/clean-up.sh"
		]
	}
}
