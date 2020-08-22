#!/usr/bin/python

import sys, time, os
from datetime import datetime, timedelta
from parseutils import Trace
from prevhourlogs import prevhourlogs as logs


# Display the count of PUTs,GETs, LabSummaries processed through
# PLIS bean
#
# Stephen Boston, CGI, 2012-11, created
# Stephen Boston, CGI, 2013-01, added timezone sensitivity and comments
#
#
# Arguments:
# 1. First UTC hour of interest eg 2012-11-23T00
# 2. Final UTC hour of interest eg 2012-11-24T00
# 3. list of server.log instances to parse
#
# Eg. $ labdaltook.py 2013-01-04T00 2013-01-04T14 server.log_2013-01-03T2* server.log_2013-01-04* server.log
#
# Example output
#
##utc, pst, PUTs,timeouts,GETS,timeouts,SUMM,timeouts
##2013-01-04T00, 2013-01-03T16, 0, 0, 0, 0, 0, 0
##2013-01-04T01, 2013-01-03T17, 0, 0, 0, 0, 0, 0
##2013-01-04T02, 2013-01-03T18, 0, 0, 0, 0, 0, 0
##2013-01-04T03, 2013-01-03T19, 0, 0, 0, 0, 0, 0
##2013-01-04T04, 2013-01-03T20, 0, 0, 0, 0, 0, 0
##2013-01-04T05, 2013-01-03T21, 0, 0, 0, 0, 0, 0
##2013-01-04T06, 2013-01-03T22, 0, 0, 0, 0, 0, 0
##2013-01-04T07, 2013-01-03T23, 0, 0, 0, 0, 0, 0
##2013-01-04T08, 2013-01-04T00, 0, 0, 0, 0, 0, 0
##2013-01-04T09, 2013-01-04T01, 0, 0, 0, 0, 0, 0
##2013-01-04T10, 2013-01-04T02, 0, 0, 0, 0, 0, 0
##2013-01-04T11, 2013-01-04T03, 0, 0, 0, 0, 0, 0
##2013-01-04T12, 2013-01-04T04, 0, 0, 0, 0, 0, 0
##2013-01-04T13, 2013-01-04T05, 950, 0, 0, 0, 0, 0
##2013-01-04T14, 2013-01-04T06, 3747, 0, 1, 0, 1, 0


#
# Declarations
#
dbg=Trace("labdaltook")

#
# hour-indexed dictionaries for storing message counts and timeout counts
# each item in the dictionary is a tuple (message count, timeout count,
# and transaction time in seconds).
#
puttable = {}
gettable = {}
summtable = {}

#
#  The indices into the tuples
#
ixCount = 0
ixTimeouts = 1
ixTime = 2

#
# We initialize each of these dictionaries
# so that we have an entry for each hour of
# interest whether or not there are data for that
# hour.
#
def inittable(table, series) :
    for item in series :
        table[item] = [0,0,0]

#
# This generates the hour series, creating a series
# of strings representing each of the hours in the period
# of interest.
#
def gethourseries(start, end) :
    res = []
    res.append(start)
    tc = time.strptime(start, "%Y-%m-%dT%H")
    tn = time.strptime(end, "%Y-%m-%dT%H")
    while tc < tn :
        dt = datetime.fromtimestamp(time.mktime(tc))
        dt = dt + timedelta(minutes=60)
        dtl = str(dt)
        date = dtl.split()[0]
        hour = dtl.split()[1].split(":")[0]
        tcs = "%sT%s" % (date,hour)
        res.append(tcs)
        tc = time.strptime(tcs, "%Y-%m-%dT%H")

    return res

def minmaxsecs(table) :
    totalsecs = 0
    count = 0
    for item in table :
        if item[1] == 0 :
            totalsecs += item[2]
            count += 1
    return ['N/A', 'N/A', float(totalsecs/float(count))]



#
# We want to display both UTC and BC Pacific time so we have
# a Boolean function for Daylight Savings Time
#
def isPDT() :
    curtz=time.tzname
    os.environ['TZ']='US/Pacific'
    pdt = time.daylight
    os.environ['TZ']=curtz[0]
    if pdt != 0 :
        return True
    return False

#
# BC Pacific time
#
def localtime(timestring) :
  if isPDT() :
    toffset = 7
  else :
    toffset = 8

  t = time.strptime(timestring, "%Y-%m-%dT%H")
  a = datetime.fromtimestamp(time.mktime(t)) - timedelta(hours=toffset)

  lts = datetime.strftime(a,"%Y-%m-%dT%H")
  return lts

#
# Initialization
#


firsthour = sys.argv[1]
lasthour = sys.argv[2]
logdir = sys.argv[3]

timeseries = gethourseries(firsthour, lasthour)

inittable(puttable, timeseries)
inittable(gettable, timeseries)
inittable(summtable, timeseries)

n = len(sys.argv)

filelist = logs(logdir).filelist
#
# Processing
# parse each of the server logs for the data of interest
#
for fname in filelist :
    f = open(fname)
    for line in f.readlines() :
        if ": took " in line :
            dbg.put(line)
            hourstamp=line[3:16]
            dbg.put(hourstamp)
            secs = int(line.split()[7])
            if "PUT:" in line :
                dbg.put("PUT")
                tbl = puttable
            elif "GET" in line :
                dbg.put("GET")
                tbl = gettable
            elif "summary" in line :
                dbg.put("SUMMARY")
                tbl = summtable

            if hourstamp in tbl :
                dbg.put("found %s in tbl" % hourstamp)
                d=tbl[hourstamp]
                d[0] += 1
                if secs == 600 :
                    d[1] +=1
                else :
                    d[2] += secs
    f.close()

#
# Display
#

#
# Header initialization and display
#
if isPDT() :
    tzs = 'pdt'
else :
    tzs = 'pst'

print "utc, %s, PUTs,timeouts,GETS,timeouts,SUMM,timeouts" % tzs

#
# iterate over the time series for the period of interest,
# pulling data from the dictionaries and printing out
# a table row for each of the hours
#
for hour in timeseries :

  putcount = puttable[hour][0]
  puttimeouts = puttable[hour][1]

  getcount = gettable[hour][0]
  gettimeouts = gettable[hour][1]

  summcount = summtable[hour][0]
  summtimeouts  = summtable[hour][1]

  print "%s, %s, %s, %s, %s, %s, %s, %s " % (hour, localtime(hour), putcount, puttimeouts, getcount, gettimeouts, summcount, summtimeouts)

