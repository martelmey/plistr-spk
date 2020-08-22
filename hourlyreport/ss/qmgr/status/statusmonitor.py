#!/usr/bin/python
#
# Status monitor to create email message
#
# Takes input from several scripts and parses
# it into general information
# Developed for Python 2.4.6 (only common version at dev time)
#
# 2012-12-18    stephen boston, CGI, created
# 2012-12-19    grant shan, CGI, fixes after detailed testing
# 2013-03       stephen boston, CGI, added props file for environmental flexibility
#                                    and a few other improvements to improve readibility etc.
# 2013-04       stephen boston, CGI  added HTML support
#
# 2014-03-13    stephen boston, CGI changed checkqueues to compensate for the addition of the wildcard columns
#
import parseutils as utils

import sys, time, datetime, math, traceback
import subprocess as sp
from properties import Properties
from parseutils import Trace


propsfile=sys.argv[1]
props=Properties(propsfile)


outputfname= props.get("outputfname")
htmloutputfname=props.get("htmloutputfname")
messagetemplatefname = props.get("messagetemplatefname")
htmlmessagetemplatefname=props.get("htmlmessagetemplatefname")
posiacountsfname=props.get("posiacountsfname")
statusdirname=props.get("statusdirname")
checkhostsfname=props.get("checkhostsfname")
trafficfname= props.get("trafficfname")
#logqlistfname=props.get("logqlistfname")
logqlistcmd =props.get("logqlistcmd")
hialqlistcmd=props.get("hialqlistcmd")
msgsperhourfname=props.get("msgsperhourfname")
logfname=statusdirname + '/' + "statusmonitor"
ssfname=props.get("ssfname")

log = Trace(logfname)
sys.stderr = log.log
#log.setLog(sys.stdout)
log.put("Starting log")
# arguments #
# Properties file locating files we need to process
#

timeformatminute="%Y-%m-%dT%H:%M"

def toint(string) :
    try :
        return int(string)
    except :
        return None
    
def localtime(timestring) :
    try :   
        lt = utils.localtime(timestring, utils.tfmt_minute)
        log.put("getting localtime as %s" % lt )
        return lt
    except :
        log.put("exception converting to local time")
        return "N/A"

#
# List of messages highlighting issues worthy of investigation
#
flags = []
#
# dictionary of posia status info
#
posias = {}

#
# List of posias with failed status
#
posiafails = []

#
# Dictionary of status, defaulting to OK
#
status = {"HOSTS": "OK", "IGF":"OK", "EMS":"OK", "PLIS": "OK", "LAB":"OK", "SS":"OK"}

#
# Dictionary for IGF status
#
igf =  [{"passcount":0, "failcount": 0}, {"passcount":0, "failcount": 0}]
igflabels = ["IGF 1", "IGF 2"]
igfix = [-1]


    

#
# Dictionary for PLIS bean stats
#
plis = {"put":0, "tmout.put":0, "get":0, "tmout.get":0, "summ":0, "tmout.summ":0 }



#
# function to build the message from the template
# Assumes that all status dictionaries have been
# filled by the main process
#
def buildmessage() :
    log.put("Building text message")
    fin = open(messagetemplatefname)
    lines = fin.readlines()
    fin.close()
    inow = datetime.datetime.now()
    now = "%4d%02d%02dT%02d%02d" % (inow.year,inow.month,inow.day, inow.hour,inow.minute)


    fout = open(outputfname, 'w')

    for line in lines :
        if not ':' in line :
            fout.write(line)
        elif line.startswith(':') :
            continue
        else :
            log.put("reading line %s" % line)
            rec = line.split(':')

            if rec[0].startswith("FLAGS") :
                print >> fout, rec[1]
                printflags(fout)

            if rec[0].startswith("Critical App servers") :
                fout.write("%s: %s\n" % (rec[0].strip(), status["HOSTS"].strip()))

