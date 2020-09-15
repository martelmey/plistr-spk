##+++--- Splunk PS/PRD Control Domain Setup
##+++--- 192.168.60.210 (eno1)
##+++--- April 29 2020
##+++--- martel.meyers

## VNC/Jump :  ssh martel.meyers@192.168.60.210 -L 5900:127.0.0.1:5900 -g
## SPK/Jump : ssh martel.meyers@192.168.60.211 -L 8000:127.0.0.1:8000 -g
## Local : From=5900(remote) To=127.0.0.1:5900(local) <defaultuser>65.110.171.190:2022

## ==================== brctl

#mac address='52:54:00:b9:84:a0'
#ether 00:10:e0:eb:af:44
(
	echo "DEVICE=br0"
	echo "TYPE=Bridge"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.60.210"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.60.254"
	echo "NM_CONTROLLED=no"
	echo "DELAY=0"
	echo "PEERDNS=no"
	echo "DNS1=192.168.60.249"
	echo "DNS2=192.168.60.248"
)>/etc/sysconfig/network-scripts/ifcfg-br0

#ether 00:10:e0:eb:af:44
(
	echo "DEVICE=eno1"
	echo "TYPE=Ethernet"
	echo "NAME=eno1"
	echo "ONBOOT=yes"
	echo "BRIDGE=br0"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-eno1

#mac address='52:54:00:43:f9:9d'
#ether 00:10:e0:eb:af:46
(
	echo "DEVICE=br1"
	echo "TYPE=Bridge"
	echo "ONBOOT=yes"
	echo "IPADDR=10.0.30.210"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.60.254"
	echo "NM_CONTROLLED=no"
	echo "DELAY=0"
	echo "PEERDNS=no"
	echo "DNS1=192.168.60.249"
	echo "DNS2=192.168.60.248"
)>/etc/sysconfig/network-scripts/ifcfg-br1

#ether 00:10:e0:eb:af:46
(
	echo "DEVICE=eno3d1"
	echo "NAME=eno3d1"
	echo "HWADDR=00:10:e0:eb:af:46"
	echo "ONBOOT=yes"
	echo "BRIDGE=br1"
	echo "NM_CONTROLLED=no"
	echo "DNS1=192.168.60.249"
	echo "DNS2=192.168.60.248"
)>/etc/sysconfig/network-scripts/ifcfg-eno3d1

#br2
#mac address='52:54:00:ce:b5:03'
(
	echo "DEVICE=br2"
	echo "TYPE=Bridge"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.57.210"
	echo "PREFIX=23"
	echo "GATEWAY=192.168.57.254"
	echo "NM_CONTROLLED=no"
	echo "DELAY=0"
	echo "PEERDNS=no"
	echo "DNS1=192.168.60.251"
)>/etc/sysconfig/network-scripts/ifcfg-br2

#enp59s0f0
#ether 3c:fd:fe:7b:65:d8
(
	echo "TYPE=Ethernet"
	echo "PROXY_METHOD=none"
	echo "BROWSER_ONLY=no"
	echo "BOOTPROTO=none"
	echo "DEFROUTE=yes"
	echo "IPV4_FAILURE_FATAL=no"
	echo "IPV6INIT=yes"
	echo "IPV6_AUTOCONF=yes"
	echo "IPV6_DEFROUTE=yes"
	echo "IPV6_FAILURE_FATAL=no"
	echo "IPV6_ADDR_GEN_MODE=stable-privacy"
	echo "NAME=enp59s0f0"
	echo "UUID=9bc3400b-fe08-421d-abf4-a3b2e63c4f08"
	echo "DEVICE=enp59s0f0"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.57.210"
	echo "PREFIX=23"
	echo "GATEWAY=192.168.57.254"
	echo "IPV6_PRIVACY=no"
	echo "DNS1=192.168.60.251"
	echo "ZONE=public"
	echo "BRIDGE=br2"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-enp59s0f0

## ==================== yum

cp /etc/yum.conf /etc/yum.conf.old
echo "proxy=http://192.168.60.250:8008" >> /etc/yum.conf
yum update
yum install virt-install
yum groupinstall "Virtualization Tools"

## ==================== nfs

mkdir -p /vms && mkdir /var/log/vms && mkdir /iso-kvm && mkdir /export/pkgs
ln -s /vms /var/log/vms
mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs
echo "192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/ nfs4 defaults 0 0" >> /etc/fstab
cp /export/pkgs/kvm/ol77.iso /iso-kvm

## ==================== kvm

## root : hialplis_N95
virt-install --name=kutlprdsplunk01 \
--network bridge=br0 \
--ram=32000 \
--vcpus=12 \
--disk path=/vms/kutlprdsplunk01,size=80 \
--cdrom=/iso-kvm/ol77.iso \
--os-variant=ol7 \
--graphics vnc

virsh autostart kutlprdsplunk01

## root : hialplis_N95
virt-install --name=kutlnpoemsbx01 \
--network bridge=br0 \
--ram=32000 \
--vcpus=8 \
--disk path=/vms/kutlnpoemsbx01,size=80 \
--cdrom=/iso-kvm/ol77.iso \
--os-variant=ol7 \
--graphics vnc

virsh autostart kutlnpoemsbx01

## root : hialplis_N95
virt-install --name=kutlprdsplunk02 \
--network bridge=br0 \
--ram=32000 \
--vcpus=8 \
--disk path=/vms/kutlprdsplunk02,size=80 \
--cdrom=/iso-kvm/ol77.iso \
--os-variant=ol7 \
--graphics vnc

virsh autostart kutlprdsplunk02

## Change IPs during OS install

## ==================== spkfw

tar -zxvf /export/pkgs/splunk/splunkforwarder-8.0.3-a6754d8441bf-Linux-x86_64.tgz -C /opt
cp -f ../conf/.bash_profile /root
splunk set deploy-poll 192.168.60.211:8089
splunk add forward-server 192.168.60.211:9997
firewall-cmd --zone=public --permanent --add-port=8089/tcp
firewall-cmd --zone=public --permanent --add-port=9997/tcp

## ==================== temp.indxs

chmod --recursive g+rwx /var
usermod -G root,qemu,kvm qemu
mkdir /var/log/audit/splunk-expansion
setfacl -m u:qemu:rwx /var/log/audit/splunk-expansion
setfacl -m u:qemu:rwx /var/log/audit
setfacl -m u:qemu:rwx /var/log
setfacl -m u:qemu:rwx /var
qemu-img create /var/log/audit/kutlprdsplunk01-expansion 150G
virsh attach-disk kutlprdsplunk01 \
--source /var/log/audit/splunk-expansion/kutlprdsplunk01-expansion \
--target vdb \
--persistent
ln -s /var/log/audit/splunk-expansion /splunk-expansion