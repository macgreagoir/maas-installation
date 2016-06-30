#!/bin/bash
#
# This file is part of maas-installation.
# Uninstall MAAS.
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

# Uninstall maas and dependencies. Explicitly purge dbconfig-common to
# work around lp:1540548
sudo apt-get purge maas* bind9 dbconfig-common* postgresql*
sudo apt-get autoremove
