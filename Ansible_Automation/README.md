# otus-linux-proffesional
## TASK 2 Ansible automation - Deploing NGINX on VMs
Before proceeding with the tasks, ensure that you have prepared the environment to work with Vagrant and Ansible.
Please make sure you have completed all necessary steps described in the hometask refference:
https://docs.google.com/document/d/1fZUXL30bDhJEQpDQgtfv3Nj4WYWto98AaYlC1vJ2LkQ/edit

Add the private network to the virtual box and choose the necessary subnet, e.g:
<img width="1102" alt="Screenshot 2024-01-22 at 01 14 57" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/9a367d30-de22-48b0-9da1-de4d772c8e85">


### Vagrant Configuration
1. After cloning the repository, modify the variables in the `Vagrantfile` to your desired values.
   
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
     "private_network", ip: "192.168.99.12#{i}"
     ```
     where `i` is a variable depending on the number of VMs.

   - Example IP addresses:
     ```
     centos-vm-1: 192.168.99.121
     ubutnu-vm-1: 192.168.99.111
     ```

2. After configuring the `Vagrantfile`, run: `vagrant up`
<img width="1079" alt="Screenshot 2024-01-22 at 01 15 38" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/1633308c-b227-45ce-9126-951e34becb12">


   - Once VMs are installed, connect to them via SSH:
     ```
     vagrant ssh centos-vm-1
     vagrant ssh ubutnu-vm-1
     ```

   - Display the current kernel version: `uname -r`:
     ```
     vagrant@ubuntu-vm-1:~$ uname -r
     5.4.0-167-generic

     [vagrant@centos-vm-1 ~]$ uname -r
     3.10.0-1127.el7.x86_64
     ```

### Ansible Configuration
1. Navigate to the Ansible folder: `cd Ansible`
2. Ensure the IP addresses in the file `inventories/hosts.ini` are correct.
3. Set Python interpreter `ansible_python_interpreter` and private SSH key `private_key_file` according to your location.
4. Check connectivity with Ansible:
```
ansible all -m ping
centos-vm-1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
ubuntu-vm-1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```
The result should be `SUCCESS` for both VMs.
5. Execute Ansible playbooks:
playbook will generate `/etc/hosts` files and check the curent kernel versions of the servers:
```
ansible-playbook main.yml --tags tag1

TASK [kernel_version : Display OS Version, family and Kernel when family is RedHat] ********************************************************************************************************************************
ok: [centos-vm-1] => {
    "msg": "OS Version is RedHat 7 and Kernel Version is 3.10.0-1127.el7.x86_64"
}

TASK [kernel_version : Display OS Version, family and Kernel when family is Debian] ********************************************************************************************************************************
ok: [ubuntu-vm-1] => {
    "msg": "OS Version is Debian 20 and Kernel Version is 5.4.0-167-generic"
}
```
The kernel versions on the fresh installed VMs centos-vm-1 and ubuntu-vm-1 are 3.10.0-1127.el7.x86_64 and 5.4.0-167-generic respectively.

6. The second playbook will update kernels and reboot the VMS:
```
LAY RECAP *********************************************************************************************************************************************************************************************************
centos-vm-1                : ok=10   changed=5    unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
ubuntu-vm-1                : ok=8    changed=4    unreachable=0    failed=0    skipped=8    rescued=0    ignored=0   
```
7. After all tasks of the second playbook have been successfuly executed the first playbook can be used to verify that the kernels have been updated successfully:
```
TASK [kernel_version : Display OS Version, family and Kernel when family is RedHat] ********************************************************************************************************************************
ok: [centos-vm-1] => {
    "msg": "OS Version is RedHat 7 and Kernel Version is 6.6.9-1.el7.elrepo.x86_64"
}
TASK [kernel_version : Display OS Version, family and Kernel when family is Debian] ********************************************************************************************************************************
skipping: [centos-vm-1]
ok: [ubuntu-vm-1] => {
    "msg": "OS Version is Debian 20 and Kernel Version is 6.6.9-060609-generic"
}
```

The kernels on both VMs have been update succesfully to version 6.6.9