##            if rec[0].startswith("POSIA") :
##                fout.write(line)
##                for posia in posias :
##                    print "checking |%s|" % posia
##                    if posia in posiafails:
##                        msg = "\t%s: FLAGGED\n" % posia
##                    else :
##                        msg = "\t%s: OK\n" % posia
##                    fout.write(msg)

            if rec[0].startswith("IGF") :
                fout.write("%s: %s\n" % (rec[0].strip(), status["IGF"]))

            if rec[0].startswith("PLIS") :
                fout.write("%s: %s\n" % (rec[0].strip(), status["PLIS"]))

            if rec[0].startswith("LAB") :
                fout.write("%s: %s\n" % (rec[0].strip(), status["LAB"]))

            if rec[0].startswith("Queue Counts") :
                fout.write("\n" + line)
                fout.write("%s\t%s\t%s\t%s\t%s\t%s\n" % ("POSIA\t", "Cur", "PrvHr", "Last received", "\tLast returned", "\tLast EMS"))
                for posia in posias :
                    p=posias[posia]
                    #log.put("Posia is %s " % p)
                    try :
                        lastrcv = localtime(p[0])
                    except :
                        lastrcv = "       N/A       "

                    try :
                        lastprc = localtime(p[1])
                    except :
                        lastprc = "       N/A       "

                    try :
                        lastems = localtime(p[2])
                    except :
                        lastems = "       N/A       "


                    count = "%-7s" % p[4]
                    prevhour = "%-7s" % p[5]


                    line = "%-10s %s %s\t%s\t%s\t%s\n" % (posia, count, prevhour, lastrcv, lastprc, lastems)
                    fout.write(line)

            if line.startswith(":Distribution Status:") :
                log.put("Opening output file |%s|" % ssfname)
                ssfin=open(ssfname)
                sslines=ssfin.readlines()
                ssfin.close()
                log.put("Closed %s " % ssfname)
                for ssline in sslines :
                    ##rec=ssline.split('|')
                    fout.write(ssline)

    fin.close()
    fout.close()



