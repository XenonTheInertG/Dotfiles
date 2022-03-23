#!/usr/bin/env python

import subprocess

def sh(cmd, input="", silence = False):
    rst = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, input=input.encode("utf-8"))
    assert rst.returncode == 0, rst.stderr.decode("utf-8")
    if silence:
        return rst.stdout.decode("utf-8")
    return print (rst.stdout.decode("utf-8"))
