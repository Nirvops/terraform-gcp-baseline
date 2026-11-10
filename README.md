# Terraform – GKE Deployment on Google Cloud

## Introduction

The objective of this project is to deploy a Kubernetes infrastructure on **Google Cloud Platform (GCP)** using **Terraform**.

This project demonstrates how to provision and manage cloud infrastructure using the Infrastructure as Code (IaC) approach.

The deployed infrastructure includes:

- A custom VPC network.
- A subnet with secondary IP ranges for Kubernetes Pods and Services.
- A zonal Google Kubernetes Engine (GKE) Standard cluster.
- A dedicated node pool using Preemptible virtual machines.
- A custom Service Account with explicitly assigned IAM permissions.

## Architecture diagram

```text
Google Cloud Platform
│
├── VPC Network
│   └── my-custom-vpc
│
├── Subnet
│   └── my-custom-subnet
│       ├── Primary range: 10.0.1.0/24
│       ├── Pods range: 10.4.0.0/14
│       └── Services range: 10.8.0.0/20
│
└── GKE Standard (Zonal)
    │
    └── my-custom-gke-cluster
        │
        └── my-custom-node-pool
            ├── Machine type: e2-small
            ├── Node count: 1
            ├── Preemptible: true
            └── Custom Service Account
```

## Technology choices

- **Terraform** >= 1.6.0
- **Google Cloud Platform (GCP)**
- **Google Kubernetes Engine (GKE)**
- **Google Compute Engine**
- **Google Cloud IAM**

## Project structure

```text
.
├── .gitignore
├── .terraform.lock.hcl
├── README.md
├── iam.tf
├── main.tf
└── variables.tf
```

| File | Description |
|---|---|
| `main.tf` | Definition of GCP resources: VPC, subnet, GKE cluster and node pool. |
| `iam.tf` | Configuration of the custom Service Account and IAM permissions. |
| `variables.tf` | Declaration of Terraform input variables. |
| `.terraform.lock.hcl` | Locks the selected provider versions and checksums. |
| `.gitignore` | Excludes local and sensitive files from Git. |

## Prerequisites

Before starting, make sure you have:

- A Google Cloud Platform account.
- An active GCP project with billing enabled.
- Terraform >= 1.6.0 installed.
- Google Cloud CLI (`gcloud`) installed.
- `kubectl` installed.

### 1. Authenticate with Google Cloud

Two authentication mechanisms are required because the Google Cloud CLI and Terraform provider do not necessarily use the same credentials.

First, authenticate the Google Cloud CLI:

```bash
gcloud auth login
```

If you are using WSL and encounter browser callback issues, use:

```bash
gcloud auth login --no-launch-browser
```

Follow the URL displayed in the terminal and complete the authentication process.

### 2. Configure the GCP project

Set the project used by the Google Cloud CLI:

```bash
gcloud config set project YOUR_PROJECT_ID
```

### 3. Configure Application Default Credentials

Terraform's Google provider uses Application Default Credentials (ADC).

Authenticate Terraform with:

```bash
gcloud auth application-default login
```

If the browser callback does not work in your environment, use:

```bash
gcloud auth application-default login --no-launch-browser
```

Finally, configure the quota project for ADC:

```bash
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

**Important:** `gcloud auth login` and `gcloud auth application-default login` serve different purposes. Both are required for the workflow documented here.

### 4. Enable the required Google Cloud APIs

The APIs used by this project are:

```bash
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

Cloud Resource Manager is also relevant to project-level IAM policy management.

Check the APIs enabled in your project with:

```bash
gcloud services list --enabled --project YOUR_PROJECT_ID
```

The account enabling APIs must have the appropriate permissions.

## Deployment

### 1. Clone the repository

```bash
git clone YOUR_REPOSITORY_URL
cd YOUR_PROJECT_DIRECTORY
```

### 2. Configure variables

The required Terraform variables are declared in `variables.tf`.

Create a `terraform.tfvars` file in the project root:

