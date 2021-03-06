#!/bin/bash
#20190605 add support for dissort atom coordinations
#20190603 add alat qe format support
#this script trafer QE input file into POSCAR format
#usage: ./qe2vasp.sh inputfile
#ponychen
#20190602
#email:18709821294@outlook.com

#get the begin and end rows of cell parameters in qe file
cellbegin=`grep -in "CELL_PARAMETERS" $1 | awk ' BEGIN{FS=":"} {print $1+1}'`
cellend=$(($cellbegin+2))

cellord=`grep -i "CELL_PARAMETERS" $1 | awk '{print $2}' | tr [A-Z] [a-z]`
if [ "$cellord" == "angstrom" ] || [ "$cellord" == "{angstrom}" ];then
    eval $(awk -v begin=$cellbegin -v end=$cellend '
       NR>=begin && NR<=end {x0[NR]=$1;y0[NR]=$2;z0[NR]=$3}
     END{for(i=begin;i<=end;i++){
     printf("cell[%d]=\"   %9.6f\t%9.6f\t%9.6f\"\n",i,x0[i],y0[i],z0[i])}}' $1)
 elif [ "$cellord" == "bohr" ] || [ "$cellord" == "{bohr}" ];then
     eval $(awk -v begin=$cellbegin -v end=$cellend '
       NR>=begin && NR<=end {x0[NR]=$1*0.5291772;y0[NR]=$2*0.5291772;z0[NR]=$3*0.5291772}
       END{for(i=begin;i<=end;i++){
        printf("cell[%d]=\"   %9.6f\t%9.6f\t%9.6f\"\n",i,x0[i],y0[i],z0[i])}}' $1)
	elif [ "$cellord" == "alat" ] || [ "$cellord" == "{alat}" ];then
		celldm=`grep "celldm(1)" $1 | awk '{print $3*0.5292}'` || celldm=`grep "A " $1 | awk '{print $3}'`
     eval $(awk -v begin=$cellbegin -v end=$cellend -v celldm=$celldm '
      NR>=begin && NR<=end {x0[NR]=$1*celldm;y0[NR]=$2*celldm;z0[NR]=$3*celldm}
      END{for(i=begin;i<=end;i++){
      printf("cell[%d]=\"   %9.6f\t%9.6f\t%9.6f\"\n",i,x0[i],y0[i],z0[i])}}' $1)
	else
		echo "sorry, at present not support this format"
	fi


#get the begin and end rows of atom coordinations in qe file
atombegin=`grep -in "ATOMIC_POSITIONS" $1 | awk ' BEGIN{FS=":"} {print $1+1}'`

noempty="1"
itr=$atombegin
ini=0
until [ "$noempty" == "" ]
do
	eval $(awk -v itr=$itr -v ini=$ini '
	NR==itr {ns=$1;x0=$2;y0=$3;z0=$4}
    END{printf("element[%d]=\"%s\"\n",ini,ns)}' $1)
	noempty=${element[$ini]}
	itr=$(($itr+1))
	ini=$(($ini+1))	
done
atomend=$(($itr-2))

#get the element type and relative numbers in qe file
elebegin=`grep -in "ATOMIC_SPECIES" $1 | awk 'BEGIN{FS=":"} {print $1+1}'`
noempty="1"
itr=$elebegin
ini=0
until [ "$noempty" == "" ]
do
	eval $(awk -v itr=$itr -v ini=$ini '
	NR==itr {ns=$1}
END{printf("elespe[%d]=\"%s\"\n",ini,ns)}' $1)
noempty=${elespe[$ini]}
itr=$(($itr+1))
ini=$(($ini+1))
done
eletol=$(($ini-1))
for ((i=0;i<=$eletol;i++))
do
	for j in ${element[*]}
	do
		if [ "$j" == "${elespe[$i]}" ];then
			elenum[$i]=$((${elenum[$i]}+1))
		fi
	done
done

#get the atom coordination
atomord=`grep -i "ATOMIC_POSITIONS" $1 | awk '{print $2}' | tr [A-Z] [a-z]`
if [ "$atomord" == "angstrom" ] || [ "$atomord" == "crystal" ] || [ "$atomord" == "{crystal}" ] || [ "$atomord" == "{angstrom}" ];then
	eval $(awk -v begin=$atombegin -v end=$atomend -v tol=$atomtol -v arr="${elespe[*]}" '
	BEGIN{split(arr,ele," ")}
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2;y0[NR]=$3;z0[NR]=$4;u[NR]=$5;v[NR]=$6;w[NR]=$7}
	   END{for(i=begin;i<=end;i++){
	   if(u[i]==0){u[i]="F"}else{u[i]="T"}
	   if(v[i]==0){v[i]="F"}else{v[i]="T"}
	   if(w[i]==0){w[i]="F"}else{w[i]="T"}}
		   k=begin-1;
		   for(i=1;i<=tol+2;i++){
			   for(j=begin;j<=end;j++){
				   if(symbol[j]==ele[i]){
					   k=k+1;
	   printf("atom[%d]=\"\t%9.6f\t%9.6f\t%9.6f\t%s\t%s\t%s\"\n",k,x0[j],y0[j],z0[j],u[j],v[j],w[j])}}}}' $1)
   elif [ "$atomord" == "bohr" ] || [ "$atomord" == "{bohr}" ];then
	eval $(awk -v begin=$atombegin -v end=$atomend -v tol=$atomtol -v arr="${elespe[*]}" '
	BEGIN{split(arr,ele," ")}
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2*0.5291772;y0[NR]=$3*0.5291772;z0[NR]=$4*0.5291772;u[NR]=$5;v[NR]=$6;w[NR]=$7}
	   END{for(i=begin;i<=end;i++){
	   if(u[i]==0){u[i]="F"}else{u[i]="T"}
	   if(v[i]==0){v[i]="F"}else{v[i]="T"}
	   if(w[i]==0){w[i]="F"}else{w[i]="T"}}
		   k=begin-1;
		   for(i=1;i<=tol+2;i++){
			   for(j=begin;j<=end;j++){
				   if(symbol[j]==ele[i]){
					   k=k+1;
	   printf("atom[%d]=\"\t%9.6f\t%9.6f\t%9.6f\t%s\t%s\t%s\"\n",k,x0[j],y0[j],z0[j],u[j],v[j],w[j])}}}}' $1)
   elif [ "$atomord" == "alat" ] || [ "$atomord" == "{alat}" ];then
	eval $(awk -v begin=$atombegin -v end=$atomend -v celldm=$celldm -v tol=$atomtol -v arr="${elespe[*]}" '
	BEGIN{split(arr,ele," ")}
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2*celldm;y0[NR]=$3*celldm;z0[NR]=$4*celldm;u[NR]=$5;v[NR]=$6;w[NR]=$7}
	   END{for(i=begin;i<=end;i++){
	   if(u[i]==0){u[i]="F"}else{u[i]="T"}
	   if(v[i]==0){v[i]="F"}else{v[i]="T"}
	   if(w[i]==0){w[i]="F"}else{w[i]="T"}}
		   k=begin-1;
		   for(i=1;i<=tol+2;i++){
			   for(j=begin;j<=end;j++){
				   if(symbol[j]==ele[i]){
					   k=k+1;
	   printf("atom[%d]=\"\t%9.6f\t%9.6f\t%9.6f\t%s\t%s\t%s\"\n",k,x0[j],y0[j],z0[j],u[j],v[j],w[j])}}}}' $1)
       else
	       echo "at present not support this coodination format"
   fi

#export to POSCAR
echo "generated by qe2vasp.sh" > POSCAR
echo "    1.00000" >> POSCAR
for ((i=$cellbegin;i<=$cellend;i=i+1))
do
	echo "    ${cell[$i]}" >> POSCAR
done

echo ${elespe[*]} >> POSCAR
echo ${elenum[*]} >> POSCAR
echo "Selective Dynamics" >> POSCAR

if [ "$atomord" == "crystal" ];then
	echo "Direct" >> POSCAR
else
    echo "Cartesian" >> POSCAR
fi

for ((i=$atombegin;i<=$atomend;i=i+1))
do
	echo "    ${atom[$i]}" >> POSCAR
done
