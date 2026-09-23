# Battery charge limit

A bar widget for [Omarchy](https://omarchy.org) that stops the laptop charging at 60%, 80%, or 100%.

It uses the kernel charge-threshold interface, so it works on any machine whose driver exposes it: ASUS, ThinkPad, Dell, Framework, Chromebook, Huawei, System76, LG, Toshiba, Samsung, Sony, and Lenovo IdeaPad. Laptops without that kernel support show no control.

Some firmware only has a few steps. 60% becomes 50% on Sony, 80% on LG, Toshiba, and Samsung, and IdeaPad conservation mode is a single on/off limit. Dell keeps a 5 point gap, so 60% charges from 55% to 60%.

## Install

```bash
omarchy plugin add https://github.com/kmyram/omarchy-battery-charge.git --enable
~/.config/omarchy/plugins/kmyram.battery-charge/install.sh
```

`omarchy plugin add` only copies the plugin. `install.sh` is a separate, explicit step because the charge limit lives in sysfs and can only be written as root. It installs:

- `/usr/local/bin/battery-charge-limit`, which accepts only `60`, `80`, or `100`
- a polkit rule so an active local session can change the limit without a password
- a udev rule and a sleep hook so the choice survives reboot and suspend

The widget appears in the right side of the bar, just before the power icon. Move it with:

```bash
omarchy bar move kmyram.battery-charge --section right
```

## Usage

Click the percentage and pick a limit. Scroll on the percentage to cycle 60, 80, and 100. The battery does not drain itself down to the new limit. It stops the next time it would have charged past it.

## Remove

```bash
~/.config/omarchy/plugins/kmyram.battery-charge/uninstall.sh
omarchy plugin remove kmyram.battery-charge
```

`uninstall.sh` removes the helper, polkit rule, udev rule, and sleep hook. The saved limit in `/var/lib/omarchy/battery-charge-limit` goes with them.

## Dependencies

Nothing to install from the package manager. The plugin needs `bash`, `pkexec`, and a kernel that exposes one of:

- `/sys/class/power_supply/*/charge_control_end_threshold`
- `/sys/class/power_supply/*/charge_stop_threshold`
- Samsung `battery_life_extender`, Sony `battery_care_limiter`, LG `battery_care_limit`, Huawei `charge_control_thresholds`, or IdeaPad `conservation_mode`

## License

MIT. See [LICENSE](LICENSE).
