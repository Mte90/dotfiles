---
name: vagrant
description: Comprehensive guide for developing with Vagrant, including Vagrantfile configuration, custom boxes, providers (VirtualBox, VMware, Hyper-V, libvirt, AWS), provisioners (Ansible, Chef, Puppet), multi-machine setups, networking, synced folders, plugins, and troubleshooting.
metadata:
  author: OSS AI Skills
  version: 1.0.0
  tags:
    - vagrant
    - virtualization
    - devops
    - development-environment
    - virtualbox
    - infrastructure
    - ansible
---

# Vagrant Development

Complete guide for managing virtual machine environments with Vagrant.

## Overview

Vagrant is a tool for building and managing virtual machine environments in a single, consistent workflow.

**Key Characteristics:**
- Reproducible environments
- Multiple providers (VirtualBox, VMware, Docker)
- Provisioners (Shell, Ansible, Chef, Puppet)
- Multi-machine support
- Portable boxes

## Installation

### Install Vagrant

```bash
# macOS (Homebrew)
brew install hashicorp/tap/hashicorp-vagrant

# Ubuntu/Debian
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vagrant

# Windows (Chocolatey)
choco install vagrant

# Or download from https://www.vagrantup.com/downloads
```

### Install Provider

```bash
# VirtualBox (most common)
# macOS: brew install --cask virtualbox
# Ubuntu: sudo apt install virtualbox
# Windows: choco install virtualbox

# VMware (requires license)
vagrant plugin install vagrant-vmware-desktop

# Hyper-V (Windows only)
# Enable in Windows Features

# libvirt (Linux)
vagrant plugin install vagrant-libvirt
```

## Basic Vagrantfile

### Minimal Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.hostname = "myvm"
  
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end
end
```

### Complete Configuration

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  # Base box
  config.vm.box = "ubuntu/focal64"
  config.vm.box_version = ">= 202310.0.0"
  config.vm.hostname = "dev-environment"
  
  # Network configuration
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 8443
  
  # Synced folders
  config.vm.synced_folder "./app", "/var/www/html"
  config.vm.synced_folder "./data", "/data", disabled: false
  
  # VirtualBox provider
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
    vb.cpus = 2
    vb.name = "my-dev-vm"
    vb.gui = false
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
  end
  
  # Shell provisioner
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y apache2 mysql-server php
  SHELL
  
  # Ansible provisioner
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
    ansible.become = true
  end
end
```

## Common Commands

```bash
# Create Vagrantfile
vagrant init ubuntu/focal64

# Start VM
vagrant up

# SSH into VM
vagrant ssh

# Stop VM
vagrant halt

# Restart VM
vagrant reload

# Destroy VM
vagrant destroy

# Suspend VM
vagrant suspend

# Resume VM
vagrant resume

# Status
vagrant status

# Global status
vagrant global-status

# Box management
vagrant box list
vagrant box add ubuntu/focal64
vagrant box remove ubuntu/focal64
vagrant box update
vagrant box outdated

# Plugin management
vagrant plugin list
vagrant plugin install vagrant-vbguest
vagrant plugin uninstall vagrant-vbguest

# Validate Vagrantfile
vagrant validate

# SSH config
vagrant ssh-config

# Package box
vagrant package --output my-custom.box
```

## Providers

