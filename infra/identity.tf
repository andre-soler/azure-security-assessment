data "azurerm_subscription" "atual" {}

resource "azurerm_user_assigned_identity" "integracao" {
  name                = "id-${var.prefixo}-integracao"
  resource_group_name = azurerm_resource_group.nuvelo.name
  location            = azurerm_resource_group.nuvelo.location
  tags                = local.tags
}

# ERRO PLANTADO: a integração tem controle total da assinatura
resource "azurerm_role_assignment" "integracao_owner" {
  scope                = data.azurerm_subscription.atual.id
  role_definition_name = "Owner"
  principal_id         = azurerm_user_assigned_identity.integracao.principal_id
  principal_type       = "ServicePrincipal"
}
