# -*- coding: utf-8 -*-
"""
this script calculate the avearage IPR all of states in a cell from cube
author: ponychen
date: 20200818
email: cjchen16s@imr.ac.cn
"""

import sys

with open(sys.argv[1],'r') as f:
    lines = f.readlines()

i = 0
while True:
    if len(lines[i].split()) == 6:
        break
    i += 1

chg = lines[i:-1]
del lines

chg1d = []
for j in chg:
    if j:
        tmp = list(map(float,j.split()))
        for k in tmp:
            chg1d.append(k)
del chg

num1 = 0
num2 = 0
for ele in chg1d:
    num1 += ele**2
    num2 += ele
num2 = num2**2

IPR = num1/num2

print("the IPR is "+str(IPR) )