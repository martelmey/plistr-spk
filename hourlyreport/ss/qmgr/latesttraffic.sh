#
# view on some interesting points of traffic
# stephen boston CGI Oct 2012
#
# ./latesttraffic [phsa | viha | vch | fha | iha | nha | igf | plis]
# example:
# $ ./latesttraffic phsa
# OR
# $ ./latesttraffic
# issued without an argument lists all
#
# Used function and case statement b/c parameter substitution in multi-level
# quotes was not possible.
#

#!/bin/bash

function phsa()
{
  echo [PHSA]
  ssh sboston@ps-phsa-posia.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-phsa-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py "Inbound message" /opt/JavaCAPS6u1p/logs'`
}


function viha()
{
  echo [VIHA]
  ssh sboston@ps-viha-posia.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-viha-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py 7message /opt/JavaCAPS6u1p/logs'`

}

function vch()
{
  echo [VCH]
  ssh sboston@ps-vch-posia.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-vch-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py "Inbound message" /opt/JavaCAPS6u1p/logs'`
}

function fha()
{
  echo [FHA]
  ssh sboston@ps-fha-posia.dmz.blackhole   2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" ` ssh sboston@ps-fha-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py 7message /opt/JavaCAPS6u1p/logs'`

}

function iha()
{
  echo [IHA]
  ssh sboston@ps-iha-posia.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-iha-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py 7message /opt/JavaCAPS6u1p/logs'`
}

function nha()
{
  echo [NHA]
  ssh sboston@ps-nha-posia.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py 7message 8  /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-nha-posia.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py "Inbound message" /opt/JavaCAPS6u1p/logs'`
}

function excl1()
{
  echo [EXCL1]
  ssh sboston@ps-excl-posia-1.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py "Inbound message" 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-excl-posia-1.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py "Inbound message" /opt/JavaCAPS6u1p/logs'`

}

function excl2()
{
  echo [EXCL2]
  ssh sboston@ps-excl-posia-2.dmz.blackhole  2>/dev/null  '/opt/JavaCAPS6u1p/py/scanposialog.py "Inbound message" 8 /opt/JavaCAPS6u1p/logs'
  echo "Prev Hour    :" `ssh sboston@ps-excl-posia-2.dmz.blackhole 2>/dev/null '/opt/JavaCAPS6u1p/py/msgsprevhour.py "Inbound message" /opt/JavaCAPS6u1p/logs'`
}

function igf()
{
  echo [IGF1]
  echo xactions' ': `ssh sboston@ps-igf1.vpn.blackhole 2>/dev/null  '/opt/SUNWappserver/py/xactstatus.py /opt/SUNWappserver/logs'`
  echo
  
  echo [IGF2]
  echo xactions' ': `ssh sboston@ps-igf2.vpn.blackhole 2>/dev/null  '/opt/SUNWappserver/py/xactstatus.py /opt/SUNWappserver/logs'`
  echo  
}

function pbeans()
{
  curhour=`date +"%Y-%m-%dT%H"`
  echo [PLIS Beans]
  ssh sboston@ps-lrs.vpn.blackhole  2>/dev/null "/opt/SUNWappserver/py/labdaltook-prevhr.py $curhour $curhour /opt/SUNWappserver/logs"
  ssh sboston@ps-lrs.vpn.blackhole  2>/dev/null "/opt/SUNWappserver/py/labdaltook-prevhr.py $curhour $curhour /opt/SUNWappserver/logs2"
  ssh sboston@ps-lrs2.vpn.blackhole  2>/dev/null "/opt/SUNWappserver/py/labdaltook-prevhr.py $curhour $curhour /opt/SUNWappserver/logs"
  
}

case $1 in
  "phsa" | "PHSA" ) phsa ;;
  "nha"  | "NHA"  ) nha ;;
  "viha" | "VIHA" ) viha ;;
  "iha"  | "IHA"  ) iha ;;
  "fha"  | "FHA"  ) fha ;;
  "vch"  | "VCH"  ) vch ;;
  "excl1 | "EXCL1") excl1;;
  "excl2 | "EXCL2") excl2;;
  "igf"  | "IGF"  ) igf;;
  "plis" | "PLIS") pbeans;;
  * ) phsa && echo " " && nha && echo " " && viha && echo " "  && iha && echo " " && fha && echo " " && vch && echo " " && excl1 && echo " " && excl2 && echo " "  && igf && echo " " && pbeans;;
esac




