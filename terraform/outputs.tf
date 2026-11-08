output "node_ips" {
  description = "Fixed IP address of each node."
  value       = { for name, node in var.nodes : name => node.ip }
}
