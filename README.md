MAAS Installaiton
=================

Prepare a private cloud of servers to be ready for a MAAS deployment

  * Configure the MAAS server network interfaces
  * Install and configure a MAAS server
  * Commission the remaining servers as MAAS nodes


Definitions
-----------

 * *MAAS server* is the machine hosting the MAAS service
 * *MAAS nodes* are the machines managed by the MAAS service
     * These may be *bare metal hosts* or KVM instances


Prerequisites
-------------

0. Install MAAS server operating system

 * Install the latest Ubuntu LTS on the MAAS server
     * Don't use the MAAS server option, just install a standard Ubuntu server


Install and Configure MAAS
-----------------------------------

*On the MAAS server, as a user with full sudo.*

0. Review and edit secrets and templates

 * Copy or extract the code to the MAAS server, into the home directory of a user with full sudo
 * `cp example-secrets/* secrets/` to work from example scripts
 * `secrets/network.sh` should be correct for the network configuration
 * `secrets/maas-config.sh` provides passwords and other options used by MAAS
 * `secrets/host-inventroy.txt` provides items for MAAS node configurations

1. Install and configure MAAS

 * `scripts/install-maas.sh`
     * Requires settings from `secrets/network.sh` and `secrets/maas-config.sh`
     * If MAAS is already installed run `scripts/uninstall-maas.sh` to remove MAAS and its dependencies
 * `scripts/configure-maas.sh`

2. Add hosts to MAAS

 * `sudo scripts/maas-add-hosts.sh`
     * Requires `secrets/host-inventory.txt`
     * Takes some time for each bare metal host to go through a boot cycle
 * The MAAS Web GUI can be accessed at http://${MAAS\_PRIV\_IP}/MAAS
     * The `maas-root` user's password is set in `secrets/maas-config.sh`


Credits
-------

Some of this includes and extends work from my colleagues, including JuanJo Ciarlante.
