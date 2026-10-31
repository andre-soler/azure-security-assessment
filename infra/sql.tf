resource "random_password" "sql_admin" {
  length           = 20
  special          = true
  override_special = "!@#%*"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "azurerm_mssql_server" "dados" {
  name                         = "sql-${var.prefixo}-${random_string.sufixo.result}"
  resource_group_name          = azurerm_resource_group.nuvelo.name
  location                     = var.location_sql
  version                      = "12.0"
  administrator_login          = "nuveloadmin"
  administrator_login_password = random_password.sql_admin.result
  tags                         = local.tags
}

# ERRO PLANTADO: firewall aceita conexões de qualquer IP do mundo
resource "azurerm_mssql_firewall_rule" "liberado" {
  name             = "liberar-tudo-temporario"
  server_id        = azurerm_mssql_server.dados.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# ERRO PLANTADO (por omissão): nenhuma auditoria configurada
