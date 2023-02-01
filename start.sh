#!/bin/bash
set -eux
cd "$(dirname "$0")"
sudo systemd-nspawn -D bootstrap -u c -M acceptbitcoin-env
