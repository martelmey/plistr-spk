#!/usr/bin/bash

# For NP, update
# existing collectd;
# Afterwards integrate
# w/ installAgent, &
# rollout to PS & PRD

hostname=$(hostname)
CONFIG_LOCAL="/opt/collectd/etc/collectd.conf"
METHOD_LOCAL="/opt/collectd/svc/collectdsvc.sh"

cp $CONFIG_LOCAL /opt/collectd/etc/collectd.conf.old
rm $CONFIG_LOCAL
cp /export/pkgs/splunk/collectd_stock.conf $CONFIG_LOCAL

echo "<Plugin write_splunk>" >> $CONFIG_LOCAL
    # Env dims
if [[ $(hostname) = dev-* ]]; then
    echo '  Dimension "env:np-dev"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *np* ]]; then
    echo '  Dimension "env:np"' >> $CONFIG_LOCAL
elif [[ $(hostname) = test-* ]]; then
    echo '  Dimension "env:np-test"' >> $CONFIG_LOCAL
elif [[ $(hostname) = kdcps-* ]]; then
    echo '  Dimension "env:ps"' >> $CONFIG_LOCAL
elif [[ $(hostname) = kdcprd-* ]]; then
    echo '  Dimension "env:prd"' >> $CONFIG_LOCAL
fi
    # App dims
if [[ $(hostname) = *hial* ]]; then
    echo '  Dimension "app:hial"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *posia* ]]; then
    echo 'Dimension "app:posia"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *fam* ]]; then
    echo '  Dimension "app:fam"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *cmu* ]]; then
    echo '  Dimension "app:cmu"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *idm* ]]; then
    echo '  Dimension "app:idm"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *lab* ]]; then
    echo '  Dimension "app:lab"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *cache* ]]; then
    echo '  Dimension "app:cache"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *ohs* ]]; then
    echo '  Dimension "app:ohs"' >> $CONFIG_LOCAL
elif [[ $(hostname) = *db* ]]; then
    echo '  Dimension "app:db"' >> $CONFIG_LOCAL
fi
(
    echo '  Port "8088"'
    echo '  Token "993f234d-e1e1-424f-a007-177c20566d3c"'
    echo '  Server "192.168.60.211"'
    echo '  Ssl false'
    echo '  SplunkMetricTransform true'
    echo '  DiskAsDimensions true'
    echo '  InterfaceAsDimensions true'
    echo '  CpuAsDimensions true'
    echo '  DfAsDimensions true'
    echo '</Plugin>'
)>>$CONFIG_LOCAL

if [[ ! -f /opt/collectd/svc/collectdsvc.sh ]]; then
    cp /export/pkgs/splunk/collectdsvc.sh /opt/collectd/svc/collectdsvc.sh
    chmod +x /opt/collectd/svc/collectdsvc.sh
fi

$METHOD_LOCAL restart
$METHOD_LOCAL status