def buildhtmlmessage() :
    log.put("building html message using template %s" % htmlmessagetemplatefname)
    fin = open(htmlmessagetemplatefname)
    log.put("Opened |%s|" % htmlmessagetemplatefname)
    lines = fin.readlines()
    fin.close()
    inow = datetime.datetime.now()
    now = "%4d%02d%02dT%02d%02d" % (inow.year,inow.month,inow.day, inow.hour,inow.minute)

    log.put("Opening output file |%s|" % htmloutputfname)
    fout = open(htmloutputfname, 'w')
    log.put("Opened %s " % htmloutputfname)

    for line in lines :
        if not line.startswith(':') :
            fout.write(line)
            log.put("wrote %s" % line)
        elif line.startswith('#') :
            log.put("skipping % " % line)
            continue
        else :
            log.put( "reading %s" % line)
            if line.startswith(":FLAGS:") :
                   if len(flags) > 0 :
                        print >> fout, "<br> %s" % line.split(":")[2]
                        for item in flags :
                            print >> fout, "<br> %s" % item

                    # print >> out, '<p>


            elif line.startswith(":AppServers:") :
                print >> fout, "<br>%s: %s" % (line.split(":")[2], status["HOSTS"].strip())

            elif line.startswith(":IGF:") :
                print >> fout, "<br>%s: %s" % (line.strip().split(":")[2], status["IGF"].strip())

            elif line.startswith(":PLIS:") :
               print >> fout, "<br>%s: %s" % (line.strip().split(":")[2], status["PLIS"].strip())

            elif line.startswith(":SS:") :
               print >> fout, "<br>%s: %s" % (line.strip().split(":")[2], status["SS"].strip())

            elif line.startswith(":LAB:") :
                print >> fout, "<br>%s: %s" % (line.strip().split(":")[2],status["LAB"].strip())

            elif line.startswith(":Queue Counts:") :
                for posia in posias :
                    log.put("POSIA dict is % s" % posia)
                    p=posias[posia]                    
                    try :
                        log.put("converting |%s| to localtime" % p[0].strip())
                        lastrcv = localtime(p[0]).strip()
                        if "N/A" not in lastrcv :
                            lastrcv = lastrcv[8:].replace('T','@')
                        log.put("converted to %s" % lastrcv)
                    except :
                        traceback.print_exc(log.log)
                        lastrcv = "N/A"

                    try :
                        lastprc = localtime(p[1]).strip()
                        if "N/A" not in lastprc :
                            lastprc = lastprc[8:].replace('T','@')
                    except :
                        lastprc = "N/A"

                    try :
                        lastems = localtime(p[2]).strip()
                        if "N/A" not in lastems :
                            lastems = lastems[8:].replace('T','@')
                    except :
                        lastems = "N/A"


                    count = "%-7s" % p[4]
                    prevhour = "%-7s" % p[5]

                    line='<tr><td align="center">%s</td><td align="center">%s</td><td align="center">%s</td><td align="center">%s</td><td align="center">%s</td><td align="center">%s</td></tr>' % (posia, count, prevhour, lastrcv, lastprc, lastems)
                    log.put("line will be %s" % line)

                    # line = "%-10s %s %s\t%s\t%s\t%s\n" % (posia, count, prevhour, lastrcv, lastprc, lastems)

                    fout.write(line)

            elif line.startswith(":Distribution Status:") :
                log.put("Opening output file |%s|" % ssfname)
                ssfin=open(ssfname)
                sslines=ssfin.readlines()
                ssfin.close()
                log.put("Closed %s " % ssfname)
                for ssline in sslines :
                    rec=ssline.split('|')
                    log.put("rec=%s" %rec)
                    sshtmlline='<tr><td>%s&nbsp;&nbsp;</td><td>&nbsp;&nbsp;%s&nbsp;&nbsp;</td><td>&nbsp;&nbsp;%s&nbsp;&nbsp;</td><td>&nbsp;&nbsp;%s&nbsp;&nbsp;</td><td>&nbsp;&nbsp;%s&nbsp;&nbsp;</td></tr>' % (rec[0].strip(), rec[1].strip(), rec[2].strip(), rec[3].strip(), rec[4].strip())
                    fout.write(sshtmlline)

    fin.close()
    fout.close()

#
# print the flag list to a writeable stream
#
def printflags(out) :
    if len(flags) > 0 :
        print >> out, "***** F L A G S *****"
    for item in flags :
        print >> out, item
    print >> out, '\n'

#
# Compare timestamps for receive and complete to spot delayed processing
#
def checkposias(posias) :
    now = datetime.datetime.now()
    firstmin = now - datetime.timedelta(minutes=5)
    lastmin = now + datetime.timedelta(minutes=5)
    curmin =  "%s-%02d-%02dT%02d%02d" % (now.year, now.month, now.day, now.hour, now.minute)
    firstmin = now
    trcv = datetime.datetime.min
    tproc = datetime.datetime.min
    procmin = datetime.datetime.min
    rcvmin = datetime.datetime.min
    gapmins = 0
    log.put("POSIAS are %s"% posias)
    for posia in posias :
        rcv =  posias[posia][0][:16].strip()
        if rcv != "None" :
            trcv = time.strptime(rcv, timeformatminute)

        proc = posias[posia][1][:16].strip()
        if proc != "None" and proc is not None:
            tproc = time.strptime(proc, timeformatminute)

        if trcv != "None" and trcv is not None :
            rcvmin = trcv.tm_hour*60 + trcv.tm_min

        if tproc != None and tproc is not None :
            procmin = tproc.tm_hour*60 + tproc.tm_min

##        if procmin is not None and rcvmin is not None :
##            gapmins = abs(rcvmin - procmin)
##
##            #
##            # 5 minutes is a wild guess. this will have to be adjusted
##            #
##            if gapmins > 1000 :
##               gapmins = abs(gapmins - 1440)
##            if gapmins > 5 :
##                flags.append("POSIA %s is processing %s minutes behind." % (posia, gapmins))
##                posiafails.append(posia)

        ems =  posias[posia][2][:16].strip()
        log.put("EMS is |%s|" % ems)
        if ems != "None" :
            tems = time.strptime(ems, timeformatminute)

        avg = posias[posia][3].strip()


        #
        # Again this threshold is a guess
        #
        if avg != "None" :
            if float(avg) > 12000.0 :
                flags.append("POSIA %s has high average processing time: %s" %( posia, avg) )