### VirtualBox Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  
  config.vm.provider "virtualbox" do |vb|
    # Basic settings
    vb.name = "my-vm"
    vb.gui = false
    vb.memory = 4096
    vb.cpus = 2
    
    # Advanced settings
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--pae", "on"]
    
    # Video settings
    vb.customize ["modifyvm", :id, "--vram", "128"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
    
    # Storage
    vb.customize ["storagectl", :id, "--name", "SATA Controller", "--ahci", "on"]
    
    # Network
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    
    # Clipboard
    vb.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    vb.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
  end
end
```

### VMware Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  
  config.vm.provider "vmware_fusion" do |vmw|  # macOS
    vmw.vmx["memsize"] = "4096"
    vmw.vmx["numvcpus"] = "4"
    vmw.vmx["vhv.enable"] = "TRUE"
    vmw.linked_clone = true
    vmw.gui = false
  end
  
  config.vm.provider "vmware_workstation" do |vmw|  # Linux/Windows
    vmw.vmx["memsize"] = "4096"
    vmw.vmx["numvcpus"] = "4"
  end
end
```

### Hyper-V Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "microsoft/windows-server-2022"
  
  config.vm.provider "hyperv" do |hv|
    hv.memory = 4096
    hv.maxmemory = 8192
    hv.cpus = 2
    hv.enable_virtualization_extensions = true
    hv.enable_checkpoints = true
    hv.vmname = "dev-vm"
    hv.vlan_id = 100
    hv.ip_address_timeout = 180
  end
end
```

### libvirt Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  
  config.vm.provider :libvirt do |libvirt|
    libvirt.cpus = 4
    libvirt.memory = 4096
    libvirt.driver = "kvm"
    libvirt.cpu_mode = "host-passthrough"
    libvirt.disk_bus = "virtio"
    libvirt.disk_driver :cache => "none", :io => "native"
    libvirt.video_type = "qxl"
    libvirt.video_vram = "128"
    libvirt.interface_type = "bridge"
    libvirt.interface_source = "br0"
  end
end
```

### AWS Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "aws"
  
  config.vm.provider :aws do |aws, override|
    override.ssh.username = "ec2-user"
    override.ssh.private_key_path = "~/.ssh/my-key.pem"
    
    aws.access_key_id = ENV['AWS_ACCESS_KEY_ID']
    aws.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
    aws.region = "us-east-1"
    aws.ami = "ami-0c55b159cbfafe1f0"
    aws.instance_type = "t3.medium"
    aws.keypair_name = "my-key"
    aws.security_groups = ["default"]
    
    aws.tags = {
      'Name' => 'vagrant-dev',
      'Environment' => 'development'
    }
    
    aws.block_device_mappings = [{
      device_name: '/dev/sda1',
      ebs: {
        volume_size: 50,
        volume_type: 'gp3',
        delete_on_termination: true
      }
    }]
  end
end
```

### DigitalOcean Provider

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "digitalocean"
  
  config.vm.provider :digital_ocean do |provider|
    provider.access_token = ENV['DIGITALOCEAN_ACCESS_TOKEN']
    provider.ssh_key_id = "12345678"
    provider.image = "ubuntu-22-04-x64"
    provider.size = "s-2vcpu-4gb"
    provider.region = "nyc3"
    provider.ssh_username = "root"
    provider.private_networking = true
    provider.tags = ["vagrant", "development"]
  end
end
```

## Provisioning

### Shell Provisioner

```ruby
Vagrant.configure("2") do |config|
  # Inline script
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update
    apt-get install -y nginx
  SHELL
  
  # External script
  config.vm.provision "shell", path: "scripts/setup.sh"
  
  # With arguments
  config.vm.provision "shell", path: "scripts/setup.sh",
    args: ["--verbose", "--env", "development"]
  
  # With environment variables
  config.vm.provision "shell", path: "scripts/setup.sh",
    env: {
      "APP_ENV" => "development",
      "DB_HOST" => "localhost"
    }
  
  # Run as non-root
  config.vm.provision "shell", path: "scripts/setup.sh",
    privileged: false
  
  # Run on specific machine
  config.vm.define "web" do |web|
    web.vm.provision "shell", inline: "echo 'Web server'"
  end
end
```

### Ansible Provisioner

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "provisioning/playbook.yml"
    ansible.inventory_path = "provisioning/inventory"
    ansible.verbose = "v"
    ansible.become = true
    
    # Extra variables
    ansible.extra_vars = {
      http_port: 80,
      db_host: "localhost"
    }
    
    # Tags
    ansible.tags = ["web", "nginx"]
    ansible.skip_tags = ["db"]
    
    # Vault
    ansible.vault_password_file = "~/.vault_pass"
    
    # Roles path
    ansible.roles_path = "provisioning/roles"
    ansible.galaxy_role_file = "provisioning/requirements.yml"
  end
end
```

### Ansible Local (runs on guest)

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "ansible_local" do |ansible|
    ansible.playbook = "playbook.yml"
    ansible.install_mode = "pip"
    ansible.version = "2.14.0"
    ansible.verbose = "v"
    ansible.become = true
    
    ansible.galaxy_file = "requirements.yml"
    ansible.galaxy_roles_path = "roles"
  end
end
```

### Chef Provisioner

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "chef_solo" do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.roles_path = "roles"
    
    chef.add_recipe "webserver::default"
    chef.add_recipe "database::default"
    
    chef.json = {
      webserver: {
        port: 80,
        docroot: "/var/www/html"
      }
    }
  end
end
```

### Puppet Provisioner

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "puppet_apply" do |puppet|
    puppet.manifests_path = "manifests"
    puppet.manifest_file = "site.pp"
    puppet.module_path = "modules"
    
    puppet.facter = {
      "environment" => "development",
      "server_role" => "web"
    }
    
    puppet.options = ["--verbose", "--debug"]
  end
end
```

### Docker Provisioner

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision "docker" do |d|
    # Pull images
    d.pull_images "nginx:latest"
    d.pull_images "postgres:14"
    
    # Run containers
    d.run "nginx",
      image: "nginx:latest",
      args: "-p 80:80 -v /vagrant/nginx.conf:/etc/nginx/nginx.conf"
    
    d.run "postgres",
      image: "postgres:14",
      args: "-e POSTGRES_PASSWORD=secret -p 5432:5432"
  end
end
```

## Multi-Machine Setup

### Basic Multi-Machine

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  
  config.vm.define "web" do |web|
    web.vm.hostname = "web"
    web.vm.network "private_network", ip: "192.168.33.10"
    web.vm.network "forwarded_port", guest: 80, host: 8080
    
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "2048"
    end
    
    web.vm.provision "shell", inline: "apt-get install -y nginx"
  end
  
  config.vm.define "db" do |db|
    db.vm.hostname = "db"
    db.vm.network "private_network", ip: "192.168.33.20"
    
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
    end
    
    db.vm.provision "shell", inline: "apt-get install -y postgresql"
  end
end
```

### Complex Multi-Machine with Dependencies

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  
  # Primary machine (default)
  config.vm.define "loadbalancer", primary: true do |lb|
    lb.vm.hostname = "lb"
    lb.vm.network "private_network", ip: "192.168.33.10"
    lb.vm.network "forwarded_port", guest: 80, host: 8080
    
    lb.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
    end
    
    lb.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y haproxy
    SHELL
  end
  
  # Web servers
  (1..3).each do |i|
    config.vm.define "web#{i}" do |web|
      web.vm.hostname = "web#{i}"
      web.vm.network "private_network", ip: "192.168.33.#{20 + i}"
      
      web.vm.provider "virtualbox" do |vb|
        vb.memory = "2048"
      end
      
      web.vm.provision "shell", inline: <<-SHELL
        apt-get update
        apt-get install -y nginx
        echo "Web Server #{i}" > /var/www/html/index.html
      SHELL
      
      # Only start after loadbalancer
      web.vm.provision "shell", run: "never" do |s|
        s.inline = "echo 'Web#{i} ready'"
      end
    end
  end
  
  # Database
  config.vm.define "database" do |db|
    db.vm.hostname = "db"
    db.vm.network "private_network", ip: "192.168.33.50"
    
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
    end
    
    db.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y postgresql
      systemctl start postgresql
    SHELL
  end
end
```

### Control Commands

```bash
# Start all machines
vagrant up

# Start specific machine
vagrant up web

# Start multiple machines
vagrant up web db

# SSH to specific machine
vagrant ssh web

# Provision specific machine
vagrant provision web

# Reload specific machine
vagrant reload web

# Destroy specific machine
vagrant destroy web
```

## Networking

### Private Networks

```ruby
Vagrant.configure("2") do |config|
  # Static IP
  config.vm.network "private_network", ip: "192.168.33.10"
  
  # With netmask
  config.vm.network "private_network", 
    ip: "192.168.33.10",
    netmask: "255.255.255.0"
  
  # DHCP
  config.vm.network "private_network", type: "dhcp"
  
  # Internal network (isolated)
  config.vm.network "private_network",
    ip: "10.0.0.10",
    virtualbox__intnet: "internal_network"
end
```

### Public Networks (Bridged)

```ruby
Vagrant.configure("2") do |config|
  # Bridge to specific interface
  config.vm.network "public_network",
    bridge: "en0: Wi-Fi (AirPort)"
  
  # With static IP
  config.vm.network "public_network",
    bridge: "en0",
    ip: "192.168.1.100"
  
  # Auto-bridge (prompts to select)
  config.vm.network "public_network"
end
```

### Port Forwarding

```ruby
Vagrant.configure("2") do |config|
  # Basic port forwarding
  config.vm.network "forwarded_port", guest: 80, host: 8080
  
  # With auto-correction
  config.vm.network "forwarded_port",
    guest: 80,
    host: 8080,
    auto_correct: true
  
  # UDP
  config.vm.network "forwarded_port",
    guest: 53,
    host: 1053,
    protocol: "udp"
  
  # Multiple ports
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 443, host: 8443
  config.vm.network "forwarded_port", guest: 3306, host: 3306
end
```

## Synced Folders

### VirtualBox Shared Folders (Default)

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "./app", "/var/www/html"
  
  # Disable default
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # With options
  config.vm.synced_folder "./app", "/var/www/html",
    owner: "www-data",
    group: "www-data",
    mount_options: ["dmode=775", "fmode=664"]
end
```

### NFS (Better Performance)

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "./app", "/var/www/html",
    type: "nfs",
    nfs_udp: false,
    mount_options: [
      "nfsvers=3",
      "tcp",
      "rsize=32768",
      "wsize=32768"
    ]
end
```

### RSync

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "./app", "/var/www/html",
    type: "rsync",
    rsync__auto: true,
    rsync__exclude: [".git/", "node_modules/", "*.log"],
    rsync__args: ["--verbose", "--archive", "--delete", "-z"]
end
```

### SMB (Windows)

```ruby
Vagrant.configure("2") do |config|
  config.vm.synced_folder "./app", "/var/www/html",
    type: "smb",
    smb_host: "127.0.0.1",
    smb_username: ENV['USER'],
    smb_password: ENV['SMB_PASSWORD']
end
```

## Custom Boxes

### Packaging a Box

```bash
# From running VM
vagrant package --base my-configured-vm --output my-custom.box

# With Vagrantfile template
vagrant package --base my-vm --output my.box --vagrantfile Vagrantfile.template

# With include files
vagrant package --base my-vm --output my.box --include README.md,metadata.json
```

### metadata.json

```json
{
  "name": "myorg/ubuntu-custom",
  "description": "Custom Ubuntu 20.04 with pre-installed tools",
  "versions": [
    {
      "version": "1.0.0",
      "providers": [
        {
          "name": "virtualbox",
          "url": "https://example.com/boxes/ubuntu-custom-1.0.0.box",
          "checksum": "sha256:abc123...",
          "checksum_type": "sha256"
        }
      ]
    }
  ]
}
```

### Adding and Using Custom Boxes

```bash
# Add local box
vagrant box add myorg/ubuntu-custom ./my-custom.box

# Add from URL
vagrant box add myorg/ubuntu-custom https://example.com/my-custom.box

# Use in Vagrantfile
# config.vm.box = "myorg/ubuntu-custom"

# List boxes
vagrant box list

# Update box
vagrant box update --box myorg/ubuntu-custom

# Remove box
vagrant box remove myorg/ubuntu-custom
```

### Publishing to Vagrant Cloud

```bash
# Login
vagrant cloud auth login

# Publish
vagrant cloud publish myorg/ubuntu-custom 1.0.0 \
  --description "Custom Ubuntu with development tools" \
  --provider virtualbox \
  --file ./my-custom.box
```

## Plugins

### Installing Plugins

```bash
# Install plugin
vagrant plugin install vagrant-vbguest

# Install specific version
vagrant plugin install vagrant-vbguest --plugin-version 0.21.0

# List installed plugins
vagrant plugin list

# Update plugin
vagrant plugin update vagrant-vbguest

# Uninstall plugin
vagrant plugin uninstall vagrant-vbguest
```

### Useful Plugins

```bash
# VirtualBox Guest Additions
vagrant plugin install vagrant-vbguest

# Host Manager (manages /etc/hosts)
vagrant plugin install vagrant-hostmanager

# Disk size management
vagrant plugin install vagrant-disksize

# Snapshot management
vagrant plugin install vagrant-snapshot

# Cachier (package cache)
vagrant plugin install vagrant-cachier
```

### Plugin Configuration

```ruby
# vagrant-vbguest
config.vbguest.auto_update = true
config.vbguest.no_remote = true

# vagrant-hostmanager
config.hostmanager.enabled = true
config.hostmanager.manage_host = true
config.hostmanager.manage_guest = true

# vagrant-disksize
config.disksize.size = '50GB'
```

## Triggers

### Basic Triggers

```ruby
Vagrant.configure("2") do |config|
  config.trigger.before :up do |trigger|
    trigger.name = "Before Up"
    trigger.info = "Starting VM..."
  end
  
  config.trigger.after :up do |trigger|
    trigger.name = "After Up"
    trigger.run = {inline: "echo 'VM is ready!'"}
  end
  
  config.trigger.before :destroy do |trigger|
    trigger.name = "Confirm Destroy"
    trigger.ask = "Are you sure you want to destroy?"
  end
end
```

### Advanced Triggers

```ruby
Vagrant.configure("2") do |config|
  # Run commands on host
  config.trigger.after :up do |trigger|
    trigger.run = {
      inline: "echo 'VM IP:' && vagrant ssh -c 'ip addr show eth1'"
    }
  end
  
  # Run commands on guest
  config.trigger.after :provision do |trigger|
    trigger.run_remote = {
      inline: "systemctl status nginx"
    }
  end
  
  # Execute only on specific machine
  config.vm.define "web" do |web|
    web.trigger.after :up do |trigger|
      trigger.info = "Web server is up!"
    end
  end
end
```

## Troubleshooting

### Common Errors

#### SSH Timeout

```ruby
Vagrant.configure("2") do |config|
  # Increase SSH timeout
  config.ssh.timeout = 120
  config.ssh.insert_key = false
  
  # For slow networks
  config.vm.provider "virtualbox" do |vb|
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
end
```

#### Network Issues

```bash
# Debug network
vagrant ssh -c "ip addr show"
vagrant ssh -c "cat /etc/network/interfaces"

# Reload network
vagrant reload

# Check VirtualBox networks
VBoxManage list natnets
VBoxManage list hostonlyifs
```

#### Synced Folder Permission Denied

```ruby
config.vm.synced_folder "./app", "/var/www/html",
  owner: "vagrant",
  group: "vagrant",
  mount_options: ["dmode=775", "fmode=664"]
```

#### Box Download Issues

```bash
# Clean download cache
rm -rf ~/.vagrant.d/tmp/*

# Download with specific version
vagrant box add ubuntu/focal64 --box-version 202310.0.0

# Use alternative download location
export VAGRANT_SERVER_URL="https://vagrantcloud.com"
```

### Debug Mode

```bash
# Enable debug logging
VAGRANT_LOG=debug vagrant up

# Enable info logging
VAGRANT_LOG=info vagrant up

# Debug specific plugin
VAGRANT_LOG=debug VAGRANT_DEFAULT_PROVIDER=virtualbox vagrant up
```

### Reset Environment

```bash
# Destroy all VMs
vagrant destroy -f

# Remove cached box
vagrant box remove ubuntu/focal64

# Clean up
rm -rf .vagrant
rm -rf ~/.vagrant.d/data

# Fresh start
vagrant up
```

## Performance Optimization

### VirtualBox Optimization

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |vb|
    # Memory and CPU
    vb.memory = 4096
    vb.cpus = 2
    
    # Enable PAE/NX
    vb.pae = true
    
    # I/O optimization
    vb.customize ["storagectl", :id, "--name", "SATA Controller", "--ahci", "on"]
    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller",
                  "--type", "hdd", "--nonrotational", "on"]
    
    # Network optimization
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    
    # Disable audio (saves resources)
    vb.customize ["modifyvm", :id, "--audio", "none"]
  end
  
  # Use NFS for better disk I/O
  config.vm.synced_folder "./app", "/app", type: "nfs"
