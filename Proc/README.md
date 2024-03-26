# otus-linux-proffesional
## TASK 12: Systemd - ps ax emulator

### Python Script Description
It iterates over every entry in the `/proc` directory, checking for directories that have a numeric name, which corresponds to process IDs (PIDs).
For each process, it attempts to read the command line used to start the process from `/proc/[PID]/cmdline`. This file contains the full command line, null `(\x00)` separated.
If the `cmdline` file is empty (which can happen for kernel threads or certain processes that don't have an accessible command line), it falls back to reading the process name from `/proc/[PID]/comm`, enclosing it in brackets to mimic how `ps` displays kernel threads.
It prints the PID and command line (or process name for kernel threads) for each process.

`get_cpu_time(pid)`: This function calculates the total CPU time in seconds used by the process. It reads the user mode and kernel mode time from `/proc/[PID]/stat` (fields 14 and 15) and converts them from clock ticks to seconds.
To convert clock ticks to seconds, we need to divide by the system clock ticks per second, which you can get with `os.sysconf(os.sysconf_names['SC_CLK_TCK'])`.

`get_tty(pid)`: This function attempts to identify the TTY device associated with the process. It reads the TTY device number from /proc/[PID]/stat and then attempts to map this number to a device name. This approach uses `/proc/[PID]/fd/0` as a proxy to get the TTY name, which may not be accurate in all cases, especially for processes not attached to a terminal or using redirections. This implementation is simplified and may need adjustments for accurate TTY mapping.

The `get_stat(pid)` function reads the process state from `/proc/[PID]/stat` and returns it. The process state is the third field in this file and represents the current state of the process (e.g., running, sleeping, stopped).

To use this script:
1. cmod +x ps_ax_emulator.py.
2. Make sure you have Python installed on your Linux system.
3. Run the script using Python: python3 ps_ax_emulator.py.

Results:
```
root@ubuntu-srv:/home/vagrant# ps ax
    PID TTY      STAT   TIME COMMAND
      1 ?        Ss     0:03 /sbin/init
      2 ?        S      0:00 [kthreadd]
      3 ?        I<     0:00 [rcu_gp]
      4 ?        I<     0:00 [rcu_par_gp]
      6 ?        I<     0:00 [kworker/0:0H-kblockd]
      8 ?        I<     0:00 [mm_percpu_wq]
      9 ?        S      0:00 [ksoftirqd/0]
     10 ?        I      0:00 [rcu_sched]
     11 ?        S      0:01 [migration/0]
     12 ?        S      0:00 [idle_inject/0]
     14 ?        S      0:00 [cpuhp/0]
     15 ?        S      0:00 [kdevtmpfs]
     16 ?        I<     0:00 [netns]
     17 ?        S      0:00 [rcu_tasks_kthre]
     18 ?        S      0:00 [kauditd]
     19 ?        S      0:00 [khungtaskd]
     20 ?        S      0:00 [oom_reaper]
     21 ?        I<     0:00 [writeback]
     22 ?        S      0:00 [kcompactd0]
     23 ?        SN     0:00 [ksmd]
     24 ?        SN     0:00 [khugepaged]
     70 ?        I<     0:00 [kintegrityd]
     71 ?        I<     0:00 [kblockd]
     72 ?        I<     0:00 [blkcg_punt_bio]
     73 ?        I<     0:00 [tpm_dev_wq]
     74 ?        I<     0:00 [ata_sff]
     75 ?        I<     0:00 [md]
     76 ?        I<     0:00 [edac-poller]
     77 ?        I<     0:00 [devfreq_wq]
     78 ?        S      0:00 [watchdogd]
     81 ?        S      0:00 [kswapd0]
     82 ?        S      0:00 [ecryptfs-kthrea]
     84 ?        I<     0:00 [kthrotld]
     85 ?        I<     0:00 [acpi_thermal_pm]
     86 ?        S      0:00 [scsi_eh_0]
     87 ?        I<     0:00 [scsi_tmf_0]
     88 ?        S      0:00 [scsi_eh_1]
     89 ?        I<     0:00 [scsi_tmf_1]
     91 ?        I<     0:00 [vfio-irqfd-clea]
     92 ?        I<     0:00 [ipv6_addrconf]
    102 ?        I<     0:00 [kstrp]
    105 ?        I<     0:00 [kworker/u3:0]
    118 ?        I<     0:00 [charger_manager]
    153 ?        I<     0:00 [cryptd]
    164 ?        I<     0:00 [mpt_poll_0]
    165 ?        I<     0:00 [ttm_swap]
    166 ?        I<     0:00 [mpt/0]
    190 ?        S      0:00 [scsi_eh_2]
    191 ?        I<     0:00 [scsi_tmf_2]
    192 ?        I<     0:05 [kworker/0:1H-kblockd]
    224 ?        I<     0:00 [raid5wq]
    267 ?        S      0:00 [jbd2/sda1-8]
    268 ?        I<     0:00 [ext4-rsv-conver]
    340 ?        S<s    0:08 /lib/systemd/systemd-journald
    371 ?        Ss     0:00 /lib/systemd/systemd-udevd
    384 ?        I<     0:00 [iprt-VBoxWQueue]
    474 ?        I<     0:00 [kaluad]
    475 ?        I<     0:00 [kmpath_rdacd]
    476 ?        I<     0:00 [kmpathd]
    477 ?        I<     0:00 [kmpath_handlerd]
    478 ?        SLsl   0:24 /sbin/multipathd -d -s
    486 ?        S<     0:00 [loop0]
    490 ?        S<     0:00 [loop1]
    492 ?        S<     0:00 [loop2]
    493 ?        S<     0:00 [loop3]
    494 ?        S<     0:00 [loop4]
    560 ?        Ss     0:00 /lib/systemd/systemd-networkd
    562 ?        Ss     0:00 /lib/systemd/systemd-resolved
    600 ?        Ssl    0:04 /usr/lib/accountsservice/accounts-daemon
    603 ?        Ss     0:00 /usr/sbin/cron -f
    605 ?        Ss     0:01 /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
    616 ?        Ss     0:00 /usr/bin/python3 /usr/bin/networkd-dispatcher --run-startup-triggers
    617 ?        Ssl    0:00 /usr/lib/policykit-1/polkitd --no-debug
    618 ?        Ssl    0:01 /usr/sbin/rsyslogd -n -iNONE
    620 ?        Ssl    0:01 /usr/lib/snapd/snapd
    622 ?        Ss     0:00 /lib/systemd/systemd-logind
    624 ?        Ssl    0:00 /usr/lib/udisks2/udisksd
    630 ?        Ss     0:00 /usr/sbin/atd -f
    638 ttyS0    Ss+    0:00 /sbin/agetty -o -p -- \u --keep-baud 115200,38400,9600 ttyS0 vt220
    646 tty1     Ss+    0:00 /sbin/agetty -o -p -- \u --noclear tty1 linux
    670 ?        Ss     0:00 sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups
    676 ?        Ssl    0:00 /usr/sbin/ModemManager
    695 ?        Ssl    0:00 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
    706 ?        Sl     0:08 /usr/sbin/VBoxService
   4163 ?        Ss     0:00 /lib/systemd/systemd --user
   4164 ?        S      0:00 (sd-pam)
   8983 ?        Ss     0:00 sshd: vagrant [priv]
   9091 ?        R      0:07 sshd: vagrant@pts/1
   9092 pts/1    Ss     0:00 -bash
   9106 pts/1    S      0:00 sudo su
   9107 pts/1    S      0:00 su
   9108 pts/1    S      0:00 bash
   9487 ?        S<     0:11 /usr/sbin/atopacctd
   9567 ?        I      0:16 [kworker/0:0-events]
  22199 ?        S<Ls   0:00 /usr/bin/atop -R -w /var/log/atop/atop_20240326 600
  22200 ?        I      0:00 [kworker/0:1-cgroup_destroy]
  29106 ?        I      0:00 [kworker/u2:1-events_power_efficient]
  30311 ?        I      0:00 [kworker/u2:0-events_power_efficient]
  30622 ?        I      0:00 [kworker/u2:2-events_unbound]
  30820 pts/1    R+     0:00 ps ax
```

```
root@ubuntu-srv:/home/vagrant# python3 my_ps_cpu_tty.py 
PID    TTY      STAT     TIME  CMD
1      ?        S     3.04     /sbin/init
2      ?        S     0.00     [kthreadd]
3      ?        I     0.00     [rcu_gp]
4      ?        I     0.00     [rcu_par_gp]
6      ?        I     0.00     [kworker/0:0H-kblockd]
8      ?        I     0.00     [mm_percpu_wq]
9      ?        S     0.44     [ksoftirqd/0]
10     ?        I     0.49     [rcu_sched]
11     ?        S     1.19     [migration/0]
12     ?        S     0.00     [idle_inject/0]
14     ?        S     0.00     [cpuhp/0]
15     ?        S     0.00     [kdevtmpfs]
16     ?        I     0.00     [netns]
17     ?        S     0.00     [rcu_tasks_kthre]
18     ?        S     0.00     [kauditd]
19     ?        S     0.01     [khungtaskd]
20     ?        S     0.00     [oom_reaper]
21     ?        I     0.00     [writeback]
22     ?        S     0.00     [kcompactd0]
23     ?        S     0.00     [ksmd]
24     ?        S     0.00     [khugepaged]
70     ?        I     0.00     [kintegrityd]
71     ?        I     0.00     [kblockd]
72     ?        I     0.00     [blkcg_punt_bio]
73     ?        I     0.00     [tpm_dev_wq]
74     ?        I     0.00     [ata_sff]
75     ?        I     0.00     [md]
76     ?        I     0.00     [edac-poller]
77     ?        I     0.00     [devfreq_wq]
78     ?        S     0.00     [watchdogd]
81     ?        S     0.00     [kswapd0]
82     ?        S     0.00     [ecryptfs-kthrea]
84     ?        I     0.00     [kthrotld]
85     ?        I     0.00     [acpi_thermal_pm]
86     ?        S     0.02     [scsi_eh_0]
87     ?        I     0.00     [scsi_tmf_0]
88     ?        S     0.02     [scsi_eh_1]
89     ?        I     0.00     [scsi_tmf_1]
91     ?        I     0.00     [vfio-irqfd-clea]
92     ?        I     0.00     [ipv6_addrconf]
102    ?        I     0.00     [kstrp]
105    ?        I     0.00     [kworker/u3:0]
118    ?        I     0.00     [charger_manager]
153    ?        I     0.00     [cryptd]
164    ?        I     0.00     [mpt_poll_0]
165    ?        I     0.00     [ttm_swap]
166    ?        I     0.00     [mpt/0]
190    ?        S     0.00     [scsi_eh_2]
191    ?        I     0.00     [scsi_tmf_2]
192    ?        I     5.40     [kworker/0:1H-kblockd]
224    ?        I     0.00     [raid5wq]
267    ?        S     0.88     [jbd2/sda1-8]
268    ?        I     0.00     [ext4-rsv-conver]
340    ?        S     8.06     /lib/systemd/systemd-journald
371    ?        S     0.45     /lib/systemd/systemd-udevd
384    ?        I     0.00     [iprt-VBoxWQueue]
474    ?        I     0.00     [kaluad]
475    ?        I     0.00     [kmpath_rdacd]
476    ?        I     0.00     [kmpathd]
477    ?        I     0.00     [kmpath_handlerd]
478    ?        S     25.01    /sbin/multipathd -d -s
486    ?        S     0.00     [loop0]
490    ?        S     0.01     [loop1]
492    ?        S     0.00     [loop2]
493    ?        S     0.03     [loop3]
494    ?        S     0.00     [loop4]
560    ?        S     0.19     /lib/systemd/systemd-networkd
562    ?        S     0.11     /lib/systemd/systemd-resolved
600    ?        S     4.43     /usr/lib/accountsservice/accounts-daemon
603    ?        S     0.11     /usr/sbin/cron -f
605    ?        S     1.30     /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
616    ?        S     0.05     /usr/bin/python3 /usr/bin/networkd-dispatcher --run-startup-triggers
617    ?        S     0.02     /usr/lib/policykit-1/polkitd --no-debug
618    ?        S     1.71     /usr/sbin/rsyslogd -n -iNONE
620    ?        S     1.60     /usr/lib/snapd/snapd
622    ?        S     0.16     /lib/systemd/systemd-logind
624    ?        S     0.06     /usr/lib/udisks2/udisksd
630    ?        S     0.00     /usr/sbin/atd -f
638    ttyS0    S     0.00     /sbin/agetty -o -p -- \u --keep-baud 115200,38400,9600 ttyS0 vt220
646    tty1     S     0.00     /sbin/agetty -o -p -- \u --noclear tty1 linux
670    ?        S     0.01     sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups
676    ?        S     0.05     /usr/sbin/ModemManager
695    ?        S     0.05     /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
706    ?        S     8.47     /usr/sbin/VBoxService
4163   ?        S     0.02     /lib/systemd/systemd --user
4164   ?        S     0.00     (sd-pam)
8983   ?        S     0.01     sshd: vagrant [priv]
9091   ?        R     7.70     sshd: vagrant@pts/1
9092   1        S     0.01     -bash
9106   1        S     0.00     sudo su
9107   1        S     0.00     su
9108   1        S     0.22     bash
9487   ?        S     11.93    /usr/sbin/atopacctd
9567   ?        I     16.75    [kworker/0:0-events]
22199  ?        S     0.25     /usr/bin/atop -R -w /var/log/atop/atop_20240326 600
22200  ?        I     0.00     [kworker/0:1-cgroup_destroy]
29106  ?        I     0.43     [kworker/u2:1-events_power_efficient]
30622  ?        I     0.10     [kworker/u2:2-events_unbound]
30923  1        R     0.02     python3 my_ps_cpu_tty.py
```