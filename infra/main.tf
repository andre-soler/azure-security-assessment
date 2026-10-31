resource "random_string" "sufixo" {
  length  = 6
  upper   = false
  special = false
}

locals {
  tags = {
    projeto  = "azure-security-assessment"
    cliente  = "nuvelo-ficticio"
    ambiente = "laboratorio"
  }
}

resource "azurerm_resource_group" "nuvelo" {
  name     = "rg-${var.prefixo}-prod"
  location = var.location
  tags     = local.tags
}
