# otus-linux-proffesional
## TASK 1 Deploing a VM from Vagrant file and update kernel
The first prerequisite is to prepare enviroment to work with Vagrant and Ansible.
Please make sure you have completed all necessary steps described in the hometask refference:
https://docs.google.com/document/d/1fZUXL30bDhJEQpDQgtfv3Nj4WYWto98AaYlC1vJ2LkQ/edit

Add the private network to the virtual box and choose the necessary subnet, e.g:
<img>
After cloning the repository, please modify the variables to your desired values and pay attention to the path of the SSH keys on your Virtual machines:
`Vagrantfile`
Add the path to your ssh pub key which will be used to connect to servers via SSH, e.g.:
```
...
ubuntu_vm.vm.provision "shell", inline: <<-SHELL
        echo "ssh-rsa YOUR PUB KEY" >> /home/vagrant/.ssh/authorized_keys
      SHELL
...
```

In `Vagrant` file choose addresses which belong to the chosen subnet:
```
"private_network", ip: "192.168.99.12#{i}"
```
where `i` is a variable which depends on the number of VMs (in the current example 1 Centos7 VM and 1 Ubuntu VM).
Therefore, ip addresses will be accordinly:
```
centos-vm-1: 192.168.99.121
ubutnu-vm-1: 192.168.99.111
```

After the `Vagrant` has been prepared the VMs can be installed `vagrant up`

As soon as VMs have been installed we can connect to them via SSH:
```
vagrant ssh centos-vm-1
vagrant ssh ubutnu-vm-1
```

To display the current kernel version `uname -r`.
The result of issing the command on the servers after installation:
```
vagrant@ubuntu-vm-1:~$ uname -r
5.4.0-167-generic

[vagrant@centos-vm-1 ~]$ uname -r
3.10.0-1127.el7.x86_64
```

As far as the servers are avaliable via SSH the Ansible configuration is ready to colpite.
Go to Ansible folder `cd Ansible`
Please ensure the ip addresses of the server are correct in the file `inventories/hosts.ini`
Python interpreter `ansible_python_interpreter` and private SSH key `private_key_file` must be choesen according to your location.

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
As the result is `SUCCESS` the ansible playbooks can be executed from the `Ansible` directory:
the first playbook will generate `/etc/hosts` files and check the curent kernel versions of the servers:
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
After freshinstalled VMs kernel versions on centos-vm-1 and ubuntu-vm-1 are 3.10.0-1127.el7.x86_64 and 5.4.0-167-generic respectivly.

The second playbook will update kernels and reboot the VMS:
```
LAY RECAP *********************************************************************************************************************************************************************************************************
centos-vm-1                : ok=10   changed=5    unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
ubuntu-vm-1                : ok=8    changed=4    unreachable=0    failed=0    skipped=8    rescued=0    ignored=0   
```
After all tasks of the playbook have been successfuly executed the first playbook can display the current state of the cernel versions of the VMs:
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