#!/bin/bash

##+++--- Splunk PS/PRD Control Domain Setup CDC
##+++--- 192.168.160.10 (enp59s0f2)
##+++--- 10.20.30.10 (enp59s0f1)
##+++--- 192.168.157.10 (enp59s0f0)

## Tunnel: Local(5900) SSH(98.158.92.147:2022) Target(127.0.0.1:5900)

## ==================== brctl

##+++--- 192.168.160.10 (br0)
touch /etc/sysconfig/network-scripts/ifcfg-br0
(
	echo "DEVICE=br0"
	echo "TYPE=Bridge"
	echo "IPADDR=192.168.160.10"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.160.254"
#	echo "DNS1="
#	echo "DNS2="
    echo "ONBOOT=yes"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-br0

cp /etc/sysconfig/network-scripts/ifcfg-enp59s0f2 /etc/sysconfig/network-scripts/ifcfg-enp59s0f2.old
(
	echo "DEVICE=enp59s0f2"
	echo "TYPE=Ethernet"
    echo "NAME=enp59s0f2"
	echo "ONBOOT=yes"
	echo "BRIDGE=br0"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-enp59s0f2

##+++--- 10.20.30.10 (br1)
touch /etc/sysconfig/network-scripts/ifcfg-br1
(
	echo "DEVICE=br1"
	echo "TYPE=Bridge"
	echo "IPADDR=10.20.30.10"
	echo "PREFIX=24"
#	echo "GATEWAY="
#	echo "DNS1="
#	echo "DNS2="
	echo "ONBOOT=yes"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-br1

cp /etc/sysconfig/network-scripts/ifcfg-enp59s0f1 /etc/sysconfig/network-scripts/ifcfg-enp59s0f1.old
(
	echo "DEVICE=enp59s0f1"
	echo "NAME=enp59s0f1"
#	echo "DNS1="
#	echo "DNS2="
    echo "ONBOOT=yes"
	echo "BRIDGE=br1"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-enp59s0f1

##+++--- 192.168.157.10 (br2)
touch /etc/sysconfig/network-scripts/ifcfg-br2
(
	echo "DEVICE=br2"
	echo "TYPE=Bridge"
	echo "IPADDR=192.168.157.10"
	echo "PREFIX=24"
#	echo "GATEWAY="
	echo "DNS1=192.168.60.251"
	echo "ONBOOT=yes"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-br2

cp /etc/sysconfig/network-scripts/ifcfg-enp59s0f0 /etc/sysconfig/network-scripts/ifcfg-enp59s0f0.old
(
	echo "DEVICE=enp59s0f0"
	echo "NAME=enp59s0f0"
	echo "TYPE=Ethernet"
	echo "IPADDR=192.168.157.10"
	echo "PREFIX=24"
#	echo "GATEWAY="
#	echo "DNS1="
	echo "ONBOOT=yes"
	echo "BRIDGE=br2"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-enp59s0f0

## ==================== yum

cp /etc/yum.conf /etc/yum.conf.old
echo "proxy=http://192.168.60.250:8008" >> /etc/yum.conf
yum install virt-install
yum groupinstall "Virtualization Tools"

## ==================== fs

mkdir -p /vms && mkdir /var/log/audit/vms && mkdir /iso-kvm
scp martel.meyers@192.168.60.250:/home/martel.meyers/ol77.iso /iso-kvm
ln -s /vms /var/log/audit/vms

## ==================== kvm

## cutlprdsplunkfd01
## root : hialplis_N95
virt-install --name=cutlprdsplunkfd01 \
--network bridge=br0 \
--ram=32000 \
--vcpus=16 \
--disk path=/vms/cutlprdsplunkfd01,size=80 \
--cdrom=/iso-kvm/ol77.iso \
--os-variant=ol7 \
--graphics vnc

virsh autostart cutlprdsplunkfd01