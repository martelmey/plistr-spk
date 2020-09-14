#!/usr/bin/bash

INSTALL_HOME="/export/pkgs/splunk"
HOSTNAME=$(hostname)

usage() {
    echo "UNIVERSAL SPLUNK INSTALLER"
    printf "Usage:\n"
    printf " --install              Assess environment, install what's needed.\n"
    printf " --verify               Verify install, permissions, configurations.\n"
    printf " --add-permits-cron     Create permit cron tailored to system.\n"
    printf " --add-wls-cron         Add WLS scripts to crontab.\n"
    printf " --collectd             Install collectd for Solaris hosts. *NEW*\n"
}

HOSTNAME=$(hostname)

collectd() {
    ANNOUNCE="[COLLECTD - INSTALL] "
    TAR="spkcollectd_sparc_final.tar.gz"
    METHOD_STOCK="/export/pkgs/splunk/collectdsvc.sh"
    METHOD_LOCAL="/opt/collectd/svc/collectdsvc.sh"
    CRONJOB="/opt/collectd/svc/cron-spkcollectd.sh"
    CRON_DIR="/var/spool/cron/crontabs"
    CONFIG_STOCK="/export/pkgs/splunk/collectd_stock.conf"
    CONFIG_LOCAL="/opt/collectd/etc/collectd.conf"
    PIDFILE="/opt/collectd/run/collectdmon.pid"
    DAEMON="/opt/collectd/sbin/collectdmon"
    LOGDIR="/opt/collectd/var/log"
            # Check for presence of /export/pkgs/splunk
    if [ ! -d /export/pkgs ]; then
        echo "$ANNOUNCE Creating /export/pkgs."
        mkdir -p /export/pkgs
    fi
    if [ ! -d $INSTALL_HOME ]; then
        echo "$ANNOUNCE Mounting /export/pkgs/splunk."
        mount 192.168.61.132:\export/utilities-kdcprd/pkgs /export/pkgs/
    fi
            # Check for correct repos
    #if pkg publisher | grep -q support || pkg publisher | grep -q release ; then
            # Check for & install deps
#        echo "$ANNOUNCE Checking dependencies."
#        sleep 2
#        declare -a DEPS=(
#            "developer/base-developer-utilities"
#            "library/libidn2" "library/libssh2" "library/libxml2"
#            "library/nghttp2" "library/security/libgpg-error"
#            "library/security/openssl" "library/zlib" "security/kerberos-5"
#            "system/library/libpcap" "system/library/math" "system/library/security/libgcrypt"
#            "system/library" "system/management/snmp/net-snmp"
#            "system/network/ldap/openldap" "web/curl"
#            )
#        for DEP in "${DEPS[@]}"
#        do
#            if ! pkg list $DEP | grep -q i-- ; then
#                echo "$ANNOUNCE $DEP will be installed."
#                sleep 1
#                pkg install $DEP
#            else
#                echo "$ANNOUNCE $DEP already installed, skipping."
#                sleep 1
#            fi
#        done
            # Begin installation
        if [[ -d /opt/collectd ]]; then
            echo "$ANNOUNCE Existing install found. Removing."
            sleep 2
            rm -rf /opt/collectd
        fi
        cd /opt
        echo "$ANNOUNCE Beginning collectd install."
        sleep 2
        cp "$INSTALL_HOME"/"$TAR" .
        tar -zxvf $TAR
        rm -f $TAR
        touch $LOGDIR/collectd.log
        cp -f $METHOD_STOCK $METHOD_LOCAL
        chmod +x $METHOD_LOCAL
        cp -f $CONFIG_STOCK $CONFIG_LOCAL
            # Generate dims
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
            # Create cronjob
        echo "$ANNOUNCE Configuring cronjob for spkcollectd service."
        sleep 2
        if [[ ! -f "$CRON_DIR"/root ]]; then
            echo "$ANNOUNCE No crontab for root found. Creating."
            sleep 2
            touch "$CRON_DIR"/root
        fi
        chmod +x $CRONJOB
        if cat "$CRON_DIR"/root | grep -q "cron-spkcollectd.sh" ; then
            echo "$ANNOUNCE Cronjob for spkcollectd service already present."
            sleep 2
        else
            echo "$ANNOUNCE Adding cronjob for spkcollectd service, every 2 minutes."
            sleep 2
            echo "0 0 * * * /opt/collectd/svc/cron-spkcollectd.sh" >> $CRON_DIR/root
        fi
            # Startup
        echo "$ANNOUNCE Starting collectd."
        sleep 2
        $METHOD_LOCAL start
        $METHOD_LOCAL status
#        $METHOD_LOCAL tail
    #else
#        echo "$ANNOUNCE Please configure a valid IPS publisher first. Quitting."
    #fi
}

