output "boundary_admin_password" {
  description = "The Password for the Boundary admin user"
  value = random_pet.random_password.id
}

output "boundary_url" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = hcp_boundary_cluster.boundary-demo.cluster_url
}

output "vault_pub_url" {
  description = "The public URL of the Vault server"
  value       = "http://${aws_instance.vault-server.public_ip}:8200"
}

output "vault_priv_url" {
  description = "The private URL of the Vault server"
  value = "http://${aws_instance.vault-server.private_ip}:8200"
}

output "boundary_admin_auth_method" {
  description = "The Auth Method ID of the default UserPass auth method in the Global scope"
  value       = jsondecode(data.http.boundary_cluster_auth_methods.response_body).items[0].id
}

output "hcp_project_id" {
  value = hcp_project.project.resource_id
}

output "vault_password" {
  description = "The vault terraform user password"
  value = random_string.vault_pass.id
}

output "vpc_id" {
  description = "The ID of the VPC"
  value = module.boundary-demo-vpc.vpc_id
}

output "priv_subnet_id" {
  description = "The ID of the first private subnet"
  value = module.boundary-demo-vpc.private_subnets[0]
}

output "vault_sec_group" {
  description = "The Security Group ID for the Vault Server"
  value = module.vault-security-group.security_group_id
}

output "ldap_password" {
  description = "The Password for the ldap_global_user Boundary User"
  value = random_string.ldap_pass.id
}

output "ldap_address" {
  description = "The IP address of the LDAP server"
  value = aws_instance.vault-server.public_ip
}