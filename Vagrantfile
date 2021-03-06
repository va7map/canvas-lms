# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "grahamb/ubuntu-trusty64-uid501"

  config.vm.network :private_network, ip: '192.168.50.50'
  config.vm.hostname = "canvas.dev"
  config.hostsupdater.aliases = ["files.canvas.dev"]

  config.vm.synced_folder ".", "/vagrant", type: :nfs

  config.vm.provider "virtualbox" do |v|
    host = RbConfig::CONFIG['host_os']

    # Give VM 1/4 system memory & access to all cpu cores on the host
    if host =~ /darwin/
      cpus = `sysctl -n hw.ncpu`.to_i
      # sysctl returns Bytes and we need to convert to MB
      # host_mem = `sysctl -n hw.memsize`.to_i / 1024 / 1024
    elsif host =~ /linux/
      cpus = `nproc`.to_i
      # meminfo shows KB and we need to convert to MB
      # host_mem = `grep 'MemTotal' /proc/meminfo | sed -e 's/MemTotal://' -e 's/ kB//'`.to_i / 1024
    else # sorry Windows folks, I can't help you
      cpus = 2
      mem = 2048
    end

    v.customize ["modifyvm", :id, "--memory", 4096]
    v.customize ["modifyvm", :id, "--cpus", cpus]
  end


  config.vm.provision "ansible" do |ansible|
    ansible.verbose  = "vvv"
    ansible.playbook = "provision/vagrant.yml"
  end

  config.vm.provision :shell, :inline => "sudo service canvas_init restart && sudo service apache2 restart", run: "always"

end