```hcl
gcp_project_id = "YOUR_PROJECT_ID"
gcp_region     = "europe-west6"
gcp_zone       = "europe-west6-b"
```

Adjust these values to match your GCP project.

**Important:** The selected zone must belong to the selected region. For example, `europe-west6-b` belongs to `europe-west6`.

The `terraform.tfvars` file contains project-specific configuration and should never be committed to Git. Make sure it is included in `.gitignore`.

### 3. Initialize Terraform

```bash
terraform init
```

This command initializes the working directory and downloads the required Google provider.

### 4. Format and validate the configuration

```bash
terraform fmt -check
terraform validate
```

- `terraform fmt -check` checks whether the Terraform files follow the standard formatting conventions.
- `terraform validate` checks the syntax and internal consistency of the configuration.

### 5. Review the deployment plan

```bash
terraform plan
```

This command displays the resources that Terraform intends to create, modify or delete.

Always review the plan before applying changes.

### 6. Deploy the infrastructure

```bash
terraform apply
```

Confirm the deployment by entering `yes`.

Terraform will provision the resources defined in the `.tf` files.

## Connecting to the Kubernetes cluster

Once the deployment is complete, retrieve the cluster credentials:

```bash
gcloud container clusters get-credentials my-custom-gke-cluster \
  --zone europe-west6-b \
  --project YOUR_PROJECT_ID
```

This command updates the local Kubernetes configuration and changes the current `kubectl` context.

Check the active context:

```bash
kubectl config current-context
```

If `kubectl` reports that the GKE authentication plugin is missing, install it:

```bash
gcloud components install gke-gcloud-auth-plugin
```

Verify the connection:

```bash
kubectl get nodes
```

Display cluster information:

```bash
kubectl cluster-info
```

## Verification

The cluster deployment was successfully tested using `kubectl`.

The following output confirms that the worker node joined the cluster and reached the `Ready` state:

```text
NAME                                                STATUS   ROLES    AGE   VERSION
gke-my-custom-gke-cl-my-custom-node-p-cb524320-0npv Ready    <none>   17m   v1.36.4-gke
```

This confirms that:

- The GKE control plane was accessible.
- The worker node successfully joined the cluster.
- Kubernetes reported the node as `Ready`.

## Cost management

**Important: GCP resources can generate charges even when no applications are deployed.**

This project uses a small machine type (`e2-small`) and a single-node pool to limit infrastructure costs.

GKE provides a monthly management-fee credit for one eligible zonal or Autopilot cluster per billing account. This credit applies to the cluster management fee, not to worker nodes or other infrastructure resources.

Compute Engine instances, persistent disks, networking and other services can still generate charges.

To avoid unnecessary costs:

1. Deploy the infrastructure only when needed.
2. Run your tests and experiments.
3. Execute `terraform destroy` after each working session.
4. Check the GCP Billing dashboard regularly.
5. Configure a budget and billing alerts in Google Cloud.

**Note:** A budget alert only sends notifications when the configured thresholds are reached. It does not automatically stop resources or prevent additional charges.

Never assume that a successful deployment is free simply because the cluster is zonal.

## Deleting the infrastructure

To delete all resources managed by Terraform:

```bash
terraform destroy
```

Confirm the deletion by entering `yes`.

**Warning:** This command deletes the infrastructure managed by the current Terraform state. Review the proposed changes before confirming.

### Destroy verification

After running `terraform destroy`, the following observations were made:

- The project's pre-existing `default` VPC network remained.
- The custom `my-custom-vpc` network was successfully deleted.
- GCP does not allow a VPC network to be deleted while instances are still attached to it.

The successful deletion of the custom VPC is therefore consistent with the GKE cluster and its worker node having been removed during the Terraform destroy operation.

The remaining `default` network was not created or managed by this Terraform project.

## Design decisions

### 1. Custom VPC instead of automatic mode

```hcl
resource "google_compute_network" "vpc_network" {
  name                    = "my-custom-vpc"
  auto_create_subnetworks = false
}
```

