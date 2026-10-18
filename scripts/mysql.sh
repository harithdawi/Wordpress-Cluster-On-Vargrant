#!/bin/bash

MASTER_IP="192.168.56.41"
HN=$(hostname)

mkdir -p /root/data /etc/my.cnf.d

# Install MySQL for both servers
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 >/dev/null 2>&1
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el9-3.noarch.rpm >/dev/null 2>&1
dnf install -y mysql-community-server >/dev/null 2>&1

if [[ "$HN" == *mysql01* ]]; then
    # --- SETUP MASTER ---
    
    # 1. Write config before starting service
    cat <<EOF > /etc/my.cnf.d/replication.cnf
[mysqld]
server-id=1
log_bin=mysql-bin
binlog_format=ROW
bind-address=0.0.0.0
EOF

    # 2. Start MySQL service
    systemctl enable --now mysqld
    sleep 10

    ROOT_PASS="$(openssl rand -base64 12)@1A"
    REPL_PASS="$(openssl rand -base64 12)@1A"
    WP_PASS="$(openssl rand -base64 12)@1A"

    TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}')
    mysql --connect-expired-password -u root -p"$TEMP_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS';" 2>/dev/null

    echo "$ROOT_PASS" > /root/data/mysql-root-password.txt
    echo "$REPL_PASS" > /root/data/mysql-replication-password.txt
    echo -e "DB_NAME=wordpress\nDB_USER=wpuser\nDB_PASS=$WP_PASS" > /root/data/wp-user-credentials.txt
    chmod 600 /root/data/*.txt

    mysql -u root -p"$ROOT_PASS" <<EOF
DROP USER IF EXISTS ''@'localhost';
DROP DATABASE IF EXISTS test;
CREATE USER IF NOT EXISTS 'repl'@'%' IDENTIFIED BY '$REPL_PASS';
GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO 'repl'@'%';
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'%' IDENTIFIED BY '$WP_PASS';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'%';
FLUSH PRIVILEGES;
EOF

    firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" port protocol="tcp" port="3306" accept' >/dev/null 2>&1
    firewall-cmd --reload >/dev/null 2>&1

elif [[ "$HN" == *mysql02* ]]; then
    # --- SETUP SLAVE ---
    ROOT_PASS=$(cat /root/data/mysql-root-password.txt)
    REPL_PASS=$(cat /root/data/mysql-replication-password.txt)

    # 1. Write configuration file BEFORE starting mysqld service
    cat <<EOF > /etc/my.cnf.d/z-replication.cnf
[mysqld]
server-id=2
relay_log=mysql-relay-bin
read_only=1
bind-address=0.0.0.0
EOF

    # 2. Start MySQL service with server-id=2 active from boot
    systemctl enable --now mysqld
    sleep 10

    TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}')
    mysql --connect-expired-password -u root -p"$TEMP_PASS" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS';" 2>/dev/null

    LOG_FILE=$(mysql -h $MASTER_IP -u repl -p"$REPL_PASS" -e "SHOW MASTER STATUS\G" 2>/dev/null | awk '/File:/ {print $2}')
    LOG_POS=$(mysql -h $MASTER_IP -u repl -p"$REPL_PASS" -e "SHOW MASTER STATUS\G" 2>/dev/null | awk '/Position:/ {print $2}')

    mysql -u root -p"$ROOT_PASS" <<EOF
SET GLOBAL server_id = 2;
STOP REPLICA;
RESET REPLICA ALL;
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='$MASTER_IP',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='$REPL_PASS',
  SOURCE_LOG_FILE='$LOG_FILE',
  SOURCE_LOG_POS=$LOG_POS,
  GET_SOURCE_PUBLIC_KEY=1;
START REPLICA;
EOF
fi