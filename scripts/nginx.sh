#!/bin/bash

# 1. bersihkan cache & install pakej
dnf clean all
dnf install -y nginx php php-fpm php-cli php-mysqlnd php-common php-mbstring php-xml 

# 2. start service
systemctl enable --now php-fpm
systemctl enable --now nginx

# 3. tetapan selinux
setsebool -P httpd_can_network_connect 1
setsebool -P httpd_can_network_connect_db 1
setsebool -P httpd_enable_homedirs 1

# 4. install & setup firewall
dnf install -y firewalld
systemctl enable --now firewalld

firewall-cmd --permanent --add-service={ssh,http,https}
firewall-cmd --reload