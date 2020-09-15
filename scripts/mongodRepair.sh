#!/bin/bash

DBPATH="/export/intindx/kvstore/mongo"

su - splunk -c 'splunk stop'
if [ -f $DBPATH/mongod.lock ]; then
    rm -f $DBPATH/mongod.lock
fi
mongod --dbpath $DBPATH --repair
su - splunk -c 'splunk start'