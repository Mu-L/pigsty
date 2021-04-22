#!/bin/bash
set -euo pipefail

#==============================================================#
# File      :   cache.sh
# Ctime     :   2021-04-22
# Mtime     :   2021-04-22
# Desc      :   make offline cache packages on initialized meta node
# Note      :   run as root
# Path      :   bin/cache.sh
# Copyright (C) 2018-2021 Ruohang Feng
#==============================================================#

PROG_NAME="$(basename $0))"
PROG_DIR="$(cd $(dirname $0) && pwd)"

PKG_PATH=${1-/tmp/pkg.tgz}

# copy grafana plugins
sudo mkdir -p /www/pigsty/grafana                                             # make grafana plugin dir
sudo tar -zcf /www/pigsty/grafana/plugins.tgz -C /var/lib/grafana/ plugins    # pack grafana plugins

# make tarball
sudo tar -zcf /tmp/pkg.tgz -C /www pigsty                                     # /www/pigsty -> /tmp/pkg.tgz
sudo chmod a+r /tmp/pkg.tgz                                                   # global readable

# move to destination location
if [[ ${PKG_PATH} != "/tmp/pkg.tgz" ]]; then
    mv -f /tmp/pkg.tgz ${PKG_PATH}
fi
ls -alh ${PKG_PATH}