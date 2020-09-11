#!/usr/bin/bash

# for np

#hostname=$(hostname)
CONFIG_LOCAL="/opt/collectd/etc/collectd.conf"
METHOD_LOCAL="/opt/collectd/svc/collectdsvc.sh"

cp $CONFIG_LOCAL /opt/collectd/etc/collectd.conf.old
rm $CONFIG_LOCAL
cp /export/pkgs/splunk/collectd_stock.conf $CONFIG_LOCAL

echo "<Plugin write_splunk>" >> $CONFIG_LOCAL
    # Env dims
echo "$HOSTNAME" | grep dev-*
if $? ! -gt 0; then
    echo 'Dimension "env:np-dev"' >> $CONFIG_LOCAL
fi
echo "$HOSTNAME" | grep test-*
if $? ! -gt 0; then
    echo 'Dimension "env:np-test"' >> $CONFIG_LOCAL
fi
echo "$HOSTNAME" | grep kdcps-*
if $? ! -gt 0; then
    echo 'Dimension "env:ps"' >> $CONFIG_LOCAL
fi
echo "$HOSTNAME" | grep kdcprd-*
if $? ! -gt 0; then
    echo 'Dimension "env:prd"' >> $CONFIG_LOCAL
fi
    # App dims
if $hostname | grep *hial*; then
    echo 'Dimension "app:hial"' >> $CONFIG_LOCAL
elif $hostname | grep *posia*; then
    echo 'Dimension "app:posia"' >> $CONFIG_LOCAL
elif $hostname | grep *fam*; then
    echo 'Dimension "app:fam"' >> $CONFIG_LOCAL
elif $hostname | grep *cmu*; then
    echo 'Dimension "app:cmu"' >> $CONFIG_LOCAL
elif $hostname | grep *idm*; then
    echo 'Dimension "app:idm"' >> $CONFIG_LOCAL
elif $hostname | grep *lab*; then
    echo 'Dimension "app:lab"' >> $CONFIG_LOCAL
elif $hostname | grep *cache*; then
    echo 'Dimension "app:cache"' >> $CONFIG_LOCAL
elif $hostname | grep *ohs*; then
    echo 'Dimension "app:ohs"' >> $CONFIG_LOCAL
elif $hostname | grep *db*; then
    echo 'Dimension "app:db"' >> $CONFIG_LOCAL
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

#$METHOD_LOCAL start
#$METHOD_LOCAL status