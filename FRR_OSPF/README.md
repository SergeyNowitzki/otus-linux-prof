# otus-linux-proffesional
## TASK 22: Dynamic Routing OSPF

### Network Topology
<img width="548" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/d7d93116-8416-4daa-8123-58ce516d5d4d">

### Playbook Structure
```
../Ansible/
├── ansible.cfg
├── group_vars
│   ├── all.yml
│   └── routers.yml
├── host_vars
│   ├── Router1.yml
│   ├── Router2.yml
│   └── Router3.yml
├── inventories
│   └── hosts.ini
├── provision.yml
└── roles
    ├── basic_cfg
    ├── basic_frr
    ├── frr_equal_cost
    └── frr_rpf
```

### Basic Configuration
The first role, `basic_cfg`, is used to install all necessary tools for performing configuration verification and troubleshooting. It also handles disabling `firewalld` and configuring the **NTP** client on all nodes to keep the date and time updated.

### OSPF Configuration
The playbook should be executed after vagrant have been installed all neccessary VM's from `Vagrantfile`.
```
ansible-playbook provision.yml --tags tag1,tag2
```
Before starting the configuration, we need to ensure that the `host_vars` variables are set according to the network topology. In the `basic_frr` configuration, the `ospf_cost` variables will be ignored because the `ospf_cost: false` setting in `/defaults/main.yml` is set to false. However, we can preemptively configure the default cost to `100` for all interfaces, and `1000` on **eth1** for **Router1** and **Router2** in preparation for subsequent steps.

This role installs all necessary **FRR** packages and enables traffic forwarding with `net.ipv4.conf.all.forwarding` set to `1`. It also configures the `/etc/frr/daemons` file by enabling the `zebra` and `ospfd` daemons. The `frr.conf` template is generated from a **Jinja2** template, utilizing variables from `host_vars`.

