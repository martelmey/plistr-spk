#!/bin/bash
current_dir="$(dirname "$0")"

# Source Shell Environment Variables
source /etc/profile

# Collect dimensions defined in default or local/dims.conf
source $current_dir/lib/conf.sh

if [[ $cloud == "aws" ]]
then
 source $current_dir/lib/aws.sh
 region=$INSTANCE_REGION
 the_dc=$INSTANCE_AZ
elif [[ $cloud == "gcp" ]]
then
 source $current_dir/lib/gcp.sh
 region=$INSTANCE_REGION
 the_dc=$INSTANCE_AZ
else
 region=$region
 if [ -z $region ]
  then
  region="null"
 fi

 the_dc=$dc
 if [ -z $the_dc ]
 then
  the_dc="null"
 fi
fi

the_ip=`hostname -i 2>/dev/null`
if [ -z $the_ip ]
then
 the_ip="null"
fi

if [ -f /etc/os-release ]
then
 source /etc/os-release
 os=`echo $NAME`
 os_version=`echo $VERSION | sed -r 's/\s\(.*//'`
else
 os="null"
 os_version="null"
fi

kernel_version=`uname -r`
if [ -z $kernel_version ]
then
 kernel_version="null"
fi

if [ -z $cloud ]
then
 cloud="null"
fi

if [ -z $environment ]
then
 environment="null"
fi

csv_head="$csv_head,\"cloud\""
csv_valu="$csv_valu,\"$cloud\""

csv_head="$csv_head,\"region\""
csv_valu="$csv_valu,\"$region\""

csv_head="$csv_head,\"dc\""
csv_valu="$csv_valu,\"$the_dc\""

csv_head="$csv_head,\"environment\""
csv_valu="$csv_valu,\"$environment\""

csv_head="$csv_head,\"ip\""
csv_valu="$csv_valu,\"$the_ip\""

csv_head="$csv_head,\"os\""
csv_valu="$csv_valu,\"$os\""

csv_head="$csv_head,\"os_version\""
csv_valu="$csv_valu,\"$os_version\""

csv_head="$csv_head,\"kernel_version\""
csv_valu="$csv_valu,\"$kernel_version\""
