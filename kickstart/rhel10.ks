# Unattended RHEL 10.2 install used to build the VM template.
# Packages are taken from the installation ISO (no subscription needed).
# The VM image is generic: cloud-init sets users, SSH keys, hostname and network on first boot.

text
cdrom
lang en_US.UTF-8
keyboard us
timezone UTC --utc
network --bootproto=dhcp --device=link --activate

# No password login: access is configured later through cloud-init.
rootpw --lock
selinux --enforcing
firewall --enabled --ssh
services --enabled=sshd,cloud-init-local,cloud-init,cloud-config,cloud-final,qemu-guest-agent,chronyd
skipx

# Single disk, plain partitions with the root partition last so it can be grown on clones.
zerombr
clearpart --all --initlabel
part biosboot --fstype=biosboot --size=1
part /boot --fstype=xfs --size=1024
part / --fstype=xfs --size=4096 --grow
bootloader --location=mbr --append="console=ttyS0,115200n8 console=tty0"

poweroff

%packages
@core
cloud-init
cloud-utils-growpart
qemu-guest-agent
openssh-server
chrony
-iwl*-firmware
%end

%post --erroronfail
# Make every clone unique: new machine-id, SSH host keys and cloud-init run.
rm -f /etc/ssh/ssh_host_*
truncate -s 0 /etc/machine-id
cloud-init clean --logs
%end
