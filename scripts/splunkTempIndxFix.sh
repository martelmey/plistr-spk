#!/bin/bash

# Until NFS indexes are restored,
# when Splunk complains of
# local disk space on -temp indexes,
# run this to cleanup & restart.

#su - splunk -c 'splunk stop'
rm -rf /export/db_np-temp
rm -rf /export/os_evt_np-temp
rm -rf /export/wls_np-temp
mkdir -p /export/db_np-temp/db && mkdir -p /export/db_np-temp/colddb && mkdir -p /export/db_np-temp/thaweddb
mkdir -p /export/os_evt_np-temp/db && mkdir -p /export/os_evt_np-temp/colddb && mkdir -p /export/os_evt_np-temp/thaweddb
mkdir -p /export/wls_np-temp/db && mkdir -p /export/wls_np-temp/colddb && mkdir -p /export/wls_np-temp/thaweddb
chown --recursive splunk:splunk /export/db_np-temp
chown --recursive splunk:splunk /export/os_evt_np-temp
chown --recursive splunk:splunk /export/wls_np-temp
#su - splunk -c 'splunk start'