##############
## Create AD
##############

module "virtual-machine" {
  source  = "./modules/pdcserver"

  # Resource Group, location, VNet and Subnet details
  resource_group_name  = "anflab-rg"
  location             = "westus"
  virtual_network_name = "netapp-vnet"
  subnet_name          = "default-sub"
  virtual_network_name2 = "anfjpe-vnet"
  subnet_name2          = "vm-sub"

  # This module support multiple Pre-Defined Linux and Windows Distributions.
  # Windows Images: windows2012r2dc, windows2016dc, windows2019dc
  virtual_machine_name               = "windc01"
  windows_distribution_name          = "windows2019dc"
  virtual_machine_size               = "Standard_D2s_v3"
  admin_username                     = "anfadmin"
  ### Must put the password here!!!
  admin_password                     = ""
  private_ip_address_allocation_type = "Static"
  private_ip_address                 = ["192.168.81.4"]

  # Active Directory domain and netbios details
  # Intended for test/demo purposes
  # For production use of this module, fortify the security by adding correct nsg rules
  active_directory_domain       = "azureisfun.local"
  active_directory_netbios_name = "AZUREISFUN"

  # Network Seurity group port allow definitions for each Virtual Machine
  # NSG association to be added automatically for all network interfaces.
  # SSH port 22 and 3389 is exposed to the Internet recommended for only testing.
  # For production environments, we recommend using a VPN or private connection
  nsg_inbound_rules = [
    {
      name                   = "rdp"
      destination_port_range = "3389"
      source_address_prefix  = "192.168.80.0/22"
      priority               = "320"
      access                 = "Allow"
      protocol               = "Tcp"
      direction              = "Inbound"
    }
  ]

  # Adding TAG's to your Azure resources (Required)
  # ProjectName and Env are already declared above, to use them here, create a varible.
  tags = {
    ProjectName = "ANF hands-on demo"
    Env         = "Demo lab"
  }
}