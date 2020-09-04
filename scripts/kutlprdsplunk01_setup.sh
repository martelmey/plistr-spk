##+++ Splunk Central Indexer/Deployment Server Logical Domain Setup
##+++ IP address: 192.168.60.211
##+++ Domain/Hostname: np.health.local.kutlprdsplunk01

## ==================== net

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
	echo "NAME=eth0"
	echo "UUID=4201f9c5-aa90-41ee-9bbe-5ee623b36655"
	echo "DEVICE=eth0"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.60.211"
	echo "NETMASK=255.255.255.0"
	echo "PREFIX=24"
	echo "GATEWAY=192.168.60.254"
	echo "DNS1=192.168.60.249"
	echo "IPV6_PRIVACY=no"
)>/etc/sysconfig/network-scripts/ifcfg-eth0

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
	echo "NAME=eth1"
	echo "DEVICE=eth1"
	echo "ONBOOT=yes"
	echo "IPADDR=192.168.57.211"
	echo "PREFIX=23"
	echo "GATEWAY=192.168.57.254"
	echo "DNS1=192.168.60.251"
	echo "IPV6_PRIVACY=no"
)>/etc/sysconfig/network-scripts/ifcfg-eth1

## ==================== users

useradd splunk -d /home/splunk
usermod -a -G root,wheel splunk
useradd duff.masterson -d /home/duff.masterson
passwd duff.masterson #welcome2020
passwd --expire duff.masterson
usermod -a -G wheel duff.masterson
useradd jacques.levesque -d /home/jacques.levesque
passwd jacques.levesque #welcome2020
passwd --expire jacques.levesque
usermod -a -G wheel jacques.levesque
useradd matthew.stanley -d /home/matthew.stanley
passwd matthew.stanley #welcome2020
passwd --expire matthew.stanley
usermod -a -G wheel matthew.stanley

## ==================== yum

mv /etc/yum.conf /etc/yum.conf.old
cp ../conf/yum.conf /etc/
yum update
yum install nfs-utils -y

## ==================== nfs

#mount 192.168.61.132:\export/utilities-splunk/npindx /export/npindx

