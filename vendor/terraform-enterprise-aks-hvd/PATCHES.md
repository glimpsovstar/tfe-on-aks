# Local patches

Vendored from [hashicorp/terraform-enterprise-aks-hvd/azurerm](https://registry.terraform.io/modules/hashicorp/terraform-enterprise-aks-hvd/azurerm/0.3.0) 0.3.0 (commit `2848c42`). MPL-2.0; see `LICENSE`. Vendored from upstream 0.3.0 commit `2848c42`; diff against that upstream release to see the patches. `examples/`, `docs/` and CI files were not copied.

## 1. `redis_managed_clustering_policy` input

- **Files:** `variables.tf` (new input), `redis.tf` (both `azurerm_managed_redis` databases use it).
- **Why:** 0.3.0 hard-codes `clustering_policy = "EnterpriseCluster"`. With TFE 2.0.8, Sidekiq logs `CROSSSLOT Keys in request don't hash to the same slot` on its heartbeat (`EXISTS` within `MULTI`) and job fetch (`BRPOP` across queues), so runs stay `pending`. Azure Managed Redis `NoCluster` (caches up to 25 GB) has no slots, so these commands work.
- **Default:** `EnterpriseCluster`, unchanged from upstream. `modules/tfe-infra` passes `NoCluster`.
- **Remove when:** the registry module exposes the policy or defaults to `NoCluster`. Then point `modules/tfe-infra` back at the registry source.

## 2. azurerm v5 names on the federated credential

- **File:** `msi.tf`, `azurerm_federated_identity_credential.tfe_kube_service_account`.
- **Change:** `parent_id` becomes `user_assigned_identity_id` (same value); the unused `resource_group_name` is removed. This clears two deprecation warnings on every plan. The Stack plan should show no change, or an in-place update, for this resource. Never a replace.
- **Not changed:** `storage_account_name` on `azurerm_storage_container.tfe` (`blob_storage.tf`) is also deprecated, but switching to `storage_account_id` may recreate the TFE blob container, so it waits for upstream.


## 3. `aks_kube_config` output

- **File:** `outputs.tf`.
- **Why:** without it, `modules/tfe-infra` read the credentials with a `data "azurerm_kubernetes_cluster"` that had `depends_on = [module.tfe]`. Any change anywhere in the module (for example a Redis update) then deferred the read to apply, so every kubernetes and helm resource was deferred too, and the Stack's `tfe` provider failed with "required token could not be found". Reading `kube_config` from the cluster resource ties the dependency to the cluster alone.

This directory is not linted by this repo's tflint (CI and pre-commit lint `bootstrap/`, `modules/` and `examples/` only); it is upstream code.
