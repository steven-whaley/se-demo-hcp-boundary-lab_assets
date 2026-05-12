output "okta_password" {
  description = "The Password for the users created in Okta"
  value       = random_string.okta_password.id
}
