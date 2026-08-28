MASTER_IP = ENV.fetch("MASTER_IP", "192.168.60.10")
AGENT_IP = ENV.fetch("AGENT_IP", "192.168.60.11")
FLANNEL_IFACE = ENV.fetch("FLANNEL_IFACE", "enp0s8")

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.synced_folder ".", "/vagrant"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: MASTER_IP

    master.vm.provision "shell",
      path: "Scripts/install-master.sh",
      env: {
        "MASTER_IP" => MASTER_IP,
        "FLANNEL_IFACE" => FLANNEL_IFACE
      }
  end

  config.vm.define "agent" do |agent|
    agent.vm.hostname = "agent"
    agent.vm.network "private_network", ip: AGENT_IP

    agent.vm.provision "shell",
      path: "Scripts/install-agent.sh",
      env: {
        "MASTER_IP" => MASTER_IP,
        "AGENT_IP" => AGENT_IP,
        "FLANNEL_IFACE" => FLANNEL_IFACE
      }
  end
end
