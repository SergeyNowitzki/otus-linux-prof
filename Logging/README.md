# otus-linux-proffesional
## TASK 17: Ansible Playbook for Logs Gathering (rsyslog, ELK)

### Vagrant Configuration
The Vagrant file describes installation 4 VMs: web (nginx server), cln (log client server), log (rsyslog server) and elk (elk server). All VMs run Ubuntu 22.
1. Modify the variables in the `Vagrantfile` to your desired values.
   
   - Add the path to your SSH public key which will be used for connecting to servers via SSH:
     ```
       ...
       ubuntu_vm.vm.provision "shell", inline: <<-SHELL
       echo "ssh-rsa YOUR PUB KEY" >> /home/vagrant/.ssh/authorized_keys
       SHELL
       ...
     ```

   - In the `Vagrantfile`, choose IP addresses belonging to the chosen subnet:
     ```
       ip: => "192.168.99.xx"
     ```

After the last instance forom the boxes VMs have been installed ansible playbook `provision.yml` will be executed to apply all configuration to the severs according to thei role. Please pay attantion to path to Ansible path:
```
      if opts[:name] == boxes.last[:name]
        config.vm.provision "ansible" do |ansible|
          ansible.playbook = "Ansible/provision.yml"
          ansible.inventory_path = "Ansible/inventories/hosts.ini"
          ansible.host_key_checking = "false"
          ansible.limit = "all"
```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - `vagrant status`
```
Current machine states:

web                       running (virtualbox)
cln                       running (virtualbox)
log                       running (virtualbox)
elk                       running (virtualbox)
```
   - Once VMs is installed, connect to them via SSH:
     ```
     vagrant ssh <hostname>
     ```


### Playbook Structure
Below is the structure of the playbook directory, highlighting the configuration files, roles, and other components:
```
Ansible
├── ansible.cfg                     # Main Ansible configuration file.
├── files
│   ├── index.html
│   ├── ntp.conf
│   ├── otus.png
│   └── rsyslog.conf
├── group_vars
│   └── all.yml
├── inventories
│   └── hosts.ini                   # Inventory defining groups of hosts and their IPs.
├── provision.yml                   # Primary playbook file configuring all components.
└── templates
    └── nginx.conf
```

### After applying the Ansible playbook, we can check the configuration logs on the servers.

```
# the directories which have been created regarding source of logs
root@log:/var/log/rsyslog# ll
total 16
drwx------ 4 root root   4096 Apr 20 16:45 ./
drwxrwxr-x 9 root syslog 4096 Apr 21 08:38 ../
drwx------ 2 root root   4096 Apr 21 09:33 cln/
drwx------ 2 root root   4096 Apr 20 16:13 web/

# all logs from the linux VM
root@log:/var/log/rsyslog# ll cln/
total 72
drwx------ 2 root root 4096 Apr 21 09:33 ./
drwx------ 4 root root 4096 Apr 20 16:45 ../
-rw-r--r-- 1 root root  310 Apr 21 09:16 CRON.log
-rw-r--r-- 1 root root  688 Apr 21 09:33 dbus-daemon.log
-rw-r--r-- 1 root root 3546 Apr 21 09:33 fwupdmgr.log
-rw-r--r-- 1 root root  673 Apr 21 08:38 kernel.log
-rw-r--r-- 1 root root 4574 Apr 20 16:47 python3.log
-rw-r--r-- 1 root root 1318 Apr 21 08:48 rsyslogd.log
-rw-r--r-- 1 root root 1788 Apr 20 16:48 sshd.log
-rw-r--r-- 1 root root 6344 Apr 20 16:48 sudo.log
-rw-r--r-- 1 root root  338 Apr 20 16:48 su.log
-rw-r--r-- 1 root root 6886 Apr 21 09:33 systemd.log
-rw-r--r-- 1 root root  860 Apr 20 16:48 systemd-logind.log
-rw-r--r-- 1 root root  403 Apr 21 08:38 systemd-networkd.log
-rw-r--r-- 1 root root  837 Apr 21 09:33 systemd-resolved.log

# web server access and error logs
root@log:/var/log/rsyslog# ll web/
total 16
drwx------ 2 root root 4096 Apr 20 16:13 ./
drwx------ 4 root root 4096 Apr 20 16:45 ../
-rw-r--r-- 1 root root 2780 Apr 20 16:16 nginx_access.log
-rw-r--r-- 1 root root 1488 Apr 20 16:16 nginx_error.log


# local logs on the web server
root@web:/var/log/nginx# ll
total 24
drwxr-xr-x 2 root     adm    4096 Apr 21 08:38 ./
drwxrwxr-x 9 root     syslog 4096 Apr 21 08:38 ../
-rw-r----- 1 www-data adm       0 Apr 18 14:50 access.log
-rw-r----- 1 www-data adm    1453 Apr 17 21:51 access.log.1
-rw-r----- 1 www-data adm       0 Apr 21 08:38 error.log
-rw-r----- 1 www-data adm    5635 Apr 21 08:38 error.log.1
-rw-r----- 1 www-data adm      93 Apr 13 14:28 error.log.2.gz
```

### ELK Installation for gathering logs from NGINX server
#### ELK Playbook Overview (elk-inst-conf.yml)
- Install Java: Elasticsearch and Logstash require Java.
- Install Elasticsearch: As the search and analytics engine.
- Install Logstash: Including the configuration for listening on port 5044 and applying a syslog filter.
- Install Kibana: For visualizing data.
- Configure Services: Ensure all services start on boot and are running.