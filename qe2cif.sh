#!/bin/bash
#this script trafer QE input file into cif format
#usage: ./qe2vasp.sh inputfile outputfile
#ponychen
#20190604
#email:18709821294@outlook.com

#get the begin and end rows of cell parameters in qe file
cellbegin=`grep -in "CELL_PARAMETERS" $1 | awk ' BEGIN{FS=":"} {print $1+1}'`
cellend=$(($cellbegin+2))

#check whether bohr unit or angstrom
cellord=`grep -i "CELL_PARAMETERS" $1 | awk '{print $2}' | tr [A-Z] [a-z]`
if [ "$cellord" == "angstrom" ] || [ "$cellord" == "{angstrom}" ];then
	isbohr=0
elif [ "$cellord" == "bohr" ] || [ "$cellord" == "{bohr}" ];then
	isbohr=1
else
	echo "sorry, at present not sipport this format"
fi
#some silly bugs in determing ax[2],so i need to get it individually....
ax[2]=`awk -v begin=$cellbegin  -v isbohr=$isbohr '
NR==begin+1 {if(isbohr==0){x0=$1;y0=$2;z0=$3}
             else{x0=$1*0.5292;y0=$2*0.5292;z0=$3*0.5292}
				 printf("%9.6f", sqrt(x0^2+y0^2+z0^2))}' $1`

