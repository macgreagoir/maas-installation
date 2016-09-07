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
: ${MAAS_PRIV_IP?} ${DYNAMIC_RANGE_HIGH?} ${DYNAMIC_RANGE_LOW?} \
  ${PRIV_GW?} ${PRIV_SUBNET?}
source $MAAS_INSTALL/secrets/maas-config.sh || exit $?
: ${MAAS_USER?} ${MAAS_USER_PASSWD?} ${MAAS_DOMAIN?}

# Create $MAAS_USER user
if [[ -z "$(sudo maas-region apikey --username $MAAS_USER)" ]]; then
    sudo maas-region-admin createadmin \
        --username=${MAAS_USER} --password=${MAAS_USER_PASSWD} \
        --email=ubuntu@$(hostname).${MAAS_DOMAIN}
    maas login $MAAS_USER http://${MAAS_PRIV_IP}/MAAS/api/2.0/ \
        "$(sudo maas-region apikey --username $MAAS_USER)"

    # Set the key to be set on nodes
    maas $MAAS_USER sshkeys create key="$(cat ~/.ssh/id_rsa.pub)"
else
    # It already exists, so login
    maas login $MAAS_USER http://${MAAS_PRIV_IP}/MAAS/api/2.0/ \
        "$(sudo maas-region apikey --username $MAAS_USER)"
fi

# Configure DHCP
maas $MAAS_USER ipranges create type=dynamic start_ip=${DYNAMIC_RANGE_LOW} end_ip=${DYNAMIC_RANGE_HIGH}
maas $MAAS_USER ipranges create type=reserved start_ip=${RESERVED_RANGE_LOW} end_ip=${RESERVED_RANGE_HIGH}
fabric=$(maas $MAAS_USER subnet update $PRIV_SUBNET gateway_ip=${PRIV_GW} | awk -F\" '/fabric/ {print $4}')
maas $MAAS_USER vlan update $fabric untagged dhcp_on=True primary_rack=$(hostname)

# Import the PXE boot images
# NOTE This returns asynchronously, before the downloads complete
maas $MAAS_USER boot-resources import

# Set upstream DNS if any
if [[ -n "$UPSTREAM_DNS" ]]; then
    maas $MAAS_USER maas set-config name=upstream_dns value="${UPSTREAM_DNS}"
fi

# Set the default kernel opts for consoles
maas $MAAS_USER maas set-config name=kernel_opts \
    value="console=tty0 console=ttyS0,115200 console=ttyS1,115200 panic=30 raid=noautodetect"

