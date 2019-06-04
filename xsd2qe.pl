#!perl
#this script tranform xsd file to qe input file, just set filename of xsd. but remerber to alter relative input parameters in qe.txt
#ponychen
#20190604
#email:18709821294@outlook.com

use strict;
use Getopt::Long;
use MaterialsScript qw(:all);

#change following parameters depend upon you
my $filename = "00";                      #your xsd file name
my $doc = $Documents{"$filename.xsd"};    
my $pos = Documents->New("qe.txt");       #output txt name
my $isfrac = "True";                      #True:the atom coordination are Direct False:the atom COORDINATION ARE CARTESIAN

#some inner parameters 
my $lattice = $doc->SymmetryDefinition;
my $FT;
my @num_atom; 
my $FT1;
my $FT2;
my $FT3;
my %element;

#some input parameters for qe
my $str1 = " &CONTROL
                 calculation = \'scf\' ,
                restart_mode = \'from_scratch\' ,
                      outdir = \'./temp/\' ,
                  pseudo_dir = \'./\' ,
                      prefix = \'Fe.mag\' ,
               etot_conv_thr = 1.0D-5 ,
               forc_conv_thr = 1D-5 ,
                       nstep = 100 ,
                     tstress = .true. ,
                     tprnfor = .true. ,
 /
 &SYSTEM
                       ibrav = 0,
                         nat = 6,
                        ntyp = 1,
                     ecutwfc = 50 ,
                     ecutrho = 500 ,
                 occupations = \'tetrahedra_opt\' ,
!                     degauss = 0.002 ,
!                    smearing = \'marzari-vanderbilt\' ,
                       nspin = 2 ,
   starting_magnetization(1) = 1.0,
 /
 &ELECTRONS
                    conv_thr = 1.0D-7 ,
                 mixing_mode = \'plain\' ,
 /
 &IONS
                ion_dynamics = \'bfgs\' ,
 /
CELL_PARAMETERS angstrom \n";

$pos->Append($str1);

#cell parameters
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorA->X, $lattice->VectorA->Y, $lattice->VectorA->Z);
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorB->X, $lattice->VectorB->Y, $lattice->VectorB->Z);
$pos->Append(sprintf "%f %f %f \n",$lattice->VectorC->X, $lattice->VectorC->Y, $lattice->VectorC->Z);

#sort the atom by atomic number and create a hash for between elementsymbol and atomic mass
my $atoms = $doc->UnitCell->Atoms;
my @sortedAt = sort {$a->AtomicNumber <=> $b->AtomicNumber} @$atoms;

$element{$sortedAt[0]->ElementSymbol}=$sortedAt[0]->Mass;
my $atom_num = $sortedAt[0]->AtomicNumber;
foreach my $atom (@sortedAt) {
  if ($atom->AtomicNumber == $atom_num) {
    next;
  } else {
    $element{$atom->ElementSymbol}=$atom->Mass;
    $atom_num = $atom->AtomicNumber;
  }
}

#pseudopotential 
$pos->Append("ATOMIC_SPECIES\n");
foreach my $ele (keys %element) {
    $pos->Append(sprintf "   %s\t%9.6f\t***.UPF\n",$ele,$element{$ele});
}     

#atom coordination
$pos->Append("ATOMIC_POSITIONS angstrom\n");
foreach my $atom (@sortedAt) {
 if ($atom->IsFixed("X")) {
    $FT1 = "0";
 } else {
    $FT1 = "1";
 }
 if ($atom->IsFixed("Y")) {
    $FT2 = "0";
 } else {
    $FT2 = "1";
 }
 if ($atom->IsFixed("Z")) {
    $FT3 = "0";
 } else {
    $FT3 = "1";
 } 

if ($atom->IsFixed("FractionalXYZ")) {
    $FT = "0 0 0";
 } elsif ($atom->IsFixed("XYZ")) {
    $FT = "0 0 0"; 
} else {
    $FT = "$FT1 $FT2 $FT3";
} 
 if ($isfrac eq "False"){
    $pos->Append(sprintf "%s\t%9.6f\t%9.6f\t%9.6f\t%s\n",$atom->ElementSymbol,$atom->X,$atom->Y,$atom->Z,$FT);}
    else{
    $pos->Append(sprintf "%s\t%9.6f\t%9.6f\t%9.6f\t%s\n",$atom->ElementSymbol,$atom->FractionalXYZ->X,$atom->FractionalXYZ->Y,$atom->FractionalXYZ->Z,$FT);}
} 

#kpoints  
$pos->Append("KPOINTS automatic\n");
$pos->Append("   2  7  3 1 1 1");   