variable "prefix" {
  default = "se"
  description = "A prefix used for all resources"
}

variable "location" {
  default     = "West Europe"
  description = "The Azure Region in which all resources should be provisioned"
}

variable "resource_group_name" {
  default     = "rg-services-01"
  description = "Name of ressource groupe"
}

variable "env" {
  default = "Services"
  description = "The Tag value for Team"
}

variable "owner" {
  default = "Emmanuel COLUSSI"
  description = "The Tag value for Owner"
}

variable "k8sversion" {
  default     = "1.24.3"
  type        = string
  description = "The version of Kubernetes"
}

variable "vm_type" {
  default     = "Standard_B4ms"
  description = "The virtual machine sizes"
}

variable "agent_count" {
  default = 2
  description = "Number of worker node"
}
