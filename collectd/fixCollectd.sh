#!/usr/bin/bash

cp -f /export/pkgs/splunk/cron-spkcollectd.sh /opt/collectd/svc/cron-spkcollectd.sh
cp -f /export/pkgs/splunk/collectdsvc.sh /opt/collectd/svc/collectdsvc.sh
chmod +x /opt/collectd/svc/cron-spkcollectd.sh
chmod +x /opt/collectd/svc/collectdsvc.sh
/opt/collectd/svc/collectdsvc.sh stop
/opt/collectd/svc/collectdsvc.sh start
/opt/collectd/svc/collectdsvc.sh tail