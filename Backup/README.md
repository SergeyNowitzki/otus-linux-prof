# otus-linux-proffesional
## TASK 18: Backup
Vagrant cconfiguration with 2 VMs: backup_server и client.
The /etc directory is backed up from the client using **borgbackup**.
The project contains the following Ansible roles:
```
Ansible/roles
├── basic_cfg
├── backup_srv_disk_prov
├── backup_srv_cfg
└── client_srv_cfg
```

### Vagrant Configuration
The Vagrant file describes installation 5 VMs Routers and 3 VMs - Servers. All VMs run Ubuntu 22.
1. Modify the variables in the `Vagrantfile` to your desired values.
   
  - Add the path to your SSH public key which will be used for connecting to servers via SSH:
     ```
       ...
       ubuntu_vm.vm.provision "shell", inline: <<-SHELL
       echo "ssh-rsa YOUR PUB KEY" >> /home/vagrant/.ssh/authorized_keys
       SHELL
       ...
     ```

  - In the `Vagrantfile`, choose IP addresses for Ansible mgmt subnet (in this case):
     ```
       "private_network", ip: => "192.168.99.xx"
     ```

  - Additional Disk Provisioning:
    Add a 2GB disk to the backup server:
    ```
      unless File.exist?("ubuntu_ssd.vdi")
        vb.customize ['createhd', '--filename', 'ubuntu_ssd.vdi', '--size', 2000] # Size in MB
      end
      vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', 'ubuntu_ssd.vdi']
    end
    ```

    After all VMs are provisioned, the `provision.yml` Ansible playbook is executed to apply configurations based on their roles. Note the Ansible configuration path:
    ```
      ubuntu_vm.vm.provision "ansible" do |ansible|
          ansible.playbook = "Ansible/provision.yml"
          ansible.inventory_path = "Ansible/inventories/hosts.ini"
          ansible.host_key_checking = "false"
          ansible.limit = "all"
    ```

2. Starting the Environment:
   - run: `vagrant up`
   - `vagrant status`
     ```
     Current machine states:

     backupServer              running (virtualbox)
     backupClient1             running (virtualbox)
     ```
   - Once VMs is installed, connect to them via SSH:
     ```
     vagrant ssh <hostname>
     ```

### Basic configuration
The first ansible role `basic_cfg` installs common utility packages (wget, net-tools, curl, vim, ntp, conntrack) that are required for administrative tasks, networking, time synchronization, and other basic functions on a server.
The task also disables the ufw firewall, which is not necessary in the current environment where the iptables firewall is in use.
The `basic_cfg` role configures the NTP service with custom settings defined in the ntp.conf file. 

### Provisionin a backup 2GB disck on the Backup server
The second role `backup_srv_disk_prov` provisions an additional **2GB** disk for backup purposes on the server. Specify the variables in the `var/main.yml` file:
```
    mount_point: /var/backup/
    disk_device: /dev/sdb
    filesystem_type: ext4
```
After creating the mount point, handler `Removing data` makes sure that the directory is empty.

### Backup server Brog configuration
Installs and configures the `borgbackup` service on the **Backup Server**, including creating the necessary user and SSH setup. As far as **Borg** operates via the SSH protocol, `.ssh` directory and all necessary files should be created in the `/home/borg` directory.

### Borg Client Configuration
Before setting up the backup operations, the `borgbackup` service must first be installed on the client. Additionally, it is necessary to create a user named **borg** along with a home directory. The SSH configuration for this user is generated from a template to ensure that borg uses a public key for secure interactions with the server.

Here is the task used to initialize the backup directory on the client side:
```
command: "sudo -H -u borg bash -c 'borg init -e none borg@{{ backup_srv_ip }}:{{ backup_dir }}'"
```

This command initiates the `borg init` process under the borg user context on the client server.

Following the setup, the backup process needs to be defined as a `systemd` service to enable scheduling. This allows for regular, automated backups of specified directories.


A **systemd service unit** is created from the `borg-backup.service.j2` template. This service unit is crucial for the automation of the backup process: `Template borg-backup.service to /etc/systemd/system`.

This task dynamically generates the `borg-backup.service` file and places it in `/etc/systemd/system`. It also triggers a handler to reload the systemd daemon to ensure the new service configuration is recognized by the system.

To manage the scheduling of the backup service, a **systemd timer** is utilized. The timer is set up via the following task: `Template borg-backup.timer to /etc/systemd/system`
This setup ensures that the backup tasks are run at predefined intervals, automating the backup of important directories as configured.

### Verifying Configuration of the playbook
1. List the backup from the client on the server `borg list borg@192.168.99.111:/var/backup/`
2. Check a list of backup files `borg list borg@192.168.99.111:/var/backup/::etc-2024-05-20_07:12:57`
3. Copy file from the backup `borg extract borg@192.168.99.111:/var/backup/::etc-2024-05-20_07:12:57 etc/hostname`
4. Check timers `systemctl list-timers --all`
