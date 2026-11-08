variable "libvirt_uri" {
  description = "Libvirt connection URI."
  type        = string
  default     = "qemu:///system"
}

variable "network_name" {
  description = "Name of the libvirt network used by the cluster."
  type        = string
  default     = "slurm-toy"
}

variable "network_gateway" {
  description = "Gateway address of the cluster network (the host side of the NAT bridge)."
  type        = string
  default     = "192.168.100.1"
}

variable "network_netmask" {
  description = "Netmask of the cluster network."
  type        = string
  default     = "255.255.255.0"
}

variable "nodes" {
  description = "Cluster nodes with their fixed IP and MAC address, and their resources."
  type = map(object({
    role    = string
    ip      = string
    mac     = string
    vcpus   = optional(number, 2)
    memory  = optional(number, 4096) # MiB
    disk_gb = optional(number, 50)
  }))
  default = {
    controller = {
      role = "controller"
      ip   = "192.168.100.10"
      mac  = "52:54:00:10:00:10"
    }
    compute1 = {
      role = "compute"
      ip   = "192.168.100.11"
      mac  = "52:54:00:10:00:11"
    }
    compute2 = {
      role = "compute"
      ip   = "192.168.100.12"
      mac  = "52:54:00:10:00:12"
    }
  }

  validation {
    condition     = alltrue([for n in values(var.nodes) : contains(["controller", "compute"], n.role)])
    error_message = "Each node role must be either \"controller\" or \"compute\"."
  }

  validation {
    condition     = length([for n in values(var.nodes) : n if n.role == "controller"]) == 1
    error_message = "Exactly one node must have the \"controller\" role."
  }
}

variable "pool_name" {
  description = "Libvirt storage pool holding the template and the VM disks. Created by scripts/build-template.sh."
  type        = string
  default     = "slurm-toy"
}

variable "pool_dir" {
  description = "Directory backing the storage pool; VM disks live here."
  type        = string
  default     = "/home/vms/slurm-toy"
}

variable "template_name" {
  description = "File name of the VM template inside the pool directory."
  type        = string
  default     = "rhel-10.2-template.qcow2"
}

variable "iso_path" {
  description = "RHEL 10.2 installation ISO used to build the template."
  type        = string
  default     = "/var/lib/libvirt/images/rhel-10.2-x86_64-dvd.iso"
}

variable "admin_user" {
  description = "Administrator account created on every VM by cloud-init (passwordless sudo, SSH key only)."
  type        = string
  default     = "cloud-user"
}

variable "ssh_public_key_path" {
  description = "Public SSH key authorized for the administrator account."
  type        = string
  default     = "~/.ssh/toy-cluster.pub"
}

variable "vm_name_prefix" {
  description = "Prefix for the libvirt domain names, to avoid clashing with other VMs on the host."
  type        = string
  default     = "slurm-"
}
