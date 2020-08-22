#!/usr/bin/python
#
# count transaction status (pass/faoil) on IGF log
# Stephen Boston CGI, April 2013
# Example:
# $ ./xactstatus.py ~/logs
#


import sys
import datetime
from prevhourlogs import prevhourlogs as logs

logdir = sys.argv[1]
lg = logs(logdir)
filelist = lg.filelist
prevhour = lg.prevhour
cntgood = 0
cntbad = 0

for fname in filelist :
  f = open(fname)
  for line in f.readlines() :
    if line.startswith(prevhour) and "transaction status" in line :
      if "passed" in line :
        cntgood += 1
      else :
        cntbad += 1
  f.close()

print "Pass :%s : Fail :%s" % (cntgood, cntbad)





