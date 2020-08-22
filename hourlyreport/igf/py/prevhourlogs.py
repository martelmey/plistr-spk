#!/usr/bin/python 
#
# creates a list of server.log containing records of the previous hour
#
# Argument:
# 1. server.log directory
#
# Example:
# /usr/bin/python
# from prevhourlogs import prevhourlogs as logs
# list = logs("~/logs").filelist
#

import datetime, glob

class prevhourlogs :
    def __init__(self, logdir) :
        #
        # List of files we will parse for the hour.
        # The list is populated below
        #
        self.filelist = []
	self.prevhour = None

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
            self.filelist.extend(pflist)
        if cflist != None :
            self.filelist.extend(cflist)

        #
        # sort and add
        #
        self.filelist = sorted(self.filelist)
        self.filelist.append("%s/server.log" % logdir)
	self.prevhour = "[#|%s-%s-%sT%s" % (then.year,then.month,then.day,then.hour)