end
```

### Parallel Operations

```ruby
# Enable parallel execution
Vagrant.configure("2") do |config|
  # Machines can be started in parallel
  config.vm.define "web"
  config.vm.define "db"
  
  # Use provisioner ordering
  config.vm.provision "shell", inline: "apt-get update", run: "always"
end
```

## Best Practices

1. **Version control your Vagrantfile**
2. **Use specific box versions** for reproducibility
3. **Use provisioners** for repeatable setup
4. **Enable auto_correct** for port forwarding
5. **Use triggers** for automation hooks
6. **Document custom boxes** with README
7. **Test multi-machine** setups thoroughly
8. **Use NFS** for better synced folder performance
9. **Keep Vagrant updated**
10. **Clean up unused boxes** regularly

## Resources

- **Documentation:** https://www.vagrantup.com/docs
- **Box Catalog:** https://app.vagrantup.com/boxes/search
- **GitHub:** https://github.com/hashicorp/vagrant
- **Community:** https://discuss.hashicorp.com/c/vagrant

## Quick Reference

### Common Vagrantfile Patterns

```ruby
# Basic
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.synced_folder ".", "/vagrant"
end

# With provisioning
Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.provision "shell", path: "setup.sh"
end

# Multi-machine
Vagrant.configure("2") do |config|
  config.vm.define "web"
  config.vm.define "db"
end
```

### Common Commands

```bash
vagrant up              # Start VM
vagrant ssh             # SSH into VM
vagrant halt            # Stop VM
vagrant destroy         # Delete VM
vagrant reload          # Restart with new config
vagrant provision       # Run provisioners
vagrant status          # Show status
vagrant global-status   # All VMs
vagrant box list        # List boxes
vagrant plugin list     # List plugins
```
