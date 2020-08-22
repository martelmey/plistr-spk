#!/usr/bin/python
#
# Stephen Boston, CGI
# May 2012
#

#
# Utility functions for AMS ops
#
import sys
import re
import datetime
import glob
import traceback
import exceptions
import sys, os, calendar,time
# from datetime import datetime, timedelta

tfmt_hour = '%Y-%m-%dT%H'
tfmt_minute = '%Y-%m-%dT%H:%M'
tfmt_second = '%Y-%m-%dT%H:%M:%S'

#
# datetime object for some time in Pacific Time
# 
def utcoffset(dt):
    #
    # get start of daylight savings time BC second sunday march
    #
    dststart  = datetime.datetime(dt.year, 3, 1)
    firstday = dststart.weekday()
    secondsun = 7-firstday + 7
    dststart = datetime.datetime(dt.year, 3, secondsun, 3 )
    
    #
    # Get end of daylight savings time BC first sunday november
    #
    dstend = datetime.datetime(dt.year, 11, 1, 3)
    firstday=dstend.weekday()
    firstday = (firstday + 7 ) % 7
    dstend= datetime.datetime(dt.year, 11, firstday, 3 )

    if dt > dststart and dt < dstend :
        return 7
    return 8
 
#
# return the Pacific time for the UTC timestring
#
def localtime(timestring, timeformat) :
  time = datetime.datetime.strptime(timestring, timeformat)
  toffset= utcoffset(time)
  t = time - datetime.timedelta(hours=toffset)
  lts = datetime.datetime.strftime(t,timeformat)
  return lts


nulltime = datetime.datetime.min

class Trace :
    def __init__(self,name) :
        self.log = open(name +'.log', 'w')

    def put(self, s ) :
        print >> self.log, s
        self.log.flush()

    def close(self) :
        self.log.close()

    def setLog(self, writeable) :
        self.log = writeable

    def close(self) :
        self.log.close()
    

#
# Extract the thread id from a log line
#
def threadIdFromLine(line):
  pos0 = line.find("ThreadID")
  if pos0 == -1 :
    return None
  pos0 += 9
  pos1 = line.find(";_ThreadName")
  return line[pos0:pos1]

#
# convert a date string to a python date
# This is often useful for date arithmetic
#
def parsedate(datestring) :
  if datestring == None :
    return nulltime
  year     = int(datestring[0:4])
  month    = int(datestring[5:7])
  day      = int(datestring[8:10])
  hour     = int(datestring[11:13])
  minute   = int(datestring[14:16])
  second   = int(datestring[17:19])
  microsec = int(datestring[20:23]+'000')

  return datetime.datetime(year,month,day,hour,minute,second,microsec)
#
# convert a date string to a python date
# This is often useful for date arithmetic
#
def parsedateMillis(datestring) :
  if datestring == None :
    return nulltime
  year     = int(datestring[0:4])
  month    = int(datestring[5:7])
  day      = int(datestring[8:10])
  hour     = int(datestring[11:13])
  minute   = int(datestring[14:16])
  second   = int(datestring[17:19])
  microsec = int(datestring[20:23])

  return datetime.datetime(year,month,day,hour,minute,second,microsec)

def timestampFromLine(line) :   
    l = line.split('|')
    time = l[1][0:23]
    return time
  

#
# Return the timestamp of a line. If a timestamp is not
# found in the usual location in the line, return None
#
def timeFromLine(line) :
  try :
    l = line.split('|')
    time = l[1][0:23]
    return parsedate(time)
  except :
   return None


#
# Return the datestring of a line containing a keyword
# where the keyword is given as a regular expression
#
def timeFromLineIF(line, regex ) :
  if not re.search(regex, line) :
    return None
  return timeFromLine(line)




#
# Return the transaction id of a line if
# the transacation id is given with
# the defined line
#
def xactIdFromLine(line) :
  if line.find("getting transaction id") < 0 :
    return None

  xactId = line.split()[5][0:36]
  return xactId

def subtracttime(stoptime,startime) :
    if stoptime == nulltime or startime == nulltime :
      return 'N/A'
##    if stoptime < startime :
##      raise exceptions.Exception("Start time:",startime," later than stop:", stoptime)
    return stoptime - startime

def deltatime(stoptime,startime) :
    if stoptime == nulltime or startime == nulltime :
      return 'N/A'
##    if stoptime < startime :
##      raise exceptions.Exception("Start time:",startime," later than stop:", stoptime)
    return stoptime - startime

def posiaTookFromLine(line) :
    if len(line.split()) < 8 :
      return None

    time = line.split()[8]
    time = int(time)
    return time

def mshFromIHAEndLine(line) :
    msh = line.split('|')[6]
    pos = msh.find('=')
    msh = msh[pos+1:]
    return msh
#
# try timedelta.total_seconds()
#
def timeFromDelta(td) :
    try :
      hours = td.days*24.0
      seconds = td.seconds
      microseconds = td.microseconds
      t = hours * 3600.0
      t+= float(seconds)
      t+= float(microseconds/1000000.0)
      return t
    except :
      print "Error: ", td



def indexline(line) :
    i = 0
    line = line.split('|')
    for item in line :
        print "[%s] %s" %(i, item)
        i += 1