I chose a custom VPC to have explicit control over the network architecture.

With automatic mode, Google Cloud creates subnets automatically across regions. Custom mode allows me to:

- Define IP address ranges manually.
- Choose the regions in which subnets are created.
- Avoid potential IP address overlaps when connecting different networks through VPN or VPC Peering.

For this personal project, avoiding IP overlaps is not an immediate requirement because the infrastructure is isolated within a single GCP project.

However, using a custom VPC reflects a common approach in real-world cloud architectures, where network addressing and connectivity need to be controlled explicitly.

### 2. GKE Standard instead of Autopilot

I chose GKE Standard because this project aims to demonstrate direct management of the Kubernetes infrastructure.

Standard mode allows me to:

- Create and manage node pools explicitly.
- Select the machine type.
- Configure the node Service Account.
- Choose between standard and interruptible virtual machines.
- Control node pool configuration and lifecycle.

With Autopilot, Google Cloud manages the underlying node infrastructure, including provisioning, scaling and many configuration aspects.

Autopilot would also be a valid alternative, especially for teams that want to focus on applications rather than infrastructure management.

However, Standard mode is more appropriate for this project because managing the worker nodes is one of its main learning objectives.

### 3. Zonal instead of regional cluster

```hcl
resource "google_container_cluster" "primary" {
  name     = "my-custom-gke-cluster"
  location = var.gcp_zone
}
```

I chose a zonal cluster because it is sufficient for a personal learning and testing environment.

The main reasons are:

- Lower infrastructure costs.
- A simpler architecture.
- A smaller number of worker nodes.
- Easier lifecycle management.

A regional cluster distributes its control plane across multiple zones to improve availability.

There is also an important difference in node pool sizing: for a regional cluster, `node_count` is applied per zone.

For example, configuring `node_count = 1` in a three-zone regional cluster generally results in three worker nodes rather than one.

GKE also provides a monthly management-fee credit for one eligible zonal or Autopilot cluster. This helps offset the control plane management fee, but does not cover the cost of worker nodes.

For this project, I deliberately prioritize lower costs over high availability.

**Trade-off:** A zonal cluster has a single-zone dependency. If the selected zone becomes unavailable, the cluster and its workloads can be affected.

### 4. Separate node pool and `remove_default_node_pool`

```hcl
remove_default_node_pool = true
initial_node_count       = 1
```

GKE normally creates a default node pool when a cluster is provisioned.

I chose to remove this initial pool and manage a dedicated node pool separately through Terraform.

The main reason is lifecycle management.

Managing the node pool as a separate Terraform resource provides an independent lifecycle. It allows node pool configuration to evolve separately from the cluster configuration.

For example, I can modify the node pool or add another one with a different machine type without managing those settings directly inside the cluster resource.

A separate node pool also allows me to explicitly configure a dedicated Service Account instead of relying on the default Compute Engine Service Account.

The default node pool could also be configured with a custom Service Account, but managing it separately makes this configuration explicit and independent.

The `initial_node_count = 1` argument is still required by the Terraform Google provider when `remove_default_node_pool = true`.

It defines the initial size used during cluster creation. The default node pool is then removed, and the separately managed node pool is created.

### 5. Preemptible nodes and their trade-offs

```hcl
node_config {
  preemptible  = true
  machine_type = "e2-small"
}
```

The node pool uses a single `e2-small` Preemptible virtual machine.

I started from an example that used Preemptible VMs and tested this configuration in my project.

Preemptible VMs allow infrastructure costs to be reduced in exchange for non-guaranteed availability.

However, they come with important limitations:

- Google Cloud can reclaim the VM when resources are needed elsewhere.
- A Preemptible VM has a maximum lifetime of 24 hours.
- Running Pods can be interrupted.
- Applications must tolerate node termination and rescheduling.
- Persistent data must be stored independently of the node.

**Trade-off:** Lower compute costs in exchange for reduced availability and a greater need for workload resilience.

Google now recommends using Spot VMs instead of Preemptible VMs for new workloads.

