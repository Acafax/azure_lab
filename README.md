# Azure LVM Lab

Small Terraform lab for Azure. It creates an Ubuntu VM, its network, and three managed disks. Azure Run Command configures LVM and runs a basic read/write test.

## What it creates

- Resource group, VNet, subnet, public IP, and SSH-only NSG
- Ubuntu 22.04 VM and three Standard LRS data disks
- LVM RAID 1 and three-disk striped volumes

## Run it

You need an Azure subscription with permission to create VM resources and run VM commands, an SSH key pair, Terraform, and Azure CLI. Azure Cloud Shell also works.

1. Authenticate and select the subscription:

   ```bash
   az login
   az account set --subscription "<subscription-id-or-name>"
   export ARM_SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
   ```

2. Create local configuration:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

   Set `ssh_public_key_path` to your public key and `allowed_ssh_cidr` to the public IP of the computer that will use SSH, for example `203.0.113.10/32`. Do not commit this file.

3. Deploy:

   ```bash
   terraform init
   terraform fmt -check -recursive
   terraform validate
   terraform plan
   terraform apply
   ```

The default VM size is `Standard_D2s_v5`. If Azure reports a quota or capacity error, choose an available VM size that supports at least three data disks and set `vm_size` in `terraform.tfvars`.

## Verify

LVM setup runs automatically through Azure Run Command. Terraform outputs the VM IP and a base SSH command. If needed, pass your private key with `ssh -i`.

On the VM, verify the volumes with:

```bash
sudo lvs -a -o +devices
findmnt /mnt/lvm/mirror /mnt/lvm/stripe
```

## Cleanup

The VM, disks, and public IP incur charges. Remove the lab when finished:

```bash
terraform destroy
```
