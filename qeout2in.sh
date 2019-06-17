#!/bin/bash
#this script save the relax cell and coordination to the input file of qe
#for the next calculation 
#usage: ./qeout2in.sh outputfile inputfile $1 is the output result after relaxation
#and $2 is the input file for qe performing scf etc.this script wil write
#the relaxed atom positions and cell para to the inputfile
#ponychen  
#20190617
#email:18709821294@163.com

#get the relaxed atomic coordinations
atombegin=`grep -in "ATOMIC_POSITIONS" $1 | tail -1 | awk ' BEGIN{FS=":"} {print $1+1}'`
atomend=`grep -in "End final coor" $1 | awk ' BEGIN{FS=":"} {print $1-1}'`

atomnum=$(($atomend-$atombegin+1))
eval $( awk -v num=$atomnum -v begin=$atombegin -v end=$atomend '
    NR>=begin && NR<=end {n[NR-begin+1]=$1;x[NR-begin+1]=$2;y[NR-begin+1]=$3;z[NR-begin+1]=$4}
    END{for(i=1;i<=num;i++){
		printf("coor[%d]=\"%s    %9.6f  %9.6f  %9.6f    \"\n",i,n[i],x[i],y[i],z[i])}}' $1)

atombegin2=`grep -in "ATOMIC_POSITIONS" $2 | awk ' BEGIN{FS=":"} {print $1+1}'`
atomend2=$(($atombegin2+$atomnum-1))

#get the relaxed cell parameters if vc-relax are performed
cellbegin=`grep -in "CELL_PARAMETERS" $1 | tail -1 | awk 'BEGIN{FS=":"} {print $1+1}'`
cellend=$(($cellbegin+2))

if [ $cellbegin ];then
	eval $( awk -v begin=$cellbegin '
	NR>=begin && NR<=begin+2 {x[NR-begin+1]=$1;y[NR-begin+1]=$2;z[NR-begin+1]=$3}
END{for(i=1;i<=3;i++){
printf("cell[%d]=\"    %9.6f  %9.6f  %9.6f\"\n",i,x[i],y[i],z[i])}}' $1)
    cellbegin2=`grep -in "CELL_PARAMETERS" $2 | awk 'BEGIN{FS=":"} {print $1+1}'`
	cellend2=$(($cellbegin2+2))
fi

#write atom coordinations to qe input file
for (( j=1; j<=$atomnum; j=j+1 ))
do
	begin=$(($atombegin2+$j-1))
	sed -i "${begin}c\ ${coor[$j]}" $2
done

#write relaxed cell parameters to qe input file if vc-relaxed performed
if [ $cellbegin ] ;then
	for (( j=1; j<=3; j=j+1 ))
	do
		begin=$(($cellbegin2+$j-1))
		sed -i "${begin}c\ ${cell[$j]}" $2
	done
fi
