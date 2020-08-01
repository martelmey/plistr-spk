##+++--- Splunk NP Control Domain Setup
##+++--- 192.168.63.240
##+++--- Subnet mask: 255.255.255.0
##+++--- Default gateway: 192.168.63.254
##+++--- Preferred DNS: 192.168.63.249
##+++--- martel.meyers

## VNC/Jump :  ssh martel.meyers@192.168.63.240 -L 5900:127.0.0.1:5900 -g
## SPK/Jump : ssh martel.meyers@192.168.63.240 -L 8000:127.0.0.1:8000 -g
## Local : From=5900(remote) To=127.0.0.1:5900(local) <defaultuser>65.110.171.190:3022

## ==================== brctl

(
	echo "DEVICE=br0"
	echo "TYPE=Bridge"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.63.240"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.63.254"
	echo "NM_CONTROLLED=no"
	echo "DELAY=0"
	echo "PEERDNS=no"
)>/etc/sysconfig/network-scripts/ifcfg-br0

(
	echo "DEVICE=eno1"
	echo "TYPE=Ethernet"
	echo "NAME=eno1"
	echo "ONBOOT=yes"
	echo "BRIDGE=br0"
	echo "NM_CONTROLLED=no"
)>/etc/sysconfig/network-scripts/ifcfg-eno1

(
	echo "DEVICE=br1"
	echo "TYPE=Bridge"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.57.240"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.63.254"
	echo "NM_CONTROLLED=no"
	echo "DELAY=0"
	echo "PEERDNS=no"
)>/etc/sysconfig/network-scripts/ifcfg-br1

(
	echo "DEVICE=enp59s0f0"
	echo "TYPE=Ethernet"
	echo "PROXY_METHOD=none"
	echo "BROWSER_ONLY=no"
	echo "DEFROUTE=yes"
	echo "BOOTPROTO=none"
	echo "IPV4_FAILURE_FATAL=no"
	echo "IPV6INIT=yes"
	echo "IPV6_AUTOCONF=yes"
	echo "IPV6_DEFROUTE=yes"
	echo "IPV6_FAILURE_FATAL=no"
	echo "IPV6_ADDR_GEN_MODE=stable-privacy"
	echo "NAME=enp59s0f0"
	echo "UUID=0687ba40-8311-4336-8084-a4b029aab51f"
	echo "ONBOOT=yes"
	echo "DNS1=192.168.63.237"
	echo "GATEWAY=192.168.57.254"
	echo "PREFIX=23"
	echo "IPV6_PRIVACY=no"
	echo "IPADDR=192.168.57.240"
	echo "ZONE=public"
	echo "NM_CONTROLLED=no"
	echo "BRIDGE=br1"
)>/etc/sysconfig/network-scripts/ifcfg-enp59s0f0

## ==================== yum

mv /etc/yum.conf /etc/yum.conf.old
cp ../conf/yum.conf /etc/
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

firewall-cmd --zone=public --permanent --add-port=5900/tcp

## root : hialplis_N95
virt-install --name=kutlnpsplunk01 \
--network bridge=br0 \
--ram=32000 \
--vcpus=6 \
--disk path=/vms/kutlnpsplunk01,size=80 \
--cdrom=/iso-kvm/ol77.iso \
--os-variant=ol7 \
--graphics vnc

virsh autostart kutlnpsplunk01