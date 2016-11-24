#!/bin/bash
#
# This file is part of maas-installation.
# Creates complete MAAS setup with given host details.
# Copyright 2015 Canonical Ltd.
# Author: JuanJo Ciarlante <jjo@canonical.com>
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

# maas-add-hosts.sh
# * Adds host to maas (nodes new mac_addresses=...)
# * Updates its IPMI details
# * Tags it for use-fastpath-installer
# * For nodes that already exist in MAAS, the node will not be re-added

set -eu

# MAAS_INSTALL is my parent directory
MAAS_INSTALL=$(cd $(dirname ${BASH_SOURCE[0]})/..; pwd)
TEMPLATES_DIR=$MAAS_INSTALL/templates
SECRETS_DIR=$MAAS_INSTALL/secrets

source $SECRETS_DIR/maas-config.sh || exit $?
: ${MAAS_DOMAIN?} ${MAAS_USER?} ${MAAS_ARCH?} ${RESCUE_USER_PASS?}

# Build a list
machines=""

# Commands to add and update machines/nodes and tags
MACHINES_ADD='nodes new autodetect_nodegroup=yes'
MACHINES_LIST='nodes list'
MACHINE_UPDATE='node update'
TAGS_ADD='tags new'
MACHINE_READ='node read'
MACHINE_COMMISSION='node commission'
[[ -f /etc/maas/maas_cluster.conf ]] && {
    # maas 1.8, just load below file for MAAS_URL
    . /etc/maas/maas_cluster.conf
}
[[ -f /etc/maas/clusterd.conf ]] && {
    # maas 1.9
    MAAS_URL=$(awk -F": " '/maas_url/ { print $2 }' /etc/maas/clusterd.conf)
}
[[ -f /etc/maas/rackd.conf ]] && {
    # maas 2.x
    MAAS_URL=$(awk -F": " '/maas_url/ { print $2 }' /etc/maas/rackd.conf)
    MACHINES_ADD='machines create power_type=ipmi'
    MACHINES_LIST='machines read'
    MACHINE_UPDATE='machine update'
    TAGS_ADD='tags create'
    MACHINE_READ='machine read'
    MACHINE_COMMISSION='machine commission'
}

# Fail if no MAAS_URL set
: ${MAAS_URL?}

# Leave only its hostname
MAAS_HOST=${MAAS_URL%/MAAS*}
MAAS_HOST=${MAAS_HOST#http*://}

# replace '/' by '_'
MAAS_ARCH_DASH=${MAAS_ARCH//\//_}

echo MAAS_HOST=$MAAS_HOST
echo MAAS_USER=$MAAS_USER
echo MAAS_ARCH=$MAAS_ARCH

maas_node_setup() {
    local hostname=$1 tags=$2 user=$3 pass=$4 ipmi_ip=$5 priv_mac=$6 pub_mac=$7
    local mac macs_args=""
    for mac in $priv_mac $pub_mac; do
        if [ $mac != "-" ];then
            macs_args="$macs_args mac_addresses=$mac "
        fi
    done
    if [ -n "$macs_args" ]; then
        # Soft-fail if already present
        (set -x
        maas $MAAS_USER $MACHINES_ADD $macs_args architecture=${MAAS_ARCH} hostname=${hostname}.${MAAS_DOMAIN} >/dev/null
        ) || true
    fi

    # Use both hostname with and w/o MAAS_DOMAIN, matches any
    local system_id=$(maas $MAAS_USER $MACHINES_LIST hostname=${hostname} hostname=${hostname}.${MAAS_DOMAIN} | sed -nr '/system_id/s/.* "(.*)",/\1/p')
    echo "mac=$priv_mac system_id=$system_id"
    test -n "$system_id" || { echo "hostname=$hostname not found, skipping"; return 0; }
    machines="$machines $system_id"
    # Update node: add MAAS_ARCH, IPMI type and auth, use-fastpath-installer
    (set -x;maas $MAAS_USER $MACHINE_UPDATE $system_id architecture=${MAAS_ARCH})
    if [ $ipmi_ip != "-" ]; then
        # TODO Not sure I like the tag match yet
        if [[ $tags =~ 'virtual' ]]; then
            # $ipmi_ip is the priv addr of the hosting system
            # $user and $pass are for a user on the host system in the libvirtd group
            (set -x;maas $MAAS_USER $MACHINE_UPDATE $system_id \
                power_type=virsh \
                power_parameters_power_address="qemu+ssh://${user}@${ipmi_ip}/system" \
                power_parameters_power_id=$hostname \
                power_parameters_power_pass=$pass)
        else
            (set -x;maas $MAAS_USER $MACHINE_UPDATE $system_id \
                power_type=ipmi \
                power_parameters_power_driver=LAN_2_0 \
                power_parameters_power_address=$ipmi_ip \
                power_parameters_power_user=$user \
                power_parameters_power_pass=$pass)
        fi
    fi

    if [[ $MACHINE_UPDATE =~ 'node' ]]; then
        (set -x
            # maas 1.7:
            maas $MAAS_USER tag update-nodes use-fastpath-installer add=$system_id > /dev/null || true
            # only maas 1.8, softfail:
            maas $MAAS_USER node update $system_id boot_type=fastpath > /dev/null || true
        )
    fi

    if [ -n "$tags" ]; then
        # Replace , by space:
        for tag in ${tags//,/ };do
            (set -x +e # ignore if existing
            maas $MAAS_USER $TAGS_ADD name="$tag"
            maas $MAAS_USER tag update-nodes $tag add=$system_id
            ) >/dev/null
        done
    fi
}

main_line() {
    while read line; do
        [[ $line =~ ^#.* ]] && continue
        set -- $line
        main $line
    done < $1
}

main() {
    hostname=${1:?missing hostname, eg: bart}
    tags=${2:?missing tags, eg: infra}
    user=${3:?missing user for ipmi, eg: root}
    pass=${4:?missing pass for ipmi, eg: n0tap4ss}
    ipmi_ip=${5:?missing private ip for ipmi, eg: 10.x.y.z+1}
    priv_mac=${6:?missing priv mac}
    pub_mac=${7:?missing pub mac}

    maas_node_setup $hostname $tags $user $pass $ipmi_ip $priv_mac $pub_mac
}

HOST_INVENTORY=${SECRETS_DIR}/host-inventory.txt

main_line $HOST_INVENTORY

# Machines can start and fail before power config is completed
for id in $machines; do
    if [[ $(maas $MAAS_USER $MACHINE_READ $id | grep -i status.*failed.*commissioning) ]]; then
        maas $MAAS_USER $MACHINE_COMMISSION $id
    fi
done
