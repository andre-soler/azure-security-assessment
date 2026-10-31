data "azurerm_client_config" "atual" {}

resource "azurerm_key_vault" "cofre" {
  name                = "kv-${var.prefixo}-${random_string.sufixo.result}"
  resource_group_name = azurerm_resource_group.nuvelo.name
  location            = azurerm_resource_group.nuvelo.location
  tenant_id           = data.azurerm_client_config.atual.tenant_id
  sku_name            = "standard"

  # ERRO PLANTADO: segredos podem ser apagados de vez, sem volta
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  # ERRO PLANTADO: aceita conexões de qualquer rede
  public_network_access_enabled = true

  # ERRO PLANTADO (por omissão): modelo de permissão antigo (access policies) em vez de RBAC
  access_policy {
    tenant_id = data.azurerm_client_config.atual.tenant_id
    object_id = data.azurerm_client_config.atual.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
  }

  tags = local.tags
}

# ERRO PLANTADO: segredo sem data de expiração
resource "azurerm_key_vault_secret" "conexao_banco" {
  name         = "senha-admin-sql"
  value        = random_password.sql_admin.result
  key_vault_id = azurerm_key_vault.cofre.id
}
