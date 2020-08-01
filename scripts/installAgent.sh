#!/usr/bin/bash

INSTALL_HOME="/export/pkgs/splunk"

usage() {
    echo "UNIVERSAL SPLUNK INSTALLER"
    printf "Usage:\n"
    printf " --install              Assess environment, install what's needed.\n"
    printf " --verify               Verify install, permissions, configurations.\n"
    printf " --add-permits-cron     Create permit cron tailored to system.\n"
    printf " --add-wls-cron         Add WLS scripts to crontab.\n"
    printf " --collectd             Install collectd. *NEW*\n"
}

collectd() {
        # If not called from install(), query for OS
    OS_PASS=$1
    ANNOUNCE="[COLLECTD]"
    if [[ -z $OS ]]; then
        read -p "Choose: Solaris or Linux   [s/l]: " OS_CMD
        if [ "$OS_CMD" == s ] || [ $OS_PASS -eq 1 ]; then
                # Solaris install
                # Check for correct repos
            TAR="collectd_write-splunk_sparc.tar.gz"
            if pkg publisher | grep -q support || pkg publisher | grep -q release ; then
                    # Check for & install deps
                declare -a DEPS=(
                    "developer/base-developer-utilities"
                    "library/libidn2" "library/libssh2" "library/libxml2"
                    "library/nghttp2" "library/security/libgpg-error"
                    "library/security/openssl" "library/zlib" "security/kerberos-5"
                    "system/library/libpcap" "system/library/math" "system/library/security/libgcrypt"
                    "system/library" "system/management/snmp/net-snmp"
                    "system/network/ldap/openldap" "web/curl"
                    )
                for DEP in "${DEPS[@]}"
                do
                    if ! pkg list $DEP | grep -q i-- ; then
                        echo "$ANNOUNCE $DEP will be installed."
                        sleep 2
                        pkg install $DEP
                    else
                        echo "$ANNOUNCE $DEP already installed, skipping."
                    fi
                done
            else
                echo "$ANNOUNCE Please configure a valid IPS publisher first. Quitting."
            fi
                # Begin installation
            cd /opt
            cp "$INSTALL_HOME"/"$TAR" .
            tar -zxvf collectd_write-splunk_sparc.tar.gz
            rm -f collectd_write-splunk_sparc.tar.gz

        elif [ "$OS_CMD" == l ] || [ $OS_PASS -eq 2 ]; then
            # Linux install
            # Check & get deps
            TAR="collectd-5.9-wpatch.tar.gz"
            declare -a DEPS=(
                "autoconf" "automake" "flex"
                "bison" "libtool" "pkg-config"
                "libcurl-devel" "libxml2" "libxml2-devel"
            )
            for DEP in "${DEPS[@]}"
            do
                if ! yum list installed $DEP; then
                    echo "$ANNOUNCE $DEP will be installed."
                    sleep 2
                    yum install $DEP
                else
                    echo "$ANNOUNCE $DEP already installed, skipping."
                fi
            done
            cd /opt
            cp "$INSTALL_HOME"/"$TAR" .
            tar -xvf $TAR
            rm -f $TAR
            cd collectd
            ./build.sh
            ./configure --with-libxml2=/usr/include/libxml2/libxml \
            --disable-perl --disable-python

        fi
    fi
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
            grep -q oinstall /etc/group
            if [[ $? -eq 0 ]]; then
                    #Add splunk user to oinstall group
                if groups splunk | grep -q oinstall; then
                    echo "$ANNOUNCE Splunk user already part of oinstall group. No change."
                    sleep 2
                else
                    echo "$ANNOUNCE Adding Splunk to oinstall group."
                    sleep 2
                    usermod -G oinstall,splunk splunk
                fi
            else
                echo "$ANNOUNCE No oinstall group found. No change."
                sleep 2
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
        echo "$ANNOUNCE No Oracle user present. Skipping group changes."
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
    HOSTNAME=$(hostname)
    SPLUNK_CMD_DEPLOY="splunk set deploy-poll 192.168.60.211:8089"
    HOME_ROOT="/export/home"

#####
    #
    #(0)set environment
    #
#####

    read -p "Choose: Solaris or Linux   [s/l]: "  OS

    if [[ "$OS" == "s" ]]; then
        COLLECTD_CONF_DIR="/opt/collectd/etc"
        COLLECTD_PLUGIN_DIR="/opt/collectd/lib/collectd"
        COLLECTD_LOG_DIR="/opt/collectd/var/log"
        CRON_DIR="/var/spool/cron/crontabs"
        SPLUNK_TAR="splunkforwarder-8.0.5-a1a6394cc5ae-SunOS-x86_64.tar.Z"
    elif [[ "$OS" == "l" ]]; then
        COLLECTD_CONF_DIR="/etc"
        COLLECTD_PLUGIN_DIR=""
        COLLECTD_LOG_DIR=""
        CRON_DIR="/var/spool/cron"
        SPLUNK_TAR="splunk-8.0.4-767223ac207f-Linux-x86_64.tgz"
    fi
    read -p "Choose: NP or PSPR     [np/pspr]: "  ENV
    if [[ "$ENV" == "np" ]]; then
        SPLUNK_CMD_FORWARD="splunk add forward-server 192.168.63.241:9997"
        SPLUNK_STR_GROUP1="defaultGroup = np-heavy-forwarder"
        SPLUNK_STR_GROUP2="[tcpout:np-heavy-forwarder]"
        SPLUNK_STR_SERVER="server = 192.168.63.241:9997"
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

	id -u splunk

	if [[ $? -eq 1 ]]; then
        echo "$ANNOUNCE No splunk user found. Creating."
        sleep 2
		useradd splunk
        groupadd splunk
        usermod -G +splunk,adm #wheel,oinstall
        mkdir "$HOME_ROOT/splunk"
        cp "$HOME_ROOT/opc/.profile" "$HOME_ROOT/splunk"
        su - splunk -c "export PATH=$PATH:/opt/splunkforwarder/bin"
        chown --recursive splunk:splunk "$HOME_ROOT/splunk"
	fi
        #Solaris install
    if [[ "$OS" == "s" ]]; then
        echo "$ANNOUNCE Installing universal forwarder..."
        sleep 2
        cp "$INSTALL_HOME/$SPLUNK_TAR" /opt/
        cd /opt
        tar -zxvf "$SPLUNK_TAR"
        rm -f "$SPLUNK_TAR"

        grep -q splunk "$HOME_ROOT/splunk/.profile"

        if [ $? -eq 1 ]; then
            echo "$ANNOUNCE Splunk not in PATH. Adding."
            sleep 2
    	    echo "export PATH=$PATH:/opt/splunkforwarder/bin" >> "$HOME_ROOT/splunk/.profile"
        fi

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
    #if [[ "$OS" == "l" ]]; then

    #fi

        #Make user-seed.conf
    touch /opt/splunkforwarder/etc/system/local/user-seed.conf
	(
		echo "[user_info]"
		echo "USERNAME = splunkadmin"
		echo "PASSWORD = hialplissplunk"
	)>/opt/splunkforwarder/etc/system/local/user-seed.conf

    	#Make splunk-launch.conf
	touch /opt/splunkforwarder/etc/splunk-launch.conf
	(
		echo "SPLUNK_SERVER_NAME=Splunkd"
		echo "SPLUNK_OS_USER=splunk"
		echo "SPLUNK_HOME=/opt/splunkforwarder"
	)>/opt/splunkforwarder/etc/splunk-launch.conf

	chown --recursive splunk:splunk /opt/splunkforwarder/
	chmod --recursive g+rwx /opt/splunkforwarder/

        # Start Splunk, set forward & deploy servers
    su - splunk -c "splunk start --accept-license --no-prompt --answer-yes"
    su - splunk -c "$SPLUNK_CMD_FORWARD"
    su - splunk -c "$SPLUNK_CMD_DEPLOY"
    echo "$ANNOUNCE Writing outputs.conf..."

        # Create outputs.conf
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
        collectd 1
    elif [[ "$OS" == "s" ]]; then
        collectd 2
    fi

}

[[ "$1" == "" ]] && usage
[[ "$1" == "--add-wls-cron" ]] && addwlscron
[[ "$1" == "--install" ]] && install
[[ "$1" == "--add-permits-cron" ]] && addoraclepermitcron
[[ "$1" == "--collectd" ]] && collectd