#
# parse igf check for failed transactions
#
##def checkigf() :
##    igfstore= "%s/%s" %(props.get("statusdirname"),"lastfail.igf.txt")
##    try :
##        #
##        # need the last fail count so that we don't
##        # report those already investigated
##        #
##
##        f=open(igfstore)
##        lastfail = int(f.readline().strip())
##        f.close()
##        log.put("igf failcount: %s " % igf["failcount"])
##        print lastfail
##        if int(igf["failcount"]) > lastfail :
##            flags.append("New failed transactions on IGF:%s" % igf["failcount"])
##    except :
##        pass
##
##    #
##    # write the last count
##    #
##    f=open(igfstore, 'w')
##    f.write(str(igf["failcount"]))
##    f.close()
##

def checkigf() :
    #igfstore= "%s/%s" %(props.get("statusdirname"),"lastfail.igf.txt")
    igfstore = "lastfail.igf.txt"
    try :
        #
        # need the last fail count so that we don't
        # report those already investigated
        #

        f=open(igfstore)
        lastfails = f.readline().strip().split()
        log.put("last fails is %s" % lastfails)
        f.close()
        
        log.put("igf failcount: %s %s" % (igf[0]["failcount"], igf[1]["failcount"]))
        for i in range(0,2) :
            if int(igf[i]["failcount"]) > int(lastfails[i].strip()) :
                flags.append("New failed transactions on %s:%s" % (igflabels[i], igf[i]["failcount"]))
                status["IGF"] = "Warning."
    except :
        traceback.print_exc()
        pass

    #
    # write the last count
    #
    f=open(igfstore, 'w')
    f.write("%s %s " % (igf[0]["failcount"],igf[1]["failcount"]))
    f.close()

#
# Check the PLIS output for timeouts
#
def checkplis() :
    plisstore="%s/%s" %( props.get("statusdirname"), "lasttmout.plis.txt")
    try :
        f = open(plisstore)
        data = f.readline().split(',')
        if int(plis["tmout.get"]) > int(data[0]) or int(plis["tmout.put"]) > int(data[1]) or int(plis["tmout.summ"]) > int(data[2]) :
            flags.append("New timeouts reported by PLIS bean. Check status of LAB apps. May need restarts.")
            status["PLIS"] = "Warning."
            status["LAB"] = "Warning."
    except :
        pass
    f = open(plisstore, 'w')
    f.write("%s,%s,%s" % (plis["tmout.get"],plis["tmout.put"],plis["tmout.summ"] ))
    f.close()



#
# check up/down status of hosts
#
def checkhosts() :
    f=open(checkhostsfname)
    for line in f.readlines() :
        if "DOWN" in line :
            flags.append(line.strip())
            hostsok = False
    f.close()

#
# *****
#

#
# *****
# check traffic stats, put posia times into the posia table
#
def checktraffic() :
    log.put("reading traffic report")
    
    
    
    f=open(trafficfname)
    for line in f.readlines():

        log.put("template line is %s" % line )
        if line.startswith('[') :
            posia = line[1:line.find(']')]
            log.put("\n\nUsing posia %s." % posia)
        elif line.startswith("Received") :
            rcv = line[15:31]
            log.put("rcv for %s is %s" % (posia, rcv))
        elif line.startswith("Processed") :
            proc = line[15:31]
            log.put("proc for %s is %s" % (posia, proc))
        elif line.startswith("EMS") :
            ems = line[15:31]
            log.put("ems for %s is %s" % (posia, ems))
        elif line.startswith("Avg") :
            avg = line[15:31].strip()
            log.put("avg for %s is %s" % (posia, avg))
        elif line.startswith("Input Queue") :
            count = line.split(":")[1].strip()
            log.put("count for %s is %s" % (posia, count))
        elif line.startswith("Prev Hour") :
            prevhour = line.split(":")[1].strip()
            log.put("prevhour for %s is %s" % (posia, prevhour))
            posias[posia] = (rcv,proc,ems,avg,count,prevhour)
            posia = 0
            rcv = 0
            proc = 0
            ems = 0
            avg = 0
            count = 0
            prevhour = 0

        elif line.startswith("xactions") :
