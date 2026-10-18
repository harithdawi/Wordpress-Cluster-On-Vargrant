# -*- mode: ruby -*-
# vi: set ft=ruby :

#  VIP : 192.168.56.111

Vagrant.configure("2") do |config|
  config.vm.box = "almalinux/9"
  config.vm.boot_timeout = 6000 #tunggu lama sikit

#mysql01 (master)
  config.vm.define "mysql01" do |node|
    node.vm.hostname = "mysql01"
    node.vm.network "private_network", ip: "192.168.56.41"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "1024"; vb.cpus = 2; end
	node.vm.provision "shell", path: "scripts/os.sh" 
	node.vm.provision "shell", path: "scripts/mysql.sh"
	node.vm.synced_folder "./data", "/root/data"
  end

#mysql02 (slave)
  config.vm.define "mysql02" do |node|
    node.vm.hostname = "mysql02"
    node.vm.network "private_network", ip: "192.168.56.42"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "1024"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh" 
	node.vm.provision "shell", path: "scripts/mysql.sh"
	node.vm.synced_folder "./data", "/root/data"
  end

#redis01
  config.vm.define "redis01" do |node|
    node.vm.hostname = "redis01"
    node.vm.network "private_network", ip: "192.168.56.30"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "512"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh"  
    node.vm.provision "shell", path: "scripts/redis.sh"
	node.vm.synced_folder "./data", "/root/data"
  end
  
#redis02
  config.vm.define "redis02" do |node|
    node.vm.hostname = "redis-passive"
    node.vm.network "private_network", ip: "192.168.56.31"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "512"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh"  
    node.vm.provision "shell", path: "scripts/redis.sh"
	node.vm.synced_folder "./data", "/root/data"
  end
  
#nginx01 (active)
  config.vm.define "nginx01" do |node|
    node.vm.hostname = "nginx01"
    node.vm.network "private_network", ip: "192.168.56.12"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "1024"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh",run: "once"
	node.vm.provision "shell", path: "scripts/hardening.sh",run: "once"
	node.vm.provision "shell", path: "scripts/nginx.sh",run: "once"
	node.vm.provision "shell", path: "scripts/nginx_sync.sh" #,run: "once"
	node.vm.provision "shell", path: "scripts/apps.sh"
	node.vm.synced_folder "./data", "/root/data" 
  end
  

#nginx02 (passive)
    config.vm.define "nginx02" do |node|
    node.vm.hostname = "nginx02"
    node.vm.network "private_network", ip: "192.168.56.13"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "1024"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh",run: "once"
	#node.vm.provision "shell", path: "scripts/hardening.sh",run: "once"
	node.vm.provision "shell", path: "scripts/nginx_sync.sh"  #,run: "once"
    node.vm.provision "shell", path: "scripts/nginx.sh"
	node.vm.synced_folder "./data", "/root/data"
  end

# haproxy01
  config.vm.define "haproxy01" do |node|
    node.vm.hostname = "haproxy01"
    node.vm.network "private_network", ip: "192.168.56.10"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "512"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh",run: "once"
	#node.vm.provision "shell", path: "scripts/hardening.sh",run: "once"
    node.vm.provision "shell", path: "scripts/haproxy.sh"
	node.vm.synced_folder "./data", "/root/data"
  end

# haproxy02
  config.vm.define "haproxy02" do |node|
    node.vm.hostname = "haproxy02"
    node.vm.network "private_network", ip: "192.168.56.11"
    node.vm.provider "virtualbox" do |vb|; vb.memory = "512"; vb.cpus = 1; end
	node.vm.provision "shell", path: "scripts/os.sh",run: "once"
	#node.vm.provision "shell", path: "scripts/hardening.sh",run: "once"
    node.vm.provision "shell", path: "scripts/haproxy.sh"
	node.vm.synced_folder "./data", "/root/data"
  end
end