Once the configuration has been applied, it can be verified as follows:
```
root@Router1:~# systemctl status frr
● frr.service - FRRouting
     Loaded: loaded (/lib/systemd/system/frr.service; enabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-05-26 17:54:32 UTC; 25min ago
       Docs: https://frrouting.readthedocs.io/en/latest/setup.html
    Process: 12880 ExecStart=/usr/lib/frr/frrinit.sh start (code=exited, status=0/SUCCESS)
   Main PID: 12890 (watchfrr)
     Status: "FRR Operational"
      Tasks: 10 (limit: 709)
     Memory: 24.4M
        CPU: 1.272s
     CGroup: /system.slice/frr.service
             ├─12890 /usr/lib/frr/watchfrr -d -F traditional zebra mgmtd ospfd staticd
             ├─12901 /usr/lib/frr/zebra -d -F traditional -s 90000000 --daemon -A 127.0.0.1
             ├─12906 /usr/lib/frr/mgmtd -d -F traditional
             ├─12908 /usr/lib/frr/ospfd -d -F traditional --daemon -A 127.0.0.1
             └─12911 /usr/lib/frr/staticd -d -F traditional --daemon -A 127.0.0.1

May 26 17:54:27 Router1 ospfd[12908]: [VTVCM-Y2NW3] Configuration Read in Took: 00:00:00
May 26 17:54:27 Router1 frrinit.sh[12918]: [12918|ospfd] Configuration file[/etc/frr/frr.conf] processing failure: 2
May 26 17:54:27 Router1 watchfrr[12890]: [ZJW5C-1EHNT] restart all process 12891 exited with non-zero status 2
May 26 17:54:32 Router1 watchfrr[12890]: [QDG3Y-BY5TN] mgmtd state -> up : connect succeeded
May 26 17:54:32 Router1 watchfrr[12890]: [QDG3Y-BY5TN] ospfd state -> up : connect succeeded
May 26 17:54:32 Router1 watchfrr[12890]: [QDG3Y-BY5TN] zebra state -> up : connect succeeded
May 26 17:54:32 Router1 watchfrr[12890]: [QDG3Y-BY5TN] staticd state -> up : connect succeeded
May 26 17:54:32 Router1 watchfrr[12890]: [KWE5Q-QNGFC] all daemons up, doing startup-complete notify
May 26 17:54:32 Router1 frrinit.sh[12880]:  * Started watchfrr
May 26 17:54:32 Router1 systemd[1]: Started FRRouting.
```
`vtysh`VTYSH is a shell for FRR daemons. It amalgamates all the CLI commands defined in each of the daemons and presents them to the user in a single shell, which saves the user from having to telnet to each of the daemons and use their individual shells (https://docs.frrouting.org/projects/dev-guide/en/latest/vtysh.html) 
```
root@Router1:~# vtysh

Hello, this is FRRouting (version 10.0).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

Router1# sh run
Building configuration...

Current configuration:
!
frr version 10.0
frr defaults traditional
hostname Router1
log file /var/log/frr/frr.log
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
interface eth1
 description r1-r2
 ip address 10.0.10.1/30
 ip ospf cost 1000
 ip ospf dead-interval 30
 ip ospf mtu-ignore
exit
!
interface eth2
 description r1-r3
 ip address 10.0.12.1/30
 ip ospf cost 100
 ip ospf dead-interval 30
 ip ospf mtu-ignore
exit
!
interface eth3
 description net1
 ip address 192.168.10.1/24
 ip ospf cost 100
 ip ospf dead-interval 30
 ip ospf mtu-ignore
exit
!
router ospf
 ospf router-id 1.1.1.1
 network 10.0.10.0/30 area 0
 network 10.0.12.0/30 area 0
 network 192.168.10.0/24 area 0
 neighbor 10.0.10.2
 neighbor 10.0.12.2
exit
!
end
```
OSPF routing table on **Router1**:
```
Router1# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 01:00:57
O>* 10.0.11.0/30 [110/200] via 10.0.10.2, eth1, weight 1, 01:00:17
  *                        via 10.0.12.2, eth2, weight 1, 01:00:17
O   10.0.12.0/30 [110/100] is directly connected, eth2, weight 1, 01:00:27
O   192.168.10.0/24 [110/100] is directly connected, eth3, weight 1, 01:00:57
O>* 192.168.20.0/24 [110/200] via 10.0.10.2, eth1, weight 1, 01:00:22
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, eth2, weight 1, 01:00:22
```
Full routing table iproute2:
```
root@Router1:~# ip route show
default via 10.0.2.2 dev eth0 proto dhcp src 10.0.2.15 metric 100
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100
10.0.2.2 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.2.3 dev eth0 proto dhcp scope link src 10.0.2.15 metric 100
10.0.10.0/30 dev eth1 proto kernel scope link src 10.0.10.1
10.0.11.0/30 nhid 26 proto ospf metric 20
	nexthop via 10.0.10.2 dev eth1 weight 1
	nexthop via 10.0.12.2 dev eth2 weight 1
10.0.12.0/30 dev eth2 proto kernel scope link src 10.0.12.1
192.168.10.0/24 dev eth3 proto kernel scope link src 192.168.10.1
192.168.20.0/24 nhid 27 via 10.0.10.2 dev eth1 proto ospf metric 20
192.168.30.0/24 nhid 28 via 10.0.12.2 dev eth2 proto ospf metric 20
192.168.99.0/24 dev eth4 proto kernel scope link src 192.168.99.101
```

```
root@Router1:~# ping 192.168.30.1
PING 192.168.30.1 (192.168.30.1) 56(84) bytes of data.
64 bytes from 192.168.30.1: icmp_seq=1 ttl=64 time=0.665 ms
64 bytes from 192.168.30.1: icmp_seq=2 ttl=64 time=0.780 ms
```

#### Asymmetric Routing
To demonstrate and utilize the possibility of routing asymmetric traffic, we need to set a kernel parameter in Linux that controls the **Reverse Path Filtering** (RPF) feature for all network interfaces on the system. RPF helps prevent IP spoofing attacks, where IP packets are sent with a forged source IP address. This setting verifies whether incoming packets have a source IP address that matches a route in the kernel's routing table. If not, the packet may be dropped, depending on the `rp_filter` setting:
`0`: No filtering - Packets are accepted regardless of their source address.
`1`: Strict mode - The route for the source address must exist, and the packet must arrive on the interface that the kernel would use to send a reply to the source address.
`2`: Loose mode - The packet is accepted if there is any route to the source, even if it is not the route the packet would take to return to the source.

The `frr_rpf` role disables Unicast Reverse Path Forwarding (URPF) and updates the cost of interface `eth1` to `1000` on **Router1**. Other interfaces will retain the default cost of `100`.

```
Router1# sh ip ospf interface eth1
eth1 is up
  ifindex 3, MTU 1500 bytes, BW 1000 Mbit <UP,BROADCAST,RUNNING>
  Internet Address 10.0.10.1/30, Broadcast 10.0.10.3, Area 0.0.0.0
  MTU mismatch detection: disabled
  Router ID 1.1.1.1, Network Type BROADCAST, Cost: 100
  Transmit Delay is 1 sec, State Backup, Priority 1
  Designated Router (ID) 2.2.2.2 Interface Address 10.0.10.2/30
  Backup Designated Router (ID) 1.1.1.1, Interface Address 10.0.10.1
  Multicast group memberships: OSPFAllRouters OSPFDesignatedRouters
  Timer intervals configured, Hello 10s, Dead 30s, Wait 30s, Retransmit 5
    Hello due in 9.067s
  Neighbor Count is 1, Adjacent neighbor count is 1
  Graceful Restart hello delay: 10s
```
To apply the configuration on **Router1** only we use `frr_rpf` with `tag3`:
```
ansible-playbook provision.yml --tags tag3
```
```
Router1# show ip ospf interface eth1
eth1 is up
  ifindex 3, MTU 1500 bytes, BW 1000 Mbit <UP,BROADCAST,RUNNING>
  Internet Address 10.0.10.1/30, Broadcast 10.0.10.3, Area 0.0.0.0
  MTU mismatch detection: disabled
  Router ID 1.1.1.1, Network Type BROADCAST, Cost: 1000
  Transmit Delay is 1 sec, State Backup, Priority 1
  Designated Router (ID) 2.2.2.2 Interface Address 10.0.10.2/30
  Backup Designated Router (ID) 1.1.1.1, Interface Address 10.0.10.1
  Multicast group memberships: OSPFAllRouters OSPFDesignatedRouters
  Timer intervals configured, Hello 10s, Dead 30s, Wait 30s, Retransmit 5
    Hello due in 8.768s
  Neighbor Count is 1, Adjacent neighbor count is 1
  Graceful Restart hello delay: 10s
```
Before configuring the `cost` on the interface connected to **Router2**:
```
Router1# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 01:00:57
O>* 10.0.11.0/30 [110/200] via 10.0.10.2, eth1, weight 1, 01:00:17
  *                        via 10.0.12.2, eth2, weight 1, 01:00:17
O   10.0.12.0/30 [110/100] is directly connected, eth2, weight 1, 01:00:27
O   192.168.10.0/24 [110/100] is directly connected, eth3, weight 1, 01:00:57
O>* 192.168.20.0/24 [110/200] via 10.0.10.2, eth1, weight 1, 01:00:22
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, eth2, weight 1, 01:00:22
```

```
Router2# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 01:18:56
O   10.0.11.0/30 [110/100] is directly connected, eth2, weight 1, 01:18:56
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, eth1, weight 1, 00:00:27
  *                        via 10.0.11.1, eth2, weight 1, 00:00:27
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, eth1, weight 1, 00:00:28
O   192.168.20.0/24 [110/100] is directly connected, eth3, weight 1, 01:18:56
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, eth2, weight 1, 01:18:16
```

Now, **Router1** considers the best path to the `192.168.20.0/24` network to be via **Router3**.
```
Router1# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/300] via 10.0.12.2, eth2, weight 1, 00:04:49
O>* 10.0.11.0/30 [110/200] via 10.0.12.2, eth2, weight 1, 00:04:49
O   10.0.12.0/30 [110/100] is directly connected, eth2, weight 1, 00:04:49
O   192.168.10.0/24 [110/100] is directly connected, eth3, weight 1, 00:05:26
O>* 192.168.20.0/24 [110/300] via 10.0.12.2, eth2, weight 1, 00:04:49
O>* 192.168.30.0/24 [110/200] via 10.0.12.2, eth2, weight 1, 00:04:49
```

However, the best route to the `192.168.10.0/24` network on **Router2** is via **Router1**.
```
Router2# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 01:20:07
O   10.0.11.0/30 [110/100] is directly connected, eth2, weight 1, 01:20:07
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, eth1, weight 1, 00:01:38
  *                        via 10.0.11.1, eth2, weight 1, 00:01:38
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, eth1, weight 1, 00:01:39
O   192.168.20.0/24 [110/100] is directly connected, eth3, weight 1, 01:20:07
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, eth2, weight 1, 01:19:27
```

##### Verification of the assymetric routing
1. On **Router1** `ping -I 192.168.10.1 192.168.20.1`
2. On **Router2** capture traffic on **eth2** with `tcpdump`:
```
root@router2:~# tcpdump -i eth2
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), capture size 262144 bytes
20:35:43.059860 IP 192.168.10.1 > Router2: ICMP echo request, id 10, seq 16, length 64
20:35:44.057019 IP 192.168.10.1 > Router2: ICMP echo request, id 10, seq 17, length 64
20:35:45.054762 IP 192.168.10.1 > Router2: ICMP echo request, id 10, seq 18, length 64
20:35:46.053208 IP 192.168.10.1 > Router2: ICMP echo request, id 10, seq 19, length 64
```
On this interface the traffic with source ip `192.168.10.1` is detected
3. On **Router2** capture traffic on **eth1** with `tcpdump`::
```
root@router2:~# tcpdump -i eth1
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth1, link-type EN10MB (Ethernet), snapshot length 262144 bytes
20:37:04.257908 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 97, length 64
20:37:05.256339 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 98, length 64
20:37:06.254127 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 99, length 64
20:37:07.273006 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 100, length 64
20:37:08.272055 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 101, length 64
20:37:09.272093 IP Router2 > 192.168.10.1: ICMP echo reply, id 10, seq 102, length 64
```
On this port, the return traffic to `192.168.10.1` is detected, which proves asymmetric routing.

#### Equal Cost Routing
**Router2** sets the cost on `eth1` to `1000` to route traffic to `192.168.10.1` via **Router3**, equalizing the path cost. The `frr_equal_cost` role is employed for this purpose:
```
ansible-playbook provision.yml --tags tag4
```

Routing table before applying the playbook:
```
Router2# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/100] is directly connected, eth1, weight 1, 01:20:07
O   10.0.11.0/30 [110/100] is directly connected, eth2, weight 1, 01:20:07
O>* 10.0.12.0/30 [110/200] via 10.0.10.1, eth1, weight 1, 00:01:38
  *                        via 10.0.11.1, eth2, weight 1, 00:01:38
O>* 192.168.10.0/24 [110/200] via 10.0.10.1, eth1, weight 1, 00:01:39
O   192.168.20.0/24 [110/100] is directly connected, eth3, weight 1, 01:20:07
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, eth2, weight 1, 01:19:27
```
```
Router2# show ip ospf interface eth1
eth1 is up
  ifindex 3, MTU 1500 bytes, BW 1000 Mbit <UP,BROADCAST,RUNNING>
  Internet Address 10.0.10.2/30, Broadcast 10.0.10.3, Area 0.0.0.0
  MTU mismatch detection: disabled
  Router ID 2.2.2.2, Network Type BROADCAST, Cost: 1000
  Transmit Delay is 1 sec, State DROther, Priority 1
  Designated Router (ID) 1.1.1.1 Interface Address 10.0.10.1/30
  Backup Designated Router (ID) 1.1.1.1, Interface Address 10.0.10.1
  Multicast group memberships: OSPFAllRouters
  Timer intervals configured, Hello 10s, Dead 30s, Wait 30s, Retransmit 5
    Hello due in 3.582s
  Neighbor Count is 1, Adjacent neighbor count is 1
  Graceful Restart hello delay: 10s
```
```
Router2# sh ip route ospf
Codes: K - kernel route, C - connected, L - local, S - static,
       R - RIP, O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, F - PBR,
       f - OpenFabric, t - Table-Direct,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup
       t - trapped, o - offload failure

O   10.0.10.0/30 [110/1000] is directly connected, eth1, weight 1, 00:03:36
O   10.0.11.0/30 [110/100] is directly connected, eth2, weight 1, 00:03:01
O>* 10.0.12.0/30 [110/200] via 10.0.11.1, eth2, weight 1, 00:03:01
O>* 192.168.10.0/24 [110/300] via 10.0.11.1, eth2, weight 1, 00:03:01
O   192.168.20.0/24 [110/100] is directly connected, eth3, weight 1, 00:03:36
O>* 192.168.30.0/24 [110/200] via 10.0.11.1, eth2, weight 1, 00:03:01
```
After the configuration has been applied, the traffic from `192.168.10.0/24` will route through **Router3** in both directions:
1. On **Router1** start pinging 192.168.20.1 from 192.168.10.1: `ping -I 192.168.10.1 192.168.20.1`
2. On **Router2** start tcpdump on **eth2**:
```
root@Router2:~# tcpdump -i eth2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on eth2, link-type EN10MB (Ethernet), snapshot length 262144 bytes
21:32:24.776154 IP 192.168.10.1 > Router2: ICMP echo request, id 11, seq 32, length 64
21:32:24.776176 IP Router2 > 192.168.10.1: ICMP echo reply, id 11, seq 32, length 64
```

Now, both the direct and returned traffic are detected on the same interface, indicating **symmetric traffic**.
