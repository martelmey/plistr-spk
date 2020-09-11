#!/usr/bin/bash

mv /opt/splunkforwarder/etc/system/local/outputs.conf /opt/splunkforwarder/etc/system/local/outputs.conf.old
touch /opt/splunkforwarder/etc/system/local/outputs.conf
#sed -i 's/server = 192.168.63.241:9997/server = 192.168.60.70:9997/g' /opt/splunkforwarder/etc/system/local/outputs.conf
(
    echo "[tcpout]"
    echo "defaultGroup = np-heavy-forwarder"
    echo "[tcpout:np-heavy-forwarder]"
    echo "disabled = false"
    echo "server = 192.168.60.70:9997"
    echo "useACK = true"
)>/opt/splunkforwarder/etc/system/local/outputs.conf
su - splunk -c 'splunk restart'
su - splunk -c 'splunk list forward-server'
cat /opt/splunkforwarder/etc/system/local/outputs.conf