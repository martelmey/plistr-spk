#!/bin/bash

## Build instructions for Collectd
## on knpdbdm01 - 192.168.63.20
## Using Oracle Developer Studio

wget https://ips-4-lin-xgcc.s3.amazonaws.com/collectd-5.9-wpatch.tar.gz

pkg install bison gcc SUNWpkgcmds libtool autoconf automake pkg-config flex runtime/perl-526@5.26.2
cd /export/home/martel.meyers/build
cp /export/pkgs/splunk/collectd-5.9-wpatch.tar.gz .
tar -xvf collectd-5.9-wpatch.tar.gz && cd collectd

./build.sh

NM=/usr/bin/gnm PERL=/usr/perl5/5.26/bin/perl ./configure \
--prefix=/export/home/martel.meyers/opt/collectd
--with-gnu-ld \
--disable-perl
#--disable-python

# remove global-pipe from libtool: export_symbols_cmds=
gmake
sudo gmake install