Spot VMs have similar pricing and interruption characteristics but do not have the 24-hour maximum lifetime.

GKE continues to support Preemptible VMs.

A possible alternative would be:

```hcl
node_config {
  spot         = true
  machine_type = "e2-small"
}
```

**Note:** This change has not been tested in this project. It would need to be validated with `terraform plan` before deployment.

Reference: [Google Cloud – Spot VMs in GKE](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/spot-vms).

### 6. Broad OAuth scope with minimal IAM permissions

```hcl
oauth_scopes = [
  "https://www.googleapis.com/auth/cloud-platform"
]
```

The nodes use the `cloud-platform` OAuth scope, which provides the broadest OAuth scope for Google Cloud API access.

However, OAuth scopes and IAM permissions are two different mechanisms.

- OAuth scopes define the API access ceiling for credentials obtained through the node.
- IAM roles define the permissions granted to the Service Account.

The effective permissions are the intersection of both mechanisms.

Since `cloud-platform` is a broad scope, it does not impose an additional meaningful restriction on API access. IAM is therefore the main permission control in this configuration.

I use a dedicated Service Account and assign the IAM roles required by the node configuration, following the principle of least privilege.

For production workloads, Workload Identity Federation for GKE should also be considered to provide individual Kubernetes workloads with their own Google Cloud identities. But for this project, no workload has been launched.

### 7. Oversized IP ranges and secondary ranges

```hcl
# Primary subnet range
ip_cidr_range = "10.0.1.0/24"

# Kubernetes Pods
ip_cidr_range = "10.4.0.0/14"

# Kubernetes Services
ip_cidr_range = "10.8.0.0/20"
```

GKE VPC-native clusters use secondary IP ranges to allocate IP addresses to Pods and Kubernetes Services.

These ranges provide dedicated address spaces within the VPC.

| Range | Purpose | CIDR size |
|---|---|---|
| `10.0.1.0/24` | Primary subnet range | /24 |
| `10.4.0.0/14` | Kubernetes Pods | /14 |
| `10.8.0.0/20` | Kubernetes Services | /20 |

The ranges were taken from an example and checked to ensure that they do not overlap with one another.

They are deliberately oversized compared with the requirements of the current single-node cluster.

For this isolated project, I accepted this oversizing because the selected ranges do not create an immediate addressing conflict.

In a production environment, the ranges should be dimensioned according to the actual number of nodes, Pods per node and Services.

### 8. `deletion_protection = false`

```hcl
deletion_protection = false
```

Cluster deletion protection is intentionally disabled.

This is a temporary learning environment that needs to be created and destroyed regularly.

Disabling deletion protection allows me to:

- Run `terraform destroy` without manually changing the cluster configuration.
- Recreate the infrastructure easily.
- Test different configurations.
- Keep the infrastructure lifecycle managed through Terraform.

For production environments, deletion protection should generally be enabled to reduce the risk of accidental cluster deletion.

### 9. Explicit IAM dependency with `depends_on`

```hcl
depends_on = [google_project_iam_member.gke_nodes_binding]
```

The node pool depends on a custom Service Account and its IAM permissions.

Terraform can infer the dependency between the node pool and the Service Account through the Service Account email reference.

However, it cannot automatically infer that the IAM binding must be created first.

The explicit `depends_on` ensures that Terraform creates the IAM binding before provisioning the node pool.

I added this dependency as a preventive measure to make the provisioning order explicit and avoid a potential race condition.

## Limitations and future improvements

This project is intentionally designed as a small, temporary learning environment. It is not a production-ready Kubernetes architecture.

The current limitations include:

| Area | Current implementation | Possible improvement |
|---|---|---|
| Availability | Zonal cluster | Regional cluster |
| Compute | One Preemptible node | Standard or Spot nodes, multiple pools |
| Networking | Public control plane endpoint | Private GKE cluster |
| Security | Node-level Service Account | Workload Identity Federation for GKE |
| Scaling | Fixed node count | Node pool autoscaling |
| Terraform state | Local state file | Remote state in a GCS bucket |
| Deletion protection | Disabled | Enabled for persistent environments |
| Monitoring | No dedicated monitoring configuration | Cloud Monitoring and alerting |

