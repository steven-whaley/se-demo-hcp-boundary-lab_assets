resource "random_pet" "pet_name" {
}

resource "random_pet" "random_password" {
  length = 2
}

#Create New HCP Project for these resources
resource "hcp_project" "project" {
  name        = "instruqt-${random_pet.pet_name.id}"
  description = "Project Created by Instruqt Boundary Demo Lab"
}

#Create HCP Boundary Cluster
resource "hcp_boundary_cluster" "boundary-demo" {
  project_id = hcp_project.project.resource_id
  cluster_id = "instruqt-${random_pet.pet_name.id}"
  username   = var.boundary_user
  password   = random_pet.random_password.id
  tier       = "PLUS"
}

resource "hcp_hvn" "boundary-vault-hvn" {
  project_id = hcp_project.project.resource_id
  hvn_id         = "boundary-vault-demo-hvn"
  cloud_provider = "aws"
  region         = var.region
  cidr_block     = "172.29.16.0/20"
}

resource "hcp_vault_cluster" "boundary-vault-cluster" {
  project_id = hcp_project.project.resource_id
  cluster_id      = hcp_boundary_cluster.boundary-demo.cluster_id
  hvn_id          = hcp_hvn.boundary-vault-hvn.hvn_id
  tier            = "dev"
  public_endpoint = true
}

resource "hcp_vault_cluster_admin_token" "boundary-token" {
  project_id = hcp_project.project.resource_id
  cluster_id = hcp_vault_cluster.boundary-vault-cluster.cluster_id
}