resource "time_sleep" "wait_60_sec" {
  depends_on      = [aws_iam_access_key.boundary_user]
  create_duration = "60s"
}

#### LDAP Auth Method Setup
# Create LDAP Auth Method
resource "boundary_auth_method_ldap" "openldap" {
  count = var.use_okta ? 0 : 1
  name          = "OpenLDAP"
  scope_id      = "global"                               
  urls          = ["ldap://${data.terraform_remote_state.boundary_demo_init.outputs.ldap_address}:1389"]           
  user_dn       = "ou=users,dc=boundary,dc=lab"                    
  user_attr     = "uid"                                  
  group_dn      = "ou=users,dc=boundary,dc=lab"                   
  bind_dn       = "cn=admin,dc=boundary,dc=lab" 
  bind_password = data.terraform_remote_state.boundary_demo_init.outputs.ldap_password                         
  state         = "active-public"                        
  enable_groups = true                                   
  #discover_dn   = true
  is_primary_for_scope = true                                   
}

# Create LDAP Managed Group
resource "boundary_managed_group_ldap" "global_users" {
  count = var.use_okta ? 0 : 1
  name           = "Global Users"
  description    = "Boundary users with access to all orgs and projects"
  auth_method_id = boundary_auth_method_ldap.openldap[0].id
  group_names    = ["boundary_users"]
}

resource "boundary_role" "ldap_global_role" {
  count = var.use_okta ? 0 : 1
  name          = "LDAP Users Global Role"
  description   = "Role that grants access to all targets in all Orgs"
  principal_ids = [boundary_managed_group_ldap.global_users[0].id]
  grant_strings = [
    "ids=*;type=session;actions=list,read:self,cancel:self",
    "ids=*;type=target;actions=list,authorize-session,read",
    "ids=*;type=host-set;actions=list,read",
    "ids=*;type=host;actions=list,read",
    "ids=*;type=host-catalog;actions=list,read",
  ]
  scope_id      = "global"
  grant_scope_ids = ["descendants"]
}

# Create the user to be used in Boundary for dynamic host discovery. Then attach the policy to the user.
resource "aws_iam_user" "boundary_user" {
  name                 = "instruqt-boundary-user"
  force_destroy        = true
}

