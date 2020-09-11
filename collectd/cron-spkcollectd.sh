#!/usr/bin/bash

CONFIG_LOCAL="/opt/collectd/etc/collectd.conf"
PIDFILE="/opt/collectd/run/collectdmon.pid"
DAEMON="/opt/collectd/sbin/collectdmon"
METHOD="/opt/collectd/svc/collectdsvc.sh"

ps -ef | grep collectdmon | grep -v status | grep -v grep

if $? -gt 0; then
    $METHOD start
fi

# /opt/collectd/sbin/collectdmon -P /opt/collectd/run/collectdmon.pid -- -C /opt/collectd/etc/collectd.conf
