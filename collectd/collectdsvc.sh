#!/usr/bin/bash

PIDFILE=/opt/collectd/run/collectdmon.pid
BIN=/opt/collectd/sbin/collectd
DAEMON=/opt/collectd/sbin/collectdmon
CONFIG=/opt/collectd/etc/collectd.conf
LOG=/opt/collectd/var/log/collectd.log

case "$1" in
  start)
    if [ -f $PIDFILE ] ; then
      echo "Already running. Stale PID file?"
      PID=`cat $PIDFILE`
      echo "$PIDFILE contains $PID"
      ps -p $PID
      if [ $? -ne 0 ] ; then
        rm $PIDFILE
      fi
    fi
    PATH=/opt/collectd/sbin:$PATH
    export PATH
    $DAEMON -P $PIDFILE -- -C $CONFIG
    if [ $? -ne 0 ] ; then
      echo $DAEMON failed to start
    fi
    ps -ef | grep collectd | grep -v status | grep -v grep
  ;;
  test)
    $BIN -T
  ;;
  stop)
    PID=`cat $PIDFILE 2>/dev/null`
    kill -15 $PID 2>/dev/null
    pwait $PID 1> /dev/null 2>/dev/null
  ;;
  restart)
    $0 stop
    $0 start
  ;;
  status)
    ps -ef | grep collectd | grep -v status | grep -v grep
  ;;
  tail)
    tail -f $LOG
  ;;
  *)
    echo "Usage: $0 [ test | start | stop | restart | status | tail ]"
    exit 1
  ;;
esac


exit 0
