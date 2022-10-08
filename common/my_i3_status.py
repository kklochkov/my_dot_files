import subprocess
import sys
import time
import select
import datetime
import math
import json
import traceback
import locale
import signal
import os
import inspect
import click
import psutil



SHELL_SEGMENT_SEPARATOR = ""
# SHELL_SEGMENT_SEPARATOR = ""
#SEGMENT_SEPARATOR=''
#RIGHT_SEPARATOR=''
#LEFT_SUBSEG=''
#RIGHT_SUBSEG=''



def escape_8bit_color_text(text, foreground_color, background_color=None, style=0):
    # https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
    # https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters

    result = ""
    if style >= 0 and style <= 9:
       result += "\033[{style}m".format(style=style)

    if foreground_color >= 0 and foreground_color <= 255:
        result += "\033[38;5;{fgc}m".format(fgc=foreground_color)

    if background_color >= 0 and background_color <= 255:
        result += "\033[48;5;{bgc}m".format(bgc=background_color)

    result += "{text}\033[0m".format(text=text)
    return result


def escape_24bit_color_text(text, foreground_color_rgb, background_color_rgb=[], style=0):
    # https://en.wikipedia.org/wiki/ANSI_escape_code#24-bit
    # https://en.wikipedia.org/wiki/ANSI_escape_code#SGR_(Select_Graphic_Rendition)_parameters

    result = ""
    if style >= 0 and style <= 9:
        result += "\033[{style}m".format(style=style)

    fgc = ";".join(str(c) for c in foreground_color_rgb)
    if fgc:
        result += "\033[38;2;{fgc}m".format(fgc=fgc)

    bgc = ";".join(str(c) for c in background_color_rgb)
    if bgc:
        result += "\033[48;2;{bgc}m".format(bgc=bgc)

    result += "{text}\033[0m".format(text=text)
    return result


def hex_to_rgb(color):
    color = color.lstrip("#")
    return list(int(color[i:i+2], 16) for i in (0, 2, 4))


class Info:
    def __init__(self, refresh_rate):
        self.__i3_data__ = []
        self.__refresh_rate__ = refresh_rate
        self.__current_invoke_index__ = 0

    def __needs_update__(self):
        needs_update = not self.__current_invoke_index__ % self.__refresh_rate__
        if needs_update:
            self.__current_invoke_index__ = 0
        self.__current_invoke_index__ += 1
        return needs_update

    def __prepare_data__(self):
        pass

    def update(self, force_update=False):
        if force_update or self.__needs_update__():
            self.__i3_data__.clear()
            self.__prepare_data__()

    def __format_percentage_data__(self, percentage, invert_colors=False):
        states = [
            {"icon": "_", "color": "#00ff00" if not invert_colors else "#ff0000"},
            {"icon": "▂", "color": "#00ff00" if not invert_colors else "#ff0000"},
            {"icon": "▄", "color": "#ffff00"},
            {"icon": "▆", "color": "#ffff00" if not invert_colors else "#00ff00"},
            {"icon": "█", "color": "#ff0000" if not invert_colors else "#00ff00"}
        ]

        state = states[0]
        if percentage >= 90:
            state = states[-1]
        elif percentage >= 75:
            state = states[-2]
        elif percentage >= 50:
            state = states[-3]
        elif percentage >= 10:
            state = states[-4]

        return state["icon"], state["color"]

    def __add_i3_object__(self,
                          name,
                          full_text,
                          instance,
                          short_text=None,
                          color=None,
                          background=None,
                          border=None,
                          border_top=None,
                          border_right=None,
                          border_bottom=None,
                          border_left=None,
                          min_width=None,
                          align=None,
                          urgent=None,
                          separator=False,
                          separator_block_width=0):
        i3_data = {}
        args = inspect.getfullargspec(self.__add_i3_object__).args
        for arg in args:
            value = locals()[arg]
            if arg == "self" or value == None:
                continue

            i3_data[arg] = value

        self.__i3_data__.append(i3_data)

    def to_i3_data(self):
        return self.__i3_data__

    def __get_shell_escaped_section__(self, index):
        return escape_24bit_color_text(self.__i3_data__[index]["full_text"], hex_to_rgb(self.__i3_data__[index].get("color", "#ffffff")))

    def to_shell(self):
        line = ""
        for i in range(0, len(self.__i3_data__)):
            line += self.__get_shell_escaped_section__(i)
        return line

    def __get_tmux_escaped_section__(self, index):
        return "#[fg={fgc}]{text}#[default]".format(fgc=self.__i3_data__[index].get("color", "#ffffff"), text=self.__i3_data__[index]["full_text"])

    def to_tmux(self):
        line = ""
        for i in range(0, len(self.__i3_data__)):
            line += self.__get_tmux_escaped_section__(i)
        return line



class BatInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

        self.__battery__ = "BAT0"
        self.__has_battery__ = os.path.exists("/sys/class/power_supply/BAT0")

    def __prepare_data__(self):
        if not self.__has_battery__:
            return

        battery = {}
        on_battery = False
        battery_found = False
        try:
            with subprocess.Popen(["upower", "-d"], stdout=subprocess.PIPE, universal_newlines=True) as proc:
                proc.wait()
                for line in proc.stdout:
                    data = line.split(maxsplit=1)

                    if len(data) < 2:
                        continue

                    key = data[0]
                    value = data[1][:-1]

                    if key == "Device:":
                        battery_found = value.endswith(self.__battery__)

                    if battery_found:
                        if key == "energy:":
                            battery["energy"] = locale.atof(value[:-3])

                        if key == "energy-full:":
                            battery["energy_full"] = locale.atof(value[:-3])

                        if key == "energy-rate:":
                            battery["energy_rate"] = locale.atof(value[:-2])

                        if key == "percentage:":
                            battery["percentage"] = locale.atoi(value[:-1])

                    if key == "on-battery:":
                        on_battery = value == "yes"

            if not len(battery):
                return

            self.__format_i3_data__(
                energy=battery["energy"],
                energy_full=battery["energy_full"],
                energy_rate=battery["energy_rate"],
                percentage=battery["percentage"],
                on_battery=on_battery
            )
        except FileNotFoundError:
            pass

    def __format_battery_state_data__(self, percentage):
        battery_states = [
            {"icon": "\uf244 ", "color": "#ff0000"},
            {"icon": "\uf243 ", "color": "#ffff00"},
            {"icon": "\uf242 ", "color": "#ffff00"},
            {"icon": "\uf241 ", "color": "#00ff00"},
            {"icon": "\uf240 ", "color": "#00ff00"}
        ]

        battery_state = battery_states[0]
        if percentage == 100:
            battery_state = battery_states[-1]
        elif percentage >= 75:
            battery_state = battery_states[-2]
        elif percentage >= 50:
            battery_state = battery_states[-3]
        elif percentage >= 10:
            battery_state = battery_states[-4]

        return battery_state["icon"], battery_state["color"]

    def __format_i3_data__(self, energy, energy_full, energy_rate, percentage, on_battery):
        delta_energy = energy_full - energy
        if on_battery:
            delta_energy = energy

        hours_float = delta_energy / max(1.0, energy_rate)
        hours = int(hours_float)
        minutes_float = (hours_float - hours) * 60
        minutes = int(minutes_float)
        seconds_float = (minutes_float - minutes) * 60
        seconds = int(seconds_float)

        icon, color = self.__format_battery_state_data__(percentage=percentage)
        status_line = "{separator} {on_battery_icon}{icon}{percentage}%{time} ".format(
            separator=SHELL_SEGMENT_SEPARATOR,
            on_battery_icon="" if on_battery else "\uf1e6 ",
            icon=icon, percentage=percentage,
            time=" ({hours:0>2}:{minutes:0>2}:{seconds:0>2})".format(hours=hours, minutes=minutes, seconds=seconds) if on_battery or percentage < 100 else "")

        self.__add_i3_object__(
            name="batteryInfo",
            full_text=status_line,
            instance="status",
            color=color
        )



class CpuInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

    def __prepare_data__(self):
       percentage = psutil.cpu_percent()
       icon, color = self.__format_percentage_data__(percentage=percentage)
       self.__add_i3_object__(
           name="cpuInfo",
           full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon="\uf080 "),
           instance="label",
           color=color
       )

       for cpu, percentage in enumerate(psutil.cpu_percent(percpu=True)):
           icon, color = self.__format_percentage_data__(percentage=percentage)
           self.__add_i3_object__(
               name="cpuInfo",
               full_text=icon,
               instance=cpu,
               color=color
           )

       self.__add_i3_object__(
           name="cpuInfo",
           full_text=" {:0.2f}% ".format(percentage),
           instance="overall",
           color=color,
           min_width="100.00%",
           align="right"
       )



class VolInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

        self.__sinks__ = {}
        self.__sources__ = {}

    def __get_info__(self, query_type):
        current_index = None
        devices = {"default": None}
        try:
            with subprocess.Popen(["pacmd", query_type], stdout=subprocess.PIPE, universal_newlines=True) as proc:
                proc.wait()
                for line in proc.stdout:
                    line = line.strip()

                    if "index:" in line:
                        current_index = line.split(":")[1].strip()

                        if "*" in line:
                            devices["default"] = current_index

                        devices[current_index] = {"index": current_index}

                    if line.startswith("name:"):
                        devices[current_index]["name"] = line.split(":")[1].strip()

                    if line.startswith("volume:"):
                        devices[current_index]["volume"] = int(line.split()[4][:-1])

                    if line.startswith("muted:"):
                        devices[current_index]["muted"] = "yes" in line

                    if line.startswith("device.description"):
                        devices[current_index]["description"] = line.split("=")[1].strip()
        except FileNotFoundError:
            pass
        return devices

    def __prepare_data__(self):
        self.__sinks__ = self.__get_info__("list-sinks")
        self.__sources__ = self.__get_info__("list-sources")

        default_sink = self.__sinks__["default"]
        default_source = self.__sources__["default"]
        if default_sink is None and default_source is None:
            return

        default_sink = self.__sinks__[default_sink]
        default_source = self.__sources__[default_source]

        self.__format_i3_data__(default_sink=default_sink,
                                default_source=default_source)

    def __format_i3_data__(self, default_sink, default_source):
        self.__format_device__(normal_icon="\uf028",
                               mute_icon="\uf026", device=default_sink)
        self.__format_device__(normal_icon="\uf130",
                               mute_icon="\uf131", device=default_source)

    def __format_device__(self, normal_icon, mute_icon, device):
        muted = device["muted"]
        color = "#ff0000" if muted else "#ffffff"
        index = device["index"]
        self.__add_i3_object__(
            name="volInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon=mute_icon if muted else normal_icon),
            instance="icon_{}".format(index),
            color=color
        )
        self.__add_i3_object__(
            name="volInfo",
            full_text="{volume}% [{index}] ".format(volume=device["volume"], index=index),
            instance="info_{}".format(index),
            color=color,
        )




class BacklightInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

    def __prepare_data__(self):
        try:
            with subprocess.Popen(["xbacklight", "-get"], stdout=subprocess.PIPE, universal_newlines=True) as proc:
                proc.wait()
                value = int(float(proc.stdout.readline().strip()))

                self.__add_i3_object__(
                    name="backlightInfo",
                    full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon="\uf042"),
                    instance="icon"
                )
                self.__add_i3_object__(
                    name="backlightInfo",
                    full_text="{percentage}% ".format(percentage=value),
                    instance="value"
                )
        except FileNotFoundError:
            pass


class MemInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

    def __prepare_data__(self):
        memory = psutil.virtual_memory()
        total = getattr(memory, "total")
        mem_percentage = getattr(memory, "percent")
        buffers = getattr(memory, "buffers", 0.0)
        cached = getattr(memory, "cached", 0.0)

        mem_cache_percentage = 100 * (buffers + cached) / total

        swap = psutil.swap_memory()
        swap_percentage = getattr(swap, "percent")

        self.__format_i3_data__(mem_percentage=mem_percentage, mem_cache_percentage=mem_cache_percentage, swap_percentage=swap_percentage)

    def __format_i3_data__(self, mem_percentage, mem_cache_percentage, swap_percentage):
        mem_icon, mem_color = self.__format_percentage_data__(
            percentage=mem_percentage)
        self.__add_i3_object__(
            name="memInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon="\uf2db "),
            instance="label",
            color=mem_color
        )

        self.__add_i3_object__(
            name="memInfo",
            full_text=mem_icon,
            instance="mem",
            color=mem_color
        )

        cache_icon, cache_color = self.__format_percentage_data__(
            percentage=mem_cache_percentage)
        self.__add_i3_object__(
            name="memInfo",
            full_text=cache_icon,
            instance="cache",
            color=cache_color
        )

        swap_icon, swap_color = self.__format_percentage_data__(
            percentage=swap_percentage)
        self.__add_i3_object__(
            name="memInfo",
            full_text=swap_icon,
            instance="swap",
            color=swap_color
        )

        self.__add_i3_object__(
            name="memInfo",
            full_text=" {mem_percentage}% ".format(mem_percentage=mem_percentage),
            instance="percentage",
            color=mem_color,
            min_width="100%",
            align="right"
        )


class HddInfo(Info):
    def __init__(self, refresh_rate, drives_to_observe):
        super().__init__(refresh_rate=refresh_rate)

        self.__drives_to_observe__ = drives_to_observe

    def __prepare_data__(self):
        for partition in psutil.disk_partitions(all=False):
            if partition.device in self.__drives_to_observe__:
                label = "/" if partition.mountpoint == "/" else partition.mountpoint.split("/")[-1]
                percentage = psutil.disk_usage(partition.mountpoint).percent

                self.__format_i3_data__(label=label, percentage=percentage)

    def __format_i3_data__(self, label, percentage):
        icon, color = self.__format_percentage_data__(percentage=percentage)
        self.__add_i3_object__(
            name="hddInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon="\uf0a0"),
            instance="label_{label}".format(label=label),
            color=color
        )

        self.__add_i3_object__(
            name="hddInfo",
            full_text=icon,
            instance="icon_{label}".format(label=label),
            color=color
        )

        self.__add_i3_object__(
            name="hddInfo",
            full_text=" {percentage}% ".format(percentage=percentage),
            instance="percentage_{label}".format(label=label),
            color=color,
            min_width="100%"
        )

        self.__add_i3_object__(
            name="hddInfo",
            full_text="[{label}] ".format(label=label),
            instance="mount_{label}".format(label=label),
            color=color,
            align="right"
        )




class GpuInfo(Info):
    def __init__(self, refresh_rate):
        super().__init__(refresh_rate=refresh_rate)

    def __prepare_data__(self):
        try:
            with subprocess.Popen([
                "nvidia-smi",
                "--format=csv,noheader,nounits",
                "--query-gpu=memory.total,memory.used"
            ], stdout=subprocess.PIPE, universal_newlines=True) as proc:
                proc.wait()
                if proc.returncode == 0:
                    data = proc.stdout.readline().split(",")
                    total = locale.atof(data[0])
                    used = locale.atof(data[1])
                    percentage = math.ceil(100 * used / total)

                    self.__format_i3_data__(percentage=percentage)
        except FileNotFoundError:
            pass

    def __format_i3_data__(self, percentage):
        icon, color = self.__format_percentage_data__(percentage=percentage)
        self.__add_i3_object__(
            name="gpuInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon="\uf11b "),
            instance="label",
            color=color
        )

        self.__add_i3_object__(
            name="gpuInfo",
            full_text=icon,
            instance="icon",
            color=color
        )

        self.__add_i3_object__(
            name="gpuInfo",
            full_text=" {percentage}% ".format(percentage=percentage),
            instance="percentage",
            color=color,
            min_width="100%",
        )


