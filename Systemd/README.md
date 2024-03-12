# otus-linux-proffesional
## TASK 10: Systemd - Creating Unit File

### Vagrant Configuration
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
     ":ip_addr => '192.168.99.121'"
     ```

   - Adding additional block device size 1GB to the VM:
     ```
            :sata5 => {
            :dfile => './sata5.vdi',
            :size => 1000, # Megabytes
            :port => 5
            }
     ```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - Once VM is installed, connect to them via SSH:
     ```
     vagrant ssh
     ```

### Ansible Configuration
1. Navigate to the Ansible folder: `cd Ansible`. Ansible contains roles which are designed to work with systemd services:
    ```
        roles
        ├── watchlog_service
        ├── spawn-fcgi-init
        └── unit-httpd
    ```
2. Ensure the IP addresses in the file `inventories/hosts.ini` are correct. In our case the host belongs to Virtual Box Host-only Network 192.168.99.0/24:
    ```
        [centos-vm]
        centos-vm-1  ansible_host=192.168.99.121
    ```

### Ansible Creating watchlog.timer and watchlog.service
Creating a service which monitors a key word in a log file every 30 seconds.
Go to the Ansible directory and execute the first role:
`ansible-playbook main.yml --tags tag1`

Check timer state on the server:
```
systemctl list-timers --all
NEXT                         LEFT     LAST                         PASSED   UNIT                         ACTIVATE
n/a                          n/a      n/a                          n/a      watchlog.timer               watchlog.service
```
If the timer did not start after the first execution please restart the playbook:
```
[root@centos-vm-1 vagrant]# systemctl list-timers
NEXT                         LEFT     LAST                         PASSED   UNIT                         ACTIVATES
Tue 2024-03-12 00:49:19 UTC  26s left n/a                          n/a      watchlog.timer               watchlog.service
Wed 2024-03-13 00:40:13 UTC  23h left Tue 2024-03-12 00:40:13 UTC  8min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-

tail -f /var/log/messages
Mar 12 16:48:57 terraform-instance systemd: Starting My watchlog service...
Mar 12 16:48:57 terraform-instance root: Tue Feb 26 16:48:57 +05 2019: I found word, master!
Mar 12 16:48:57 terraform-instance systemd: Started My watchlog service.
Mar 12 16:49:27 terraform-instance systemd: Starting My watchlog service...
Mar 12 16:49:27 terraform-instance root: Tue Feb 26 16:49:27 +05 2019: I found word, master!
Mar 12 16:49:27 terraform-instance systemd: Started My watchlog service.
```

### Converting init-script to unit file.
Install spawn-fcgi from epel.
The spawn-fcgi.service file is situated in `/roles/spawn-fcgi-init/files`
All other configuration will be applied after execution the ansible-playbook:
`ansible-playbook main.yml --tags tag2`
Check if the configuration has been applied correctly:
```
[root@centos-vm-1 vagrant]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2024-03-12 00:52:04 UTC; 41s ago
 Main PID: 11183 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
```


### Chenge unit-file of apache httpd to start several server instances with diffirent configuration.
New configuration for httpd.service is situated in files and will copy after the playbook has been executed.
The amount of instances can be defined in vars file:
```
httpd_services:
  - name: 'first'
    listen_port: '8181'
  - name: 'second'
    listen_port: '8282'
```
e.g. 2 instances will be started with listen port 8181 and 8282 respectevly.

As far as Centos7 was chosen as an OS the SELinux configuration should be kept in mind, becasue httpd service can start with the custom ports by default. The following taks in the playbook are supposed to solve the SELinux issue:
```
- name: Install SELinux tools
  yum:
    name: "{{ packages }}"
    state: present
  vars:
    packages:
      - setroubleshoot-server 
      - selinux-policy-mls 
      - setools-console 
      - policycoreutils-python 
      - policycoreutils-newrole

- name: Allow httpd to listen on custom port
  seport:
    ports: "{{ item.listen_port }}"
    proto: tcp
    setype: http_port_t
    state: present
  with_items: "{{ httpd_services }}"
```

After execution of ansible role `ansible-playbook main.yml --tags tag3` the following result is expected:
```
[root@centos-vm-1 vagrant]# ss -nltp | grep httpd
LISTEN     0      128       [::]:8181                  [::]:*                   users:(("httpd",pid=13342,fd=4),("httpd",pid=13341,fd=4),("httpd",pid=13340,fd=4),("httpd",pid=13339,fd=4),("httpd",pid=13338,fd=4),("httpd",pid=13337,fd=4),("httpd",pid=13336,fd=4))
LISTEN     0      128       [::]:8282                  [::]:*                   users:(("httpd",pid=13445,fd=4),("httpd",pid=13444,fd=4),("httpd",pid=13443,fd=4),("httpd",pid=13442,fd=4),("httpd",pid=13441,fd=4),("httpd",pid=13440,fd=4),("httpd",pid=13439,fd=4))

[root@centos-vm-1 vagrant]# systemctl status httpd@first
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2024-03-12 00:54:08 UTC; 1min 35s ago
     Docs: man:httpd.service(8)
 Main PID: 13336 (httpd)

 [root@centos-vm-1 vagrant]# systemctl status httpd@second
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd@.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2024-03-12 00:54:09 UTC; 1min 59s ago
     Docs: man:httpd.service(8)
 Main PID: 13439 (httpd)
 ```