The control plane endpoint is public by default in this configuration. No private cluster or control plane access restrictions are configured.

The Preemptible node can also be interrupted.

The cluster was used for deployment and testing but was not intended to remain online continuously.

Finally, Terraform state is stored locally. For collaborative or long-lived environments, a remote GCS backend with appropriate access controls and state locking should be configured.

## Troubleshooting

The following section documents issues encountered during the project and the corresponding solutions.

### 1. `could not find default credentials`

**Problem:** Terraform could not find Application Default Credentials.

**Cause:** The Google Cloud CLI authentication and Terraform ADC authentication are separate.

**Solution:**

```bash
gcloud auth application-default login
```

### 2. `no active account selected`

**Problem:** Google Cloud CLI commands failed because no active account was selected.

**Solution:**

```bash
gcloud auth login
```

Check the active account:

```bash
gcloud auth list
```

### 3. `set-quota-project` configuration error

**Problem:** The `gcloud auth application-default set-quota-project` command failed with an error mentioning the `serviceusage.services.use` permission.

**Resolution:** The command succeeded after using the project ID instead of the displayed project name. The Google Cloud CLI had also been authenticated in the meantime, so the exact cause cannot be attributed to a single change.

The error message was misleading because it referred to a missing permission, while the project identifier had also been changed.

Use the actual GCP project ID:

```bash
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

The project ID and project display name are not necessarily the same.

### 4. Browser callback issues on WSL

**Problem:** The browser authentication callback through localhost did not work correctly in WSL.

**Solution:** Use the no-browser authentication flow:

```bash
gcloud auth login --no-launch-browser
```

For Terraform ADC:

```bash
gcloud auth application-default login --no-launch-browser
```

Follow the URL displayed in the terminal and complete authentication manually.

### 5. `gke-gcloud-auth-plugin` not found

**Problem:** `kubectl` could not authenticate to GKE because the required authentication plugin was missing.

**Solution:**

```bash
gcloud components install gke-gcloud-auth-plugin
```

Then retrieve the cluster credentials again:

```bash
gcloud container clusters get-credentials my-custom-gke-cluster \
  --zone europe-west6-b \
  --project YOUR_PROJECT_ID
```

### 6. Zone and region mismatch

**Problem:** During code review, before running `terraform plan`, an inconsistency was identified between the configured region and zone.

The initial configuration used a zone belonging to a different region.

**Resolution:** Ensure that the selected zone belongs to the configured region.

For this project:

```hcl
gcp_region = "europe-west6"
gcp_zone   = "europe-west6-b"
```

This inconsistency was caught during code review and was not an error reported by Terraform.

### 7. Zonal versus regional cluster configuration

**Problem:** During code review, before running `terraform plan`, the cluster configuration was identified as potentially regional because `var.gcp_region` was used instead of `var.gcp_zone` for its location.

A regional cluster would have resulted in three worker nodes with the intended three-zone configuration and `node_count = 1` per zone.

**Resolution:** Use the zone variable to explicitly configure a zonal cluster:

```hcl
resource "google_container_cluster" "primary" {
  name     = "my-custom-gke-cluster"
  location = var.gcp_zone
}
```

This was identified during code review, not through a Terraform plan or deployment error.

## References

- [Terraform Google Cloud Provider – Documentation](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Google Kubernetes Engine – Documentation](https://docs.cloud.google.com/kubernetes-engine/docs)
- [About GKE modes of operation](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/choose-cluster-mode)
- [Spot VMs in GKE](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/spot-vms)
- [Google Cloud IAM – Documentation](https://docs.cloud.google.com/iam/docs)
- [Google Cloud VPC – Documentation](https://docs.cloud.google.com/vpc/docs)

---

**Project built with Terraform and Google Cloud Platform.**