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

## VM template

The VMs are cloned from a template built once from the ISO with kickstart:

```bash
./scripts/build-template.sh
```

It is idempotent: if the template already exists, it does nothing.

## Status

Work in progress. This repository only provisions the infrastructure; any work built on top of it belongs in a separate repository.
