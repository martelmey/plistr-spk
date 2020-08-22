#!/usr/bin/python
#
# combines the posia stats for the hourly report
# prints to stdio
#
# Stephen Boston CGI, March 2013
#
# Arguments
# 1. phrase identifying inbound message arrival
# 2. TOOK time offset. TOOK line format varies across servers
# 3. The log directory
#

import sys, datetime, subprocess as sp, parseutils as psu
from prevhourlogs import prevhourlogs as logs



n=len(sys.argv) - 3

#
# phrase that marks arrival of message
#
inboundkey = sys.argv[1]
tooktimeoffset = int(sys.argv[2].strip())
logdir = sys.argv[3]


log = psu.Trace("scanposialog")

#
# returns a datetime tuple for a log timestamp
#
# Should be moved to parseutils once we feel like
# going through a new release of that library
#
def timeFromLine(line) :
    timestr = line.split("|")[1].split(".")[0]
    return datetime.datetime.strptime(timestr, "%Y-%m-%dT%H:%M:%S")

def queuesize() :
    log.put("In queuesize()")
    inque  = "N/A"
    errque = "N/A"
    dmque  = "N/A"

    p=sp.Popen('imqcmd list dst -u admin -p admin', shell=True, stderr=sp.STDOUT, stdout=sp.PIPE)
     
    for line in p.stdout :
        log.put(line)
        if line.startswith("quePosia_v2In") :
            inque = line.split()[5]
            if "PAUSED" in line :
                inque = "<%s>" % inque
        elif line.startswith("quePosiaError") :
            errque = line.split()[5]
        elif "dmq" in line :
            dmque = line.split()[5]

    return inque, errque, dmque




#
# Variables tracking most recent activity
#
lastrcv = None
lastprc = None
lastems = None

#
# Variable tracking msgs per second i.e. processed messages
#
prccount = 0 # count of messages
time0 = None # time of first message processed
time1 = None # time of last message processed

#
# Average HIAL transaction time
#
tookcount = 0
tooktime = 0
avgtook = 0
msgspersec = 0

filelist = logs(logdir).filelist
log.put(filelist)
#
# iterate over the 
#
for fname in filelist :
    log.put("Opening fname")
    f=open(fname)
    for line in f :
        #
        # Average HIAL time
        #
        if "HIAL TOOK" in line :
          if len(line.split()) > tooktimeoffset :
            tookcount += 1
            time = int(line.split()[tooktimeoffset])
            tooktime += int(time)
        #
        # Last processed and msgs/sec
        #
        elif "SendToHial" in line :
            prccount += 1
            lastprc = psu.timestampFromLine(line)
            if time0 == None :
                time0 = timeFromLine(line)
            else :
                time1 = timeFromLine(line)
        #
        # last message received
        #
        elif inboundkey in line :
            lastrcv = psu.timestampFromLine(line)
        # last EMS ACK received
        #
        elif "HTTP:" in line :
            lastems = psu.timestampFromLine(line)

    f.close()

#
# Average HIAL time
#

if tookcount > 0:
   avgtook = float(tooktime)/float(tookcount)

#
# Messages per second
#
if prccount > 0:
        timediff = time1-time0
        days, seconds = timediff.days, timediff.seconds
        #print "days = %s / seconds = %s" % (days,seconds)
        seconds += (days * 24 * 3600)
        #print "Seconds plussed = %s" % seconds

        msgspersec=  float(seconds) /float(prccount)

inqueue,errqueue,dmqueue = queuesize()

print "Received     : %s" % lastrcv
print "Processed    : %s" % lastprc
print "EMS ACK      : %s" % lastems
print "Avg Ms       : %0.3f" % avgtook
print "Msg/Sec      : %0.3f" % msgspersec
print "Input Queue  : %s" % inqueue
print "Error Queue  : %s" % errqueue
print "DM Queue     : %s" % dmqueue

