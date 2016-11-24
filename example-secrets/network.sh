# Export the variables used to create network interfaces configurations.
# Used in maas_server_interfaces.tmpl and maas_interfaces.tmpl.

# Align with maas_server_interfaces.tmpl
export MAAS_PRIV_IFACE=eth0
export MAAS_PRIV_IP=::ffff:0:0:192.168.122.10
export PRIV_GW=::ffff:0:0:192.168.122.1
export PRIV_SUBNET=::ffff:0:0
export PRIV_NETMASK=96
export DNS_NS="$MAAS_PRIV_IP"
# Dynamic are addresses used for PXE; commissioning and, if DHCP, deployment
export DYNAMIC_RANGE_LOW=::ffff:0:0:192.168.122.40
export DYNAMIC_RANGE_HIGH=::ffff:0:0:192.168.122.99
# Reserved are addresses MAAS will not assign to machines
export RESERVED_RANGE_LOW=::ffff:0:0:192.168.122.1
export RESERVED_RANGE_HIGH=::ffff:0:0:192.168.122.39
# Space-separated list of dns forwarders. Leave empty for system
# defaults
export UPSTREAM_DNS=''
