# otus-linux-proffesional
## TASK 22: Dynamic Routing OSPF

### Network Topology
<img width="548" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/d7d93116-8416-4daa-8123-58ce516d5d4d">

### Basic Configuration
apt install vim traceroute tcpdump net-tools
sudo apt install frr frr-pythontools
sysctl net.ipv4.conf.all.forwarding=1
vim /etc/frr/daemons
zebra=yes
ospfd=yes

chown frr:frr /etc/frr/frr.conf 
chmod 640 /etc/frr/frr.conf 

   systemct restart frr 
   systemctl enable frr


### OSPF Configuration

#### Asymmetric Routing
setting in Linux is a kernel parameter that controls the **Reverse Path Filtering** (RPF)feature for all network interfaces on the system. RPF is a network feature used to help prevent IP spoofing attacks, where IP packets are sent with a forged source IP address. This setting checks whether incoming packets have a source IP address that matches a route in the kernel's routing table. If not, the packet may be dropped, depending on the setting of `rp_filter`.
0: No filtering - Packets are accepted regardless of their source address
1: Strict mode - the route for the source address exists and that the packet arrives on the interface that the kernel would use to send a reply to the source address.
2: Loose mode - If there is a route, the packet is accepted, even if it's not the route the packet would take to go back to the source.

Disable URPF
sysctl net.ipv4.conf.all.rp_filter=0
sysctl -p
#### Equal Cost Routing


### Verifying 
systemctl status frr
root@router1:~# vtysh
root@router1:~# ip a | grep "inet " 
