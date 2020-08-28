[[ "$(which curl 2>/dev/null)" == "" ]] && echo "Error: cannot find 'curl'" && exit 1
file_out="/tmp/splunk-gcp.out"
if [ ! -f "$file_out" ]
then
 # fetch instance info
 curl --noproxy "*" -s --connect-timeout 3 http://metadata.google.internal/computeMetadata/v1/instance/zone -H "Metadata-Flavor: Google" | grep -Po "zones\/\K(.+)" > $file_out
fi
INSTANCE_AZ=$(cat $file_out)
file_size=$(wc -c $file_out | awk '{print $1}')
if [ $file_size = 0 ]
then
 INSTANCE_AZ="null"
 INSTANCE_REGION="null"
 rm -f $file_out
else
 INSTANCE_REGION=`echo $INSTANCE_AZ | grep -Po '\K(\w+-\w+)'`
fi
# export instance info
export INSTANCE_AZ
export INSTANCE_REGION
