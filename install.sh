#!/bin/bash
# One-time setup for the privileged charge-limit helper.
# Omarchy's plugin installer never runs sudo, so this stays explicit.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)

if [[ $(id -u) -ne 0 ]]; then
  exec pkexec "$0"
fi

install -d -m 0755 \
  /usr/local/bin \
  /var/lib/omarchy \
  /etc/polkit-1/rules.d \
  /etc/udev/rules.d \
  /usr/lib/systemd/system-sleep \
  /usr/share/polkit-1/actions

install -m 0755 "$ROOT/bin/battery-charge-limit" /usr/local/bin/battery-charge-limit
install -m 0644 "$ROOT/share/com.kmyram.battery-charge-limit.policy" \
  /usr/share/polkit-1/actions/com.kmyram.battery-charge-limit.policy
install -m 0644 "$ROOT/share/49-battery-charge-limit.rules" \
  /etc/polkit-1/rules.d/49-battery-charge-limit.rules
install -m 0644 "$ROOT/share/99-battery-charge-threshold.rules" \
  /etc/udev/rules.d/99-battery-charge-threshold.rules
install -m 0755 "$ROOT/share/battery-charge-limit.sleep" \
  /usr/lib/systemd/system-sleep/battery-charge-limit

# Drop the earlier hardcoded 60% tmpfiles rule, if this machine had one.
rm -f /etc/tmpfiles.d/battery-charge-threshold.conf

udevadm control --reload
/usr/local/bin/battery-charge-limit apply

echo "Charge limit helper installed."
