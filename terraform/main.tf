terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

resource "proxmox_virtual_environment_vm" "srv_db01" {
  name      = "SRV-DB01"
  node_name = var.proxmox_node

  clone {
    vm_id = var.template_vm_id
    full  = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr1"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "192.168.226.23/24"
        gateway = "192.168.226.1"
      }
    }
  }
}
