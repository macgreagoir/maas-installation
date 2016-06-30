#!/bin/bash
#
# This file is part of maas-installation.
# Install MAAS.
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

set +e
# Generate a passwdless ssh key, if one does not exist
[[ -e ~/.ssh/id_rsa ]] || echo | ssh-keygen -b 2048 -q -N ''
set -e

# Make sure default locale is set, workaround lp:1382774
grep -q LC_ALL /etc/default/locale ||
    sudo su - -c 'echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale'

# Install maas
# NOTE If re-installing first `sudo apt-get purge maas* bind9 dbconfig-common* postgresql*`
dpkg -l software-properties-common > /dev/null || sudo apt-get install -y software-properties-common
[[ -f /etc/apt/sources.list.d/maas-stable-trusty.list ]] || {
    sudo add-apt-repository -y ppa:maas/stable  # 1.9
    sudo apt-get update
}
# libapache2-mod-wsgi has been seen to be missing after a purge
sudo apt-get install -y maas pwgen curl libapache2-mod-wsgi

# IPv4 only for bind
grep -q OPTIONS.*\\-4 /etc/default/bind9 ||
    sudo sed -i 's/^OPTIONS="\(.*\)/OPTIONS="-4 \1/' /etc/default/bind9
# Remove duplicate dnssec config, lp:1540539
grep -q dnssec-validation /etc/bind/named.conf.options &&
    sudo sed -i -r 's/dnssec-validation .*?;//' /etc/bind/named.conf.options

sudo service bind9 restart

# Only listen as proxy on private addr, lp#1379567
maas_proxy_conf=/usr/share/maas/maas-proxy.conf
[[ -f $maas_proxy_conf ]] || maas_proxy_conf=/etc/maas/maas-proxy.conf
sudo sed -i \
    -e "s/^http_port 3128 transparent/http_port ${MAAS_PRIV_IP}:3128 transparent/" \
    -e "s/^http_port 8000/http_port ${MAAS_PRIV_IP}:8000/" \
    $maas_proxy_conf
sudo service maas-proxy restart

# Reconfig MAAS for private addrs 
echo "set maas-cluster-controller/maas-url http://${MAAS_PRIV_IP}/MAAS/" \
    | sudo debconf-communicate
echo "set maas/default-maas-url ${MAAS_PRIV_IP}" \
    | sudo debconf-communicate
sudo dpkg-reconfigure -fnoninteractive maas-cluster-controller
sudo dpkg-reconfigure -fnoninteractive maas-region-controller

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

