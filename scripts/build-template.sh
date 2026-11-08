#!/usr/bin/env bash
# Build the RHEL 10.2 VM template from the installation ISO using kickstart.
# Idempotent: does nothing if the template already exists.
#
# Environment overrides:
#   ISO_PATH       installation ISO
#   POOL_NAME      libvirt storage pool that holds the template and the VM disks
#   POOL_DIR       directory backing the pool
#   TEMPLATE_NAME  template file name inside the pool directory
#   DISK_SIZE_GB   template disk size
set -euo pipefail

ISO_PATH="${ISO_PATH:-/var/lib/libvirt/images/rhel-10.2-x86_64-dvd.iso}"
POOL_NAME="${POOL_NAME:-slurm-toy}"
POOL_DIR="${POOL_DIR:-/home/vms/slurm-toy}"
TEMPLATE_NAME="${TEMPLATE_NAME:-rhel-10.2-template.qcow2}"
DISK_SIZE_GB="${DISK_SIZE_GB:-50}"

LIBVIRT_URI="qemu:///system"
BUILD_DOMAIN="slurm-toy-template-build"
KICKSTART="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/kickstart/rhel10.ks"
TEMPLATE_PATH="${POOL_DIR}/${TEMPLATE_NAME}"

virsh_cmd() { virsh -c "${LIBVIRT_URI}" "$@"; }

[[ -r "${ISO_PATH}" ]] || { echo "ISO not readable: ${ISO_PATH}" >&2; exit 1; }
[[ -r "${KICKSTART}" ]] || { echo "Kickstart not found: ${KICKSTART}" >&2; exit 1; }

# Ensure the storage pool exists and is running.
if ! virsh_cmd pool-info "${POOL_NAME}" >/dev/null 2>&1; then
    virsh_cmd pool-define-as "${POOL_NAME}" dir --target "${POOL_DIR}"
    virsh_cmd pool-build "${POOL_NAME}"
    virsh_cmd pool-autostart "${POOL_NAME}"
fi
if [[ "$(virsh_cmd pool-info "${POOL_NAME}" | awk '/^State:/ {print $2}')" != "running" ]]; then
    virsh_cmd pool-start "${POOL_NAME}"
fi

if virsh_cmd vol-info --pool "${POOL_NAME}" "${TEMPLATE_NAME}" >/dev/null 2>&1; then
    echo "Template already exists: ${TEMPLATE_PATH}"
    exit 0
fi

echo "Building template ${TEMPLATE_PATH} (this takes several minutes)..."
virt-install \
    --connect "${LIBVIRT_URI}" \
    --name "${BUILD_DOMAIN}" \
    --os-variant rhel10.2 \
    --vcpus 2 \
    --memory 4096 \
    --disk "path=${TEMPLATE_PATH},size=${DISK_SIZE_GB},format=qcow2" \
    --network none \
    --graphics none \
    --location "${ISO_PATH}" \
    --initrd-inject "${KICKSTART}" \
    --extra-args "inst.ks=file:/$(basename "${KICKSTART}") inst.text console=ttyS0,115200n8" \
    --noreboot \
    --noautoconsole \
    --wait

# The installer powers the VM off when done; drop the build domain and keep the disk.
virsh_cmd undefine "${BUILD_DOMAIN}"
echo "Template ready: ${TEMPLATE_PATH}"
