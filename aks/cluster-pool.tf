
data "azurerm_subnet" "aks" {
  name                 = var.vnet
  virtual_network_name = var.vnet
  resource_group_name  = var.resource_group
}

data "azurerm_resource_group" "aks" {
  name = var.resource_group
}

resource "azurerm_kubernetes_cluster" "kubernetes-cluster" {
  name                = var.cluster_name
  location            = data.azurerm_resource_group.location
  resource_group_name = data.azurerm_resource_group.name
  dns_prefix          = "${var.cluster_name}"

  default_node_pool {
      name            = "default"
      node_count      = 1
      vm_size         = "Standard_f8s"
      max_pods        = 250
      os_disk_size_gb = 100
      enable_auto_scaling   = false
      enable_node_public_ip = false
      vnet_subnet_id  = data.azurerm_subnet.aks.id
    }
    network_profile {
      network_plugin    = "azure"
      load_balancer_sku = "Standard"
      load_balancer_profile {
        outbound_ip_address_ids = [
          module.vnet.lb-pubicip-backend-id
        ]
      }
    }
    identity {
        type = "SystemAssigned"
    }
    role_based_access_control {
       enabled = true
    }
  lifecycle {
    ignore_changes = [
      windows_profile
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "workers" {
  name                  = "worker"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes-cluster.id
  enable_node_public_ip = false
  enable_auto_scaling   = false
  max_pods        = 250
  os_disk_size_gb = 100
  os_type         = "Linux"
  node_count      = 3
  vm_size         = "Standard_f8s"
  mode            = "User"
  vnet_subnet_id  = data.azurerm_subnet.aks.id
}
