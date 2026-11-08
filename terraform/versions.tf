terraform {
  required_version = ">= 1.6"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.9"
    }
  }

  # The state lives outside the repository so it survives deleting and re-cloning it.
  # The path is passed by scripts/tf-init.sh.
  backend "local" {}
}
