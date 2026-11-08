# slurm-toy-cluster-IaC

Infrastructure as code for a toy Slurm cluster on KVM/QEMU.

- **Terraform** creates the infrastructure (network, disks and VMs).
- **Ansible** installs and configures the software (Slurm and dependencies).

## Cluster

| Node       | Role       | CPUs | RAM  | Disk  |
|------------|------------|------|------|-------|
| controller | controller | 2    | 4 GB | 50 GB |
| compute1   | compute    | 2    | 4 GB | 50 GB |
| compute2   | compute    | 2    | 4 GB | 50 GB |

- OS: RHEL 10.2 (installed from the ISO with kickstart).
- Static IPs on a dedicated libvirt network.
- Boots into `multi-user.target` by default; desktop is optional.

## Prerequisites

- A RHEL 10 host with hardware virtualization enabled.
- The RHEL 10.2 installation ISO at `/var/lib/libvirt/images/rhel-10.2-x86_64-dvd.iso`
  (override with the `ISO_PATH` environment variable).
- libvirt/KVM, Terraform and Ansible, and your user in the `libvirt` group.

To install the tools on RHEL:

```bash
./scripts/install-prereqs.sh
```

Log out and back in afterwards so the `libvirt` group membership takes effect.

- **The nodes must be registered with Red Hat** (`subscription-manager register`) before running the
  Ansible playbook. The playbook assumes the BaseOS and AppStream repositories are available on every node;
  it does not handle subscriptions.

## Accessing the nodes

Each VM has an administrator account created by cloud-init (`cloud-user` by default, see the `admin_user`
variable), with passwordless sudo and SSH key authentication only. The authorized key is read from
`ssh_public_key_path` (default `~/.ssh/toy-cluster.pub`):

```bash
ssh -i ~/.ssh/toy-cluster cloud-user@192.168.100.10   # controller
```

## VM template

The VMs are cloned from a template built once from the ISO with kickstart:

```bash
./scripts/build-template.sh
```

It is idempotent: if the template already exists, it does nothing.

## Terraform state

The Terraform state is stored **outside** the repository, at a fixed per-user path:

```
~/.local/share/slurm-toy/terraform.tfstate
```

This way, deleting and re-cloning the repository does not make Terraform forget the existing VMs.
Always initialize with the helper script instead of calling `terraform init` directly:

```bash
./scripts/tf-init.sh
```

To use another directory, set `SLURM_TOY_STATE_DIR` before running it.

## Status

Work in progress. This repository only provisions the infrastructure; any work built on top of it belongs in a separate repository.
