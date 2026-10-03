# Tenant and object ID of whoever runs Terraform (az login / service principal).
data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "main" {
  name     = "${var.cluster_name}-rg"
  location = var.location

  tags = {
    Project   = "darviq-multicloud"
    ManagedBy = "terraform"
  }
}

# --- Network ---------------------------------------------------------------
# A dedicated VNet and node subnet, so pods get VNet IPs through Azure CNI
# (overlay mode keeps pod IPs out of the subnet's address space).
resource "azurerm_virtual_network" "main" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]
  tags                = azurerm_resource_group.main.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "nodes"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 0)]
}

# --- AKS -------------------------------------------------------------------
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "system"
    vm_size        = var.node_vm_size
    node_count     = var.node_count
    vnet_subnet_id = azurerm_subnet.nodes.id

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # Managed identity instead of a service principal: no secret to rotate.
  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    # k8s/base relies on NetworkPolicy being enforced.
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  # Microsoft Entra ID for user sign-in, with Kubernetes RBAC.
  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = true
  }

  tags = azurerm_resource_group.main.tags
}

# --- Image registry --------------------------------------------------------
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = false
  tags                = azurerm_resource_group.main.tags
}

# Let the cluster's kubelet identity pull images without any stored password.
resource "azurerm_role_assignment" "aks_pull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

# The identity running Terraform gets cluster-admin through Azure RBAC.
resource "azurerm_role_assignment" "deployer_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}
