# Export the variables used to create network interfaces configurations.
# Used in maas_server_interfaces.tmpl and maas_interfaces.tmpl.

# Align with maas_server_interfaces.tmpl
export MAAS_PRIV_IFACE=eth0
export MAAS_PRIV_IP=192.168.123.10
export PRIV_GW=192.168.123.1
export PRIV_SUBNET='192.168.123.0/24'
export PRIV_NETMASK=255.255.254.0
export MAAS_PUB_IP=192.168.124.10
export PUB_NETMASK=255.255.255.0
export PUB_GW=192.168.124.1
export DNS_NS="$MAAS_PRIV_IP 8.8.8.8 8.8.4.4"
# Dynamic are addresses used for PXE; commissioning and, if DHCP, deployment
export DYNAMIC_RANGE_LOW=192.168.123.40
export DYNAMIC_RANGE_HIGH=192.168.123.99
export BROADCAST_IP=192.168.123.255
# Reserved are addresses MAAS will not assign to machines
export RESERVED_RANGE_LOW=192.168.123.1
export RESERVED_RANGE_HIGH=192.168.123.39
# Space-separated list of dns forwarders. Leave empty for system
# defaults
export UPSTREAM_DNS=''
