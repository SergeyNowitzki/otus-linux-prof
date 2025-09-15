[root@raid-rocky ~]# cat /etc/os-release 
NAME="Rocky Linux"
VERSION="8.9 (Green Obsidian)"
ID="rocky"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.9"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Rocky Linux 8.9 (Green Obsidian)"
ANSI_COLOR="0;32"
LOGO="fedora-logo-icon"
CPE_NAME="cpe:/o:rocky:rocky:8:GA"
HOME_URL="https://rockylinux.org/"
BUG_REPORT_URL="https://bugs.rockylinux.org/"
SUPPORT_END="2029-05-31"
ROCKY_SUPPORT_PRODUCT="Rocky-Linux-8"
ROCKY_SUPPORT_PRODUCT_VERSION="8.9"
REDHAT_SUPPORT_PRODUCT="Rocky Linux"
REDHAT_SUPPORT_PRODUCT_VERSION="8.9"
[root@raid-rocky ~]# lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
sda                         8:0    0  128G  0 disk  
├─sda1                      8:1    0    1G  0 part  
│ └─md0                     9:0    0 1024M  0 raid1 /boot
└─sda2                      8:2    0  127G  0 part  
  └─md1                     9:1    0  127G  0 raid1 
    ├─rl_rocky8_raid-root 253:0    0  125G  0 lvm   /
    └─rl_rocky8_raid-swap 253:1    0    2G  0 lvm   [SWAP]
sdb                         8:16   0  128G  0 disk  
├─sdb1                      8:17   0    1G  0 part  
│ └─md0                     9:0    0 1024M  0 raid1 /boot
└─sdb2                      8:18   0  127G  0 part  
  └─md1                     9:1    0  127G  0 raid1 
    ├─rl_rocky8_raid-root 253:0    0  125G  0 lvm   /
    └─rl_rocky8_raid-swap 253:1    0    2G  0 lvm   [SWAP]
[root@raid-rocky ~]# cat /proc/mdstat 
Personalities : [raid1] 
md1 : active raid1 sdb2[1] sda2[2]
      133101568 blocks super 1.2 [2/2] [UU]
      bitmap: 0/1 pages [0KB], 65536KB chunk

md0 : active raid1 sda1[0] sdb1[1]
      1048512 blocks [2/2] [UU]
      
unused devices: <none>
[root@raid-rocky ~]# mdadm --detail /dev/md0
/dev/md0:
           Version : 0.90
     Creation Time : Mon Sep 15 08:01:53 2025
        Raid Level : raid1
        Array Size : 1048512 (1023.94 MiB 1073.68 MB)
     Used Dev Size : 1048512 (1023.94 MiB 1073.68 MB)
      Raid Devices : 2
     Total Devices : 2
   Preferred Minor : 0
       Persistence : Superblock is persistent

       Update Time : Mon Sep 15 08:46:19 2025
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              UUID : 228e45c1:bfe82540:e2687acc:91e6b532 (local to host raid-rocky)
            Events : 0.82

    Number   Major   Minor   RaidDevice State
       0       8        1        0      active sync   /dev/sda1
       1       8       17        1      active sync   /dev/sdb1
[root@raid-rocky ~]# mdadm --detail /dev/md1
/dev/md1:
           Version : 1.2
     Creation Time : Mon Sep 15 08:01:58 2025
        Raid Level : raid1
        Array Size : 133101568 (126.94 GiB 136.30 GB)
     Used Dev Size : 133101568 (126.94 GiB 136.30 GB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

     Intent Bitmap : Internal

       Update Time : Mon Sep 15 08:47:18 2025
             State : clean 
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : bitmap

              Name : raid-rocky:1  (local to host raid-rocky)
              UUID : edf33045:92449f81:7fdb9d0b:e7ee5120
            Events : 388

    Number   Major   Minor   RaidDevice State
       2       8        2        0      active sync   /dev/sda2
       1       8       18        1      active sync   /dev/sdb2
[root@raid-rocky ~]#