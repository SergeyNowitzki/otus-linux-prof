import os

def get_cmdline(pid):
    try:
        with open(f'/proc/{pid}/cmdline', 'r') as cmdline_file:
            cmdline = cmdline_file.read().replace('\x00', ' ').strip()
            if not cmdline:
                with open(f'/proc/{pid}/comm', 'r') as comm_file:
                    cmdline = f'[{comm_file.read().strip()}]'
            return cmdline
    except FileNotFoundError:
        return None

def get_cpu_time(pid):
    try:
        with open(f'/proc/{pid}/stat', 'r') as stat_file:
            stat_info = stat_file.read().split()
            utime = int(stat_info[13])
            stime = int(stat_info[14])
            clk_tck = os.sysconf(os.sysconf_names['SC_CLK_TCK'])
            total_time_seconds = (utime + stime) / clk_tck
            return total_time_seconds
    except FileNotFoundError:
        return None

def get_tty(pid):
    try:
        with open(f'/proc/{pid}/stat', 'r') as stat_file:
            tty_nr = int(stat_file.read().split()[6])
            if tty_nr == 0:
                return '?'
            tty_device = os.path.basename(os.readlink(f'/proc/{pid}/fd/0'))
            return tty_device
    except:
        return '?'

def get_stat(pid):
    try:
        with open(f'/proc/{pid}/stat', 'r') as stat_file:
            stat_info = stat_file.read().split()
            process_state = stat_info[2]
            return process_state
    except FileNotFoundError:
        return None

def main():
    print(f'{"PID":<6} {"TTY":<8} {"STAT":<8} {"TIME":<5} {"CMD"}')
    for pid in os.listdir('/proc'):
        if pid.isdigit():
            cmdline = get_cmdline(pid)
            cpu_time = get_cpu_time(pid)
            tty = get_tty(pid)
            stat = get_stat(pid)
            if cmdline:
                print(f'{pid:<6} {tty:<8} {stat:<5} {cpu_time:<8.2f} {cmdline}')

if __name__ == '__main__':
    main()
