##+++ Splunk NP Heavy Forwarder Logical Domain Setup
##+++ IP address: 192.168.63.241
##+++--- Subnet mask: 255.255.255.0
##+++--- Default gateway: 192.168.63.254
##+++--- Preferred DNS: 192.168.63.249
##+++ Domain/Hostname: np.health.local.kutlnpsplunk01

## ==================== users

useradd splunk -d /home/splunk
usermod -a -G root,wheel splunk

## ==================== yum

#Proxy method
mv /etc/yum.conf /etc/yum.conf.old
cp ../conf/yum.conf /etc/yum.conf
#Local repo method
cp ../conf/npyum_local-yum.repo /etc/yum.repos.d/local-yum.repo
mv /etc/yum.repos.d/oracle-linux-ol7.repo oracle-linux-ol7.repo.disabled
mv /etc/yum.repos.d/uek-ol7.repo uek-ol7.repo.disabled
mv /etc/yum.repos.d/virt-ol7.repo virt-ol7.repo.disabled

yum update
yum install nfs-utils -y

## ==================== nfs

mkdir -p /export/pkgs
mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/
echo "192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/ nfs4 defaults 0 0" >> /etc/fstab

## ==================== spk

tar -zxvf /export/pkgs/splunk/splunk-8.0.4-767223ac207f-Linux-x86_64.tgz -C /opt
mkdir -p /opt/splunk/etc/licenses/enterprise
cp -f /export/pkgs/splunk/conf/Splunk.License.lic /opt/splunk/etc/licenses/enterprise
cp -f /export/pkgs/splunk/conf/cdom_bash_profile /home/splunk/.bash_profile
cp -f /export/pkgs/splunk/conf/hforwarder_NP_user-seed.conf /opt/splunk/etc/system/local/user-seed.conf
cp -f /export/pkgs/splunk/conf/hforwarder_NP_splunk-launch.conf_hforwarder /opt/splunk/etc/splunk-launch.conf
cp -f /export/pkgs/splunk/conf/hforwarder_outputs.conf /opt/splunk/etc/system/local/outputs.conf
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
splunk add licenses /opt/splunk/etc/licenses/enterprise/Splunk.License.lic -auth splunk:hialplissplunk
splunk enable listen 9997
# Need to configure this app? \/
splunk enable app SplunkForwarder
splunk set deploy-poll 192.168.60.211:8089
splunk add forward-server 192.168.60.211:9997
cp /opt/splunk/etc/system/default/props.conf /opt/splunk/etc/system/local
cp /opt/splunk/etc/system/default/transforms.conf /opt/splunk/etc/system/local