resource "azurerm_storage_account" "arquivos" {
  name                     = "st${var.prefixo}${random_string.sufixo.result}"
  resource_group_name      = azurerm_resource_group.nuvelo.name
  location                 = azurerm_resource_group.nuvelo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # ERRO PLANTADO: permite que containers sejam públicos
  allow_nested_items_to_be_public = true

  # ERRO PLANTADO: aceita conexões sem HTTPS
  https_traffic_only_enabled = false

  tags = local.tags
}

resource "azurerm_storage_container" "uploads" {
  name               = "uploads-agencias"
  storage_account_id = azurerm_storage_account.arquivos.id

  # ERRO PLANTADO: qualquer pessoa com o link lê os arquivos
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "lista" {
  name                   = "lista-convidados-evento-hotel.csv"
  storage_account_name   = azurerm_storage_account.arquivos.name
  storage_container_name = azurerm_storage_container.uploads.name
  type                   = "Block"
  source_content         = "nome,email,cpf\nFulano Ficticio,fulano@exemplo.test,000.000.000-00\n"
}
