#!/bin/bash
set -euxo pipefail

source ~/.${INSTRUQT_PARTICIPANT_ID}-env.sh

cd ${TF_BASE}/boundary-demo-okta
terraform destroy -auto-approve

cd ${TF_BASE}/boundary-demo-init
terraform destroy -auto-approve