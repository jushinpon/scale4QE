=b
original files from read-in sout folder
ori.lmp
ori.sout
ori.in
Only QE input file is required. 
=cut
use warnings;
use strict;
use Cwd;
use POSIX;

sub qein2data{

my ($sys_para_hr) = @_;

my $input_file = `grep -v "#" $sys_para_hr->{read_file}`;#input_path.dat indicating path and filename
$input_file =~ s/^\s+|\s+$//g;#QE input file
my $dir = `dirname $input_file`;#get path
$dir =~ s/^\s+|\s+$//g;#folder includes all files 
my @QEinput = `find $dir -type f -name "*.in"`;#find the corresponding QE in file
map { s/^\s+|\s+$//g; } @QEinput;
my $inputNo = @QEinput;
die "only one QE input file can exist in $dir!\n" if ($inputNo != 1);
my $QEinput = $QEinput[0];
chomp $QEinput;

my $QEnat = `grep "nat =" $QEinput|awk '{print \$3}'`;#atom number from QE input file	
$QEnat =~ s/^\s+|\s+$//g;
die "You don't get the Atom Number in the DFT input file, $QEinput!!!\n" unless($QEnat);

my $QEtype = `grep "ntyp =" $QEinput|awk '{print \$3}'`;#atom number from QE input file	
$QEtype =~ s/^\s+|\s+$//g;
die "You don't get the Atom type Number in the DFT input file, $QEinput!!!\n" unless($QEnat);

#Al 26.981538 Al.pbe-n-kjpaw_psl.1.0.0.UPF
my @ele = `grep -v '^[[:space:]]*\$' $QEinput|egrep -A$QEtype "ATOMIC_SPECIES"|grep -v 'ATOMIC_SPECIES'|grep -v -- '--'|awk '{print \$1}'`;
die "You don't get element symbols in the DFT input file, $QEinput!!!\n" unless(@ele);
map { s/^\s+|\s+$//g; } @ele;

my @ele_mass = `grep -v '^[[:space:]]*\$' $QEinput|grep -A $QEtype ATOMIC_SPECIES|grep -v ATOMIC_SPECIES|grep -v -- '--'|awk '{print \$2}'`;
die "You don't get element mass in the DFT input file, $QEinput!!!\n" unless(@ele);
map { s/^\s+|\s+$//g; }  @ele_mass;
my @mass;
for (1..@ele_mass){
    push @mass,"$_ $ele_mass[$_ - 1] # $ele[$_ - 1] ";
}
my $masses = join("\n",@mass);
chomp $masses;

my %ele2type;#element symbol to lmp type id
@ele2type{@ele} = 0..$#ele;##the same ID as @ele
`cp $QEinput $sys_para_hr->{output_folder}/ori.in`;
##get box information for lammps
my @box;
my @CellVec = `grep -A 3 "CELL_PARAMETERS" $QEinput`;
chomp @CellVec; 
for (@CellVec){
  if(m/^\s*([-+]?\d+\.?\d*e?[+-]?\d*)\s+([-+]?\d+\.?\d*e?[+-]?\d*)\s+([-+]?\d+\.?\d*e?[+-]?\d*)/){
		push @box, [$1,$2,$3];
  }	
}    
die "The no cell information in $QEinput\n" unless (@box);
my $a = ( ${$box[-3]}[0]**2.0 + ${$box[-3]}[1]**2.0 + ${$box[-3]}[2]**2.0 )**0.5;
my $b = ( ${$box[-2]}[0]**2.0 + ${$box[-2]}[1]**2.0 + ${$box[-2]}[2]**2.0 )**0.5;
my $c = ( ${$box[-1]}[0]**2.0 + ${$box[-1]}[1]**2.0 + ${$box[-1]}[2]**2.0 )**0.5;
my $cosalpha = (${$box[-2]}[0]*${$box[-1]}[0] + ${$box[-2]}[1]*${$box[-1]}[1] + ${$box[-2]}[2]*${$box[-1]}[2])/($b*$c);
my $cosbeta =  (${$box[-1]}[0]*${$box[-3]}[0] + ${$box[-1]}[1]*${$box[-3]}[1] + ${$box[-1]}[2]*${$box[-3]}[2])/($c*$a);
my $cosgamma = (${$box[-3]}[0]*${$box[-2]}[0] + ${$box[-3]}[1]*${$box[-2]}[1] + ${$box[-3]}[2]*${$box[-2]}[2])/($a*$b);
#https://docs.lammps.org/Howto_triclinic.html
my $lx = $a;
my $xy = $b*$cosgamma;
my $xz = $c*$cosbeta;
my $ly = sqrt($b**2.0 - $xy**2.0);
my $yz = ($b*$c*$cosalpha-$xy*$xz)/$ly;
my $lz = sqrt($c**2.0 - $xz**2.0 - $yz**2.0);

my $cell =<<"CELL_MESSAGE";
0.0 $lx xlo xhi
0.0 $ly ylo yhi
0.0 $lz zlo zhi
$xy $xz $yz xy xz yz
CELL_MESSAGE
chomp $cell;
#get coordinates
############## coord ############
##ATOMIC_POSITIONS (angstrom)        
##Al           -0.0000004209       -0.0000004098       -0.0000002490
#ATOMIC_POSITIONS {angstrom} for input file
my @coord = `grep -v '^[[:space:]]*\$' $QEinput|egrep -A$QEnat "ATOMIC_POSITIONS"|grep -v 'ATOMIC_POSITIONS'|grep -v -- '--'`;
map { s/^\s+|\s+$//g; } @coord;
die "**no coord was found in $QEinput\n" unless (@coord);
my @tempcoord;
my $count = 0;
for(@coord){
  chomp;
	#if(m/^\w+\s+([-+]?\d+\.?\d*)\s+([-+]?\d+\.?\d*)\s+([-+]?\d+\.?\d*)/){
	if(m/^(\w+)\s+([-+]?\d+\.?\d*e?[+-]?\d*)\s+([-+]?\d+\.?\d*e?[+-]?\d*)\s+([-+]?\d+\.?\d*e?[+-]?\d*)/){
        $count++;
        chomp ($1,$2,$3,$4);
        my $lmptype = $ele2type{$1} + 1;
        my @temp = ($count,$lmptype,$2,$3,$4);
        my $temp = join(" ",@temp);
        push @tempcoord,$temp;
	}	
}
die "no coord string was found in $QEinput\n" unless (@tempcoord);
my $coords = join("\n",@tempcoord);

my $here_doc =<<"END_MESSAGE";
# LAMMPS data file written by OVITO Basic 3.7.8

$QEnat atoms
$QEtype atom types

$cell

Masses

$masses

Atoms  # atomic

$coords
END_MESSAGE

open(FH, "> $sys_para_hr->{output_folder}/ori.lmp") or die $!;
print FH $here_doc;
close(FH);

`cp $sys_para_hr->{output_folder}/ori.lmp $sys_para_hr->{output_folder}/ori.data`;#for dpgen labelling
}# end sub
1;