class NetInfo(Info):
    def __init__(self, refresh_rate, iface_to_observe):
        super().__init__(refresh_rate=refresh_rate)

        self.__iface_to_observe__ = iface_to_observe

    def __prepare_data__(self):
        devices = {}
        try:
            with subprocess.Popen(["nmcli", "--terse", "--fields=general,ap,ip4", "device", "show"],
                                  stdout=subprocess.PIPE, universal_newlines=True) as proc:
                proc.wait()

                current_device = None
                current_connection = None
                connection_matched = False
                for line in proc.stdout:
                    data = line.strip().split(":")
                    if len(data) < 2:
                        continue

                    key = data[0]
                    value = data[1]

                    if key == "GENERAL.DEVICE":
                        if value[0] in self.__iface_to_observe__:
                            current_device = value
                            devices[current_device] = {}
                        else:
                            current_device = None
                            current_connection = None
                            connection_matched = False

                    if not current_device:
                        continue

                    if key == "GENERAL.TYPE":
                        devices[current_device]["type"] = value

                    if key == "GENERAL.CONNECTION":
                        devices[current_device]["connection"] = value
                        current_connection = value

                    if key.endswith("SSID"):
                        connection_matched = current_connection == value

                    if key.endswith("SIGNAL") and connection_matched:
                        devices[current_device]["signal"] = locale.atoi(value)

                    if key == "IP4.ADDRESS[1]":
                        devices[current_device]["ip"] = value.split("/")[0]
        except FileNotFoundError:
            pass

        self.__format_i3_data__(devices=devices)

    def __format_wifi__(self, icon, device_id, ip, connection, signal):
        bar, color = self.__format_percentage_data__(
            signal, invert_colors=True)
        self.__add_i3_object__(
            name="netInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon=icon),
            instance="icon_{}".format(device_id),
            color=color
        )
        self.__add_i3_object__(
            name="netInfo",
            full_text=connection,
            short_text="",
            instance="connection_{device_id}".format(device_id=device_id),
            color=color
        )
        self.__add_i3_object__(
            name="netInfo",
            full_text=" {bar}".format(bar=bar),
            short_text="",
            instance="bar_{device_id}".format(device_id=device_id),
            color=color
        )
        self.__add_i3_object__(
            name="netInfo",
            short_text="",
            full_text=" {signal}% ".format(signal=signal),
            instance="signal_{device_id}".format(device_id=device_id),
            color=color
        )
        self.__add_i3_object__(
            name="netInfo",
            full_text="[{ip}] ".format(ip=ip),
            short_text=ip,
            instance="ip_{device_id}".format(device_id=device_id),
            color=color
        )

    def __format_device__(self, icon, device_id, ip):
        self.__add_i3_object__(
            name="netInfo",
            full_text="{separator} {icon} ".format(separator=SHELL_SEGMENT_SEPARATOR, icon=icon),
            instance="icon_{device_id}".format(device_id=device_id)
        )
        self.__add_i3_object__(
            name="netInfo",
            full_text="{ip} ".format(ip=ip),
            instance="ip_{device_id}".format(device_id=device_id)
        )

    def __format_i3_data__(self, devices):
        for key in devices:
            device = devices[key]
            icon = self.__iface_to_observe__[key[0]]
            ip = device.get("ip")
            if not ip:
                continue

            if device["type"] == "wifi":
                connection = device["connection"]
                signal = device["signal"]
                self.__format_wifi__(
                    icon=icon, device_id=key, ip=ip, connection=connection, signal=signal)
            else:
                self.__format_device__(icon=icon, device_id=key, ip=ip)




class TimeInfo(Info):
    def __prepare_data__(self):
        self.__add_i3_object__(
            name="timeInfo",
            full_text="{separator} {datetime} ".format(separator=SHELL_SEGMENT_SEPARATOR, datetime=datetime.datetime.now().strftime("%c")),
            instance="local"
        )


