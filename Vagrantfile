# -*- mode: ruby -*-
# vi: set ft=ruby :

sVUSER='vagrant'  # // vagrant user
sHOME="/home/#{sVUSER}"  # // home path for vagrant user
sNET='en0: Wi-Fi (Wireless)'  # // network adaptor to use for bridged mdoe
sIP_CLASS_D='192.168.10'  # // NETWORK CIDR for configs
sIP="#{sIP_CLASS_D}.190"

Vagrant.configure("2") do |config|
  
  config.vm.box = "debian/buster64"
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024  # // RAM / Memory
    v.cpus = 1  # // CPU Cores / Threads
  end

  config.vm.provision "shell", path: "1.install_commons.sh"

  # // Postgresql 1st node & Vault Dev Server 2nd node.
  (1..2).each do |iX|
    if iX == 1 then
      config.vm.define vm_name="postgresql" do |postgresql_node|
        postgresql_node.vm.hostname = vm_name
        postgresql_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sIP}"
        postgresql_node.vm.provision "file", source: "2.install_postgresql.sh", destination: "#{sHOME}/install_postgresql.sh"
        postgresql_node.vm.provision "shell", inline: "/bin/bash -c 'PG_IP_CIDR=#{sIP_CLASS_D}.0/0 #{sHOME}/install_postgresql.sh'"
      end
    end
    if iX == 2 then
      config.vm.define vm_name="vault#{iX-1}" do |vault_node|
        vault_node.vm.hostname = vm_name
        vault_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sIP_CLASS_D}.#{254-iX}"
        vault_node.vm.provision "file", source: "3.install_vault_postgresql.sh", destination: "#{sHOME}/install_vault_postgresql.sh"
        vault_node.vm.provision "shell", inline: "/bin/bash -c 'PG_FQDN=#{sIP} #{sHOME}/install_vault_postgresql.sh'"
      end
    end
  end

end
