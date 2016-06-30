#!/bin/bash
#
# This file is part of maas-installation.
# Output content for the MAAS server /etc/network/interfaces
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

# This will likely be run on outside the MAAS server, which is not likely to
# have this code repository at the time. For that reason, it does not write
# directly to the file but to std out

set -eu

# MAAS_INSTALL is my parent directory
MAAS_INSTALL=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)

source $MAAS_INSTALL/secrets/network.sh || exit $?
: ${MAAS_PRIV_IP?} ${PRIV_NETMASK?} ${MAAS_PUB_IP?} ${PUB_NETMASK?} ${PUB_GW?} ${DNS_NS?}

replace=''
for v in MAAS_PRIV_IP PRIV_NETMASK MAAS_PUB_IP PUB_NETMASK PUB_GW DNS_NS; do
  replace="${replace}s/@${v}@/${!v}/g;"
done

sed -e "$replace" $MAAS_INSTALL/templates/maas-server-interfaces.tmpl
