# Export the variables used to create network interfaces configurations.
# Used in maas_server_interfaces.tmpl and maas_interfaces.tmpl.

# Align with maas_server_interfaces.tmpl
export MAAS_PRIV_IFACE=eth0
export MAAS_PRIV_IP=10.0.2.10
export PRIV_NETMASK=255.255.254.0
export MAAS_PUB_IP=1.1.1.10
export PUB_NETMASK=255.255.255.0
export PUB_GW=1.1.1.1
export DNS_NS="$MAAS_PRIV_IP 8.8.8.8 8.8.4.4"
# MAAS DHCP scope on private network
export STATIC_IP_RANGE_LOW=10.0.2.100
export STATIC_IP_RANGE_HIGH=10.0.3.109
export IP_RANGE_LOW=10.0.2.110
export IP_RANGE_HIGH=10.0.3.239
export BROADCAST_IP=10.0.3.255
export ROUTER_IP=10.0.2.1
# no management (0), manage DHCP (1), manage DHCP and DNS (2)
export MANAGEMENT=2
# Space-separated list of dns forwarders. Leave empty for system
# defaults
export UPSTREAM_DNS=''
