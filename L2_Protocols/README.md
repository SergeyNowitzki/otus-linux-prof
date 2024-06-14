# otus-linux-proffesional
## TASK 25: L2 Protocols (VLAN, LACP)

<img width="645" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/13588765-9d72-469d-b9b5-19de03b010a9">

This scenario does not work properly in a virtual environment. The LACP bond is up, but traffic cannot pass through the router. Although the bond interfaces are UP, L3 connectivity is absent.
The following output shows the status of the bond interface (`bond0`):
```
root@inetRouter:~#cat /proc/net/bonding/bond0
Ethernet Channel Bonding Driver: v5.15.0-91-generic

Bonding Mode: IEEE 802.3ad Dynamic link aggregation
Transmit Hash Policy: layer2 (0)
MII Status: up
MII Polling Interval (ms): 100
Up Delay (ms): 0
Down Delay (ms): 0
Peer Notification Delay (ms): 0

802.3ad info
LACP active: on
LACP rate: fast
Min links: 0
Aggregator selection policy (ad_select): stable
System priority: 65535
System MAC address: 9e:4c:92:27:59:7d
Active Aggregator Info:
	Aggregator ID: 1
	Number of ports: 2
	Actor Key: 9
	Partner Key: 9
	Partner Mac Address: 8a:a3:b3:dc:c5:fb

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:63:6a:11
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: churned
Actor Churned Count: 0
Partner Churned Count: 1
details actor lacp pdu:
    system priority: 65535
    system mac address: 9e:4c:92:27:59:7d
    port key: 9
    port priority: 255
    port number: 1
    port state: 15
details partner lacp pdu:
    system priority: 65535
    system mac address: 8a:a3:b3:dc:c5:fb
    oper key: 9
    port priority: 255
    port number: 2
    port state: 55

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
Link Failure Count: 0
Permanent HW addr: 08:00:27:81:2d:34
Slave queue ID: 0
Aggregator ID: 1
Actor Churn State: none
Partner Churn State: none
Actor Churned Count: 0
Partner Churned Count: 0
details actor lacp pdu:
    system priority: 65535
    system mac address: 9e:4c:92:27:59:7d
    port key: 9
    port priority: 255
    port number: 2
    port state: 63
details partner lacp pdu:
    system priority: 65535
    system mac address: 8a:a3:b3:dc:c5:fb
    oper key: 9
    port priority: 255
    port number: 2
    port state: 63
```

**office1Router** is configured as a router-on-a-stick and handles the default gateways for `VLAN 10` and `VLAN 20`:
```
root@office1Router:~# brctl show
bridge name	bridge id		STP enabled	interfaces
br1		8000.9ebc399be0e2	no		eth2.10
							        eth3.10
br2		8000.be518fbc5e93	no      eth4.20
                                    eth5.20
```
The IP configuration for the VLAN interfaces is as follows:
```
9: br1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 9e:bc:39:9b:e0:e2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.10.1/24 brd 192.168.10.255 scope global br1
       valid_lft forever preferred_lft forever
    inet6 fe80::9cbc:39ff:fe9b:e0e2/64 scope link
       valid_lft forever preferred_lft forever
10: br2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether be:51:8f:bc:5e:93 brd ff:ff:ff:ff:ff:ff
    inet 192.168.20.1/24 brd 192.168.20.255 scope global br2
       valid_lft forever preferred_lft forever
    inet6 fe80::bc51:8fff:febc:5e93/64 scope link
       valid_lft forever preferred_lft forever
```
**office1Router** is connected to a dedicated interface to all clients and servers. Below is the verification of reachability between clients.

Verifying reachability between clients:
<img width="879" alt="image" src="https://github.com/SergeyNowitzki/otus-linux-prof/assets/39993377/24287939-3e23-44dd-94c3-9cfb3bf5aa5d">

