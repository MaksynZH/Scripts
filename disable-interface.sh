#!/bin/bash
interface=$(ip link show | grep enx | awk '{print $2}' | sed 's/://' | head -1)
if [ -n "$interface" ] && ip link show "$interface" | grep -q "UNKNOWN"; then
    ip link set "$interface" down
fi
exit 0