resource "aws_iam_policy" "boundary_policy" {
  name        = "boundary_policy"
  path        = "/"
  description = "Policy for the Boundary IAM user to do Dynamic Host Discovery and access S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "s3:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "boundary_user_policy" {
  user       = aws_iam_user.boundary_user.name
  policy_arn = aws_iam_policy.boundary_policy.arn
}



# Generate some secrets to pass in to the Boundary configuration.
# WARNING: These secrets are not encrypted in the state file. Ensure that you do not commit your state file!
resource "aws_iam_access_key" "boundary_user" {
  user = aws_iam_user.boundary_user.name
}


##### PIE Org Resources #####

# Create Organization Scope for Platform Engineering
resource "boundary_scope" "pie_org" {
  scope_id                 = "global"
  name                     = "pie_org"
  description              = "Platform Infrastructure Engineering Org"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

# Create Project for PIE AWS resources
resource "boundary_scope" "pie_aws_project" {
  name                     = "pie_aws_project"
  description              = "PIE AWS Project"
  scope_id                 = boundary_scope.pie_org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# Create targets in PIE AWS project
resource "boundary_target" "pie-k8s-vault-target" {
  type                     = "tcp"
  name                     = "pie-k8s-vault-target"
  description              = "connect to the k8s Target with a token from the Vault K8s secret engine"
  scope_id                 = boundary_scope.pie_aws_project.id
  session_connection_limit = -1
  default_port             = 6443
  address                  = aws_instance.k8s_cluster.private_ip
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
  brokered_credential_source_ids = [
    boundary_credential_library_vault.k8s-admin-role.id,
    boundary_credential_library_vault.k8s-cert.id
  ]
}

resource "boundary_target" "pie-k8s-target" {
  type                     = "tcp"
  name                     = "pie-k8s-target"
  description              = "Connect to the K8s target with user supplied certificate"
  scope_id                 = boundary_scope.pie_aws_project.id
  session_connection_limit = -1
  default_port             = 6443
  address                  = aws_instance.k8s_cluster.private_ip
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
}

resource "boundary_target" "pie-ssh-target" {
  type                     = "tcp"
  name                     = "pie-ssh-target"
  description              = "Connect to the SSH target with a user supplied SSH key"
  scope_id                 = boundary_scope.pie_aws_project.id
  session_connection_limit = -1
  default_port             = 22
  address                  = aws_instance.k8s_cluster.private_ip
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
}

resource "boundary_target" "pie-ssh-cert-target" {
  #count = var.use_okta ? 1 : 0
  type                     = "ssh"
  name                     = "pie-ssh-cert-target"
  description              = "Connect to the SSH server using OIDC username.  Only works for OIDC users."
  scope_id                 = boundary_scope.pie_aws_project.id
  session_connection_limit = -1
  default_port             = 22
  address = aws_instance.k8s_cluster.private_ip
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh_cert.id
  ]
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
 enable_session_recording = true
 storage_bucket_id        = boundary_storage_bucket.pie_session_recording_bucket.id
}

resource "boundary_target" "pie-ssh-cert-target-admin" {
  type                     = "ssh"
  name                     = "pie-ssh-cert-target-admin"
  description              = "Connect to the SSH target as the default ec2-user account"
  scope_id                 = boundary_scope.pie_aws_project.id
  session_connection_limit = -1
  default_port             = 22
  address = aws_instance.k8s_cluster.private_ip
  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh_cert_admin.id
  ]
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""
 enable_session_recording = true
 storage_bucket_id        = boundary_storage_bucket.pie_session_recording_bucket.id
}

# Create PIE Vault Credential Store
resource "boundary_credential_store_vault" "pie_vault" {
  name        = "PIE Vault"
  description = "PIE Vault Credential Store"
  namespace   = vault_namespace.pie.path_fq
  address     = data.terraform_remote_state.boundary_demo_init.outputs.vault_pub_url
  token       = vault_token.boundary-token-pie.client_token
  scope_id    = boundary_scope.pie_aws_project.id
}

# Credential Library to provide K8s service token
resource "boundary_credential_library_vault" "k8s-admin-role" {
  name                = "K8s Admin Role"
  description         = "K8s Credential Admin Role Token"
  credential_store_id = boundary_credential_store_vault.pie_vault.id
  path                = "kubernetes/creds/cluster-admin-role" 
  http_method         = "POST"
  http_request_body = <<EOT
  {
    "kubernetes_namespace": "default"
  }
  EOT
}

# Credential Library to provide SSH certificate for logged in user
resource "boundary_credential_library_vault_ssh_certificate" "ssh_cert" {
  name                = "ssh_cert"
  description         = "Signed SSH Certificate Credential Library"
  credential_store_id = boundary_credential_store_vault.pie_vault.id
  path                = "ssh/sign/cert-role" # change to Vault backend path
  username            = "{{truncateFrom .User.Email \"@\"}}"
  key_type            = "ecdsa"
  key_bits            = 384
  extensions = {
    permit-pty = ""
  }
}

# Credential library to provide SSH certificate for ec2-user
resource "boundary_credential_library_vault_ssh_certificate" "ssh_cert_admin" {
  name                = "ssh_cert_admin"
  description         = "Signed SSH Certificate Credential Library"
  credential_store_id = boundary_credential_store_vault.pie_vault.id
  path                = "ssh/sign/cert-role" # change to Vault backend path
  username            = "ec2-user"
  key_type            = "ecdsa"
  key_bits            = 384
  extensions = {
    permit-pty = ""
  }
}

# Credential Library to provide K8s CA Certificate
resource "boundary_credential_library_vault" "k8s-cert" {
  name                = "K8s Cert"
  description         = "K8s CA Certificate"
  credential_store_id = boundary_credential_store_vault.pie_vault.id
  path                = "secrets/data/k8s-cluster" 
  http_method         = "get"
}

##### Dev Org Resources #####

# Create Organization Scope for Dev
resource "boundary_scope" "dev_org" {
  scope_id                 = "global"
  name                     = "dev_org"
  description              = "Dev Org"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

# Create Project for Dev AWS resources
resource "boundary_scope" "dev_aws_project" {
  name                     = "dev_aws_project"
  description              = "Dev AWS Project"
  scope_id                 = boundary_scope.dev_org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# Create Postgres RDS Target
resource "boundary_target" "dev-db-target" {
  type                     = "tcp"
  name                     = "dev-db-target"
  description              = "Connect to the postgres database with Vault DB secrets engine credentials"
  scope_id                 = boundary_scope.dev_aws_project.id
  session_connection_limit = -1
  default_port             = 30932
  address                  = aws_instance.k8s_cluster.private_ip
  egress_worker_filter     = "\"${var.region}\" in \"/tags/region\""

  brokered_credential_source_ids = [
    boundary_credential_library_vault.database.id
  ]
}

# Create Dev Vault Credential store
resource "boundary_credential_store_vault" "dev_vault" {
  name        = "dev_vault"
  description = "Dev Vault Credential Store"
  namespace   = vault_namespace.dev.path_fq
  address     = data.terraform_remote_state.boundary_demo_init.outputs.vault_pub_url
  token       = vault_token.boundary-token-dev.client_token
  scope_id    = boundary_scope.dev_aws_project.id
}

# Create Database Credential Library
resource "boundary_credential_library_vault" "database" {
  name                = "database"
  description         = "Postgres DB Credential Library"
  credential_store_id = boundary_credential_store_vault.dev_vault.id
  path                = "database/creds/db1" # change to Vault backend path
  http_method         = "GET"
  credential_type     = "username_password"
}

##### IT Org Resources #####

# Create Organization Scope for Corporate IT
resource "boundary_scope" "it_org" {
  scope_id                 = "global"
  name                     = "it_org"
  description              = "Corporate IT Org"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

# Create Project for IT AWS resources
resource "boundary_scope" "it_aws_project" {
  name                     = "it_aws_project"
  description              = "Corp IT AWS Project"
  scope_id                 = boundary_scope.it_org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# Create the dynamic host catalog for IT 
resource "boundary_host_catalog_plugin" "it_dynamic_catalog" {
  depends_on = [time_sleep.wait_60_sec]

  name        = "it_${var.region}_catalog"
  description = "IT AWS ${var.region} Catalog"
  scope_id    = boundary_scope.it_aws_project.id
  plugin_name = "aws"

  attributes_json = jsonencode({
    "region"                      = var.region,
    "disable_credential_rotation" = true
  })

  secrets_json = jsonencode({
    "access_key_id"     = aws_iam_access_key.boundary_user.id,
    "secret_access_key" = aws_iam_access_key.boundary_user.secret
  })
}

resource "time_sleep" "catalog_wait" {
  depends_on      = [boundary_host_catalog_plugin.it_dynamic_catalog]
  create_duration = "30s"
}

# Create the host set for IT team from dynamic host catalog
resource "boundary_host_set_plugin" "it_set" {
  name            = "IT hosts in ${var.region}"
  host_catalog_id = boundary_host_catalog_plugin.it_dynamic_catalog.id
  attributes_json = jsonencode({
    "filters" = "tag:Team=IT",
  })
}

# Create the RDP Target in the IT AWS project
resource "boundary_target" "it-rdp-target" {
  type                     = "tcp"
  name                     = "it-rdp-target"
  description              = "Connect to the RDP target with user supplied credentials"
  scope_id                 = boundary_scope.it_aws_project.id
  session_connection_limit = -1
  default_port             = 3389
  default_client_port = 54389

  host_source_ids = [
    boundary_host_set_plugin.it_set.id
  ]
  egress_worker_filter = "\"${var.region}\" in \"/tags/region\""
}

# Create Session Recording Bucket
# Delay creation to give the worker time to register

resource "time_sleep" "worker_timer" {
  depends_on = [aws_instance.worker]
  create_duration = "120s"
}

resource "random_string" "bucket_string" {
  length = 4
  special = false
}

resource "boundary_storage_bucket" "pie_session_recording_bucket" {
  depends_on = [time_sleep.worker_timer]

  name        = "PIE Session Recording Bucket ${random_string.bucket_string.result}"
  description = "Session Recording bucket for PIE team"
  scope_id    = "global"
  plugin_name = "aws"
  bucket_name = aws_s3_bucket.boundary_recording_bucket.id
  attributes_json = jsonencode({
    "region"                    = var.region,
    disable_credential_rotation = true
  })

  secrets_json = jsonencode({
    "access_key_id"     = aws_iam_access_key.boundary_user.id,
    "secret_access_key" = aws_iam_access_key.boundary_user.secret
  })
  worker_filter = "\"${var.region}\" in \"/tags/region\""
}