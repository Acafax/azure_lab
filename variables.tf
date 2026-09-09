variable "resource_group_name" {
  description = "Name of the Azure resource group created for the lab."
  type        = string
  default     = "azure-lvm-raid-lab"
}

variable "location" {
  description = "Azure region in which the lab resources are created."
  type        = string
  default     = "northeurope"
}

variable "vm_size" {
  description = "Azure VM SKU used for the lab."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "admin_username" {
  description = "Linux administrator account configured on the VM."
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to the public SSH key installed on the VM."
  type        = string
  default     = "~/.ssh/id_rsa.pub"

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_path))
    error_message = "ssh_public_key_path must point to an existing public SSH key file."
  }
}

variable "allowed_ssh_cidr" {
  description = "Trusted IPv4 or IPv6 CIDR allowed to connect to the VM over SSH."
  type        = string

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid IPv4 or IPv6 CIDR, for example 203.0.113.10/32."
  }
}
