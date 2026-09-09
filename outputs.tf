output "resource_group_name" {
  description = "Name of the resource group containing the lab."
  value       = azurerm_resource_group.lab.name
}

output "public_ip_address" {
  description = "Public IP address assigned to the lab VM."
  value       = azurerm_public_ip.vm.ip_address
}

output "ssh_command" {
  description = "Base SSH command. Add -i with the path to your private SSH key when it is not loaded by your SSH agent."
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.vm.ip_address}"
}
