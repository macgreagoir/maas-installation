#!/bin/bash
#
# This file is part of maas-installation.
# Configure MAAS.
# Copyright 2015 Canonical Ltd.
# 
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3, as published by the
# Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranties of MERCHANTABILITY,
# SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Run this script as a user with sudo

set -eu

# MAAS_INSTALL is my parent directory
MAAS_INSTALL=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

source $MAAS_INSTALL/secrets/network.sh || exit $?
: ${MAAS_PRIV_IFACE?} ${MAAS_PRIV_IP?} ${IP_RANGE_HIGH?} ${IP_RANGE_LOW?} \
  ${MANAGEMENT?} ${BROADCAST_IP?} ${ROUTER_IP?}
source $MAAS_INSTALL/secrets/maas-config.sh || exit $?
: ${MAAS_USER?} ${MAAS_USER_PASSWD?}

# Create $MAAS_USER user
if [[ -z "$(sudo maas-region-admin apikey --username $MAAS_USER)" ]]; then
    sudo maas-region-admin createadmin \
        --username=${MAAS_USER} --password=${MAAS_USER_PASSWD} \
        --email=ubuntu$(hostname)
    maas login $MAAS_USER http://${MAAS_PRIV_IP}/MAAS/api/1.0/ \
        "$(sudo maas-region-admin apikey --username $MAAS_USER)"

    # Set the key to be set on nodes
    maas $MAAS_USER sshkeys new key="$(cat ~/.ssh/id_rsa.pub)"
else
    # It already exists, so login
    maas login $MAAS_USER http://${MAAS_PRIV_IP}/MAAS/api/1.0/ \
        "$(sudo maas-region-admin apikey --username $MAAS_USER)"
fi

# Configure DHCP
# The interface as set in the maas-server-interfaces.tmpl
# DHCP scope options come from network.sh and are written to a string for
# node-group-interface update
# TODO How can we set the domain name ($MAAS_DOMAIN)?
dhcp_options=''
for o in STATIC_IP_RANGE_HIGH STATIC_IP_RANGE_LOW \
         IP_RANGE_HIGH IP_RANGE_LOW \
         MANAGEMENT BROADCAST_IP ROUTER_IP; do
    dhcp_options="$dhcp_options ${o,,}=${!o}"
done
node_group_uuid=$(maas $MAAS_USER node-groups list | awk -F\" '/uuid/ {print $4}')
maas $MAAS_USER node-group-interface update \
    $node_group_uuid $MAAS_PRIV_IFACE $dhcp_options

# Import the PXE boot images
# NOTE This returns asynchronously, before the downloads complete
maas $MAAS_USER boot-resources import

# Set upstream DNS if any
if [[ -n "$UPSTREAM_DNS" ]]; then
    maas $MAAS_USER maas set-config name=upstream_dns value="${UPSTREAM_DNS}"
fi

# Set the default kernel opts for consoles
maas maas-root maas set-config name=kernel_opts \
    value="console=tty0 console=ttyS0,115200 console=ttyS1,115200 panic=30 raid=noautodetect"

# Set the kernel opts for the virtual tag if it exists
if maas maas-root tag read virtual 2>&1 >/dev/null; then 
    maas maas-root tag update virtual \
       kernel_opts='console=tty0 console=ttyS0,115200 panic=30'
fi

