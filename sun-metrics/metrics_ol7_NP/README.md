TA-linux-metrics can be used on Linux Forwarders to send Operating System metrics to Splunk without using collectd or the HTTP Event Collector (HEC) and it is fully compatible with the "Splunk App for Infrastructure":
https://splunkbase.splunk.com/app/3975/

Note: the output is formatted for multiple-measurement metric data points (new to Splunk v8) which allows for reduced Splunk License consumption as a single metric data point can now contain multiple measurements and multiple dimensions.

Use the built-in Setup Page to configure the inputs on a Standalone Instance, or use a Deployment Server to push the add-on to your forwarders.

### Compatibility ###

*   Splunk Enterprise v8.0.x
*   Splunk App for Infrastructure v2.0.1
*   Linux: Ubuntu 16.04, Ubuntu 18.04, CentOS 7, CentOS 8, Amazon Linux, RHEL 7

### Metrics ###

*   CPU
*   Memory
*   Swap
*   Load
*   Uptime
*   Filesystems
*   Disk I/O
*   Interfaces
*   Processes
*   Docker (Coming Soon)

### Dimensions ###

*   cloud
*   region
*   dc
*   environment
*   host
*   ip
*   os
*   os_version
*   kernel_version
*   model
*   device
*   mountpoint
*   type
*   disk
*   disk_type
*   interface
*   process_name
*   pid
*   user

### Installation ###

*   Create a new 'metric' index on your indexer/s, e.g. metrics_linux

Example indexes.conf :-

    [metrics_linux]
    coldPath = $SPLUNK_DB/metrics_linux/colddb
    homePath = $SPLUNK_DB/metrics_linux/db
    thawedPath = $SPLUNK_DB/metrics_linux/thaweddb
    datatype = metric

*   Install the add-on on your Linux servers and enable the inputs. Either use the built-in Setup Page, or copy the input stanzas from the default directory to the local directory (i.e. local/inputs.conf) and enable them as required:
    *   Update: disabled = 0
    *   Update: index = metrics_linux
    *   Note: DO NOT UPDATE sourcetype = metrics_csv

*   If you enable process monitoring, configure the relevant processes to monitor for your environment. Copy the stanza from the default directory to the local directory (i.e. local/process_mon.conf) and configure them as required:
    *   Update: whitelist = bash,zsh,sshd,python.*
    *   Update: blacklist = splunkd
    *   Note: the whitelist and blacklist should be comma separated without spaces

*   Configure the relevant dimensions for your environment. Copy the dimensions from the default directory to the local directory (i.e. local/dims.conf) and configure them as required:
    *   Note: you can set `cloud` to `aws` or `gcp` and the built-in scripts will Auto-Discover the Region and Zone of the instance, e.g.

            [all]
            cloud = gcp
        
    *   Shell environment variables are also supported, e.g.
    
            [all]
            environment = $Deploy_Environment
        
*   Install the "Splunk App for Infrastructure" on your Search Head
    *   **IMPORTANT:** Update the 'sai_metrics_indexes' macro, e.g. index=metrics_linux

### Troubleshooting ###

*   If you don't see any Entities under 'Investigate' in the Splunk App for Infrastructure :-

    *   Update the 'sai_metrics_indexes' macro in the Splunk App for Infrastructure, e.g. index=metrics_linux

*   Error when enabling inputs via the Setup Page:

        Encountered the following error while trying to update: Error while posting to url=/servicesNS/nobody/TA-linux-metrics/data/inputs/script/.%252Fbin%252Fcpu_usage.sh

    *   Create a new 'metric' index before you enable any inputs

*   Run the following search to confirm that metrics are being indexed :-

        | mcatalog values(metric_name) WHERE index=metrics_linux

    *   Add the 'metrics_linux' index to "Indexes searched by default" :-

        https://docs.splunk.com/Documentation/Splunk/latest/Search/Searchindexes#Control_index_access_using_Splunk_Web

*   If you see similar errors to the following in 'splunkd.log' on the forwarder :-

        01-28-2020 16:26:45.553 +1100 WARN  IndexProcessor - The metric name is missing for source=/opt/splunk/etc/apps/TA-linux-metrics/bin/cpu_usage.sh, sourcetype=cpu_usage, host=wildstylez, index=metrics_linux. Metric event data without a metric name is invalid and cannot be indexed. Ensure the input metric data is not malformed. raw=["_time","metric_name:cpu.user","metric_name:cpu.system","metric_name:cpu.nice","metric_name:cpu.idle","metric_name:cpu.wait","metric_name:cpu.interrupt","metric_name:cpu.softirq","metric_name:cpu.steal","model","cloud","region","dc","environment","ip","os","os_version","kernel_version"]

        01-28-2020 16:26:45.553 +1100 WARN  IndexProcessor - The metric value=<unset> is not valid for source=/opt/splunk/etc/apps/TA-linux-metrics/bin/cpu_usage.sh, sourcetype=cpu_usage, host=wildstylez, index=metrics_linux. Metric event data with an invalid metric value cannot be indexed. Ensure the input metric data is not malformed. raw=["_time","metric_name:cpu.user","metric_name:cpu.system","metric_name:cpu.nice","metric_name:cpu.idle","metric_name:cpu.wait","metric_name:cpu.interrupt","metric_name:cpu.softirq","metric_name:cpu.steal","model","cloud","region","dc","environment","ip","os","os_version","kernel_version"]

    *   Ensure that the sourcetype is set to `metrics_csv`

### Contact ###

*   Developers:
    *   Luke Harris (Data Analytics Practice Lead at Katana1)
    *   Chris Barbour (Professional Services Consultant at Katana1)
*   Web: https://katana1.com
