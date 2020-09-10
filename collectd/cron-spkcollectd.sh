#!/usr/bin/bash

CONFIG_LOCAL="/opt/collectd/etc/collectd.conf"
PIDFILE="/opt/collectd/run/collectdmon.pid"
DAEMON="/opt/collectd/sbin/collectdmon"

ps -ef | grep collectdmon | grep -v status | grep -v grep

if $? -gt 0; then
    $DAEMON -P $PIDFILE -- -C $CONFIG_LOCAL
fi

# ./collectdmon -P /opt/collectd/run/collectdmon.pid -- -C /opt/collectd/etc/collectd.conf