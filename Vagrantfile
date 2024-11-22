# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.box = "gyptazy/ubuntu22.04-arm64"
  config.vm.network "forwarded_port", guest: 80, host: 80
  config.vm.network "private_network", ip: "192.168.57.10"

  config.vm.provision "shell", path: "provision.sh"


end
