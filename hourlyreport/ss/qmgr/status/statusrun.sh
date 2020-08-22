#!/bin/bash

parentdir=$1
BASE_DIR=
ORACLE_PW=$(decrypt -a aes -k ${BASE_DIR}/ctl/keyfile < ${BASE_DIR}/ctl/encrypted.pwd)
rm $parentdir/qmgr/status/iEHRPLISStatus.html
echo $$
echo "gathering stats"
echo "getting server status"
$parentdir/qmgr/checkhosts.py $parentdir/qmgr/hostlist >$parentdir/qmgr/status/checkhosts.out
echo Done
echo "getting traffic report - This can take a while. Checking multiple servers"
$parentdir/qmgr/latesttraffic.sh > $parentdir/qmgr/status/traffic.out
echo Done
echo .getting SS hourly report.
sqlplus -s SS_RO/`crypt \`hostname\` < /failover/pr-ss/iehr/hial/ss/dbpasswd.encypted`@HLPROD @$parentdir/qmgr/status/SS_DISTRIBUTION_Q_CHECK > $parentdir/qmgr/status/ssstatus.out
echo Done
echo "Building message"
$parentdir/qmgr/status/statusmonitor.py $parentdir/qmgr/status/statusmonitor.env
cat $parentdir/qmgr/status/iEHRPLISStatus.html |  /usr/sbin/sendmail -t
#cat $parentdir/qmgr/status/iEHRPLISStatus.html
echo "Mail Sent" 

