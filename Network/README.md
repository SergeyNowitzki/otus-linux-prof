# otus-linux-proffesional
## TASK 19: Network Design

### Subnetting

<table>
  <tr align="center">
    <th>Name</th>
    <th>Network</th>
    <th>Mask</th>
    <th>N</th>
    <th>Hostmin</th>
    <th>Hostmax</th>
    <th>Broadcast</th>
  </tr>
  <tr>
    <td colspan="7" align="center"> Central Network </td>
  </tr>
    <td align="left">Directors</td>
    <td align="left">192.168.0.0/28</td>
    <td align="left">255.255.255.240</td>
    <td align="center">14</td>
    <td align="left">192.168.0.1</td>
    <td align="left">192.168.0.14</td>
    <td align="left">192.168.0.15</td>
  </tr>
  </tr>
    <td align="left">Office Hardware</td>
    <td align="left">192.168.0.32/28</td>
    <td align="left">255.255.255.240</td>
    <td align="center">14</td>
    <td align="left">192.168.0.33</td>
    <td align="left">192.168.0.46</td>
    <td align="left">192.168.0.47</td>
  </tr>
  </tr>
    <td align="left">WiFi MGMT</td>
    <td align="left">192.168.0.64/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.0.65</td>
    <td align="left">192.168.0.126</td>
    <td align="left">192.168.0.127</td>
  </tr>
    <td colspan="7" align="center"> Office 1 Network </td>
  </tr>
    <td align="left">Dev</td>
    <td align="left">192.168.2.0/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.2.1</td>
    <td align="left">192.168.2.62</td>
    <td align="left">192.168.2.63</td>
  </tr>
  </tr>
    <td align="left">Test</td>
    <td align="left">192.168.2.64/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.2.65</td>
    <td align="left">192.168.2.126</td>
    <td align="left">192.168.2.127</td>
  </tr>
  </tr>
    <td align="left">Managers</td>
    <td align="left">192.168.2.128/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.2.129</td>
    <td align="left">192.168.2.190</td>
    <td align="left">192.168.2.191</td>
  </tr>
  </tr>
    <td align="left">Office hardware</td>
    <td align="left">192.168.2.192/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.2.193</td>
    <td align="left">192.168.2.254</td>
    <td align="left">192.168.2.255</td>
  </tr>
    <td colspan="7" align="center"> Office 2 Network </td>
  </tr>
    <td align="left">Dev</td>
    <td align="left">192.168.1.0/25</td>
    <td align="left">255.255.255.128</td>
    <td align="center">126</td>
    <td align="left">192.168.1.1</td>
    <td align="left">192.168.1.126</td>
    <td align="left">192.168.1.127</td>
  </tr>
  </tr>
    <td align="left">Test</td>
    <td align="left">192.168.1.128/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.1.129</td>
    <td align="left">192.168.1.190</td>
    <td align="left">192.168.1.191</td>
  </tr>
  </tr>
    <td align="left">Office</td>
    <td align="left">192.168.1.192/26</td>
    <td align="left">255.255.255.192</td>
    <td align="center">62</td>
    <td align="left">192.168.1.193</td>
    <td align="left">192.168.1.254</td>
    <td align="left">192.168.1.255</td>
  </tr>
    <td colspan="7" align="center"> InetRouter — CentralRouter network </td>
  </tr>
    <td align="left">Inet — central</td>
    <td align="left">192.168.255.0/30</td>
    <td align="left">255.255.255.252</td>
    <td align="center">2</td>
    <td align="left">192.168.255.1</td>
    <td align="left">192.168.255.2</td>
    <td align="left">192.168.255.3</td>
  </tr>
</table>
<br />

### Unused Subnets
192.168.0.16/28 
192.168.0.48/28
192.168.0.128/25
192.168.255.64/26
192.168.255.32/27
192.168.255.16/28
192.168.255.8/29  
192.168.255.4/30



### Vagrant Configuration
The Vagrant file describes installation 4 VMs Routers and 3 VMs - Servers. All VMs run Ubuntu 22.
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

### NAT Configuration
The `inetRouter` is used for Internet access. In our configuration, we need to apply Network Address Translation (NAT) to the local subnet `192.168.0.0/16`, mapping it to the IP address allocated to the router’s external interface, `eth0`. The files `iptables_rules.ipv4` and `iptables_restore` are copied to inetRouter (task `Set up NAT on inetRouter`) and applied with the handler `Iptables restore`. The `iptables_restore` script is located in the `if-pre-up.d` directory, ensuring that the IP tables rules are reapplied after every reboot of the server.

### IP routing (Packet forwarding) configuration
To enable the routers to forward IP packets between interfaces, the ip forwarding task is activated. The setting `net.ipv4.conf.all.forwarding` is configured to `1` in the `/etc/sysctl.conf` file. This configuration is applied across all routers to facilitate packet forwarding.

### Default rotue disabling
The default route is disabled by copying the `00-installer-config.yaml` file to all routers except the inetRouter.

### Static routes configuration on the routers
Static routes are pre-configured in the Netplan files located in the template directory. These configurations are aligned with the network topology:
```
templates
├── 50-vagrant_centralRouter.yaml
├── 50-vagrant_centralServer.yaml
├── 50-vagrant_inetRouter.yaml
├── 50-vagrant_office1Router.yaml
├── 50-vagrant_office1Server.yaml
├── 50-vagrant_office2Router.yaml
└── 50-vagrant_office2Server.yaml
```


### Verifying Configuration of the playbook
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