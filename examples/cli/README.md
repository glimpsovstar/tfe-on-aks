# Plain CLI examples

Three root configs, applied in order. Without a Stack, Terraform can't configure the Kubernetes and Helm providers from a cluster created in the same run, so 01 and 02 are split. 03 is separate because the `tfe` provider needs the admin token, which only exists after 02 has applied.

1. `01-infra`: AKS and the data services. Runs anywhere your IP is in `aks_authorized_cidrs`.
2. `02-app`: secrets, certificate, Helm release, first admin. Writes the admin token to Key Vault. Must run from inside the VNet (the agent VM or an Azure DevOps self-hosted agent), because TFE has only an internal load balancer.
3. `03-config`: TFE organization, projects and teams. Reads the admin token from Key Vault (`tfe-admin-token`). Must run where both Key Vault and TFE are reachable, i.e. inside the VNet: Key Vault allows the agent subnet and operator IPs, and TFE has only an internal load balancer.

For each root, copy and edit the examples first:

```bash
cp terraform.tfvars.example terraform.tfvars
cp backend.tf.example backend.tf
```

```bash
cd examples/cli/01-infra
cp terraform.tfvars.example terraform.tfvars && cp backend.tf.example backend.tf
terraform init && terraform apply

cd ../02-app
cp terraform.tfvars.example terraform.tfvars && cp backend.tf.example backend.tf
export TF_VAR_tfe_license="$(cat <path-to>.hclic)"
terraform init && terraform apply

cd ../03-config
cp terraform.tfvars.example terraform.tfvars && cp backend.tf.example backend.tf
terraform init && terraform apply
```

Running `02-app` on a laptop over VPN: set `acme_azure_auth_method = "cli"` so the certificate challenge uses your `az login`.