mkdir -p /export/pkgs
mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/
echo "192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/ nfs4 defaults 0 0" >> /etc/fstab
mkdir /export/npindx && mkdir /export/psindx && mkdir /export/prdindx && mkdir /export/intindx
mount 192.168.61.132:\export/utilities-splunk/npindx /export/npindx/
echo "192.168.61.132:\export/utilities-splunk/npindx /export/npindx/ nfs4 defaults 0 0" >> /etc/fstab
mount 192.168.61.132:\export/utilities-splunk/psindx /export/psindx/
echo "192.168.61.132:\export/utilities-splunk/psindx /export/psindx/ nfs4 defaults 0 0" >> /etc/fstab
mount 192.168.61.132:\export/utilities-splunk/prdindx /export/prdindx/
echo "192.168.61.132:\export/utilities-splunk/prdindx /export/prdindx/ nfs4 defaults 0 0" >> /etc/fstab
mount 192.168.61.132:\export/utilities-splunk/intindx /export/intindx/
echo "192.168.61.132:\export/utilities-splunk/intindx /export/intindx/ nfs4 defaults 0 0" >> /etc/fstab
chown --recursive splunk:splunk /export/*indx/

## ==================== spk

rpm --install /export/pkgs/splunk/jdk-11.0.7_linux-x64_bin.rpm
tar -zxvf /export/pkgs/splunk/splunk-8.0.3-a6754d8441bf-Linux-x86_64.tgz -C /opt/splunk
cp -f ../conf/.bash_profile /home/splunk
cp -f ../conf/user-seed.conf /opt/splunk/etc/system/local
cp -f ../conf/central_PSPR_inputs.conf /opt/splunk/etc/system/local
cp -f ../conf/splunk-launch.conf /opt/splunk/etc
mkdir -p /opt/splunk/etc/licenses/enterprise
cp ../Splunk.License.lic /opt/splunk/etc/licenses/enterprise
firewall-cmd --zone=public --permanent --add-port=8088/tcp
firewall-cmd --zone=public --permanent --add-port=8000/tcp
firewall-cmd --zone=public --permanent --add-port=8089/tcp
firewall-cmd --zone=public --permanent --add-port=9997/tcp
firewall-cmd --zone=public --permanent --add-port=9998/tcp
firewall-cmd --zone=public --permanent --add-port=9999/tcp
chown --recursive splunk:splunk /opt/splunk/
sudo /opt/splunk/bin/./splunk enable boot-start -systemd-managed 1 -user splunk
sed -i '/[Service]/a LimitNOFILE=65536' /etc/systemd/system/Splunkd.service
sed -i '/[Service]/a LimitNPROC=16000' /etc/systemd/system/Splunkd.service 
sed -i '/[Service]/a LimitDATA=8000000000' /etc/systemd/system/Splunkd.service 
sed -i '/[Service]/a LimitFSIZE=infinity' /etc/systemd/system/Splunkd.service 
sed -i '/[Service]/a TasksMax=16000' /etc/systemd/system/Splunkd.service
sed -i '/GRUB_CMDLINE_LINUX="/ s/$/transparent_hugepage=never/' /etc/default/grub
#sed -i 's/GRUB_CMDLINE_LINUX="/& transparent_hugepage=never/' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg ## Reboot required here
#add splunk to visudo file
splunk add licenses /opt/splunk/etc/licenses/enterprise/Splunk.License
splunk add user observer -role user -password password123 -full-name "Read-Only User"
splunk enable listen 9997

###
#### APPS
###

tar -zxvf /export/pkgs/splunk/appsnadons/splunk-add-on-for-infrastructure_203.tgz -C /opt/splunk/etc/apps
tar -zxvf /export/pkgs/splunk/appsnadons/splunk-app-for-infrastructure_210.tgz -C /opt/splunk/etc/apps
tar -zxvf /export/pkgs/splunk/appsnadons/splunk-linux-add-on.tgz -C /opt/splunk/etc/apps
tar -zxvf /export/pkgs/splunk/appsnadons/splunk-db-connect_331.tgz -C /opt/splunk/etc/apps
tar -zxvf /export/pkgs/splunk/appsnadons/splunk-add-on-for-oracle-database_370.tgz -C /opt/splunk/etc/apps
tar -zxvf /export/pkgs/splunk/appsnadons/oracle-weblogic-app-for-splunk_30-beta.tgz -C /opt/splunk/etc/apps

###
#### APP CONFIGS
###

mkdir /opt/splunk/etc/apps/Splunk_TA_nix/local
cp /opt/splunk/etc/apps/Splunk_TA_nix/default/inputs.conf /opt/splunk/etc/apps/Splunk_TA_nix/local
cp -f ../conf/inputs_splunk_app_infrastructure.conf /opt/splunk/etc/apps/splunk_app_infrastructure/local
cp -f ../conf/outputs_splunk_app_infrastructure.conf /opt/splunk/etc/apps/splunk_app_infrastructure/local

###
#### DEPLOYMENT APPS
###

cp -rf /opt/splunk/etc/apps/Splunk_TA_nix/ /opt/splunk/etc/deployment-apps
cp -rf /opt/splunk/etc/apps/Splunk_TA_oracle/ /opt/splunk/etc/deployment-apps
cp -rf /opt/splunk/etc/apps/Function1_WebLogicServer/ /opt/splunk/etc/deployment-apps
tar -zxvf /export/pkgs/splunk/appsnadons/metrics-add-on-for-infrastructure_103.tgz -C /opt/splunk/etc/deployment-apps/TA-linux-metrics_ol7
tar -zxvf /export/pkgs/splunk/appsnadons/CUSTOM_SOLARIS_METRICS_SCRIPTS.tgz -C /opt/splunk/etc/deployment-apps/TA-linux-metrics_sunos
tar -zxvf /export/pkgs/splunk/appsnadons/ol7_serverclass_base.tgz -C /opt/splunk/etc/deployment-apps
tar -zxvf /export/pkgs/splunk/appsnadons/sunos_serverclass_base.tgz -C /opt/splunk/etc/deployment-apps

# Always run after change:
chown --recursive splunk:splunk /opt/splunk/
splunk restart

## ==================== temp space fix

mkdir /export/os_evt_np-temp
mkdir /export/os_evt_np-temp/db
mkdir /export/os_evt_np-temp/colddb
mkdir /export/os_evt_np-temp/thaweddb

mkdir /export/db_np-temp
mkdir /export/db_np-temp/db
mkdir /export/db_np-temp/colddb
mkdir /export/db_np-temp/thaweddb

mkdir /export/wls_np-temp
mkdir /export/wls_np-temp/db
mkdir /export/wls_np-temp/colddb
mkdir /export/wls_np-temp/thaweddb