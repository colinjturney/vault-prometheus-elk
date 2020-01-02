BOX_IMAGE = "bento/ubuntu-18.04"

Vagrant.configure("2") do |config|

  config.vm.define "vault-server" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "vault"
    subconfig.vm.network "private_network", ip: "10.0.0.10"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '512']
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-rsyslog-client.sh"
      s.args = ["10.0.0.15"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-vault.sh"
      s.args = ["10.0.0.10"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path =  "install-consul.sh"
      s.args = ["10.0.0.10", '"10.0.0.10","10.0.0.11","10.0.0.12","10.0.0.13"', 'dc1', 0, "false"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-telegraf.sh"
      s.args = ["dc1","vault-server"]
    end
  end

  config.vm.define "consul-1-server" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "consul-1"
    subconfig.vm.network "private_network", ip: "10.0.0.11"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '512']
    end
    subconfig.vm.provision "shell" do |s|
      s.path =  "install-consul.sh"
      s.args = ["10.0.0.11", '"10.0.0.10","10.0.0.11","10.0.0.12","10.0.0.13"', 'dc1', 3, "true"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-telegraf.sh"
      s.args = ["dc1","consul-server"]
    end
    subconfig.vm.network "forwarded_port", guest: 7500, host: 57500
  end

  config.vm.define "consul-2-server" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "consul-2"
    subconfig.vm.network "private_network", ip: "10.0.0.12"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '512']
    end
    subconfig.vm.provision "shell" do |s|
      s.path =  "install-consul.sh"
      s.args = ["10.0.0.12", '"10.0.0.10","10.0.0.11","10.0.0.12","10.0.0.13"', 'dc1', 0, "true"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-telegraf.sh"
      s.args = ["dc1","consul-server"]
    end
  end

  config.vm.define "consul-3-server" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "consul-3"
    subconfig.vm.network "private_network", ip: "10.0.0.13"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '512']
    end
    subconfig.vm.provision "shell" do |s|
      s.path =  "install-consul.sh"
      s.args = ["10.0.0.13", '"10.0.0.10","10.0.0.11","10.0.0.12","10.0.0.13"', 'dc1', 0, "true"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-telegraf.sh"
      s.args = ["dc1","consul-server"]
    end
  end

  config.vm.define "prometheus" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "prometheus"
    subconfig.vm.network "private_network", ip: "10.0.0.14"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '1024']
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-prometheus.sh"
      s.args = ['10.0.0.14']
    end
    subconfig.vm.provision "shell", path: "install-grafana.sh"
    subconfig.vm.provision "shell", path: "config-grafana.sh"
    subconfig.vm.network "forwarded_port", guest: 3000, host: 43000
    subconfig.vm.network "forwarded_port", guest: 9090, host: 49090
  end

  config.vm.define "elasticsearch" do |subconfig|
    subconfig.vm.box = BOX_IMAGE
    subconfig.vm.hostname = "elasticsearch"
    subconfig.vm.network "private_network", ip: "10.0.0.15"
    subconfig.vm.provider :virtualbox do |vb|
             vb.customize ['modifyvm', :id,'--memory', '2048']
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-elasticsearch.sh"
      s.args = ["10.0.0.15"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-kibana.sh"
      s.args = ["10.0.0.15"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-logstash.sh"
      s.args = ["10.0.0.15"]
    end
    subconfig.vm.provision "shell" do |s|
      s.path = "install-rsyslog-server.sh"
      s.args = ["10.0.0.15"]
    end
  end
end
