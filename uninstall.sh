#!/bin/bash
# Remove the privileged helper installed by install.sh.
# The bar plugin itself is removed with: omarchy plugin remove kmyram.battery-charge
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  exec pkexec "$0"
fi

rm -f \
  /usr/local/bin/battery-charge-limit \
  /usr/share/polkit-1/actions/com.kmyram.battery-charge-limit.policy \
  /etc/polkit-1/rules.d/49-battery-charge-limit.rules \
  /etc/udev/rules.d/99-battery-charge-threshold.rules \
  /usr/lib/systemd/system-sleep/battery-charge-limit \
  /etc/tmpfiles.d/battery-charge-threshold.conf \
  /var/lib/omarchy/battery-charge-limit

udevadm control --reload || true
echo "Charge limit helper removed."
