#!/usr/bin/env sh
# ------------------------------------------------------------
# Access the web UI of a DrayTek Vigor modem (bridge mode) from a UX7 box
# ------------------------------------------------------------

# Exit on any error and treat unset variables as errors
set -eu

# ------------------------------------------------------------------
# Configuration – change these values if your environment differs
# ------------------------------------------------------------------
WAN_IF="eth1"                # WAN interface on the UX7
WAN_IP="192.168.2.2"         # Desired static IP on the WAN side
WAN_CIDR="24"                # Netmask in CIDR notation (255.255.255.0)
MODEM_IP="192.168.2.1"       # IP of the DrayTek Vigor modem
UX7_SUBNET="192.168.1.0/24"  # Subnet behind the UX7 that the modem must reach

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

# ------------------------------------------------------------------
# Assign the static IP to the WAN interface
# ------------------------------------------------------------------
log "Configuring ${WAN_IF} with ${WAN_IP}/${WAN_CIDR}"
ip address replace "${WAN_IP}/${WAN_CIDR}" dev "${WAN_IF}"

# ------------------------------------------------------------------
# Add a direct route for the modem's LAN (192.168.2.0/24)
# ------------------------------------------------------------------
log "Adding route for ${WAN_IP%.*}.0/${WAN_CIDR} via ${WAN_IF}"
ip route replace "${WAN_IP%.*}.0/${WAN_CIDR}" dev "${WAN_IF}"

# ------------------------------------------------------------------
# Telnet into the modem to push a static route back
# busybox telnet 192.168.2.1
# ip route add 192.168.1.0 255.255.255.0 192.168.2.2 static
# ------------------------------------------------------------------

log "Configuration complete."
