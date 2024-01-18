#!/bin/bash

set -euo pipefail


export TF_BASE="$(pwd)/terraform"
echo "export TF_BASE=\"$TF_BASE\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh


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

export TF_BASE="$(pwd)/terraform"
echo "export TF_BASE=\"$TF_BASE\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

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
read -s hcp_client_id
echo "export HCP_CLIENT_ID=\"$hcp_client_id\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
echo ""

echo "Please provide your HCP Client Secret: "
read -s hcp_client_secret
echo "export HCP_CLIENT_SECRET=\"$hcp_client_secret\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
echo ""

echo "Please provide your Okta API Token: "
read -s okta_api_token
echo "export OKTA_API_TOKEN=\"$okta_api_token\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh
echo ""

echo "Please provide your Okta Org Name: "
read -s okta_org_name
echo "export TF_VAR_okta_org_name=\"$okta_org_name\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh 

echo "export TF_VAR_public_key=\"$(cat ~/.ssh/id_rsa.pub)\"" >> ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

source .bashrc



cd ${TF_BASE}/boundary-demo-init
terraform init
terraform apply -auto-approve

