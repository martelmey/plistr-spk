##+++ Splunk PS/PRD Heavy Forwarder Logical Domain Setup
##+++ IP address: 192.168.60.213
##+++ Domain/Hostname: np.health.local.kutlprdsplunk02

## ==================== users

useradd splunk -d /home/splunk
usermod -a -G root,wheel splunk

## ==================== yum

mv /etc/yum.conf /etc/yum.conf.old
cp ../conf/yum.conf /etc/
yum update
yum install nfs-utils -y

## ==================== nfs

mkdir -p /export/pkgs
mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/
echo "192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/ nfs4 defaults 0 0" >> /etc/fstab

## ==================== spk

tar -zxvf /export/pkgs/splunk/splunk-8.0.4-767223ac207f-Linux-x86_64.tgz -C /opt/splunk
cp -f /export/pkgs/splunk/conf/.bash_profile /home/splunk
cp -f /export/pkgs/splunk/conf/user-seed.conf /opt/splunk/etc/system/local
cp -f /export/pkgs/splunk/conf/splunk-launch.conf /opt/splunk/etc
cp -f /export/pkgs/splunk/conf/Splunk.License.lic /opt/splunk/etc/licenses/enterprise
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
sudo /opt/splunk/bin/./splunk enable boot-start
splunk add licenses /opt/splunk/etc/licenses/enterprise/Splunk.License.lic -auth splunk:hialplissplunk
splunk enable listen 9997
splunk set deploy-poll 192.168.60.211:8089
# Need to configure this app? \/
splunk enable app SplunkForwarder
splunk add forward-server 192.168.60.211:9997
#had to disable firewalld to access web from browser