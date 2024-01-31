# otus-linux-proffesional
## TASK 3: Managing RAID Array Using mdadm Utility

In this task we are going to use `mdadm` utility to work with RAID arrays.

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

   - Adding additional block device size 1GB to the VM:
     ```
            :sata5 => {
            :dfile => './sata5.vdi',
            :size => 1000, # Megabytes
            :port => 5
            }
     ```

2. After configuring the `Vagrantfile`, run: `vagrant up`
   - Once VM is installed, connect to them via SSH:
     ```
     vagrant ssh
     ```

### Ansible Configuration
1. Navigate to the Ansible folder: `cd Ansible`. Ansible contains roles which are supposed to use to create a RAID, add a disk to a RAID, remove a disk form a RAID and destry a RAID:
    ```
        roles
        ├── adding_disk
        ├── create_raid
        ├── destroy_raid
        └── remove_disk
    ```
2. Ensure the IP addresses in the file `inventories/hosts.ini` are correct. In our case the host belongs to Virtual Box Host-only Network 192.168.99.0/24:
    ```
        [centos-vm]
        centos-vm-1  ansible_host=192.168.99.99
    ```

### Ansible Creating RAID array and mounting
1. Define variables for creating a RAID array in `roles/create_raid/vars/all.yml`. The list of RAIDs can be created with the following parameters:
  - `name` - a name of raid
  - `devices` - a list of devices the RAID includes
  - `filesystem` - Define filesystem of the RAID
  - `level` - Define the array raid level (0|1|4|5|6|10)
  - `mountpoint` - Define mountpoint for the array device

2. Execute Ansible playbook from with from the `Ansible` directory  `ansible-playbook main.yml --tags tag1`:
    ```
        [WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

        PLAY [Working with RAID arrays mdadm] *****************************************************************************************************************************************

        TASK [Gathering Facts] ********************************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [create_raid : Check and print OS Version] *******************************************************************************************************************************
        ok: [centos-vm-1] => {
            "ansible_os_family": "RedHat"
        }

        TASK [create_raid : Installation Software and Components] *********************************************************************************************************************
        ok: [centos-vm-1]

        TASK [create_raid : Checking Status Of Array(s)] ******************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'present', 'opts': 'noatime'})

        TASK [create_raid : Creating Array(s)] ****************************************************************************************************************************************
        skipping: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'present', 'opts': 'noatime'}) 
        skipping: [centos-vm-1]

        TASK [create_raid : Capturing Array Details] **********************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [create_raid : Creating Array(s) Filesystem] *****************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'present', 'opts': 'noatime'})

        TASK [create_raid : Mounting Array(s)] ****************************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'present', 'opts': 'noatime'})

        TASK [create_raid : Ensure /etc/mdadm/ directory exists] **********************************************************************************************************************
        ok: [centos-vm-1]

        TASK [create_raid : Ensure /etc/mdadm/mdadm.conf file exists] *****************************************************************************************************************
        ok: [centos-vm-1]

        TASK [create_raid : arrays | Updating /etc/mdadm/mdadm.conf] ******************************************************************************************************************
        changed: [centos-vm-1] => (item=ARRAY /dev/md127 metadata=1.2 name=otuslinux:127 UUID=c520f33b:e4a5bf99:034976b9:314cb98e)

        PLAY RECAP ********************************************************************************************************************************************************************
        centos-vm-1                : ok=10   changed=1    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
    ```

    According to the our quiremts RAID 10 has been created and file `/etc/mdadm/mdadm.conf` has been modified.

    We can verify that the RAID has been created:
    ```
        [root@otuslinux vagrant]# cat /proc/mdstat
        Personalities : [raid10]
        md127 : active raid10 sdf[3] sde[2] sdd[1] sdc[0]
              2043904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

        [root@otuslinux vagrant]# lsblk
        NAME    MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
        sda       8:0    0   40G  0 disk
        `-sda1    8:1    0   40G  0 part   /
        sdb       8:16   0 1000M  0 disk
        sdc       8:32   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdd       8:48   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sde       8:64   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdf       8:80   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
    ```

### Ansible Removing a faulty a Disk from the RAID array
1. If we need to remove a failty disk from the array we can use role `remove_disk`.
   In `remove_disk/var/main.yml` we can define the name of `raid` and `device` which should be removed from the array.
   Now playbook `ansible-playbook main.yml --tags tag2` can be executed:
   ```
        [WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

        PLAY [Working with RAID arrays mdadm] ******************************************************************************************************************************************************

        TASK [Gathering Facts] *********************************************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [remove_disk : Check and print OS Version] ********************************************************************************************************************************************
        ok: [centos-vm-1] => {
            "ansible_os_family": "RedHat"
        }

        TASK [remove_disk : Checking Status Of Array(s)] *******************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [remove_disk : Display Array Status] **************************************************************************************************************************************************
        ok: [centos-vm-1] => {
            "msg": "md127 : active raid10 sdf[3] sde[2] sdd[1] sdc[0]\n      2043904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]"
        }

        TASK [remove_disk : Marking Devices As Faulty] *********************************************************************************************************************************************
        changed: [centos-vm-1]

        TASK [remove_disk : Removing Devices] ******************************************************************************************************************************************************
        changed: [centos-vm-1]

        PLAY RECAP *********************************************************************************************************************************************************************************
        centos-vm-1                : ok=6    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
   ```
2. We can check whether device `dev/sdb` has been removed from array `md127`
    ```
        root@otuslinux vagrant]# cat /proc/mdstat
        Personalities : [raid10]
        md127 : active raid10 sde[2] sdd[1] sdc[0]
              2043904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]

        [root@otuslinux vagrant]# lsblk
        NAME    MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
        sda       8:0    0   40G  0 disk
        `-sda1    8:1    0   40G  0 part   /
        sdb       8:16   0 1000M  0 disk
        sdc       8:32   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdd       8:48   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sde       8:64   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdf       8:80   0 1000M  0 disk
    ```
   We can confirm that disk `dev/sdb` has been removed from the array

