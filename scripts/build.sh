#!/bin/bash
set -e
DEBIAN_FRONTEND=noninteractive

# some mirrors have issues, i skipped httpredir in favor of an eu mirror, moved to bullseye

echo "deb http://deb.debian.org/debian/ bullseye main" > /etc/apt/sources.list
echo "deb http://security.debian.org/debian-security bullseye-security main" >> /etc/apt/sources.list

# install dependencies for build
# source: https://learn.netdata.cloud/docs/agent/packaging/installer/methods/manual

apt-get update && \
apt-get install -y curl git && \
bash <(curl -sSL https://raw.githubusercontent.com/netdata/netdata/master/packaging/installer/install-required-packages.sh)

# fix the extra warning when building netdata

git config --global advice.detachedHead false

# fetch netdata

git clone https://github.com/netdata/netdata.git /netdata.git
cd /netdata.git
TAG=$(</git-tag)
if [ ! -z "$TAG" ]; then
	echo "Checking out tag: $TAG"
	git checkout tags/$TAG
else
	echo "No tag, using master"
fi

# fix for https://github.com/netdata/netdata/issues/11652

git submodule update --init --recursive

# use the provided installer

./netdata-installer.sh --dont-wait --dont-start-it --disable-telemetry

# remove build dependencies

cd /
rm -rf /netdata.git

dpkg -P autoconf autogen automake bash cmake curl g++ git iproute2 libelf-dev libjudy-dev liblz4-dev libmnl-dev libprotobuf-dev libssl-dev libuuid1 libuv1-dev libyaml-dev lm-sensors make netcat-openbsd nodejs openssl pkg-config protobuf-compiler python3 python3-mysqldb python3-yaml uuid-dev zlib1g zlib1g-dev

apt-get -y autoremove
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# symlink access log and error log to stdout/stderr

ln -sf /dev/stdout /var/log/netdata/access.log
ln -sf /dev/stdout /var/log/netdata/debug.log
ln -sf /dev/stderr /var/log/netdata/error.log
