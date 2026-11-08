locals {
  ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  prefix_length  = length(regexall("1", join("", [for o in split(".", var.network_netmask) : format("%08b", tonumber(o))])))
}

# Builds the template from the ISO if it does not exist yet (no-op otherwise).
resource "terraform_data" "template" {
  triggers_replace = [var.pool_name, var.pool_dir, var.template_name, var.iso_path]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/build-template.sh"
    environment = {
      ISO_PATH      = var.iso_path
      POOL_NAME     = var.pool_name
      POOL_DIR      = var.pool_dir
      TEMPLATE_NAME = var.template_name
    }
  }
}

# Each disk is a copy-on-write clone of the template.
resource "libvirt_volume" "disk" {
  for_each = var.nodes

  name          = "${each.key}.qcow2"
  pool          = var.pool_name
  capacity      = each.value.disk_gb
  capacity_unit = "GiB"

  backing_store = {
    path   = "${var.pool_dir}/${var.template_name}"
    format = { type = "qcow2" }
  }

  target = {
    format = { type = "qcow2" }
  }

  depends_on = [terraform_data.template]
}

resource "libvirt_cloudinit_disk" "init" {
  for_each = var.nodes

  name = "${each.key}-cloudinit"

  user_data = <<-EOT
    #cloud-config
    hostname: ${each.key}
    fqdn: ${each.key}.${var.network_name}
    manage_etc_hosts: true
    users:
      - name: ${var.admin_user}
        sudo: ALL=(ALL) NOPASSWD:ALL
        shell: /bin/bash
        lock_passwd: true
        ssh_authorized_keys:
          - ${local.ssh_public_key}
  EOT

  meta_data = <<-EOT
    instance-id: ${each.key}
    local-hostname: ${each.key}
  EOT

  network_config = <<-EOT
    version: 2
    ethernets:
      nic0:
        match:
          macaddress: "${each.value.mac}"
        set-name: eth0
        addresses:
          - ${each.value.ip}/${local.prefix_length}
        routes:
          - to: default
            via: ${var.network_gateway}
        nameservers:
          addresses:
            - ${var.network_gateway}
  EOT
}

# The cloud-init ISO is uploaded into the pool so libvirt can attach it.
resource "libvirt_volume" "init" {
  for_each = var.nodes

  name = "${each.key}-cloudinit.iso"
  pool = var.pool_name

  create = {
    content = {
      url = libvirt_cloudinit_disk.init[each.key].path
    }
  }
}

resource "libvirt_domain" "node" {
  for_each = var.nodes

  name        = each.key
  type        = "kvm"
  memory      = each.value.memory
  memory_unit = "MiB"
  vcpu        = each.value.vcpus
  running     = true
  autostart   = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    boot_devices = [{ dev = "hd" }]
  }

  devices = {
    disks = [
      {
        driver = { type = "qcow2" }
        source = { volume = { pool = var.pool_name, volume = libvirt_volume.disk[each.key].name } }
        target = { dev = "vda", bus = "virtio" }
      },
      {
        device = "cdrom"
        driver = { type = "raw" }
        source = { volume = { pool = var.pool_name, volume = libvirt_volume.init[each.key].name } }
        target = { dev = "sda", bus = "sata" }
      },
    ]

    interfaces = [{
      type   = "network"
      model  = { type = "virtio" }
      mac    = { address = each.value.mac }
      source = { network = { network = libvirt_network.cluster.name } }
    }]

    consoles = [{
      target = { type = "serial", port = 0 }
    }]
  }
}
