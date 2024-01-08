output "boundary_admin_password" {
  description = "The Password for the Boundary admin user"
  value = random_pet.random_password.id
}

output "boundary_url" {
  description = "The public URL of the HCP Boundary Cluster"
  value       = hcp_boundary_cluster.boundary-demo.cluster_url
}

output "vault_pub_url" {
  description = "The public URL of the HCP Vault cluster"
  value       = hcp_vault_cluster.boundary-vault-cluster.vault_public_endpoint_url
}