#!/bin/bash

# 1. buat swap (2GB) jika belum ada
if ! swapon --show | grep -q '/swapfile'; then
    fallocate -l 2G /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null
    swapon /swapfile
    grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 2. set timezone & install utiliti asas
timedatectl set-timezone Asia/Kuala_Lumpur
dnf install -y epel-release
dnf install -y wget curl git net-tools vim openssl rsync

# 3. setup firewall & benarkan vrrp (keepalived) + ssh
dnf install -y firewalld
systemctl enable --now firewalld

firewall-cmd --permanent --add-protocol=vrrp
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# 4. tukar selinux ke permissive (runtime & kekal selepas reboot)
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config