addoraclepermitcron() {
    ANNOUNCE="[CRON - ORACLE PERMITS] "
    CRON_DIR="/var/spool/cron/crontabs"

    #Create root cron if not present
    if [[ ! -f "$CRON_DIR"/root ]]; then
        echo "$ANNOUNCE No crontab for root found. Creating."
        sleep 2
        touch "$CRON_DIR"/root
    fi

    #Create assertGroupPermits for Solaris Oracle user
    #Maintain list of monitored dirs in $DIRS
    #Only add permits for each dir found on system

    echo "$ANNOUNCE Generating assertGroupPermits.sh"
    rm /root/splunk-scripts/assertGroupPermits.sh #Force new script
    touch /root/splunk-scripts/assertGroupPermits.sh
    echo "#!/usr/bin/bash" >/root/splunk-scripts/assertGroupPermits.sh
    sleep 2

    STR1="chmod --recursive g+rwx "
    declare -a DIRS=(
        "/u01/app/"
        "/u01/oracle/"
        "/opt/SUNWappserver/"
        "/opt/cachesys"
        "/opt/dsee7"
        )
    for DIR in "${DIRS[@]}"
    do
        if [ -d $DIR ] ; then
            STR2="$STR1$DIR"
            echo "$STR2" >> /root/splunk-scripts/assertGroupPermits.sh
        fi
    done
    chmod +x /root/splunk-scripts/assertGroupPermits.sh
    if cat "$CRON_DIR"/root | grep -q "assertGroupPermits.sh" ; then
        echo "$ANNOUNCE Cronjob for group permits assertion already present."
        sleep 2
    else
        echo "$ANNOUNCE Adding cronjob to assert group permits every 2 minutes."
        sleep 2
        echo "0 0 * * * /root/splunk-scripts/assertGroupPermits.sh" >> $CRON_DIR/root
    fi

    id -u oracle
    if [[ $? -eq 1 ]]; then
        echo "$ANNOUNCE No Oracle user present. Skipping group changes."
        sleep 2
        else
                #Add oracle user to splunk group
            if groups oracle | grep -q splunk; then
                echo "$ANNOUNCE Oracle user already part of Splunk group. No change."
                sleep 2
            else
                echo "$ANNOUNCE Adding Oracle to Splunk group."
                sleep 2
                if groups oracle | grep -q dba ; then
                    usermod -G splunk,oinstall,dba oracle
                    else
                    usermod -G splunk,oinstall oracle
                fi
            fi
                # check for oinstall & asmadmin groups
            if  grep -q oinstall /etc/group  &&  grep -q asmadmin /etc/group; then
                echo "$ANNOUNCE oinstall & asmadmin groups found. Assigning to Splunk user."
                usermod -G +oinstall splunk
                usermod -G +asmadmin splunk
                sleep 3
            elif grep -q oinstall /etc/group; then
                echo "$ANNOUNCE oinstall group found. Assinging to Splunk user."
                usermod -G +oinstall splunk
                sleep 3
            elif grep -q asmadmin /etc/group; then
                echo "$ANNOUNCE asmadmin group found. Assinging to Splunk user."
                usermod -G +asmadmin splunk
                sleep 3
            fi
    fi
        #Run assertGroupPermits.sh now
    /root/splunk-scripts/assertGroupPermits.sh
    echo "$ANNOUNCE assertGroupPermits.sh ran first time. Permissions set."
}

