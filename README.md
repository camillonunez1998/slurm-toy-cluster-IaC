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

## Status

Work in progress. This repository only provisions the infrastructure; any work built on top of it belongs in a separate repository.
