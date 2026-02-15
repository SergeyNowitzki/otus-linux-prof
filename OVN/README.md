# OVN/OVS Lab Setup Guide
## Lab Architecture
```
┌────────────────────────────────────────────────────┐
│                VirtualBox Host                     │
│                                                    │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ovn-central │  │ compute-1  │  │ compute-2  │    │
│  │            │  │            │  │            │    │
│  │ OVN NB/SB  │  │ OVS + KVM  │  │ OVS + KVM  │    │
│  │ ovn-northd │  │ovn-controller ovn-controller    │
│  │            │  │            │  │            │    │
│  │ .99.10     │  │ .99.11     │  │ .99.12     │    │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘    │
│        │               │               │           │
│        └───────────────┴───────────────┘           │
│         192.168.99.0/24 (Host-Only Network)        │
└────────────────────────────────────────────────────┘
```
### Components Overview
**OVN Central (Control Plane):**
- `ovn-ovsdb-server-nb` - Northbound database (logical network config) - Port 6641
- `ovn-ovsdb-server-sb` - Southbound database (physical network state) - Port 6642
- `ovn-northd` - Translator daemon (converts logical → physical flows)

**Compute Nodes (Data Plane):**
- `openvswitch-switch` - Open vSwitch daemon
- `ovn-controller` - Local agent (reads from SB DB, programs OVS)
- `libvirtd` - KVM hypervisor
- `br-int` - Integration bridge (where VMs connect)


### Step 1: Deploy Infrastructure with Vagrant
    ```
    # Deploy the infrastructure
      vagrant up

    # Test SSH access to all nodes
      vagrant ssh ovn-central
    # Ping compute nodes
      ping -c 3 192.168.99.11
      ping -c 3 192.168.99.12

    # Exit and test the others
      vagrant ssh compute-1
      vagrant ssh compute-2
    ```

### Step 2: Configure OVN on ovn-central (Control Plane)
- Verify OVN services Are Installed:
  ```
    vagrant ssh ovn-central

  # Check installed packages
    dpkg -l | grep ovn-central

  # Check service status (may not be running yet)
    sudo systemctl status ovn-ovsdb-server-nb --no-pager
    sudo systemctl status ovn-ovsdb-server-sb --no-pager
    sudo systemctl status ovn-northd --no-pager
  
  # Start and enable OVN services
    sudo systemctl start ovn-ovsdb-server-nb
    sudo systemctl enable ovn-ovsdb-server-nb

    sudo systemctl start ovn-ovsdb-server-sb
    sudo systemctl enable ovn-ovsdb-server-sb

    sudo systemctl start ovn-northd
    sudo systemctl enable ovn-northd
  ```
- Configure Remote Access
  ```
  # Configure Northbound DB to listen on TCP
    sudo ovn-nbctl set-connection ptcp:6641:0.0.0.0

  # Configure Southbound DB to listen on TCP
    sudo ovn-sbctl set-connection ptcp:6642:0.0.0.0

  # Verify connection settings are stored
    sudo ovn-nbctl get-connection
  # Output: ptcp:6641:0.0.0.0

  # Verify connection settings are stored
    sudo ovn-sbctl get-connection
  # Output: read-write role="" ptcp:6642:0.0.0.0
  ```
- Restart services and check the status
  ```
  # Restart OVN services
    sudo systemctl restart ovn-ovsdb-server-nb
    sudo systemctl restart ovn-ovsdb-server-sb
    sudo systemctl restart ovn-northd

  # Check service status
    sudo systemctl status ovn-ovsdb-server-nb --no-pager
    sudo systemctl status ovn-ovsdb-server-sb --no-pager
    sudo systemctl status ovn-northd --no-pager
  ```
- If database curroption issue takes place:
  ```
  sudo journalctl -u ovn-ovsdb-server-nb -n 50 --no-pager

  # Output shows:
  # Feb 15 14:20:49 ovn-central ovn-ctl[3702]:  * ovnnb_db is not running
  # Feb 15 14:20:49 ovn-central systemd[1]: ovn-ovsdb-server-nb.service: Deactivated successfully.
  ```
- Recreate Databases
  ```
  # Stop all services
    sudo systemctl stop ovn-northd
    sudo systemctl stop ovn-ovsdb-server-nb
    sudo systemctl stop ovn-ovsdb-server-sb

  # Backup and remove corrupted database files
    sudo mv /var/lib/ovn/ovnnb_db.db /var/lib/ovn/ovnnb_db.db.bak 2>/dev/null || true
    sudo mv /var/lib/ovn/ovnsb_db.db /var/lib/ovn/ovnsb_db.db.bak 2>/dev/null || true

  # Recreate databases from schema
    sudo ovsdb-tool create /var/lib/ovn/ovnnb_db.db /usr/share/ovn/ovn-nb.ovsschema
    sudo ovsdb-tool create /var/lib/ovn/ovnsb_db.db /usr/share/ovn/ovn-sb.ovsschema

  # Start services
    sudo systemctl start ovn-ovsdb-server-nb
    sleep 3
    sudo systemctl start ovn-ovsdb-server-sb
    sleep 3

  # Verify services are running
    sudo systemctl status ovn-ovsdb-server-nb --no-pager
    sudo systemctl status ovn-ovsdb-server-sb --no-pager
  ```
