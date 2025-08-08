variable "prefix" {
  description = "value to prefix all resources with"
  type = string
  default = "ansible"
}


variable "resource_group_name" {
  description = "Name of the resource group where shared resources are located"
  type        = string
  
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string  
}

variable "vm_count" {
  description = "Number of virtual machines to create"
  type        = number
  default     = 3
}

variable "admin_username" {
  description = "Admin username for the virtual machines"
  type        = string
  default     = "cloud_user"
}

variable "admin_password" {
  description = "Admin password for the virtual machines"
  type        = string
  sensitive   = true
}

variable "vm_tags" {
  default = [
    { environment = "dev"},
    { environment = "test"},
    { environment = "prod"}
  ]
}