addwlscron() {
    # Using wrappers in /root/splunk-scripts
    ANNOUNCE="[CRON - SPLUNK WLS] "
    CRON_DIR="/var/spool/cron/crontabs"

    #Create root cron if not present
    if [[ ! -f "$CRON_DIR"/root ]]; then
        echo "$ANNOUNCE No root cron present. Creating ..."
        sleep 2
        touch "$CRON_DIR"/root
    fi

    # wls_admin /minute
    if [ ! -f /root/splunk-scripts/splunkWlsMinute.sh ] ; then
        echo "$ANNOUNCE Generating splunkWlsMinute.sh"
        sleep 2
        touch /root/splunk-scripts/splunkWlsMinute.sh
        (
            echo "#!/usr/bin/bash"
            echo "su - oracle -c '/opt/splunkforwarder/etc/apps/wls_admin_*/bin/runWlstScriptsMinute.sh'"
        )>/root/splunk-scripts/splunkWlsMinute.sh
        chmod +x /root/splunk-scripts/splunkWlsMinute.sh
    fi
    if cat "$CRON_DIR"/root | grep -q "splunkWlsMinute.sh" ; then
        echo "$ANNOUNCE Cronjob /minute for wls_admin already present."
        sleep 2
    else
        echo "$ANNOUNCE Adding cronjob /minute for wls_admin."
        sleep 2
        echo "* * * * * /root/splunk-scripts/splunkWlsMinute.sh" >> $CRON_DIR/root
        sleep 2
    fi

    # wls_admin /hourly
    if [ ! -f /root/splunk-scripts/splunkWlsHourly.sh ] ; then
        echo "$ANNOUNCE Generating splunkWlsHourly.sh"
        sleep 2
        touch /root/splunk-scripts/splunkWlsHourly.sh
        (
            echo "#!/usr/bin/bash"
            echo "su - oracle -c '/opt/splunkforwarder/etc/apps/wls_admin_*/bin/runWlstScriptsHourly.sh'"
        )>/root/splunk-scripts/splunkWlsHourly.sh
        chmod +x /root/splunk-scripts/splunkWlsHourly.sh
    fi
    if cat "$CRON_DIR"/root | grep -q "splunkWlsHourly.sh" ; then
        echo "$ANNOUNCE Cronjob /hourly for wls_admin already present."
        sleep 2
    else
        echo "$ANNOUNCE Adding cronjob /hourly for wls_admin."
        sleep 2
        echo "0 * * * * /root/splunk-scripts/splunkWlsHourly.sh" >> $CRON_DIR/root
    fi

    # wls_admin /daily
    if [ ! -f /root/splunk-scripts/splunkWlsDaily.sh ] ; then
        echo "$ANNOUNCE Generating splunkWlsDaily.sh"
        sleep 2
        touch /root/splunk-scripts/splunkWlsDaily.sh
        (
            echo "#!/usr/bin/bash"
            echo "su - oracle -c '/opt/splunkforwarder/etc/apps/wls_admin_*/bin/runWlstScriptsHourly.sh'"
        )>/root/splunk-scripts/splunkWlsDaily.sh
        chmod +x /root/splunk-scripts/splunkWlsDaily.sh
    fi
    if cat "$CRON_DIR"/root | grep -q "splunkWlsDaily.sh" ; then
        echo "$ANNOUNCE Cronjob /daily for wls_admin already present."
        sleep 2
    else
        echo "$ANNOUNCE Adding cronjob /daily for wls_admin."
        sleep 2
        echo "0 1 * * * /root/splunk-scripts/splunkWlsDaily.sh" >> $CRON_DIR/root
    fi
    echo "$ANNOUNCE All wls_admin scripts added to crontab."
    crontab -l
    sleep 2
}

