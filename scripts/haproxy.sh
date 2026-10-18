#!/bin/bash

HN=$(hostname)
VIP="192.168.56.111"
INTERFACE="eth1"     

# IP Node
IP_HAPROXY1="192.168.56.10"
IP_HAPROXY2="192.168.56.11"

dnf install -y haproxy keepalived firewalld


cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000ms
    timeout client  50000ms
    timeout server  50000ms

frontend http_in
    bind *:80
    mode http
    default_backend web_servers

backend web_servers
    mode http
    balance roundrobin
    option httpchk GET /
    server nginx1 192.168.56.12:80 check
    server nginx2 192.168.56.13:80 check backup
EOF


if [[ "$HN" == *"haproxy01"* ]]; then
    # Config untuk Master
    cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state MASTER
    interface $INTERFACE
    virtual_router_id 51
    priority 100
    advert_int 1
	
	
	unicast_src_ip $IP_HAPROXY1
    unicast_peer {
        $IP_HAPROXY2
    }
	
    authentication {
        auth_type PASS
        auth_pass 1234yahoo
    }
    virtual_ipaddress {
        $VIP
    }
}
EOF

elif [[ "$HN" == *"haproxy02"* ]]; then
    # Config untuk Backup
    cat <<EOF > /etc/keepalived/keepalived.conf
vrrp_instance VI_1 {
    state BACKUP
    interface $INTERFACE
    virtual_router_id 51
    priority 90
    advert_int 1
	
	unicast_src_ip $IP_HAPROXY2
    unicast_peer {
        $IP_HAPROXY1
    }
	
    authentication {
        auth_type PASS
        auth_pass 1234yahoo
    }
    virtual_ipaddress {
        $VIP
    }
}
EOF
fi


systemctl enable --now haproxy keepalived firewalld

firewall-cmd --permanent --add-service={ssh,http,https}
firewall-cmd --permanent --add-protocol=vrrp
firewall-cmd --reload