resource "azurerm_virtual_network" "principal" {
  name                = "vnet-${var.prefixo}-prod"
  resource_group_name = azurerm_resource_group.nuvelo.name
  location            = azurerm_resource_group.nuvelo.location
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "legado" {
  name                 = "snet-vm-legado"
  resource_group_name  = azurerm_resource_group.nuvelo.name
  virtual_network_name = azurerm_virtual_network.principal.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "legado" {
  name                = "nsg-vm-legado"
  resource_group_name = azurerm_resource_group.nuvelo.name
  location            = azurerm_resource_group.nuvelo.location
  tags                = local.tags

  # ERRO PLANTADO: SSH aberto para a internet inteira
  security_rule {
    name                       = "permitir-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # ERRO PLANTADO: RDP aberto para a internet inteira
  security_rule {
    name                       = "permitir-rdp"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "legado" {
  subnet_id                 = azurerm_subnet.legado.id
  network_security_group_id = azurerm_network_security_group.legado.id
}
