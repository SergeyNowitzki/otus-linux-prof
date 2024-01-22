# otus-linux-proffesional
## TASK 2 Ansible automation - Deploing NGINX on VMs
Before proceeding with the tasks, ensure that you have prepared the environment to work with Vagrant and Ansible.
After cloning the repository, install all necessary packages:
```
pip install -r requirements.txt
```
Python version of the project is 3.9.18

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
     "private_network", ip: "192.168.99.12#{i}"
     ```
     where `i` is a variable depending on the number of VMs.

   - Example IP addresses:
     ```
     centos-vm-1: 192.168.99.121
     ubutnu-vm-1: 192.168.99.111
     ```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - Once VMs are installed, connect to them via SSH:
     ```
     vagrant ssh centos-vm-1
     vagrant ssh ubutnu-vm-1
     ```

### Ansible Configuration
1. Navigate to the Ansible folder: `cd Ansible`. The directory contains the folowing files and folders:
    ```
    ├── ansible.cfg
    ├── files
    │   └── otus.png
    ├── inventories
    │   └── hosts.ini
    ├── playbook_nginx_inst.yml
    └── templates
        ├── hosts.j2
        ├── index.j2
        └── nginx.j2
    ```
2. Ensure the IP addresses in the file `inventories/hosts.ini` are correct. It also contains variable which are used for generationg `index.html` and `nginx.conf`, e.g. `listen_port=8080` is used to define a virtual server port.
3. Set Python interpreter `ansible_python_interpreter` and private SSH key `private_key_file` according to your location in `ansible.cfg`.
4. `files` directory is supposed to contain web-page content, e.g. in our case it is picture `otus.png`
5. There are jinja templates in the `templates` directory for generating `/etc/hosts`, `index.html` and `nginx.conf` files based on defined variables. 

### Ansible NGINX servers configuration
1. Execute Ansible playbook `ansible-playbook playbook_nginx_inst.yml`:
```
PLAY [Installation NGINX Web Server] *********************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************************************
ok: [centos-vm-1]
ok: [ubuntu-vm-1]

TASK [Check and print OS Version] ************************************************************************************************************************
ok: [centos-vm-1] => {
    "ansible_os_family": "RedHat"
}
ok: [ubuntu-vm-1] => {
    "ansible_os_family": "Debian"
}

TASK [generate /etc/hosts file for all hosts from host.ini file] *****************************************************************************************
ok: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Create a directory if it does not exist] ***********************************************************************************************************
ok: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Install NGINX Web Server for Debian Family] ********************************************************************************************************
skipping: [centos-vm-1]
ok: [ubuntu-vm-1]

TASK [Start NGINX Web Server and Enabel it on boot for Debian Family] ************************************************************************************
skipping: [centos-vm-1]
ok: [ubuntu-vm-1]

TASK [Install epel-release] ******************************************************************************************************************************
skipping: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Install NGINX Web Server for RedHat Family] ********************************************************************************************************
skipping: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Adding group www-data] *****************************************************************************************************************************
skipping: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Adding user www-data] ******************************************************************************************************************************
skipping: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [Start Apache Web Server and Enabel it on boot for Debian Family] ***********************************************************************************
skipping: [ubuntu-vm-1]
ok: [centos-vm-1]

TASK [generate index.htlm] *******************************************************************************************************************************
ok: [ubuntu-vm-1]
changed: [centos-vm-1]

TASK [generate nginx.conf file for all hosts from host.ini file] *****************************************************************************************
ok: [ubuntu-vm-1]
changed: [centos-vm-1]

TASK [Copy files to /var/www/html] ***********************************************************************************************************************
ok: [ubuntu-vm-1] => (item=otus.png)
ok: [centos-vm-1] => (item=otus.png)

RUNNING HANDLER [Restart NGINX RedHat] *******************************************************************************************************************
changed: [centos-vm-1]

RUNNING HANDLER [Restart NGINX Debian] *******************************************************************************************************************
skipping: [centos-vm-1]

PLAY RECAP ***********************************************************************************************************************************************
centos-vm-1                : ok=13   changed=3    unreachable=0    failed=0    skipped=3    rescued=0    ignored=0   
ubuntu-vm-1                : ok=9    changed=0    unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
```
2. After all tasks of the playbook have been successfuly executed the nginx server will be installed and configured on the severs according to OS system
```
LAY RECAP *********************************************************************************************************************************************************************************************************
centos-vm-1                : ok=10   changed=5    unreachable=0    failed=0    skipped=5    rescued=0    ignored=0   
ubuntu-vm-1                : ok=8    changed=4    unreachable=0    failed=0    skipped=8    rescued=0    ignored=0   
```
3. After all tasks of the second playbook have been successfuly executed the first playbook can be used to verify that the kernels have been updated successfully:
  - Debian OS
    <img width="1079" alt="Screenshot 2024-01-22 at 01 15 38" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/1633308c-b227-45ce-9126-951e34becb12">

  - RedHat OS
    <img width="1102" alt="Screenshot 2024-01-22 at 01 14 57" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/9a367d30-de22-48b0-9da1-de4d772c8e85">
