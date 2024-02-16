# Boundary Demo

## Demo Environment
This terraform code builds an HCP Boundary enviroment that inclues connectivity to HCP Vault for credential brokering and injection, Okta integration for OIDC authentication and managed groups, and a number of AWS resources that are used as workers and Boundary targets.  

### Features
- SSH with Vault generated SSH Certificates and username templating
- RDP Target with brokered AD credentials from Vault LDAP Secrets Engine
- Okta integration using managed groups with different targets for each group
- Session Recording
- K8s target with brokered credentials from Vault K8s Secrets Engine
- Database target with brokered credentials from Vault DB Secrets Engine
- Multi-hop using HCP ingress worker and private egress worker

### Boundary Organization Structure
![image](./org-structure.png)

### Demo Environment Diagram
![image](./diagram.png)

### Components
| Component | Purpose |
| ----------- | ----------- |
| HCP Boundary | Boundary Control Plane |
| HCP Vault | Boundary Credential Store |
| Boundary Worker | Boundary EC2 Worker |
| Okta | OIDC Authentication |
| EC2 Linux Instance | SSH Cert Auth Target, Postgres Target, K8s Target |
| EC2 Windows Instance | RDP Target |

### Prerequisites
**HCP Account**

You will need an account on the Hashicorp Cloud Platform to create the Boundary and Vault clusters.  Sign up for an HCP account here:  https://www.hashicorp.com/cloud.  You will also need to create a Service Principal and Service Principal keys.  The documentation for creating a Service Principal is here:  https://developer.hashicorp.com/hcp/docs/hcp/admin/iam/service-principals.  **The Service Principal should be created at the Organization level rather than the project level.**  

**Okta Developer Account**

You will need an Okta developer account to fully utilize this demo.  You can sign up for an account here: https://developer.okta.com/signup/
Once logged in you will need to create an API token.  The process for creating an API token is here:  https://developer.okta.com/docs/guides/create-an-api-token/main/#create-the-token.  Be sure to save the token as you will need it later.  

**The Boundary Desktop Client Installed**
You will need the Boundary Desktop Client installed to demo certain features like the integrated terminal.  https://developer.hashicorp.com/boundary/tutorials/oss-getting-started/oss-getting-started-desktop-app

**PSQL Binary Installed**
You will need the PSQL binary installed to connect to the database server using the `boundary connect postgres` command.  Install PSQL based on instructions for your speicfic OS.  

**RDP Client Installed**
You will need a Remote Desktop Protocol client installed to connect to the RDP targets.  On Windows sytems this is installed automatically but Linux or Mac users will need to install a RDP client.  

## Connecting to Targets
### Okta Users
When using the Okta integration four users are created in your directory.  

**Passwords** - All Okta users have the same password which is the value of the okta_user_password terraform variable that you set in the *boundary-demo-tfc-build* workspace. 

| User | Okta Group | Boundary Org | Description |
| --------- | -------- | -------- | -------- |
| global_user@boundary.lab | All | All | Has rights to connect to all targets in all orgs |
| pie_user@boundary.lab | pie_users | pie_org | Has rights to connect to all targets in PIE org |
| dev_user@boundary.lab | dev_users | dev_org | Has rights to connect to all targets in DEV org |
| it_user@boundary.lab | it_users | it_org | Has rights to connect to all targets in IT org |

### Available Targets
| Target | Org\Project | Credentials | Description |
| --------- | -------- | -------- | -------- |
| pie-ssh-cert-target | pie_org\pie_aws_project | **Injected** using Vault SSH Cert Secrets Engine | Connects to the SSH target as the logged in username.  **Only usable when logged in via Okta as pie_user or global_user** |
| pie-ssh-cert-target-admin | pie_org\pie_aws_project | **Injected** using Vault SSH Cert Secrets Engine | Connects to the SSH target as ec2-user |
| pie-ssh-tcp-target | pie_org\pie_aws_project | User supplied ssh key | Connect using user supplied SSH key |
| pie-k8s-target | pie_org\pie_aws_project | **Brokered** SA token from Vault K8s Secrets Engine | Connect using the k8s-connect script in the scripts folder of the repo.  See video below for more info |
| dev-db-target | dev_org\dev_aws_project | **Brokered** from Vault DB Secrets Engine | Connects using credentials brokered from Vault |
| it-rdp-target | it_org\it_aws_project | User supplied username and password | Connect using Administrator@boundary.lab user and password set in admin_pass TF variable |
| it-rdp-target-admin | it_org\it_aws_project | **Brokered** from Vault LDAP Secrets Engine | Connect using username (be sure to add @boundary.lab to the end) and password provided by Vault in connection info |