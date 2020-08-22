#!/usr/bin/python


#
# counts messages received by POSIA in the previous hour
# args:
# 1. the phrase or word in the server.log that marks
#    the arrival of an incoming message
# 2. path to the server.log directory.
#
# Example: ~/py/msgsperhour.py 7message ~/logs
#
# stephen boston cgi, April 2013
#
import sys, datetime, glob, parseutils



inboundstr = sys.argv[1]
logdir = sys.argv[2]

log = parseutils.Trace("msgsprevhour")

#
# List of files we will parse for the hour.
# The list is populated below
#
filelist = []

#
# Calculate the previous hour
#
now  = datetime.datetime.now()
then = now - datetime.timedelta(hours=1)

#
# Because server.logs are named for the time they are
# rolled over, we need to get all the files named in
# that hour, in the next, hour and in the current log
#
# Glob the server.logs to parse, get them into one
# list, and add the current server.log
#
prevfiles="%s/server.log_%s-%02d-%02dT%02d*" % (logdir,then.year,then.month,then.day,then.hour)
nowfiles="%s/server.log_%s-%02d-%02dT%02d*" % (logdir,now.year,now.month,now.day,now.hour)
pflist = glob.glob(prevfiles)
cflist = glob.glob(nowfiles)

#
# concat the lists
#
if pflist != None :
    filelist.extend(pflist)
if cflist != None :
    filelist.extend(cflist)

#
# sort and add
#
filelist = sorted(filelist)
filelist.append("%s/server.log" % logdir)

log.put("File list is %s" % filelist)


#
# Form the logging timestamp that we will be looking for
#
hourstr="[#|%s-%02d-%02dT%02d" % (then.year,then.month,then.day,then.hour)
log.put("Using %s" % hourstr)
#
# Go through the files and count
#
count =0
for fname in filelist :
    log.put("Opening %s" % fname)
    f=open(fname)
    
    for line in f :
        log.put(line)
        if line.startswith(hourstr) and inboundstr in line :
            count += 1

#
# Keep the output simple so that
# we don't have to parse it into
# the format we eventually want
# to use.
print count

log.close()

