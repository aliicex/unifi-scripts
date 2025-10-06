#!/bin/sh

# Fix MTU issues with WireGuard by adjusting TCP MSS
# This script sets up iptables rules to clamp the TCP MSS to the path MTU for
# packets going through the WireGuard interface (wgclt+).

# Define constants
WG_INTERFACE="wgclt+"
TCP_FLAGS="SYN,RST SYN"

# Function to add iptables rule
add_iptables_rule() {
    local table="$1"
    local chain="$2"
    local direction="$3"

    if ! iptables -t "$table" -A "$chain" "$direction" "$WG_INTERFACE" \
        -p tcp -m tcp --tcp-flags "$TCP_FLAGS" -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null; then
        
        iptables -t "$table" -A "$chain" "$direction" "$WG_INTERFACE" \
            -p tcp -m tcp --tcp-flags "$TCP_FLAGS" -j TCPMSS --clamp-mss-to-pmtu
    fi
}

# Add rules for different chains and directions
add_iptables_rule "mangle" "UBIOS_FORWARD_TCPMSS" "-o"
add_iptables_rule "mangle" "UBIOS_FORWARD_TCPMSS" "-i"
add_iptables_rule "mangle" "UBIOS_OUTPUT_TCPMSS" "-o"