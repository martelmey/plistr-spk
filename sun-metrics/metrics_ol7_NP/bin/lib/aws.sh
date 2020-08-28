[[ "$(which curl 2>/dev/null)" == "" ]] && echo "Error: cannot find 'curl'" && exit 1
file_out="/tmp/splunk-aws.out"
if [ ! -f "$file_out" ]
then
 # fetch instance info
 curl --noproxy "*" -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/placement/availability-zone > $file_out
fi
INSTANCE_AZ=$(cat $file_out)
file_size=$(wc -c $file_out | awk '{print $1}')
if [ $file_size = 0 ]
then
 INSTANCE_AZ="null"
 INSTANCE_REGION="null"
 rm -f $file_out
else
 INSTANCE_REGION="`echo \"$INSTANCE_AZ\" | sed -e 's:\([0-9][0-9]*\)[a-z]*\$:\\1:'`"
fi
# export instance info
export INSTANCE_AZ
export INSTANCE_REGION
