#!/usr/bin/python

import sys,socket,traceback, string
#
# checks for the up/down status of a list of hosts/ports
#

# Changes:
#
#	04/16/2013  Gail	Added igf2, 2 new domains for lab, and 1 new domain for lab2
#       05/01/2013 Gail G       Added xrs, split out hosts into a config file so that can be used for multiple envs
#       05/22/2013 Gail G       Change variable names to be lowercase
#       2013-04    SB		Input file as arg
# Check if file exists
# Import file into array

configfile = sys.argv[1]
hosts = []
hostinfo = []

with open(configfile, "r") as the_file:
    for line in the_file:
        newline = line.rstrip('\r\n')
        hosts.append(newline)

#hosts.sort()

hosts = sorted(hosts)
for host in hosts :
    hostinfo = ""
    hostinfo = host.split(",")
    hostname = hostinfo[0]
    port = hostinfo[1]
    portno = int(port)
   
    try :
        s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(10.0)
        s.connect((hostname, portno))

	print '{0:35}Port:{1:4} is UP'.format(hostname, portno)
        s.close()
    except socket.error :
	print '{0:35}Port:{1:4} is DOWN'.format(hostname, portno)
        s.close()
    except :
        print "Unexpected error:", sys.exc_info()[0]
        s.close()
