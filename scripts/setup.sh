#!/bin/bash

set -euo pipefail

if [[ -f ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh ]]; then
  rm ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
  touch ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
else
  touch ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
fi

if ! grep -E "^source ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh$" ~/.bashrc > /dev/null 2>&1; then
  echo "" >> ~/.bashrc
  echo "source ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh" >> ~/.bashrc
fi

export TF_BASE="$(pwd)/se-demo-hcp-boundary-lab_assets/terraform"
echo "export TF_BASE=\"$TF_BASE\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

export TF_VAR_vault_license=$(cat /root/vault.hclic)
echo "export TF_VAR_vault_license=\"$TF_VAR_vault_license\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

default_setup_info_text=\
"This track sets up an HCP Boundary cluster and an AWS VPC with the following components
- Self managed worker in a private subnet
- EC2 instance as an SSH target
- EC2 instance running K8s as a K8s target
- Postgres Container as a Postgres Target
- Windows Server as an RDP Target
- Session Recording Configuration

This script will create the HCP Boundary and Vault clusters for you.  It will create a new Project within you HCP environment
to contain the Boundary and Vault clusters.  This project and the associated resources should get cleaned up when
the Instruqt environment is terminated.  You will need to provide HCP Credentials with Admin rights so that the project 
can be created.  
"

echo "$default_setup_info_text"
echo ""

echo "Please provide your HCP Client ID: "
read hcp_client_id
echo "export HCP_CLIENT_ID=\"$hcp_client_id\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
echo ""

echo "Please provide your HCP Client Secret: "
read -s hcp_client_secret
echo "export HCP_CLIENT_SECRET=\"$hcp_client_secret\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
echo ""

use_okta="failed"
while [ "$use_okta" = "failed" ]
do
  echo "Do you want to configure Boundary to use Okta OIDC for Authentication? y/n"
  read use_okta
  case $use_okta in
    y) 
      echo "export TF_VAR_use_okta=\"true\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
      ;;
    n) 
      echo "export TF_VAR_use_okta=\"false\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
      ;;
    *) 
      use_okta=failed; echo "Please enter either y or n when answering the question."
      echo ""
      ;;
  esac
done

if [[ "$use_okta" == "y" ]]; then
  echo "Please provide your Okta API Token: "
  read -s okta_api_token
  echo "export OKTA_API_TOKEN=\"$okta_api_token\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
  echo ""

  echo "Please provide your Okta Org Name: "
  read okta_org_name
  echo "export TF_VAR_okta_org_name=\"$okta_org_name\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh 
fi

use_ldap="failed"
while [ "$use_ldap" = "failed" ]
do
  echo "Do you want to configure Boundary to use Vault LDAP Secrets Engine to connect to the RDP Target?" 
  echo "This adds approximately 7 minutes to the deployment.  Please answer y/n"
  read use_ldap
  case $use_okta in
    y) 
      echo "export TF_VAR_use_ldap=\"true\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
      ;;
    n) 
      echo "export TF_VAR_use_ldap=\"false\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
      ;;
    *) 
      use_okta=failed; echo "Please enter either y or n when answering the question."
      echo ""
      ;;
  esac
done

echo "export TF_VAR_public_key=\"$(cat ~/.ssh/id_rsa.pub)\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

source .bashrc

cd ${TF_BASE}/boundary-demo-init
terraform init
terraform apply -auto-approve
if [ $? -eq 0 ]; then
  touch ${HOME}/.init-success
fi

cd ${TF_BASE}/boundary-demo-targets
terraform init
terraform apply -auto-approve
if [ $? -eq 0 ]; then
  touch ${HOME}/.targets-success
fi

if [[ "$use_okta" == "y" ]]; then
  cd ${TF_BASE}/boundary-demo-okta
  terraform init
  terraform apply -auto-approve
  if [ $? -eq 0 ]; then
    touch ${HOME}/.okta-success
  fi
fi

BOUNDARY_URL=`terraform output -state="${TF_BASE}/boundary-demo-init/terraform.tfstate" -raw boundary_url`
BOUNDARY_ADMIN_PASSWORD=`terraform output -state="${TF_BASE}/boundary-demo-init/terraform.tfstate" -raw boundary_admin_password`
BOUNDARY_PASSWORD_AUTH_METHOD=`terraform output -state="${TF_BASE}/boundary-demo-init/terraform.tfstate" -raw boundary_admin_auth_method`
if [[ "$use_okta" == "y" ]]; then
  OKTA_USER_PASSWORD=`terraform output -state="${TF_BASE}/boundary-demo-okta/terraform.tfstate" -raw okta_password`
fi

if [[ "$use_ldap" == "y" ]]; then
  echo "Setting up the LDAP secrets engine to provide dynamic AD credentials to connect to the Windows target."
  echo "The script will sleep for 5 minutes while waiting for Domain Controller promotion and Certificate Services setup to complete."
  sleep 360

  cd ${TF_BASE}/boundary-demo-ad-secrets
  terraform init
  terraform apply -auto-approve
  if [ $? -eq 0 ]; then
    touch ${HOME}/.ldap-success
  fi 
fi 

echo "Click Next in the bottom right to validate that your Boundary environment is set up correctly and get \
instructions on how to log in and connect to your targets"
