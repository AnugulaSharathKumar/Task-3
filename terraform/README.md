# GCP Terraform: Default VPC, Firewall, and Compute Engine (Ubuntu 22.04)
This Terraform configuration creates:
- Uses the project's default VPC (`default`) and the default subnet in `asia-south1`
- A firewall rule allowing internal traffic within the subnet
- A firewall rule allowing SSH (port 22) to instances tagged `ssh`
- A VM `private-vm` in zone `asia-south1-a` running Ubuntu 22.04 with an external IP for SSH access
Quick start::
1. Install Terraform 1.0+
2. Authenticate: `gcloud auth application-default login` or set service account credentials
3. From this folder run:
```bash
terraform init
terraform apply -var 'project_id=project-3e800f45-77e7-454a-a2b' -auto-approve
```
Notes:
- To add SSH keys, pass `-var "ssh_keys=user:ssh-rsa AAAA..."` to `terraform apply`.
- The VM will have an external IP so you can SSH to it directly. The firewall only allows SSH to instances with the `ssh` tag.
- If you prefer a private-only VM keep `access_config {}` removed from the `network_interface` and use Cloud NAT / bastion host instead.
 - To add SSH keys, pass `-var "ssh_keys=user:ssh-rsa AAAA..."` to `terraform apply`.
 - The VM runs Ubuntu 22.04 LTS. It will have an external IP so you can SSH to it directly; the firewall only allows SSH to instances with the `ssh` tag.
 - If you prefer a private-only VM, remove `access_config {}` from the `network_interface` and use Cloud NAT or a bastion host instead.

Runner setup:
- This instance will install `nginx` and a GitHub Actions self-hosted runner at first boot using the `startup-script` metadata.
- The runner is configured with the name `private-vm` and is managed by a systemd unit `github-runner.service` which is `BindsTo=nginx.service`. When `nginx` stops, the runner service will stop as well; when `nginx` is running the runner is started.
- You must provide two variables when applying:
	- `-var 'github_owner_repo=OWNER/REPO'` (e.g. `my-org/my-repo`)
	- `-var 'github_runner_token=REG_TOKEN'` (a registration token from GitHub; expires after a short time)

Example apply with runner variables:

```bash
terraform init
terraform apply -var 'project_id=project-3e800f45-77e7-454a-a2b' \
	-var 'github_owner_repo=my-org/my-repo' \
	-var 'github_runner_token=PASTE_TOKEN_HERE' -auto-approve
```

Security note:
- The registration token is sensitive and is stored only in instance metadata during provisioning; rotate/revoke as needed.
