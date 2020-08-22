#!/usr/bin/python

import sys

class Properties :
    def __init__(self,fname) :
        self.table={}
        f=open(fname)
        for line in f :
            l = line.split("=")
            if len(l) < 2 :
                continue
            self.table[l[0]]=l[1].strip()
            print "Added %s to table." % l

    def get(self, propname) :
        if propname not in self.table :
            raise ValueError("%s not found in properties." % propname)

        return self.table[propname]


