# Laboratório Network Security & Cloud Essentials
# Duas VMs Ubuntu 22.04 numa rede INTERNA do VirtualBox ("lab-net"), isolada do host e da LAN.
# O adaptador 1 (NAT) é só para apt e para o `vagrant ssh`; o IP do laboratório é
# configurado pelos scripts da Fase 1 (netplan), por isso auto_config: false.

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_check_update = false

  vms = {
    # O cliente vem primeiro: ele gera a chave SSH que o servidor autoriza no provisionamento.
    "cliente"  => { ip: "192.168.50.20", mac: "080027500020" },
    "servidor" => { ip: "192.168.50.10", mac: "080027500010" },
  }

  vms.each do |nome, o|
    config.vm.define nome do |vm|
      vm.vm.hostname = nome
      vm.vm.network "private_network", ip: o[:ip], mac: o[:mac],
                    virtualbox__intnet: "lab-net", auto_config: false
      vm.vm.provider "virtualbox" do |vb|
        vb.name = "lab-nsce-#{nome}"
        vb.memory = 1024
        vb.cpus = 1
        vb.linked_clone = true   # as VMs compartilham o disco base da box (economiza espaço)
      end
      vm.vm.provision "shell", path: "lab/provision.sh", args: [nome]
    end
  end
end
