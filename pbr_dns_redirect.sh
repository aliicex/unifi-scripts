#!/bin/sh

# Configure DNS redirection rules for UnifiOS with ctrld support
# This script modifies firewall rules to direct DNS traffic to ctrld listener

# Define constants
CTRLD_PORT="53"
CTRLD_IP="127.0.0.1"
TABLE="nat"
CHAIN="UBIOS_DNS_REDIRECT"

# Function to check if rule exists
rule_exists() {
    local destination="$1"
    iptables -t "$TABLE" -C "$CHAIN" \
        -p udp --dport 53 -j DNAT --to-destination "$destination" 2>/dev/null
    return $?
}

# Function to add DNS redirection rule
add_dns_rule() {
    local destination="$1"
    if ! rule_exists "$destination"; then
        iptables -t "$TABLE" -I "$CHAIN" 1 \
            -p udp --dport 53 -j DNAT --to-destination "$destination"
    fi
}

# Function to remove existing DNS rules
remove_old_rules() {
    while iptables -t "$TABLE" -D "$CHAIN" \
        -p udp --dport 53 -j DNAT --to-destination "$WAN_DNS" 2>/dev/null; do
        continue
    done
}

# Main execution
echo "Configuring DNS redirection rules..."

# Remove existing WAN DNS rules
remove_old_rules

# Add new rule for ctrld
add_dns_rule "${CTRLD_IP}:${CTRLD_PORT}"

echo "DNS rules configuration completed"