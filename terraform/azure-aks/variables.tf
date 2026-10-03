variable "subscription_id" {
  description = "Azure subscription ID to deploy into."
  type        = string
}

variable "location" {
  description = "Azure region for the resource group, cluster and registry."
  type        = string
  default     = "centralindia"
}

variable "cluster_name" {
  description = "Name of the AKS cluster (also used to name the resource group and network)."
  type        = string
  default     = "darviq-aks"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version. Leave null to use the region's default."
  type        = string
  default     = null
}

variable "node_vm_size" {
  description = "VM size for the default node pool."
  type        = string
  default     = "Standard_D2s_v5"
}

variable "node_count" {
  description = "Number of nodes in the default node pool."
  type        = number
  default     = 2
}

variable "vnet_cidr" {
  description = "Address space for the cluster virtual network."
  type        = string
  default     = "10.41.0.0/16"
}

variable "registry_name" {
  description = "Globally unique name for the Azure Container Registry (5-50 alphanumeric characters)."
  type        = string
  default     = "darviqdemoregistry"
}
