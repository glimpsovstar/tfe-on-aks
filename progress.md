# Progress

## Goal / scope
Reference implementation: build AKS, install Terraform Enterprise and configure it, through an HCP Terraform Stack or plain Terraform modules. New AKS only.

## Done
- AKS + TFE install + TFE configuration (two-pass Stack), validated end to end in a lab on TFE 2.0.8 with the HashiCorp HVD AKS module 0.3.0 (vendored with three patches; see `vendor/terraform-enterprise-aks-hvd/PATCHES.md`).
- CI: fmt, tflint, trivy, terraform-docs drift, unit tests, `terraform stacks validate`.

## In progress
- Nothing.

## Next
1. Choose and add a LICENSE.
2. Support for an existing AKS cluster.
3. Return to the registry HVD module once it exposes the Redis clustering policy and a kube_config output.

## Key context
- Read `docs/production.md` before any production use (certificates, private AKS API, SSO, identity, sizing).
- `./scripts/test.sh` runs the unit tests; see `.github/workflows/ci.yml` for the full CI.
