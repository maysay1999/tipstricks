#-------------------------------
# Local Declarations
#-------------------------------
locals {
  nsg_inbound_rules = { for idx, security_rule in var.nsg_inbound_rules : security_rule.name => {
    idx : idx,
    security_rule : security_rule,
    }
  }

  import_command       = "Import-Module ADDSDeployment"
  password_command     = "$password = ConvertTo-SecureString ${var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password} -AsPlainText -Force"
  install_ad_command   = "Install-WindowsFeature -Name AD-Domain-Services,DNS -IncludeManagementTools"
  configure_ad_command = "Install-ADDSForest -CreateDnsDelegation:$false -DomainMode Win2012R2 -DomainName ${var.active_directory_domain} -DomainNetbiosName ${var.active_directory_netbios_name} -ForestMode Win2012R2 -InstallDns:$true -SafeModeAdministratorPassword $password -Force:$true"
  shutdown_command     = "shutdown -r -t 60"
  exit_code_hack       = "exit 0"
  powershell_command   = "${local.import_command}; ${local.password_command}; ${local.install_ad_command}; ${local.configure_ad_command}; ${local.shutdown_command}; ${local.exit_code_hack}"
}

#----------------------------------------------------------
# Resource Group, VNet, Subnet selection & Random Resources
#----------------------------------------------------------

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  address_space       = [ "192.168.80.0/22" ]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "snet" {
  name                 = var.subnet_name
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [ "192.168.81.0/24" ]
}

resource "azurerm_virtual_network" "vnet2" {
  name                = var.virtual_network_name2
  address_space       = [ "172.28.80.0/22" ]
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_subnet" "snet2" {
  name                 = var.subnet_name2
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = [ "172.28.81.0/24" ]
}

#---------------------------------------
# Bastion, bastion IP and bastion host
#---------------------------------------
resource "azurerm_subnet" "bastion" {
  name = "AzureBastionSubnet"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [ "192.168.82.0/27" ]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastionip"
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  location            = data.azurerm_resource_group.rg.location
}