##            igfdata = line.split(':')
##            igf["passcount"] += int(igfdata[2])
##            igf["failcount"] += int(igfdata[4])

              igfix[0]+=1
              log.put("igf index is %s " % igfix[0])
              igfdata = line.split(':')
              igf[igfix[0]]["passcount"] += int(igfdata[2])
              igf[igfix[0]]["failcount"] += int(igfdata[4])
        

            
        elif line.startswith("20") :
            plisdata = line.split(',')
            plis["put"] += int(plisdata[2])
            plis["tmout.put"] += int(plisdata[3])
            plis["get"] += int(plisdata[4])
            plis["tmout.get"] += int(plisdata[5])
            plis["summ"] += int(plisdata[6])
            plis["tmout.summ"] += int(plisdata[7])
    f.close()


#
# *****
#
##def checkqueues() :
##    f=open(logqlistfname)
##    for line in f.readlines() :
##        if "jms_AuditLog_Messages" in line :
##            data = line.split()
##            consumercount = int(data[4])
##            queuecount = int(data[5])
##            if consumercount < 10 :
##                flags.append("Consumers on audit log queue missing.Count is %s. Should be 10." % consumercount)
##            if queuecount > 125000 :
##                flags.append("Audit log queue is %s" % queuecount)
##
##            continue
##
##        if "jms_LabService_LA_QueryResponse" in line :
##            data = line.split()
##            queuecount = int(data[5])
##            if queuecount > 50 :
##                flags.append("LAQuery Response Queue is high at %s. This may have a small drag on performance and will be investigated." % queuecount)
##
##            continue


def checkqueues() :
    log.put("Checking queues. command is %s" % logqlistcmd)
    p=sp.Popen(logqlistcmd, shell=True, stderr=sp.STDOUT, stdout=sp.PIPE)
    log.put("q check process is opened.")
    for line in p.stdout :
        log.put("process read %s" % line )
        if "jms_AuditLog_Messages" in line :
            data = line.split()
            print "jms auditlog messages data is ", data
            consumercount = int(data[5])
            queuecount = int(data[7])
            log.put("audit log queucount is %s" % queuecount)
            if consumercount < 10 :
                flags.append("Consumers on audit log queue missing.Count is %s. Should be 10." % consumercount)
            if queuecount > 125000 :
                flags.append("Audit log queue is %s" % queuecount)

            continue

    p=sp.Popen(logqlistcmd, shell=True, stderr=sp.STDOUT, stdout=sp.PIPE)
    for line in p.stdout :
       if "jms_LabService_LA_QueryResponse" in line :
           data = line.split()
           queuecount = int(data[7])
           if queuecount > 50 :
               flags.append("LAQuery Response Queue is high at %s. This may have a small drag on performance and will be investigated." % queuecount)

           continue

    p=sp.Popen(hialqlistcmd, shell=True, stderr=sp.STDOUT, stdout=sp.PIPE)
    for line in p.stdout :
       if "jms_SubscriptionServices_DistributionRequest" in line and  "jms_SubscriptionServices_DistributionRequest_Email" not in line :
           data = line.split()
           if(data[1].strip().startswith("Queue")) :
               consumercount = int(data[4])
               log.put("line %s" % line)
               if consumercount == 0 :
                  status["SS"] = "Warning."
                  continue


#
# *****
#



checkhosts()

checktraffic()
checkigf()
#checkposias(posias)
checkplis()
checkqueues()
#buildmessage()
buildhtmlmessage()
log.close()


