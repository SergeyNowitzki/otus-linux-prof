# otus-linux-proffesional
## TASK 21: Iptables scenarios

inetRouter2 is added to the topology that is used in Network design task.
as an point to point connection between routers CentralRouter and inetrouter we will allocate free subnet `192.168.255.12/30`
we also need to use additional service subnet which is allocated for communicating VM's host and inetRouter2 for DNAT to NGINX server. In this case it is `192.168.50.0/24`
inetRouter2 is connected via host only subnet to the host machine (in our case **192.168.50.10**)
inetRouter2 will redirect all request from **192.168.50.10:8080** to centralServer **192.168.0.2:80**.
NGINX which is supposed to be installed on centralServer should be avaliable from other offices.

<img width="481" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/394fbfa9-f238-47e7-8adf-dae4ccd367d4">

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
       :net => "192.168.99.xx"
     ```

After the last instance from the VM boxes has been installed, the Ansible playbook `provision.yml` will be executed to apply all configurations to the servers according to their roles. Please pay attantion to path to Ansible path:
```
      if boxconfig[:vm_name] == "office2Server"
        box.vm.provision "ansible" do |ansible|
          ansible.playbook = "Ansible/provision.yml"
          ansible.inventory_path = "Ansible/inventories/hosts.ini"
          ansible.host_key_checking = "false"
          ansible.limit = "all"
```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - `vagrant status`
```
Current machine states:

inetRouter                running (virtualbox)
inetRouter2               running (virtualbox)
centralRouter             running (virtualbox)
centralServer             running (virtualbox)
office1Router             running (virtualbox)
office1Server             running (virtualbox)
office2Router             running (virtualbox)
office2Server             running (virtualbox)
```
   - Once VMs is installed, connect to them via SSH:
     ```
     vagrant ssh <hostname>
     ```

### Basic configuration
The first ansible role `basic_cfg` installs common utility packages (wget, net-tools, curl, vim, ntp, conntrack) that are required for administrative tasks, networking, time synchronization, and other basic functions on a server.
The task also disables the ufw firewall, which is not necessary in the current environment where the iptables firewall is in use.
The `basic_cfg` role configures the NTP service with custom settings defined in the ntp.conf file. 

### IP routing (Packet forwarding) configuration
To enable the routers to forward IP packets between interfaces, the ip forwarding task is activated. The setting `net.ipv4.conf.all.forwarding` is configured to `1` in the `/etc/sysctl.conf` file. This configuration is applied across all routers to facilitate packet forwarding.
The default route is disabled by copying the `00-installer-config.yaml` file to all routers except the inetRouter.
Static routes are pre-configured in the Netplan files located in the template directory. These configurations are aligned with the network topology:
```
templates
├── 50-vagrant_centralRouter.yaml
├── 50-vagrant_centralServer.yaml
├── 50-vagrant_inetRouter.yaml
├── 50-vagrant_inetRouter2.yaml
├── 50-vagrant_office1Router.yaml
├── 50-vagrant_office1Server.yaml
├── 50-vagrant_office2Router.yaml
└── 50-vagrant_office2Server.yaml
```

### NGINX installation on centralServer
This role is designed to install and configure NGINX on the **centralServer**. It sets up NGINX to listen on port 80, which is the default HTTP port, enabling the server to handle web traffic

### NAT Configuration
The `inetRouter` is used for Internet access. In our configuration, we need to apply **SNAT** to the local subnet `192.168.0.0/16`, mapping it to the IP address allocated to the router’s external interface, `eth0`. The files `iptables_rules.ipv4` and `iptables_restore` are copied to inetRouter (task `Set up NAT on inetRouter`) and applied with the handler `Iptables restore`. The `iptables_restore` script is located in the `if-pre-up.d` directory, ensuring that the IP tables rules are reapplied after every reboot of the server.
To enable port forwarding from **inetRouter2** to the NGINX server on **centralServer**, it is necessary to implement iptables rules specified in the file `iptables_DNAT_rules.ipv4`. Additionally, to ensure these rules persist after a reboot, the `iptables_restore` script should be incorporated into the network configuration. The specific rules to be applied are as follows:
```
iptables -t nat -A PREROUTING -i eth2 -p tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
iptables -t nat -A POSTROUTING -s 192.168.0.2/32 -o eth2 -p tcp --sport 80 -j SNAT --to-source 192.168.50.10:8080
```
The first rule directs traffic arriving on port **8080** to the NGINX server at port **80**. The second rule modifies the source of responses to appear as if they come from the **inetRouter2** IP address on port **8080**, ensuring proper routing back to the original requester.

### Portknocking configuration on inetRouter 
The Ansible role specifically tailored for securing and managing network access on a server, particularly focusing on SSH access.
The roll installs `knockd`, `iptables-persistent`, and `netfilter-persistent`. These packages are crucial for implementing port-knocking and persisting iptables rules across reboots.
Additionally the roll deploys a custom `knockd.conf` configuration file to the server. This file specifies the operational parameters of knockd, including the sequence of ports (`sequence = 7000,8000,9000`) to be knocked and the commands to run when the sequence is detected.
Increases security by rejecting new SSH connections on eth1, thus protecting against unauthorized access attempts over this interface.

### Verifying Configuration of the playbook
1. Routing and SNAT configuration
```
vagrant@office1Server:~$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=57 time=16.9 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=57 time=15.7 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=57 time=17.0 ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=57 time=11.4 ms


