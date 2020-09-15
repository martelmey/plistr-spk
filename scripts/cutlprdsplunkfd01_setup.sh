#!/bin/bash

##+++--- CDC Splunk Indexer/Deployment Server Setup
##+++--- 192.168.160.212 (eth0)
##+++--- 10.20.30.212 (eth1)
##+++--- 192.168.157.212 (eth2)
##+++--- cutlprdsplunkfd01

## ==================== net

##+++--- 192.168.160.212
cp /etc/sysconfig/network-scripts/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0.old
(
    echo "DEVICE=eth0"
	echo "TYPE=Ethernet"
    echo "NAME=eth0"
    echo "IPADDR=192.168.60.211"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.60.254"
	echo "DNS1=192.168.60.249"
    echo "ONBOOT=yes"
    echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-eth0

##+++--- 10.20.30.212
touch /etc/sysconfig/network-scripts/ifcfg-eth1
(
    echo "DEVICE=eth1"
	echo "TYPE=Ethernet"
    echo "NAME=eth1"
    echo "IPADDR=10.20.30.212"
	echo "PREFIX="
	echo "GATEWAY="
	echo "DNS1="
    echo "ONBOOT=yes"
    echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-eth1

##+++--- 192.168.157.212
touch /etc/sysconfig/network-scripts/ifcfg-eth2
(
    echo "DEVICE=eth2"
	echo "TYPE=Ethernet"
    echo "NAME=eth2"
    echo "IPADDR=192.168.157.212"
	echo "PREFIX="
	echo "GATEWAY="
	echo "DNS1="
    echo "ONBOOT=yes"
    echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-eth2

firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=8088/tcp
firewall-cmd --zone=public --permanent --add-port=8089/tcp
firewall-cmd --zone=public --permanent --add-port=9997/tcp
firewall-cmd --zone=public --permanent --add-port=9998/tcp
firewall-cmd --zone=public --permanent --add-port=9999/tcp

## ==================== users

mkdir /home/splunk
touch /home/splunk/.bash_profile
(
    echo "export PATH=/usr/bin:/usr/sbin:/opt/splunk/bin"
    echo "if [ -f /usr/bin/less ]; then"
    echo '    export PAGER="/usr/bin/less -ins"'
    echo "elif [ -f /usr/bin/more ]; then"
    echo '    export PAGER="/usr/bin/more -s"'
    echo "fi"
    echo "case ${SHELL} in"
    echo "*bash)"
    echo '    typeset +x PS1="\u@\h:\w\\$ "'
    echo "    ;;"
    echo "esac"
)>/home/splunk/.bash_profile
source /home/splunk/.bash_profile
useradd splunk -d /home/splunk
groupadd splunk
chown --recursive splunk:splunk /home/splunk/.bash_profile
usermod -G splunk,wheel splunk

## ==================== yum

cp /etc/yum.conf /etc/yum.conf.old
echo "proxy=http://192.168.60.250:8008" >> /etc/yum.conf
yum update
yum install nfs-utils -y

## ==================== nfs

mkdir -p /export/pkgs
# mounts here
chown --recursive splunk:splunk /export/*indx/

## ==================== spk

INSTALL_ROOT="/export/pkgs/splunk"
SPLUNK_TAR="splunk-8.0.6-152fb4b2bb96-Linux-x86_64.tgz"

tar -zxvf $SPLUNK_TAR -C /opt/splunk
touch /opt/splunkforwarder/etc/system/local/user-seed.conf
(
    echo "[user_info]"
    echo "USERNAME = splunkadmin"
    echo "PASSWORD = hialplissplunk"
)>/opt/splunkforwarder/etc/system/local/user-seed.conf
touch /opt/splunkforwarder/etc/splunk-launch.conf
(
    echo "SPLUNK_SERVER_NAME=Splunkd"
    echo "SPLUNK_OS_USER=splunk"
    echo "SPLUNK_HOME=/opt/splunkforwarder"
)>/opt/splunkforwarder/etc/splunk-launch.conf
if [ ! -d /opt/splunk/etc/licenses/enterprise ]; then
    mkdir -p /opt/splunk/etc/licenses/enterprise
fi
cp $INSTALL_ROOT/Splunk.License.lic /opt/splunk/etc/licenses/enterprise
chown --recursive splunk:splunk /opt/splunk/
sudo /opt/splunk/bin/./splunk enable boot-start -user splunk
splunk add licenses /opt/splunk/etc/licenses/enterprise/Splunk.License
splunk enable listen 9997
