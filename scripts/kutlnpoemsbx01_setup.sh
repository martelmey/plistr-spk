##+++ OEM Sandbox Logical Domain Setup
##+++ IP Address: 192.168.60.212
##+++ Domain/Hostname: np.health.local.kutlprdnpoemsbx01

useradd leonardo.garland -d /home/leonardo.garland
passwd leonardo.garland #welcome2020
passwd --expire leonardo.garland
usermod -a -G wheel leonardo.garland
useradd jacques.levesque -d /home/jacques.levesque
passwd jacques.levesque #welcome2020
passwd --expire jacques.levesque
usermod -a -G wheel jacques.levesque
useradd duff.masterson -d /home/duff.masterson
passwd duff.masterson #welcome2020
passwd --expire duff.masterson
usermod -a -G wheel duff.masterson
#vi /etc/group

## ==================== yum

mv /etc/yum.conf /etc/yum.conf.old
cp ../conf/yum.conf /etc/
yum update

## ==================== nfs

mkdir -p /export/pkgs
cp -f ../conf/yum.conf /etc/
mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/
echo "192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/  nfs defaults 0 0" >> /etc/fstab

## ==================== spkfw

useradd splunk -d /home/splunk
usermod -a -G wheel splunk
tar -zxvf /export/pkgs/splunk/splunkforwarder-8.0.3-a6754d8441bf-Linux-x86_64.tgz -C /opt
cp -f ../conf/.bash_profile /root
splunk set deploy-poll 192.168.60.211:8089
splunk add forward-server 192.168.60.211:9997
firewall-cmd --zone=public --permanent --add-port=8089/tcp
firewall-cmd --zone=public --permanent --add-port=9997/tcp
# install collectd