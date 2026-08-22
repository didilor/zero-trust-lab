variable "proxmox_endpoint" {
  description = "URL de l'API Proxmox"
  type        = string
}

variable "proxmox_api_token" {
  description = "Jeton API Proxmox (root@pam!terraform)"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Nom du nœud Proxmox"
  type        = string
  default     = "pve"
}

variable "template_vm_id" {
  description = "ID de la VM template à cloner (SRV-KC01)"
  type        = number
  default     = 102
}