#get a b c cosbc cosac cosab
eval $(awk -v begin=$cellbegin -v end=$cellend -v isbohr=$isbohr '
     NR>=begin && NR<=end {if(isbohr==0){x0[NR]=$1;y0[NR]=$2;z0[NR]=$3}
                           else{x0[NR]=$1*0.5292;y0[NR]=$2*0.5292;z0[NR]=$3*0.5292}}
     END{for(i=begin;i<=end;i++){
	 ax[i-begin+1]=sqrt(x0[i]^2+y0[i]^2+z0[i]^2);
     printf("cell[%d]=\"   %9.6f\t%9.6f\t%9.6f\"\n",i,x0[i],y0[i],z0[i])}
	 cosalpha=(x0[begin+1]*x0[end]+y0[begin+1]*y0[end]+z0[begin+1]*z0[end])/(ax[2]*ax[3]);
	 cosbeita=(x0[begin]*x0[end]+y0[begin]*y0[end]+z0[begin]*z0[end])/(ax[1]*ax[3]);
	 cosgamma=(x0[begin]*x0[begin+1]+y0[begin]*y0[begin+1]+z0[begin]*z0[begin+1])/(ax[1]*ax[2]);
	 sinalpha=sqrt(1-cosalpha^2);
	 sinbeita=sqrt(1-cosbeita^2);
	 singamma=sqrt(1-cosgamma^2);
	 if(cosalpha==0){alpha=90}
	 else{alpha=atan2(sinalpha,cosalpha)*180/3.1415926};
		 if(cosbeita==0){beita=90}
		 else{beita=atan2(sinbeita,cosbeita)*180/3.1415926};
			 if(cosgamma==0){gamma=90}
			 else{gamma=atan2(singamma,cosgamma)*180/3.1415926};
	printf("ax[1]=%9.6f\n",ax[1]);   
	printf("ax[3]=%9.6f\n",ax[3]);
	printf("alpha=%9.6f\n",alpha);
	printf("beita=%9.6f\n",beita);
	printf("gamma=%9.6f\n",gamma)}' $1)

#echo cell parameters into temp file
echo ${cell[$cellbegin]} > temp
echo ${cell[$(($cellbegin+1))]} >> temp
echo ${cell[$cellend]} >> temp

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

#echo atom coordination to temp
atomord=`grep -i "ATOMIC_POSITIONS" $1 | awk '{print $2}' | tr [A-Z] [a-z]`
if [ "$atomord" == "angstrom" ] || [ "$atomord" == "{angstrom}" ];then
	awk -v begin=$atombegin -v end=$atomend '
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2;y0[NR]=$3;z0[NR]=$4}
	   END{for(i=begin;i<=end;i++){
	   printf("%s%d\t1.0000\t%9.6f\t%9.6f\t%9.6f\t%s\n",symbol[i],i-begin+1,x0[i],y0[i],z0[i],symbol[i])}}' $1 >> temp
   elif [ "$atomord" == "bohr" ] || [ "$atomord" == "{bohr}" ];then
	awk -v begin=$atombegin -v end=$atomend '
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2*0.5292;y0[NR]=$3*0.5292;z0[NR]=$4*0.5292}
	   END{for(i=begin;i<=end;i++){
	   printf("%s%d\t1.0000\t%9.6f\t%9.6f\t%9.6f\t%s\n",symbol[i],i-begin+1,x0[i],y0[i],z0[i],symbol[i])}}' $1 >> temp
   elif [ "$atomord" == "alat" ] || [ "$atomord" == "{alat}" ];then
	awk -v begin=$atombegin -v end=$atomend -v celldm=$celldm'
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2*celldm;y0[NR]=$3*celldm;z0[NR]=$4*celldm}
	   END{for(i=begin;i<=end;i++){
	   printf("%s%d\t1.0000\t%9.6f\t%9.6f\t%9.6f\t%s\n",symbol[i],i-begin+1,x0[i],y0[i],z0[i],symbol[i])}}' $1 >> temp
   elif [ "$atomord" == "crystal" ] || [ "$atomord" == "{crystal}" ];then
	eval $(awk -v begin=$atombegin -v end=$atomend '
	       NR>=begin && NR<=end {symbol[NR]=$1;x0[NR]=$2;y0[NR]=$3;z0[NR]=$4}
	   END{for(i=begin;i<=end;i++){
	   printf("atom[%d]=\"%s%d\t1.0000\t%9.6f\t%9.6f\t%9.6f\t%s\"\n",i-begin+1,symbol[i],i-begin+1,x0[i],y0[i],z0[i],symbol[i])}}' $1)
       else
	       echo "at present not support this coodination format"
   fi

#read from temp and convert atom coordination to crystal format
	eval $(awk -v begin=$atombegin -v end=$atomend '
	BEGIN{col=end-begin}
		NR>=1 && NR<=3 {r[NR+2]=$1;s[NR+2]=$2;t[NR+2]=$3}
		NR>=4 && NR<=4+col {symbol[NR]=$1;x0[NR]=$3;y0[NR]=$4;z0[NR]=$5;v0[NR]=$6}
	END{A1=s[5]*r[3]-s[3]*r[5];
	    B1=t[5]*r[3]-t[3]*r[5];
		A2=s[4]*r[3]-s[3]*r[4];
		B2=t[4]*r[3]-t[3]*r[4];
		Q=B2*A1-B1*A2;
		k[3]=(A2*r[5]-A1*r[4])/Q;
		l[3]=A1*r[3]/Q;
		m[3]=-A2*r[3]/Q;
		k[2]=(B2*r[5]-B1*r[4])/(-Q);
		l[2]=B1*r[3]/(-Q);
		m[2]=-B2*r[3]/(-Q);
		k[1]=(1-s[3]*k[2]-t[3]*k[3])/r[3];
		l[1]=-(s[3]*l[2]+t[3]*l[3])/r[3];
		m[1]=-(s[3]*m[2]+t[3]*m[3])/r[3];
		for(i=4;i<=4+col;i++){
			x1[i]=k[1]*x0[i]+l[1]*y0[i]+m[1]*z0[i];
			y1[i]=k[2]*x0[i]+l[2]*y0[i]+m[2]*z0[i];
			z1[i]=k[3]*x0[i]+l[3]*y0[i]+m[3]*z0[i];
			printf("atom[%d]=\"%s\t1.0000\t%9.6f\t%9.6f\t%9.6f\t%s\"\n",i-3,symbol[i],x1[i],y1[i],z1[i],v0[i])
		}}' temp )
rm temp

#write relative data to file in cif format
if [ $2 ];then
echo "#-----------------------------------------------

# CRYSTAL DATA

#-----------------------------------------------

data_VESTA_phase_1


_chemical_name_common                ''
_cell_length_a                       ${ax[1]}
_cell_length_b                       ${ax[2]}
_cell_length_c                       ${ax[3]}
_cell_angle_alpha                    $alpha
_cell_angle_beta                     $beita
_cell_angle_gamma                    $gamma
_space_group_name_H-M_alt            'p 1'
_space_group_IT_number               1

loop_
_space_group_symop_operation_xyz
   'x, y, z'

loop_
   _atom_site_label
   _atom_site_occupancy
   _atom_site_fract_x
   _atom_site_fract_y
   _atom_site_fract_z
   _atom_site_type_symbol" > $2

for((i=1;i<=$(($atomend-$atombegin+1));i++))
do
	echo "   ${atom[$i]}" >> $2
done
else
	echo "please input output filename, okay, guy!"
fi