- Configure Startup Options ` /etc/default/ovn-central`:
  ```
  vim /etc/default/ovn-central
  OVN_CTL_OPTS="--db-nb-create-insecure-remote=yes --db-sb-create-insecure-remote=yes"

  # Restart all services to apply configuration
    sudo systemctl restart ovn-ovsdb-server-nb
    sudo systemctl restart ovn-ovsdb-server-sb
    sudo systemctl restart ovn-northd
  ```
- Manual Connection Configuration
  ```
  # Now configure the connection in the running databases
    sudo ovn-nbctl set-connection ptcp:6641:0.0.0.0
    sudo ovn-sbctl set-connection ptcp:6642:0.0.0.0

  # Check ports NOW
    sudo ss -tlnp | grep 6641
  # Output: LISTEN 0.0.0.0:6641 users:(("ovsdb-server",pid=4035,fd=23))
  # ✅ SUCCESS!

    sudo ss -tlnp | grep 6642  
  # Output: LISTEN 0.0.0.0:6642 users:(("ovsdb-server"...))
  # ✅ SUCCESS!
  ```
- Final Verification
  ```
  # Verify both databases are accessible
    sudo ovn-nbctl show

  # Should return (empty is OK)
    sudo ovn-sbctl show
  # Should return (no chassis yet is OK)

  # Check all services are active
    sudo systemctl status ovn-ovsdb-server-nb ovn-ovsdb-server-sb ovn-northd --no-pager
  ```
### Step 3: Configure Compute Nodes
- Configure **Compute-1**
  ```
  vagrant ssh compute-1

  # Start OVS
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch

  # Configure connection to OVN Central
    sudo ovs-vsctl set open_vswitch . \
    external-ids:ovn-remote=tcp:192.168.99.10:6642 \
    external-ids:ovn-encap-type=geneve \
    external-ids:ovn-encap-ip=192.168.99.11 \
    external-ids:system-id=compute-1 \
    external-ids:hostname=compute-1

  # Verify configuration
    sudo ovs-vsctl get open_vswitch . external-ids
    # Output: {hostname=compute-1, ovn-encap-ip="192.168.99.11", ovn-encap-type=geneve, ovn-remote="tcp:192.168.99.10:6642", rundir="/var/run/openvswitch", system-id=compute-1}

  # Create integration bridge
    sudo ovs-vsctl --may-exist add-br br-int
    sudo ovs-vsctl set bridge br-int fail_mode=secure

  # Start OVN controller
    sudo systemctl start ovn-controller
    sudo systemctl enable ovn-controller

  # Verify
    sudo ovs-vsctl show
    # Output: dda24d7f-e727-4691-82cb-dfd420d9d518
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port br-int
            Interface br-int
                type: internal
    ovs_version: "2.17.9"
  ```
- Configure **Compute-2**
  ```
  vagrant ssh compute-2

  # Same steps, different IP
    sudo systemctl start openvswitch-switch
    sudo systemctl enable openvswitch-switch

  sudo ovs-vsctl set open_vswitch . \
    external-ids:ovn-remote=tcp:192.168.99.10:6642 \
    external-ids:ovn-encap-type=geneve \
    external-ids:ovn-encap-ip=192.168.99.12 \
    external-ids:system-id=compute-2 \
    external-ids:hostname=compute-2

  sudo ovs-vsctl --may-exist add-br br-int
  sudo ovs-vsctl set bridge br-int fail_mode=secure

  sudo systemctl start ovn-controller
  sudo systemctl enable ovn-controller
  
  # there is a tunnel geneve with compute-1
  root@compute-2:~# ovs-vsctl show
  2d9d1c4e-3ab8-4365-b6f0-3f02eb5b12e7
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port br-int
            Interface br-int
                type: internal
        Port ovn-df6644-0
            Interface ovn-df6644-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.99.11"}
    ovs_version: "2.17.9"
  ```
- Verify Registration From ovn-central:
  ```
  sudo ovn-sbctl show
  
    # Expected output:
    # Chassis "09ac8726-263a-4678-8b68-f200434f6238"
    #     hostname: compute-2
    #     Encap geneve
    #         ip: "192.168.99.12"
    # Chassis "df664406-0a89-46e9-a498-b6efa470b66f"
    #     hostname: compute-1
    #     Encap geneve
    #         ip: "192.168.99.11"
  ```

### Step 4: Create Logical Network
  ```
  vagrant ssh ovn-central

  # Create logical switch
  sudo ovn-nbctl ls-add net1
  sudo ovn-nbctl set logical_switch net1 other_config:subnet=10.0.1.0/24
  
  # Create logical router
  sudo ovn-nbctl lr-add router1
  sudo ovn-nbctl lrp-add router1 rp-net1 02:00:00:00:01:01 10.0.1.1/24
  
  # Connect switch to router
  sudo ovn-nbctl lsp-add net1 net1-rp
  sudo ovn-nbctl lsp-set-type net1-rp router
  sudo ovn-nbctl lsp-set-addresses net1-rp router
  sudo ovn-nbctl lsp-set-options net1-rp router-port=rp-net1
  
  # Verify
  sudo ovn-nbctl show

    #switch d8422b85-669b-4e6c-90ec-29cd6f0cf419 (net1)
    #    port net1-rp
    #        type: router
    #        router-port: rp-net1
    #router 6c749957-1e15-477d-8f6e-fc4a6022610c (router1)
    #    port rp-net1
    #        mac: "02:00:00:00:01:01"
    #        networks: ["10.0.1.1/24"]
  ```

