# Lab vs production

The defaults in this repository suit a small, cost-sensitive environment. Change the following before you run it for real. See the [disclaimer in the README](../README.md#disclaimer).

| Area | Sample default | For production |
|---|---|---|
| TLS certificate | Let's Encrypt (ACME). A convenience for labs. | Use a certificate from your own CA (or a public CA you manage). Do not depend on ACME in an environment that must stay up. |
| AKS API server | Public endpoint limited to a CIDR allow-list (agent VM and `operator_cidrs`). | Private AKS API. Use option B (existing AKS cluster) with your own private cluster, and run `02-app` and `03-config` from a host with a route to it. |
| Sign-in | `collaborator_auth_policy = "password"`, because the bootstrap admin's token user has no 2FA. | SSO with 2FA, or `two_factor_mandatory` once every owner has enrolled. |
| Stack identity | Contributor and User Access Administrator on the resource group that also holds the agent VM. | Put the identity and the agent in a separate resource group. Give the identity least privilege and no User Access Administrator (or add an ABAC condition on it). |
| Agent VM | Public IP, SSH, stock Ubuntu image. | No public IP and no SSH. Use your organisation's approved base image with EDR and monitoring. |
| Sizing | `lab` preset (2 nodes, small PostgreSQL and Redis, no HA). | Use the `production` preset (see the sizing table in [architecture.md](architecture.md)) and size it for your run volume. |
| SKU availability | `Standard_B2ls_v2` agent, `Standard_D4ds_v5` nodes. | Check SKU and quota availability per region and subscription before you apply. Some subscriptions restrict B-series. |
| Redis | Azure Managed Redis with the `NoCluster` policy. | Keep `NoCluster`. Sidekiq fails with CROSSSLOT errors on `EnterpriseCluster`, and runs stay pending. |
| TFE configuration | Created by the Stack (`tfe_config`) after install. | Keep TFE configuration separate from the install, in its own workspace or pipeline, so a change to the organisation cannot disturb the platform. |
| Success criteria | `scripts/acceptance.sh` and a ready pod. | Readiness is not enough. Prove it with a real plan and apply in a workspace, as `scripts/acceptance.sh` does. |

## Also review

- Secrets in state: bootstrap local state, Stack state and the agent VM `custom_data` contain secrets. Store and restrict them accordingly.
- Backups for PostgreSQL and Blob storage, and a disaster recovery plan for your region.
- The `.trivyignore` entry for AZU-0043 (no AKS network policy).