vagrant@office1Server:~$ ip route
default via 192.168.2.129 dev eth1 proto static
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.3 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
192.168.2.128/26 dev eth1 proto kernel scope link src 192.168.2.130
192.168.99.0/24 dev eth2 proto kernel scope link src 192.168.99.21

root@inetRouter:/home/vagrant# conntrack -L | grep 192.168.2.130
conntrack v1.4.6 (conntrack-tools): udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=56635 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=56635 mark=0 use=1
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=37405 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=37405 mark=0 use=1
udp      17 29 src=192.168.2.130 dst=178.251.64.52 sport=123 dport=123 src=178.251.64.52 dst=10.0.2.15 sport=123 dport=123 mark=0 use=1
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=54818 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=54818 mark=0 use=1
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=52688 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=52688 mark=0 use=1
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=38135 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=38135 mark=0 use=1
tcp      6 115 TIME_WAIT src=192.168.2.130 dst=172.217.17.142 sport=33416 dport=80 src=172.217.17.142 dst=10.0.2.15 sport=80 dport=33416 [ASSURED] mark=0 use=1
udp      17 24 src=192.168.2.130 dst=37.247.53.178 sport=123 dport=123 src=37.247.53.178 dst=10.0.2.15 sport=123 dport=123 mark=0 use=1
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=43123 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=43123 mark=0 use=2
udp      17 24 src=192.168.2.130 dst=4.2.2.2 sport=39987 dport=53 src=4.2.2.2 dst=10.0.2.15 sport=53 dport=39987 mark=0 use=1

root@inetRouter:/home/vagrant# ip route
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.2.3 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
192.168.0.0/16 via 192.168.255.2 dev eth1 proto static
192.168.99.0/24 dev eth2 proto kernel scope link src 192.168.99.10
192.168.255.0/30 dev eth1 proto kernel scope link src 192.168.255.1
```
2. DNAT from inetRouter2 to the centralSerevr
http://192.168.50.10:8080/
<img width="479" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/034b8dfe-82e5-434a-b6f5-3d316baf6b27">

We can also check source ip address and a user-agent of the client:
http://192.168.50.10:8080/inspect
```
...
       location /inspect {
            default_type text/plain;
            return 200 "$remote_addr\n$http_user_agent";
        }
...
```
<img width="715" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/9e9870b1-90c2-4755-88f3-c993e256d262">

`conntrack -L` check conntrack on the interRouter2 to see NAT translations:
<img width="881" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/2984e7cb-41e4-44d9-809d-303a5ab6e4f9">

We can also see relevant access logs on the NGINX server:
<img width="723" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/00c94afd-bcd1-433e-a6fa-e8d486c4507f">

4. Port knocking
iptables rules before port knocking:
<img width="728" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/0efe1a6e-924b-4cf8-bb20-f991ae53104e">


Let's check the port knocking configuration from **centralRouter**
<img width="735" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/5c9f7d3a-a290-4f39-817b-59a7e0eaf767">

The script to "knock" to the sequence of ports:
```
for x in 7000 8000 9000; do nc -zv 192.168.255.1 $x; done
```
After the script has been used we could connect to the server, as far as the allowing rule has been applyed after the port was knocked:
<img width="740" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/32ddc011-3031-48e5-b1ce-43a70dc20530">

