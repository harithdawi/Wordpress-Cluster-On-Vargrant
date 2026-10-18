#!/bin/bash

REDIS_PASS="rediskucantik!2026"
MASTER_IP="192.168.56.30"
HN=$(hostname)

# 1. Install & Buka Port Firewall
dnf install -y redis
firewall-cmd --permanent --add-port=6379/tcp >/dev/null 2>&1
firewall-cmd --reload >/dev/null 2>&1

# 2. Settings Asas (Buka Akses & Set Password)
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
echo "requirepass $REDIS_PASS" >> /etc/redis/redis.conf

# 3. Tetapan Mengikut Hostname
if [[ "$HN" == *"redis01"* ]]; then
    echo "# Configured as Master" >> /etc/redis/redis.conf

elif [[ "$HN" == *"redis02"* ]]; then
    # Jika Slave, tambah setting sambungan ke Master
    echo "masterauth $REDIS_PASS" >> /etc/redis/redis.conf
    echo "replicaof $MASTER_IP 6379" >> /etc/redis/redis.conf
fi

# 4. On & Start Redis
systemctl enable --now redis
systemctl restart redis

# 5. Check Status
echo "--- Status Replication ($HN) ---"
REDISCLI_AUTH="$REDIS_PASS" redis-cli info replication | grep -E "role|master_host|master_link_status"