#!/usr/bin/env bash
# Initialize Terraform with the state stored outside the repository.
# Extra arguments are passed to `terraform init` (e.g. -upgrade).
set -euo pipefail

STATE_DIR="${SLURM_TOY_STATE_DIR:-${HOME}/.local/share/slurm-toy}"
TERRAFORM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../terraform" && pwd)"

mkdir -p "${STATE_DIR}"
terraform -chdir="${TERRAFORM_DIR}" init \
    -backend-config="path=${STATE_DIR}/terraform.tfstate" "$@"
