# Dedicated NAT network. DHCP only hands out the fixed leases reserved per node MAC.
resource "libvirt_network" "cluster" {
  name      = var.network_name
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [{
    address = var.network_gateway
    netmask = var.network_netmask
    dhcp = {
      hosts = [for name, node in var.nodes : {
        name = name
        mac  = node.mac
        ip   = node.ip
      }]
    }
  }]
}
