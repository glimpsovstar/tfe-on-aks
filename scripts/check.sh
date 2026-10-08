#!/usr/bin/env bash
# Runs the same checks as CI (.github/workflows/ci.yml), locally. Run before every push.
# Needs terraform, tflint, terraform-docs; trivy is used when installed.
set -euo pipefail
cd "$(dirname "$0")/.."

step() { echo; echo "==> $*"; }

step "terraform fmt"
terraform fmt -check -recursive

step "tflint (our directories; vendor/ is upstream code)"
tflint --init >/dev/null
for d in bootstrap modules examples; do
  tflint --recursive --chdir="$d" --config "$PWD/.tflint.hcl"
done

step "terraform-docs drift"
for d in modules/*; do
  terraform-docs markdown table --output-file README.md --output-mode inject "$d" >/dev/null
done
git diff --exit-code -- 'modules/*/README.md' || { echo "module READMEs were out of date and have been regenerated; commit them" >&2; exit 1; }

if command -v trivy >/dev/null 2>&1; then
  step "trivy config (HIGH, CRITICAL)"
  trivy config --exit-code 1 --severity HIGH,CRITICAL --quiet .
else
  echo; echo "==> trivy not installed; skipped (CI runs it)"
fi

step "unit tests"
# terraform test reads a local bootstrap/terraform.tfvars, which CI doesn't have; set it aside for the run.
tfvars=bootstrap/terraform.tfvars
aside=""
if [[ -f "$tfvars" ]]; then
  aside=$(mktemp)
  mv "$tfvars" "$aside"
  trap 'mv "$aside" "$tfvars"' EXIT
fi
./scripts/test.sh

step "stacks validate"
lock_backup=$(mktemp)
cp .terraform.lock.hcl "$lock_backup"
terraform stacks init >/dev/null
terraform stacks validate
cp "$lock_backup" .terraform.lock.hcl
chmod 644 .terraform.lock.hcl

echo; echo "ALL CI CHECKS PASSED"