### Ansible Adding a Disk to RAID array
1. To add a disk to the array role `adding_disk` can be used.
  `raid` and `device` variables must be defined in file `adding_disk/var/main.yml`
  playbook execution: `ansible-playbook main.yml --tags tag3`
    ```
        [WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

        PLAY [Working with RAID arrays mdadm] ******************************************************************************************************************************************************

        TASK [Gathering Facts] *********************************************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [adding_disk : Check and print OS Version] ********************************************************************************************************************************************
        ok: [centos-vm-1] => {
            "ansible_os_family": "RedHat"
        }

        TASK [adding_disk : Checking Status Of Array(s)] *******************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [adding_disk : Display Array Status] **************************************************************************************************************************************************
        ok: [centos-vm-1] => {
            "msg": "md127 : active raid10 sde[2] sdd[1] sdc[0]\n      2043904 blocks super 1.2 512K chunks 2 near-copies [4/3] [UUU_]"
        }

        TASK [adding_disk : Appending device to the array] *****************************************************************************************************************************************
        changed: [centos-vm-1]

        PLAY RECAP *********************************************************************************************************************************************************************************
        centos-vm-1                : ok=5    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
    ```
2. As we can see after the task has been executed disk `dev/sdf` has been succesfully appended to the array
    ```
        [root@otuslinux vagrant]# lsblk
        NAME    MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINT
        sda       8:0    0   40G  0 disk
        `-sda1    8:1    0   40G  0 part   /
        sdb       8:16   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdc       8:32   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdd       8:48   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sde       8:64   0 1000M  0 disk
        `-md127   9:127  0    2G  0 raid10 /mnt/md127
        sdf       8:80   0 1000M  0 disk
        
        [root@otuslinux vagrant]# cat /proc/mdstat
        Personalities : [raid10]
        md127 : active raid10 sdb[4] sde[2] sdd[1] sdc[0]
              2043904 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
        ```

### Ansible Destroying an Array
To destoy the raid `ansible-playbook main.yml --tags tag4`
All parameters of the array should be defind in the `destroy_raid/var/main.yml` file.
    ```
        [WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

        PLAY [Working with RAID arrays mdadm] ******************************************************************************************************************************************************

        TASK [Gathering Facts] *********************************************************************************************************************************************************************
        ok: [centos-vm-1]

        TASK [destroy_raid : Check and print OS Version] *******************************************************************************************************************************************
        ok: [centos-vm-1] => {
            "ansible_os_family": "RedHat"
        }

        TASK [destroy_raid : Checking Status Of Array(s)] ******************************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        TASK [destroy_raid : UNmounting Array(s)] **************************************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        TASK [destroy_raid : Removing Array(s)] ****************************************************************************************************************************************************
        changed: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        TASK [destroy_raid : Zeroing Out Array Devices] ********************************************************************************************************************************************
        changed: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        TASK [destroy_raid : Wiping Out Array Devices] *********************************************************************************************************************************************
        changed: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        TASK [destroy_raid : Updating /etc/mdadm/mdadm.conf] ***************************************************************************************************************************************
        ok: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        RUNNING HANDLER [destroy_raid : Updating Initramfs dracut] *********************************************************************************************************************************
        changed: [centos-vm-1]

        RUNNING HANDLER [destroy_raid : Stopping RAID] *********************************************************************************************************************************************
        changed: [centos-vm-1] => (item={'name': 'md127', 'devices': ['/dev/sdc', '/dev/sdd', '/dev/sde', '/dev/sdf'], 'filesystem': 'ext4', 'level': '10', 'mountpoint': '/mnt/md127', 'state': 'absent', 'opts': 'noatime'})

        PLAY RECAP *********************************************************************************************************************************************************************************
        centos-vm-1                : ok=10   changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

        [root@otuslinux vagrant]# cat /etc/mdadm/mdadm.conf
        [root@otuslinux vagrant]# mdadm --detail --scan
        [root@otuslinux vagrant]# cat /proc/mdstat
        Personalities : [raid10]
        unused devices: <none>
    ```