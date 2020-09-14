#!/bin/bash

# Until NFS indexes are restored,
# when Splunk complains of
# local disk space on -temp indexes,
# run this to cleanup & restart.

su - splunk -c 'splunk stop'
rm -rf db_np-temp
rm -rf os_evt_np-temp
rm -rf wls_np-temp
mkdir -p db_np-temp/db && db_np-temp/colddb && db_np-temp/thaweddb
mkdir -p os_evt_np-temp/db && os_evt_np-temp/colddb && os_evt_np-temp/thaweddb
mkdir -p wls_np-temp/db && wls_np-temp/colddb && wls_np-temp/thaweddb
chown --recursive splunk:splunk db_np-temp
chown --recursive splunk:splunk os_evt_np-temp
chown --recursive splunk:splunk wls_np-temp
su - splunk -c 'splunk start'