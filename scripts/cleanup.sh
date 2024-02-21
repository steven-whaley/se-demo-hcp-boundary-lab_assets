#!/bin/bash
set -euxo pipefail

source ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh >/dev/null 2>&1

if [[ "$TF_VAR_use_okta" == "true"]]; then
    cd ${TF_BASE}/boundary-demo-okta
    terraform destroy -auto-approve
fi

cd ${TF_BASE}/boundary-demo-init
terraform destroy -target hcp_boundary_cluster.boundary-demo -auto-approve
terraform destroy -target hcp_project.project -auto-approve