#!/bin/bash
set -eux

# make sure we are in current directory
cd "$(dirname "$0")"

if [[ $EUID -ne 0  ]]; then
  echo "This script must be run as root"
  exit 1
fi

mkdir bootstrap

debootstrap --arch=amd64 --variant=minbase stable bootstrap

echo "Pick root password"
systemd-nspawn -D bootstrap passwd

echo "Add user c and pick password"
systemd-nspawn -D bootstrap adduser c

systemd-nspawn -D bootstrap -P /bin/bash <<EOT

DEBIAN_FRONTEND=noninteractive apt -y install --no-install-recommends tmux less vim wget ca-certificates ssh git unzip xz-utils procps inotify-tools sqlite3 autoconf automake build-essential libtool libgmp-dev libsqlite3-dev python3 python3-mako net-tools zlib1g-dev libsodium-dev gettext

su - c

NODE_VERSION=v16.15.0
BITCOIN_VERSION=22.0
CLIGHTNING_VERSION=v22.11.1

wget https://nodejs.org/dist/\$NODE_VERSION/node-\$NODE_VERSION-linux-x64.tar.xz
tar xvf node-\$NODE_VERSION-linux-x64.tar.xz
rm node-\$NODE_VERSION-linux-x64.tar.xz

wget https://bitcoin.org/bin/bitcoin-core-\$BITCOIN_VERSION/bitcoin-\$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
tar xvf bitcoin-\$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz
rm bitcoin-\$BITCOIN_VERSION-x86_64-linux-gnu.tar.gz

wget https://github.com/ElementsProject/lightning/releases/download/\$CLIGHTNING_VERSION/clightning-\$CLIGHTNING_VERSION.zip
unzip clightning-\$CLIGHTNING_VERSION.zip
rm clightning-\$CLIGHTNING_VERSION.zip

cd clightning-\$CLIGHTNING_VERSION
./configure
make

cd

echo 'export PS1="\W\$ "' >> .bashrc

echo "export PATH=$PATH:/home/c/node-\$NODE_VERSION-linux-x64/bin:/home/c/bitcoin-\$BITCOIN_VERSION/bin:/home/c/clightning-\$CLIGHTNING_VERSION/lightningd:/home/c/clightning-\$CLIGHTNING_VERSION/cli" >> .bashrc

EOT
