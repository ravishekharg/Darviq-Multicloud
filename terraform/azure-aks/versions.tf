terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      # Let `terraform destroy` remove the group even if Azure added
      # resources to it (AKS creates a few on its own).
      prevent_deletion_if_contains_resources = false
    }
  }

  subscription_id = var.subscription_id
}
