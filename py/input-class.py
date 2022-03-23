#!/usr/bin/env python
#
# Copyright (C)  @xenontheinertg 
# SPDX-License-Identifier: GPL-3.0-or-later

import sys, getopt

class Main:
    def __init__(a, argv):
        inputfile = ''
        outputfile = ''
        try:
            opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
        except getopt.GetoptError:
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit(2)
        for opt, arg in opts:
            if opt == '-h':
                print ('test.py -i <inputfile> -o <outputfile>')
                sys.exit()
            elif opt in ("-i", "--ifile"):
                inputfile = arg
            elif opt in ("-o", "--ofile"):
                outputfile = arg
        print ('Input file is "', inputfile)
        print ('Output file is "', outputfile)

if __name__ == "__main__":
   Main(sys.argv[1:])
