    
# -*- coding: utf-8 -*-
"""
@author: ponychen
plot phono band wth k point distance not k index
"""

import numpy as np
import sys
import math

def parse_filband(feig, npl=10):
    # feig : filband in bands.x input file
    # npl : number per line

    feig=open(feig)
    l=feig.readline()
    nbnd=int(l.split(',')[0].split('=')[1])
    nks=int(l.split(',')[1].split('=')[1].split('/')[0])
    
    eig=np.zeros((nks,nbnd+1),dtype=np.float32)
    
    kpoints=np.zeros([nks,3],dtype=np.float32)
    for i in range(nks):
        l=feig.readline()
        kpoints[i,:]=list(map(float,l.split()))
        if i==0:
            kpath=0.0
        else:
            kpath+=np.sqrt(np.sum((kpoints[i,:]-kpoints[i-1,:])**2))
        eig[i,-1]=kpath
        count=0
        # npl: max number of bands in one line
        n=math.ceil(nbnd/npl)
        for j in range(n):
            l=feig.readline()
            for k in range(len(l.split())):
                eig[i][count]=l.split()[k]  # str to float
                count=count+1
                
    feig.close()

    return eig, nbnd, nks

eig, nbnd, nks=parse_filband(sys.argv[1],npl=10)
with open('freq.txt',"w") as f:
    for j in range(nbnd):
        for i in range(nks):
            line=str(eig[i,-1])+" "+str(eig[i,j])+"\n"
            f.write(line)
        f.write("\n")

    