class MouseEventsWatcher:
    def __init__(self):
        self.__poll__ = select.poll()
        self.__poll__.register(sys.stdin, select.POLLIN)

    def update(self):
        while self.__poll__.poll(1):
            with open("{path}/{name}.trace".format(path=os.path.expanduser("~"), name=os.path.basename(__file__)), "w") as file:
                file.write(sys.stdin.readline())

            # TODO: gnome-control-center sound if clicking on sound
            # TODO: notify-send with more info for audio
            # TODO: gnome-control-center wifi or network




__refresh_signal_arrived__ = True


def __refresh_signal_handler__(signal, frame):
    global __refresh_signal_arrived__
    __refresh_signal_arrived__ = True


# localectl status
# setxkbmap -query
# xset -q


def i3_mode(components):
    mouse_events_watcher = MouseEventsWatcher()

    print("{ \"version\": 1, \"click_events\": true }")
    print("[")

    global __refresh_signal_arrived__

    while True:
        mouse_events_watcher.update()

        i3_data = []

        for component in components:
            force_update = __refresh_signal_arrived__ and (isinstance(component, VolInfo) or isinstance(component, BacklightInfo))

            component.update(force_update=force_update)
            i3_data += component.to_i3_data()

        __refresh_signal_arrived__ = False

        print(json.dumps(i3_data), ",")

        time.sleep(1)


def tmux_mode(components):
    line = ""
    for component in components:
        component.update(force_update=True)
        line += component.to_tmux()

    print(line.strip())


def shell_mode(components):
    line = ""
    for component in components:
        component.update(force_update=True)
        line += component.to_shell()

    print(line.strip())

#    for style in range(0, 10):
#        print(escape_8bit_color_text("HELLO {style}".format(style=style), foreground_color=255, background_color=128, style=style))
#
#    for style in range(0, 10):
#        print(escape_24bit_color_text("HELLO {style}".format(style=style), foreground_color_rgb=[255,0,0], background_color_rgb=[0,255,0], style=style))


@click.command()
@click.option("-m", "--mode", type=click.Choice(["i3", "tmux", "shell"], case_sensitive=False),
        help="""Operation mode: i3 or tmux.
        In i3 mode the script start the loop to communicate with i3 window manager.
        In tmux mode the script prints a status line and exits.
        In shell mode the script prints a status line and exists.""", required=True)
@click.option("-d", "--hard-drive", type=str, multiple=True, help="A name of a hard-drive to observe.", required=True)
def main(mode, hard_drive):
    net_info = NetInfo(refresh_rate=5, iface_to_observe={"e": "\uf0e8", "w": "\uf1eb", "g": "\uf0f7"})
    hdd_info = HddInfo(refresh_rate=60, drives_to_observe=list(hard_drive))
    cpu_info = CpuInfo(refresh_rate=5)
    gpu_info = GpuInfo(refresh_rate=5)
    mem_info = MemInfo(refresh_rate=5)
    bat_info = BatInfo(refresh_rate=10)
    vol_info = VolInfo(refresh_rate=5)
    bkl_info = BacklightInfo(refresh_rate=5)
    time_info = TimeInfo(refresh_rate=1)

    components = [net_info, hdd_info, cpu_info, mem_info, gpu_info, bkl_info, vol_info, bat_info, time_info]
    if mode == "i3":
        i3_mode(components=components)
    elif mode == "tmux":
        tmux_mode(components=components)
    elif mode == "shell":
        shell_mode(components=components)

if __name__ == "__main__":
    try:
        # pick up system locale for proper usage of atoi/atof on utils' output
        locale.setlocale(locale.LC_ALL, '')

        # https://i3wm.org/docs/i3status.html#_signals
        signal.signal(signal.SIGUSR1, __refresh_signal_handler__)

        main()
    except (BrokenPipeError, KeyboardInterrupt, SystemExit):
        sys.exit(0)
    except:
        with open("{path}/{name}.log".format(path=os.path.expanduser("~"), name=os.path.basename(__file__)), "w") as file:
            traceback.print_exc(file=file)
            sys.exit(1)
    finally:
        sys.exit(0)

