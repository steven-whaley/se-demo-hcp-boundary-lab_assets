provider "okta" {
  org_name = var.okta_org_name
  base_url = "okta.com"
}

locals {
  logout_redirect_url = format("%s:%s", data.terraform_remote_state.boundary_demo_init.outputs.boundary_url, "3000")
  callback_url        = format("%s%s", data.terraform_remote_state.boundary_demo_init.outputs.boundary_url, "/v1/auth-methods/oidc:authenticate:callback")
}

resource "random_pet" "okta_password" {
  length = 2
}

# Create the Okta OAuth App for Boundary
resource "okta_app_oauth" "okta_app" {

  label                     = "HCP Boundary Demo"
  type                      = "web"
  login_uri                 = local.callback_url
  post_logout_redirect_uris = [local.logout_redirect_url]
  redirect_uris             = [local.callback_url]
  grant_types               = ["authorization_code"]
  response_types            = ["code"]
  groups_claim {
    type        = "FILTER"
    filter_type = "REGEX"
    name        = "groups"
    value       = ".*"
  }
}

# Create then assign the pie, dev, IT, and global users to groups and groups to the Okta App
resource "okta_user" "global_user" {
  first_name                = "Global"
  last_name                 = "User"
  login                     = "global_user@boundary.lab"
  email                     = "global_user@dev.null"
  password                  = random_pet.okta_password.id
  expire_password_on_create = false
}

resource "okta_user" "pie_user" {
  first_name                = "PIE"
  last_name                 = "User"
  login                     = "pie_user@boundary.lab"
  email                     = "pie_user@dev.null"
  password                  = random_pet.okta_password.id
  expire_password_on_create = false
}

resource "okta_group" "pie_users" {
  name        = "pie_users"
  description = "Platform Infrastructure Engineering Group"
}

resource "okta_user_group_memberships" "pie_user" {
  user_id = okta_user.pie_user.id
  groups  = [okta_group.pie_users.id]
}

resource "okta_app_group_assignment" "pie_users" {
  app_id   = okta_app_oauth.okta_app.id
  group_id = okta_group.pie_users.id
}

resource "okta_user" "dev_user" {
  first_name                = "DEV"
  last_name                 = "User"
  login                     = "dev_user@boundary.lab"
  email                     = "dev_user@dev.null"
  password                  = random_pet.okta_password.id
  expire_password_on_create = false
}

resource "okta_group" "dev_users" {
  name        = "dev_users"
  description = "Developer User Group"
}

resource "okta_user_group_memberships" "dev_users" {
  user_id = okta_user.dev_user.id
  groups  = [okta_group.dev_users.id]
}

resource "okta_app_group_assignment" "dev_users" {
  app_id   = okta_app_oauth.okta_app.id
  group_id = okta_group.dev_users.id
}

resource "okta_user" "it_user" {
  first_name                = "IT"
  last_name                 = "User"
  login                     = "it_user@boundary.lab"
  email                     = "it_user@dev.null"
  password                  = random_pet.okta_password.id
  expire_password_on_create = false
}

resource "okta_group" "it_users" {
  name        = "it_users"
  description = "IT User Group"
}

resource "okta_user_group_memberships" "it_users" {
  user_id = okta_user.it_user.id
  groups  = [okta_group.it_users.id]
}

resource "okta_app_group_assignment" "it_users" {
  app_id   = okta_app_oauth.okta_app.id
  group_id = okta_group.it_users.id
}

resource "okta_user_group_memberships" "global_user" {
  user_id = okta_user.global_user.id
  groups = [
    okta_group.pie_users.id,
    okta_group.dev_users.id,
    okta_group.it_users.id
  ]
}

