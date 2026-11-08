#!/usr/bin/env bash
# Install the host prerequisites on RHEL 10: libvirt/KVM, Terraform and Ansible.
# Run as a regular user; sudo is used for the privileged steps.
set -euo pipefail

HASHICORP_REPO_URL="https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Run this script as a regular user, not as root." >&2
    exit 1
fi

echo "Installing libvirt, QEMU/KVM and Ansible..."
sudo dnf install -y libvirt qemu-kvm virt-install libvirt-client xorriso ansible-core

if ! command -v terraform >/dev/null 2>&1; then
    echo "Installing Terraform from the HashiCorp repository..."
    sudo curl -fsSL "${HASHICORP_REPO_URL}" -o /etc/yum.repos.d/hashicorp.repo
    sudo dnf install -y terraform
fi

echo "Enabling libvirt services..."
sudo systemctl enable --now virtqemud.socket virtnetworkd.socket virtstoraged.socket

if ! id -nG "${USER}" | grep -qw libvirt; then
    echo "Adding ${USER} to the libvirt group (log out and back in to apply)..."
    sudo usermod -aG libvirt "${USER}"
fi

echo "Done. Versions:"
terraform version | head -n 1
ansible --version | head -n 1
virsh --version