#Installs: (1)splunk ufw, (2)cron permissions scripts, (3)collectd
install() {
    
    SPLUNK_CMD_DEPLOY="splunk set deploy-poll 192.168.60.211:8089"

    #if [[ ! -f "$INSTALL_HOME" ]]; then
    #    
    #fi
    
#####
    #
    #(0)set environment
    #
#####

    read -p "Choose: Solaris or Linux   [s/l]: "  OS

    if [[ "$OS" == "s" ]]; then
        CRON_DIR="/var/spool/cron/crontabs"
        SPLUNK_TAR="splunkforwarder-8.0.3-a6754d8441bf-SunOS-sparc.tar.Z"
        HOME_ROOT="/export/home"
        PROFILE=".profile"
        ADMGROUP="adm"
    elif [[ "$OS" == "l" ]]; then
        CRON_DIR="/var/spool/cron"
        SPLUNK_TAR="splunkforwarder-8.0.5-a1a6394cc5ae-Linux-x86_64.tgz"
        HOME_ROOT="/home"
        PROFILE=".bash_profile"
        ADMGROUP="wheel"
    fi
    read -p "Choose: NP or PSPR     [np/pspr]: "  ENV
    if [[ "$ENV" == "np" ]]; then
        SPLUNK_CMD_FORWARD="splunk add forward-server 192.168.60.70:9997"
        SPLUNK_STR_GROUP1="defaultGroup = np-heavy-forwarder"
        SPLUNK_STR_GROUP2="[tcpout:np-heavy-forwarder]"
        SPLUNK_STR_SERVER="server = 192.168.60.70:9997"
    elif [[ "$ENV" == "pspr" ]]; then
        SPLUNK_CMD_FORWARD="splunk add forward-server 192.168.60.213:9997"
        SPLUNK_STR_GROUP1="defaultGroup = pspr-heavy-forwarder"
        SPLUNK_STR_GROUP2="[tcpout:pspr-heavy-forwarder]"
        SPLUNK_STR_SERVER="server = 192.168.60.213:9997"
    fi

#####
    #
    #(1)splunk ufw
    #
#####

    ANNOUNCE="[INSTALL] "
        #Remove existing install, create splunk user if missing
	if [[ -d /opt/splunkforwarder ]]; then
        echo "$ANNOUNCE Existing install found. Removing."
        sleep 2
		rm -rf /opt/splunkforwarder
        sudo su - splunk -c "/opt/splunkforwarder/bin/.splunk stop"
	fi

        #Solaris install
    if [[ "$OS" == "s" ]]; then
        id -u splunk
        if [[ $? -gt 0 ]]; then
            echo "$ANNOUNCE No splunk user found. Creating."
            sleep 2
            useradd splunk
            groupadd splunk
            usermod -G +$ADMGROUP splunk
            usermod -G +splunk splunk
            mkdir "$HOME_ROOT/splunk"
            chown --recursive splunk:splunk "$HOME_ROOT/splunk"
            usermod -d "$HOME_ROOT/splunk" splunk
            touch "$HOME_ROOT/splunk/$PROFILE"
            (
                echo "export PATH=/usr/bin:/usr/sbin:/opt/splunkforwarder/bin"
                echo "if [ -f /usr/bin/less ]; then"
                echo '    export PAGER="/usr/bin/less -ins"'
                echo "elif [ -f /usr/bin/more ]; then"
                echo '    export PAGER="/usr/bin/more -s"'
                echo "fi"
                echo "case ${SHELL} in"
                echo "*bash)"
                echo '    typeset +x PS1="\u@\h:\w\\$ "'
                echo "    ;;"
                echo "esac"
            )>>"$HOME_ROOT/splunk/$PROFILE"
            source "$HOME_ROOT/splunk/$PROFILE"
            chown --recursive splunk:splunk "$HOME_ROOT/splunk"
	    fi
        echo "$ANNOUNCE Installing universal forwarder..."
        sleep 2
        cp "$INSTALL_HOME/$SPLUNK_TAR" /opt/
        cd /opt
        tar -zxvf "$SPLUNK_TAR"
        rm -f "$SPLUNK_TAR"

        grep -q splunk "$HOME_ROOT/splunk/$PROFILE"

        if [ $? -eq 1 ]; then
            echo "$ANNOUNCE Splunk not in PATH. Adding."
            sleep 2
    	    echo "export PATH=$PATH:/opt/splunkforwarder/bin" >> "$HOME_ROOT/splunk/.profile"
        fi

        echo "$ANNOUNCE Configuring firewall..."
        cp /etc/firewall/pf.conf /etc/firewall/pf.conf.old
        sleep 2
        declare -a PORTS=("8088" "8089" "9997")
        for PORT in "${PORTS[@]}"; do
            grep $PORT /etc/firewall/pf.conf
            if [[ $? -eq 1 ]]; then
                echo "$ANNOUNCE Port " "$PORT" " closed. Opening..."
                sleep 2
                echo "pass all from any to any port = " "$PORT" >> /etc/firewall/pf.conf
            fi
        done
	    svcadm refresh network/firewall
    fi

        #Linux install
    if [[ "$OS" == "l" ]]; then
        id -u splunk
        if [[ $? != 0 ]]; then
            echo "$ANNOUNCE No splunk user found. Creating."
            sleep 2
            useradd splunk
            groupadd splunk
            usermod -G +splunk,$ADMGROUP splunk
            mkdir "$HOME_ROOT/splunk"
            touch "$HOME_ROOT/splunk/$PROFILE"
            (
                echo "export PATH=/usr/bin:/usr/sbin:/opt/splunkforwarder/bin"
                echo "if [ -f /usr/bin/less ]; then"
                echo '    export PAGER="/usr/bin/less -ins"'
                echo "elif [ -f /usr/bin/more ]; then"
                echo '    export PAGER="/usr/bin/more -s"'
                echo "fi"
                echo "case ${SHELL} in"
                echo "*bash)"
                echo '    typeset +x PS1="\u@\h:\w\\$ "'
                echo "    ;;"
                echo "esac"
            )>>"$HOME_ROOT/splunk/$PROFILE"
            source "$HOME_ROOT/splunk/$PROFILE"
            chown --recursive splunk:splunk "$HOME_ROOT/splunk"
	    fi
        echo "$ANNOUNCE Installing universal forwarder..."
        sleep 2
        tar -zxvf "$INSTALL_HOME/$SPLUNK_TAR" -C /opt
        systemctl status firewalld | grep running
        if [ $? == 0 ]; then
            echo "$ANNOUNCE Configuring firewall..."
            sleep 2
            declare -a PORTS=("8088" "8089" "9997")
            for PORT in "${PORTS[@]}"; do
                firewall-cmd --list-all | grep $PORT
                if [[ $? != 0 ]]; then
                    echo "$ANNOUNCE Port " "$PORT" " closed. Opening..."
                    sleep 2
                    firewall-cmd --zone=public --permanent --add-port=$PORT/tcp
                fi
            done
            systemctl restart firewalld
        else
            echo "$ANNOUNCE FirewallD not running. Skipping configuration."
            sleep 2
        fi
    fi

        #Make user-seed.conf
    echo "$ANNOUNCE Generating user-seed.conf."
    sleep 2
    touch /opt/splunkforwarder/etc/system/local/user-seed.conf
	(
		echo "[user_info]"
		echo "USERNAME = splunkadmin"
		echo "PASSWORD = hialplissplunk"
	)>/opt/splunkforwarder/etc/system/local/user-seed.conf

    	#Make splunk-launch.conf
    echo "$ANNOUNCE Generating splunk-launch.conf."
    sleep 2
	touch /opt/splunkforwarder/etc/splunk-launch.conf
	(
		echo "SPLUNK_SERVER_NAME=Splunkd"
		echo "SPLUNK_OS_USER=splunk"
		echo "SPLUNK_HOME=/opt/splunkforwarder"
	)>/opt/splunkforwarder/etc/splunk-launch.conf

	chown --recursive splunk:splunk /opt/splunkforwarder/
	chmod --recursive g+rwx /opt/splunkforwarder/

        # Start Splunk, set forward & deploy servers
    echo "$ANNOUNCE Starting Splunk, configuring deploy & forward servers."
    sleep 2
    su - splunk -c "splunk start --accept-license --no-prompt --answer-yes"
    su - splunk -c "$SPLUNK_CMD_FORWARD"
    su - splunk -c "$SPLUNK_CMD_DEPLOY"
    echo "$ANNOUNCE Writing outputs.conf..."

        # Create outputs.conf
    echo "$ANNOUNCE Creating outputs.conf."
    sleep 2
    touch /opt/splunkforwarder/etc/system/local/outputs.conf
		(
			echo "[tcpout]"
			echo "$SPLUNK_STR_GROUP1"
            echo "$SPLUNK_STR_GROUP2"
			echo "disabled = false"
			echo "$SPLUNK_STR_SERVER"
			echo "useACK = true"
		)>/opt/splunkforwarder/etc/system/local/outputs.conf
	sudo /opt/splunkforwarder/bin/./splunk enable boot-start

#####
    #
    #(2)cron permissions scripts
    #
#####
        #Create crontabs
    mkdir -p /root/splunk-scripts
        #Create assertSplunkPermits
    if [ ! -f /root/splunk-scripts/assertSplunkPermits.sh ] ; then
		echo "$ANNOUNCE Generating assertSplunkPermits.sh"
		touch /root/splunk-scripts/assertSplunkPermits.sh
		(
			echo "#!/usr/bin/bash"
			echo "chown --recursive splunk:splunk /opt/splunkforwarder/"
		)>/root/splunk-scripts/assertSplunkPermits.sh
		chmod +x /root/splunk-scripts/assertSplunkPermits.sh
	fi

        #Create root cron if not present
    if [[ ! -f "$CRON_DIR"/root ]]; then
        touch "$CRON_DIR"/root
    fi

        #Config group permits if on Solaris
    if [[ "$OS" == "s" ]]; then
        addoraclepermitcron
        #addwlscron
    fi

        #Add assertSplunkPermits.sh to cron
    if cat "$CRON_DIR"/root | grep -q "assertSplunkPermits.sh" ; then
        echo "$ANNOUNCE Cronjob for ownership assertion already present."
        sleep 2
    else
        echo "$ANNOUNCE Adding cronjob to assert ownership every 2 minutes."
        sleep 2
        echo "0 0 * * * /root/splunk-scripts/assertSplunkPermits.sh" >> $CRON_DIR/root
    fi
        #Run assertSplunkPermits.sh now
    /root/splunk-scripts/assertSplunkPermits.sh
    echo "$ANNOUNCE assertSplunkPermits.sh ran first time. Permissions set."
    sleep 2

#####
    #
    #(3)collectd
    #
#####

    if [[ "$OS" == "s" ]]; then
        collectd
    fi

}

[[ "$1" == "" ]] && usage
[[ "$1" == "--add-wls-cron" ]] && addwlscron
[[ "$1" == "--install" ]] && install
[[ "$1" == "--add-permits-cron" ]] && addoraclepermitcron
[[ "$1" == "--collectd" ]] && collectd