# Create the OIDC auth method in boundary linked to the Okta Oauth App
resource "boundary_auth_method_oidc" "oidc_auth_method" {
  name                 = "okta_auth"
  description          = "Okta OIDC Auth Method"
  scope_id             = "global"
  client_id            = okta_app_oauth.okta_app.client_id
  client_secret        = okta_app_oauth.okta_app.client_secret
  issuer               = format("%s%s.%s", "https://", var.okta_org_name, "okta.com")
  claims_scopes        = ["email", "groups", "profile"]
  account_claim_maps   = ["nickname=name"]
  signing_algorithms   = ["RS256"]
  api_url_prefix       = data.terraform_remote_state.boundary_demo_init.outputs.boundary_url
  is_primary_for_scope = true
}

# Create the managed group in boundary for Dev users
resource "boundary_managed_group" "dev_managed_group" {
  auth_method_id = boundary_auth_method_oidc.oidc_auth_method.id
  filter         = "\"dev_users\" in \"/token/groups\""
  name           = "Dev Users Group"
}

# Create the role for dev users to connect to targets in the AWS W2 Dev project
resource "boundary_role" "okta_dev_role" {
  name          = "Dev Role"
  principal_ids = [boundary_managed_group.dev_managed_group.id]
  grant_strings = [
    "ids=*;type=session;actions=list,read:self,cancel:self",
    "ids=*;type=target;actions=list,authorize-session,read",
    "ids=*;type=host-set;actions=list,read",
    "ids=*;type=host;actions=list,read",
    "ids=*;type=host-catalog;actions=list,read",
  ]
  scope_id        = data.terraform_remote_state.boundary_demo_targets.outputs.dev_org_id
  grant_scope_ids = ["children"]
}

# Create the managed group in boundary for PIE users
resource "boundary_managed_group" "pie_managed_group" {
  auth_method_id = boundary_auth_method_oidc.oidc_auth_method.id
  filter         = "\"pie_users\" in \"/token/groups\""
  name           = "PIE Users Group"
}

# Create the role for dev users to connect to targets in the AWS W2 PIE project
resource "boundary_role" "okta_pie_role" {
  name          = "PIE Role"
  principal_ids = [boundary_managed_group.pie_managed_group.id]
  grant_strings = [
    "ids=*;type=session;actions=list,read:self,cancel:self",
    "ids=*;type=target;actions=list,authorize-session,read",
    "ids=*;type=host-set;actions=list,read",
    "ids=*;type=host;actions=list,read",
    "ids=*;type=host-catalog;actions=list,read",
  ]
  scope_id        = data.terraform_remote_state.boundary_demo_targets.outputs.pie_org_id
  grant_scope_ids = ["children"]
}

# Create the managed group in boundary for IT users
resource "boundary_managed_group" "it_managed_group" {
  auth_method_id = boundary_auth_method_oidc.oidc_auth_method.id
  filter         = "\"it_users\" in \"/token/groups\""
  name           = "Corp Users Group"
}

# Create the role for dev users to connect to targets in the AWS W2 IT project
resource "boundary_role" "okta_it_role" {
  name          = "IT Role"
  principal_ids = [boundary_managed_group.it_managed_group.id]
  grant_strings = [
    "ids=*;type=session;actions=list,read:self,cancel:self",
    "ids=*;type=target;actions=list,authorize-session,read",
    "ids=*;type=host-set;actions=list,read",
    "ids=*;type=host;actions=list,read",
    "ids=*;type=host-catalog;actions=list,read",
  ]
  scope_id        = data.terraform_remote_state.boundary_demo_targets.outputs.it_org_id
  grant_scope_ids = ["children"]
}

# Set up Permissions to list aliases
resource "boundary_role" "list_aliases" {
  name          = "list_aliases"
  description   = "Role to allow listing aliases"
  principal_ids = [boundary_managed_group.it_managed_group.id, boundary_managed_group.pie_managed_group.id, boundary_managed_group.dev_managed_group.id]
  grant_strings = [
    "ids=*;type=auth-token;actions=read:self",
    "ids=*;type=alias;actions=read",
    "type=alias;actions=list",
    "ids={{.User.Id}};type=user;actions=list-resolvable-aliases"
  ]
  scope_id = "global"
}