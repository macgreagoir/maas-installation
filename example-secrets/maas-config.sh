#!/bin/bash
# Export MAAS config used in the installation

export MAAS_DOMAIN=maas
export MAAS_ARCH=amd64/generic
export MAAS_USER=maas-root
# Use `pwgen 16` to generate some
export MAAS_USER_PASSWD=THISISNOTAPASSWORD
# p=THISISNOTAPASSWORD; echo $p; mkpasswd -m md5 -s <<<"$p"
export RESCUE_USER_PASS='$1$3hzVUXkf$ysW5MsjOzkIvJ2XRubD5v/'
