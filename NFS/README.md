# otus-linux-proffesional
## TASK 7: Ansible Playbook for NFS Configuration

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
     ":ip_addr => '192.168.99.99'"
     ```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - Once VM is installed, connect to them via SSH:
     ```
     vagrant ssh <hostname>
     ```

### Playbook Structure
Below is the structure of the playbook directory, highlighting the configuration files, roles, and other components:
```
Ansible/
├── ansible.cfg          # Main Ansible configuration file.
├── group_vars/
│   └── all.yml          # Global variables applicable across all hosts.
├── inventories/
│   └── hosts.ini        # Inventory defining groups of hosts and their IPs.
├── main.yml             # Primary playbook file orchestrating the roles.
├── roles/
│   ├── nfs_cln_cfg/     # Role for configuring NFS clients.
│   │   ├── handlers/
│   │   ├── meta/
│   │   ├── tasks/
│   │   │   └── main.yml # Main task file for NFS client configuration.
│   │   └── vars/
│   │       └── main.yml # Variables specific to NFS client setup.
│   └── nfs_srv_cfg/     # Role for setting up NFS servers.
│       ├── handlers/
│       ├── meta/
│       ├── tasks/
│       │   └── main.yml # Main task file for NFS server setup.
│       ├── templates/
│       └── vars/
│           └── main.yml # Variables specific to NFS server configuration.
└── templates/            # Storage for template files.

```

### NFS Server Configuration (nfs_srv_cfg Role)
Configures a host to serve as an NFS server. It involves:

- Installation of NFS server packages `nfs-utils` and `rpcbind`
- Enabling and starting necessary services (`rpcbind`, `nfs-server`).
- Creating and exporting NFS directories (`/srv/share/` and `/srv/share/upload`)
- Setting up firewall rules to allow NFS-related traffic.

To configure NFS servers, run:
```
ansible-playbook -i inventories/hosts.ini main.yml --tags tag1
```

After the playbook has been successfully executed we can verify configuration of the server:
- firewall rule contains the necessary protocols
```
[root@nfs-srv vagrant]# sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources:
  services: dhcpv6-client mountd nfs nfs3 rpc-bind ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```
- ensure that server is listening service ports:
```
[root@nfs-srv vagrant]# ss -tnplu | grep -E ':2049|:111'
udp    UNCONN     0      0         *:2049                  *:*
udp    UNCONN     0      0         *:111                   *:*                   users:(("rpcbind",pid=342,fd=6))
udp    UNCONN     0      0      [::]:2049               [::]:*
udp    UNCONN     0      0      [::]:111                [::]:*                   users:(("rpcbind",pid=342,fd=9))
tcp    LISTEN     0      64        *:2049                  *:*
tcp    LISTEN     0      128       *:111                   *:*                   users:(("rpcbind",pid=342,fd=8))
tcp    LISTEN     0      64     [::]:2049               [::]:*
tcp    LISTEN     0      128    [::]:111                [::]:*                   users:(("rpcbind",pid=342,fd=11))
```
- check the exported directory
```
[root@nfs-srv vagrant]# exportfs -s
/srv/share  192.168.99.0/24(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

### NFS Client Configuration (nfs_cln_cfg Role)
Prepares a host to act as an NFS client, which includes:

- Installing NFS client packages.
- Mounting NFS shares from the server.
- Creating a test file `test_file.txt` in the NFS mount to verify access and write capabilities.

Check if the share has been mounted:
```
[root@nfs-cln1 vagrant]# df -h | grep mnt
192.168.99.111:/srv/share   40G  3.2G   37G   8% /mnt

[root@nfs-cln1 vagrant]# mount | grep /mnt
192.168.99.111:/srv/share on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.99.111,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.99.111)
```

As we can see the file has been copied to the shared directory:
```
[root@nfs-cln1 vagrant]# cat /mnt/upload/test_file.txt
This is a test file created on a client
```
