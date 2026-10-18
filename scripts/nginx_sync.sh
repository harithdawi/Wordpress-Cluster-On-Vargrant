#!/bin/bash

REMOTE_IP="192.168.56.13"
SSH_KEY="/root/data/sync_key"
DIR="/usr/share/nginx/html/"

if [[ "$(hostname)" == *nginx01* ]]; then
    dnf install -y rsync openssh-clients lsyncd
    mkdir -p /var/log/lsyncd $(dirname "$SSH_KEY")
    
    [ -f "$SSH_KEY" ] || ssh-keygen -t ed25519 -N "" -f "$SSH_KEY"

    cat <<EOF > /etc/lsyncd.conf
settings { logfile = "/var/log/lsyncd/lsyncd.log", statusFile = "/var/log/lsyncd/lsyncd.status", insist = true }
sync {
    default.rsync,
    source = "$DIR",
    target = "root@$REMOTE_IP:$DIR",
    delay = 2,
    delete = true,
    rsync = { archive = true, compress = true, rsh = "/usr/bin/ssh -i $SSH_KEY -o BatchMode=yes -o StrictHostKeyChecking=no" }
}
EOF
    systemctl enable --now lsyncd

elif [[ "$(hostname)" == *nginx02* ]]; then
    install -d -m 700 /root/.ssh
    [ -f "${SSH_KEY}.pub" ] && cat "${SSH_KEY}.pub" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi