#!/bin/sh

# Configure DNS redirection rules for UnifiOS with ctrld support
# This script modifies firewall rules to hijack DNS traffic and send to ctrld

# Define constants
TABLE="nat"
CHAIN="UBIOS_PREROUTING_PBR"
CLIENT_SET="UBIOS_trafficroute_clients_2"
LOCAL_NET_SET="UBIOS_local_network"
CTRLD_IP="0.0.0.0"
CTRLD_PORT="5354"

# Function to insert custom DNAT and RETURN rules for UDP/TCP in PBR chain
insert_pbr_dns_rules() {
    local proto="$1"
    local dport="$2"

    # Find the line number for the RETURN rule
    local return_rule="-p $proto -m set --match-set $CLIENT_SET src -m set --match-set $LOCAL_NET_SET dst -m $proto --dport $dport -j RETURN"
    local dnat_rule="-p $proto -m set --match-set $CLIENT_SET src -m set --match-set $LOCAL_NET_SET dst -m $proto --dport $dport -j DNAT --to-destination $CTRLD_IP:$CTRLD_PORT"

    # Check if DNAT rule already exists
    if ! iptables -t "$TABLE" -C "$CHAIN" -p "$proto" -m set --match-set "$CLIENT_SET" src -m set --match-set "$LOCAL_NET_SET" dst -m "$proto" --dport "$dport" -j DNAT --to-destination "$CTRLD_IP:$CTRLD_PORT" 2>/dev/null; then
        # Find the line number of the RETURN rule
        local line
        line=$(iptables -t "$TABLE" -L "$CHAIN" --line-numbers | grep -F "$return_rule" | awk '{print $1}' | head -n1)
        if [ -n "$line" ]; then
            # Insert DNAT rule just before RETURN rule
            iptables -t "$TABLE" -I "$CHAIN" "$line" -p "$proto" -m set --match-set "$CLIENT_SET" src -m set --match-set "$LOCAL_NET_SET" dst -m "$proto" --dport "$dport" -j DNAT --to-destination "$CTRLD_IP:$CTRLD_PORT"
        else
            # If RETURN rule not found, just append
            iptables -t "$TABLE" -A "$CHAIN" -p "$proto" -m set --match-set "$CLIENT_SET" src -m set --match-set "$LOCAL_NET_SET" dst -m "$proto" --dport "$dport" -j DNAT --to-destination "$CTRLD_IP:$CTRLD_PORT"
        fi
    fi
}

# Main execution
echo "Configuring DNS redirection rules..."

# Insert custom PBR rules for UDP and TCP port 53
insert_pbr_dns_rules "udp" 53
insert_pbr_dns_rules "tcp" 53

echo "DNS rules configuration completed"
