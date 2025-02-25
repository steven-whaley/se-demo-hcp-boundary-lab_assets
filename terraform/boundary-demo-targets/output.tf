output "worker_ip_address" {
  description = "Boundary worker private IP"
  value       = aws_instance.worker.private_ip
}

output "k8s_ip_address" {
  description = "K8s host private IP"
  value       = aws_instance.k8s_cluster.private_ip
}

output "dc_ip_address" {
  description = "The Domain Controller IP address"
  value       = aws_instance.rdp-target.private_ip
}

output "bastion_ip_address" {
  description = "The Bastion IP address"
  value       = aws_instance.bastion.private_ip
}

output "pie_org_id" {
  description = "The ORG ID of the PIE Project"
  value       = boundary_scope.pie_org.id
}

output "pie_project_id" {
  description = "The project ID of the PIE AWS project"
  value       = boundary_scope.pie_aws_project.id
}

output "it_org_id" {
  description = "The ORG ID of the IT Project"
  value       = boundary_scope.it_org.id
}

output "it_project_id" {
  description = "The project ID of the IT AWS project"
  value       = boundary_scope.it_aws_project.id
}

output "dev_org_id" {
  description = "The ORG ID of the DEV Project"
  value       = boundary_scope.dev_org.id
}

output "dev_project_id" {
  description = "The project ID of the DEV AWS project"
  value       = boundary_scope.dev_aws_project.id
}

output "it_host_set_id" {
  description = "The ID of the dynamic host set plugin used for the IT hosts"
  value       = boundary_host_set_plugin.it_set.id
}



