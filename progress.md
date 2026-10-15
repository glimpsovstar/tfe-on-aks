# Progress

## Goal / scope
Reference implementation: build AKS (or use an existing one), install Terraform Enterprise and configure it, through an HCP Terraform Stack or plain Terraform modules.

## Done
- AKS + TFE install + TFE configuration (two-pass Stack), validated end to end in a lab on TFE 2.0.8 with the HashiCorp HVD AKS module 0.3.0 (vendored with three patches; see `vendor/terraform-enterprise-aks-hvd/PATCHES.md`).
- Option B, existing AKS cluster (`create_aks_cluster = false` in `tfe-infra` and `examples/cli/01-infra`): identity, Blob role and federated credential created outside the HVD module, which can't federate to a cluster it didn't create. Unit-tested with mocks only (branch `djoo/existing-aks`).
- CI: fmt, tflint, trivy, terraform-docs drift, unit tests, `terraform stacks validate`.

## In progress
- Nothing.

## Next
1. Choose and add a LICENSE.
2. Run option B against a live existing AKS cluster and record the result. Then: `02-app` authenticates with the operator's Entra login (kubelogin), so option B no longer puts the existing cluster's admin credential in `01-infra` state (security review finding, 2026-10-16); option B in the Stack.
3. Return to the registry HVD module once a tagged release has Redis `NoCluster` (on upstream `main` since PR #24, not in 0.3.0) and a kube_config output.

## Key context
- Read `docs/production.md` before any production use (certificates, private AKS API, SSO, identity, sizing).
- `./scripts/test.sh` runs the unit tests; see `.github/workflows/ci.yml` for the full CI.
