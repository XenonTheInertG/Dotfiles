#!/usr/bin/env python3

import os

name = '0000'
x = 101
for i in range(101):
  if x > 100:
    name = '00'
  elif x > 10:
    name = '000'
  elif x > 0:
    name = '0000'
  #print(i)
  #print(name)
  x-=1
  out = (name + str(x)) + '.png'
  print(out)
  os.system('convert input.png -resize 1080x540 miff:- | composite -colors 8 -dissolve %s -gravity center watermark.png - output/%s'%(str(i) + '%', out))

