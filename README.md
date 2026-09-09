# Azure LVM Lab

Terraform portfolio project that provisions an Ubuntu VM, its network, and three managed data disks in Azure. Azure Run Command then configures LVM volumes and performs a basic read/write test without SSH provisioning.

## Scope

- Resource group, VNet, subnet, static public IP, and NSG
- Ubuntu 22.04 VM with SSH password authentication disabled
- Three Standard LRS managed disks attached to the VM
- LVM RAID 1 volume and a three-disk striped volume
- Azure Run Command executes `scripts/setup_lvm.sh` after the disks are attached

## Requirements

- An Azure subscription with permission to create the listed resources and run VM commands
- Available VM quota and capacity for the chosen `vm_size` in the selected `location`
- Terraform 1.0 or later and Azure CLI, or Azure Cloud Shell
- An SSH key pair

The AzureRM 4.x provider requires the subscription ID during `plan` and `apply`. Authenticate with Azure CLI and export the active subscription ID as `ARM_SUBSCRIPTION_ID` before running Terraform. In Cloud Shell, use the same steps; no separate local installation is needed.

## Deploy

1. Clone the repository, authenticate Azure CLI, and select the target subscription:

   ```bash
   az login
   az account set --subscription "<subscription-id-or-name>"
   export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
   ```

2. Create the local variables file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Set `ssh_public_key_path` to the public part of your SSH key and `allowed_ssh_cidr` to the public IP address of the computer that will connect to the VM, for example `203.0.113.10/32`. Do not commit this file.

3. Initialize, validate, review, and apply the plan:

   ```bash
   terraform init
   terraform fmt -check -recursive
   terraform validate
   terraform plan
   terraform apply
   ```

The default VM size is `Standard_D2s_v5`, which supports three data disks. If Azure reports quota or capacity errors, choose another available VM SKU that supports at least three data disks and set it in `terraform.tfvars`.

## Verify

Terraform outputs the resource group, public IP, and a base SSH command. If your private key is not loaded in SSH agent, include its path with `ssh -i` when connecting. Azure Run Command performs the LVM setup automatically; it does not require an SSH connection from Cloud Shell.

On the VM, verify the volumes with:

```bash
sudo lvs -a -o +devices
findmnt /mnt/lvm/mirror /mnt/lvm/stripe
```

## Cleanup

The VM, disks, and public IP incur Azure charges. Remove the lab when testing is complete:

```bash
terraform destroy
```
