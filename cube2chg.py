# -*- coding: utf-8 -*-
"""
Created on Thu Aug 27 15:03:21 2020

@author: ponychen
"""

import numpy as np
import sys

# read cube file
with open(sys.argv[1],'r') as f:
    f.readline()
    f.readline() #past first two lines
    trdline = f.readline().split()
    natom = int(trdline[0])
    orig = list(map(float,trdline[1:4]))
    step = np.zeros([3,3]) # step of translation vector
    ngrid = [0,0,0] # number of graids along 3 directional vetors
    for i in range(3):
        tmp = f.readline().split()
        ngrid[i] = int(tmp[0])
        step[i,:] = list(map(float,tmp[1:4]))
    # read atoms elements type and coordinates
    dd = {79:'Au'} #relationship between atomic index and symbol
    ele = {}
    cord = np.zeros([natom,3])
    for i in range(natom):
        tmp = f.readline().split()
        if dd[int(tmp[0])] not in ele.keys():
            ele[dd[int(tmp[0])]] = 1
        else:
            ele[dd[int(tmp[0])]] += 1
        cord[i,:] = list(map(float,tmp[2:5]))
    # check whther the total numbers of atoms are right
    if natom != sum(ele.values()):
        sys.exit("check your file! number of atoms is not match!!!\n")
    # read grid
    oneDgrid = []
    while True:
        tmp = f.readline()
        if not tmp:
            break
        tmp = list(map(float,tmp.split()))
        for i in range(len(tmp)):
            oneDgrid.append(tmp[i])

# output to CHGCAR
tDgrid = np.zeros(ngrid)
ii = 0
for i in range(ngrid[0]):
    for j in range(ngrid[1]):
        for k in range(ngrid[2]):
            tDgrid[i,j,k] = oneDgrid[ii]
            ii += 1

with open('CHGCAR','w') as ff:
    ff.write('converted from cube by ponychen \n')
    ff.write('1.00000000 \n')
    cell = step*np.array(ngrid).reshape(3,1)*0.5291772
    tmp = np.cross(cell[0,:],cell[1,:])
    vol = abs(np.dot(tmp,cell[2,:]))
    for i in range(3):
        ff.write(str(cell[i,0])+ "  "+str(cell[i,1])+"  "+str(cell[i,2])+"\n")
    line1 = ' '
    line2 = ' '
    for i in ele.keys():
        line1 += i
        line1 += ' '
        line2 += str(ele[i])
        line2 += ' '
    line1 += '\n'
    line2 += '\n'
    ff.write(line1)
    ff.write(line2)
    ff.write('Cartesian\n')
    for i in range(natom):
        ff.write(str(cord[i,0]*0.5291772)+' ' +str(cord[i,1]*0.5291772)+' '+str(cord[i,2]*0.5291772)+'\n')
    ff.write('\n')
    ff.write(str(ngrid[0])+' '+str(ngrid[1])+' '+str(ngrid[2])+'\n')
    nn = 0
    for i in range(ngrid[2]):
        for j in range(ngrid[1]):
            for k in range(ngrid[0]):
                ff.write(str(tDgrid[k,j,i]/0.5291772**3*vol  )+' ')
                if nn%5 == 4:
                    ff.write('\n')
                nn += 1
        