resource "azurerm_bastion_host" "bastion" {
  name                = "dcbastion"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location

  ip_configuration {
    name                 = "bastionconf"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

#---------------------------------------
# Win 10 client
#---------------------------------------
resource "azurerm_network_security_group" "win10" {
    name                = "win10-nsg"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    security_rule {
        name                       = "RDP"
        priority                   = 1100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "win10" {
  name                = "win10-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  # network_security_group_id = azurerm_network_security_group.win10.id

  ip_configuration {
    name                          = "win10-ip"
    subnet_id                     = azurerm_subnet.snet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "win10" {
    network_interface_id      = azurerm_network_interface.win10.id
    network_security_group_id = azurerm_network_security_group.win10.id
}

resource "azurerm_windows_virtual_machine" "win10" {
  name                = "win10-client"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids = [
    azurerm_network_interface.win10.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro"
    version   = "latest"
  }
}

#---------------------------------------
# Ubuntu client
#---------------------------------------
resource "azurerm_network_security_group" "ubuntu" {
    name                = "ubuntu-nsg"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "ubuntu-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ubuntu-ip"
    subnet_id                     = azurerm_subnet.snet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "ubuntu" {
    network_interface_id      = azurerm_network_interface.ubuntu.id
    network_security_group_id = azurerm_network_security_group.ubuntu.id
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "ubuntu"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  disable_password_authentication = false
  admin_password = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids = [
    azurerm_network_interface.ubuntu.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

#---------------------------------------
# peering 
#---------------------------------------
resource "azurerm_virtual_network_peering" "peering-1" {
  name                      = "peer1to2"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "peering-2" {
  name                      = "peer2to1"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

#---------------------------------------
# DNS
#---------------------------------------
resource "azurerm_virtual_network_dns_servers" "dnsip" {
  virtual_network_id = azurerm_virtual_network.vnet2.id
  dns_servers        = ["192.168.81.4", "168.63.129.16"]
}

resource "random_password" "passwd" {
  count       = var.os_flavor == "windows" && var.admin_password == null ? 1 : 0
  length      = 24
  min_upper   = 4
  min_lower   = 2
  min_numeric = 4
  special     = false

  keepers = {
    admin_password = var.os_flavor
  }
}

resource "random_string" "str" {
  count   = var.enable_public_ip_address == true ? var.instances_count : 0
  length  = 6
  special = false
  upper   = false
  keepers = {
    domain_name_label = var.virtual_machine_name
  }
}

# #-----------------------------------
# # Public IP for PDC Virtual Machine
# #-----------------------------------
# resource "azurerm_public_ip" "pip" {
#   count               = var.enable_public_ip_address == true ? var.instances_count : 0
#   name                = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}-0${count.index + 1}")
#   location            = data.azurerm_resource_group.rg.location
#   resource_group_name = data.azurerm_resource_group.rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
#   domain_name_label   = format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), random_string.str[count.index].result)
#   tags                = merge({ "ResourceName" = lower("pip-vm-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}-0${count.index + 1}") }, var.tags, )
# }

#---------------------------------------
# Network Interface for PDC Virtual Machine
#---------------------------------------
resource "azurerm_network_interface" "nic" {
  count                         = var.instances_count
  name                          = var.instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  dns_servers                   = var.dns_servers
  enable_ip_forwarding          = var.enable_ip_forwarding
  enable_accelerated_networking = var.enable_accelerated_networking
  tags                          = merge({ "ResourceName" = var.instances_count == 1 ? lower("nic-${format("vm%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")))}") : lower("nic-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}") }, var.tags, )

  ip_configuration {
    name                          = lower("ipconig-${format("vm%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)}")
    primary                       = true
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = var.private_ip_address_allocation_type
    private_ip_address            = var.private_ip_address_allocation_type == "Static" ? element(concat(var.private_ip_address, [""]), count.index) : null
    public_ip_address_id          = var.enable_public_ip_address == true ? element(concat(azurerm_public_ip.pip.*.id, [""]), count.index) : null
  }
}

resource "azurerm_availability_set" "aset" {
  count                        = var.enable_vm_availability_set ? 1 : 0
  name                         = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}")
  resource_group_name          = data.azurerm_resource_group.rg.name
  location                     = data.azurerm_resource_group.rg.location
  platform_fault_domain_count  = var.platform_fault_domain_count
  platform_update_domain_count = var.platform_update_domain_count
  managed                      = true
  tags                         = merge({ "ResourceName" = lower("avail-${var.virtual_machine_name}-${data.azurerm_resource_group.rg.location}") }, var.tags, )
}

#---------------------------------------------------------------
# Network security group for Virtual Machine Network Interface
#---------------------------------------------------------------
resource "azurerm_network_security_group" "nsg" {
  name                = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in")
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  tags                = merge({ "ResourceName" = lower("nsg_${var.virtual_machine_name}_${data.azurerm_resource_group.rg.location}_in") }, var.tags, )
}

resource "azurerm_network_security_rule" "nsg_rule" {
  for_each                    = local.nsg_inbound_rules
  name                        = each.key
  priority                    = 100 * (each.value.idx + 1)
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = each.value.security_rule.destination_port_range
  source_address_prefix       = each.value.security_rule.source_address_prefix
  destination_address_prefix  = element(concat(azurerm_subnet.snet.address_prefixes, [""]), 0)
  description                 = "Inbound_Port_${each.value.security_rule.destination_port_range}"
  resource_group_name         = data.azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nsg.name
  depends_on                  = [azurerm_network_security_group.nsg]
}

resource "azurerm_network_interface_security_group_association" "nsgassoc" {
  count                     = var.instances_count
  network_interface_id      = element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)
  network_security_group_id = azurerm_network_security_group.nsg.id
}

#---------------------------------------
# PDC Windows Virutal machine
#---------------------------------------
resource "azurerm_windows_virtual_machine" "win_vm" {
  count                      = var.os_flavor == "windows" ? var.instances_count : 0
  name                       = var.instances_count == 1 ? var.virtual_machine_name : format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1)
  computer_name              = var.instances_count == 1 ? var.virtual_machine_name : format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) # not more than 15 characters
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.virtual_machine_size
  admin_username             = var.admin_username
  admin_password             = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids      = [element(concat(azurerm_network_interface.nic.*.id, [""]), count.index)]
  source_image_id            = var.source_image_id != null ? var.source_image_id : null
  provision_vm_agent         = true
  allow_extension_operations = true
  dedicated_host_id          = var.dedicated_host_id
  license_type               = var.license_type
  availability_set_id        = var.enable_vm_availability_set == true ? element(concat(azurerm_availability_set.aset.*.id, [""]), 0) : null
  tags                       = merge({ "ResourceName" = var.instances_count == 1 ? var.virtual_machine_name : format("%s%s", lower(replace(var.virtual_machine_name, "/[[:^alnum:]]/", "")), count.index + 1) }, var.tags, )

  dynamic "source_image_reference" {
    for_each = var.source_image_id != null ? [] : [1]
    content {
      publisher = var.windows_distribution_list[lower(var.windows_distribution_name)]["publisher"]
      offer     = var.windows_distribution_list[lower(var.windows_distribution_name)]["offer"]
      sku       = var.windows_distribution_list[lower(var.windows_distribution_name)]["sku"]
      version   = var.windows_distribution_list[lower(var.windows_distribution_name)]["version"]
    }
  }

  os_disk {
    storage_account_type = var.os_disk_storage_account_type
    caching              = "ReadWrite"
  }
}

#---------------------------------------
# Promote Domain Controller
#---------------------------------------
resource "azurerm_virtual_machine_extension" "adforest" {
  name                       = "ad-forest-creation"
  virtual_machine_id         = azurerm_windows_virtual_machine.win_vm.0.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
        "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
    }
SETTINGS
}

#---------------------------------------
# Win 10 client
#---------------------------------------
resource "azurerm_network_security_group" "win10" {
    name                = "win10-nsg"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    security_rule {
        name                       = "RDP"
        priority                   = 1100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "win10" {
  name                = "win10-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  # network_security_group_id = azurerm_network_security_group.win10.id

  ip_configuration {
    name                          = "win10-ip"
    subnet_id                     = azurerm_subnet.snet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "win10" {
    network_interface_id      = azurerm_network_interface.win10.id
    network_security_group_id = azurerm_network_security_group.win10.id
}

resource "azurerm_windows_virtual_machine" "win10" {
  name                = "win10-client"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  admin_password      = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids = [
    azurerm_network_interface.win10.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "win10-21h2-pro"
    version   = "latest"
  }
}

#---------------------------------------
# Ubuntu client
#---------------------------------------
resource "azurerm_network_security_group" "ubuntu" {
    name                = "ubuntu-nsg"
    location            = data.azurerm_resource_group.rg.location
    resource_group_name = data.azurerm_resource_group.rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 1100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_network_interface" "ubuntu" {
  name                = "ubuntu-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ubuntu-ip"
    subnet_id                     = azurerm_subnet.snet2.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "ubuntu" {
    network_interface_id      = azurerm_network_interface.ubuntu.id
    network_security_group_id = azurerm_network_security_group.ubuntu.id
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "ubuntu"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = var.admin_username
  disable_password_authentication = false
  admin_password = var.admin_password == null ? element(concat(random_password.passwd.*.result, [""]), 0) : var.admin_password
  network_interface_ids = [
    azurerm_network_interface.ubuntu.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

#---------------------------------------
# peering 
#---------------------------------------
resource "azurerm_virtual_network_peering" "peering-1" {
  name                      = "peer1to2"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network_peering" "peering-2" {
  name                      = "peer2to1"
  resource_group_name       = data.azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet.id
}

#---------------------------------------
# DNS
#---------------------------------------
resource "azurerm_virtual_network_dns_servers" "dnsip" {
  virtual_network_id = azurerm_virtual_network.vnet2.id
  dns_servers        = ["192.168.81.4", "168.63.129.16"]
}