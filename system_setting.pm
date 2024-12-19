=b
What you want to do for the cell and system parameter setting.
=cut
package system_setting;

use strict;
use warnings;
use Cwd;

my $currentPath = getcwd();# dir for all scripts
chdir("..");
my $mainPath = getcwd();# main path of Perl4dpgen dir
chdir("$currentPath");


#for cubic cell, a, b, and c are x, y, and z axises
my %deform = (
    scale_1da => ["a",-0.1,0.1],#negative direction, positive direction
    scale_2dab => ["a",-0.1,0.1,"b",-0.1,0.1],
    scale_3d => ["a",-0.1,0.1,"b",-0.1,0.1,"c",-0.1,0.1],#for the same format
    #if no shape change, you may remove the following
    shape => ["alpha",5.0,"beta",5.0,"gamma",5.0]#angle range for random change
); 
my %sys_para = (
    shape_deform => "no",#yes if you want to change box shape
    rand_range => 0.0,#range for random shift of each atom
    scale_No => 5,#total number of generated structures for a scale case (should be x2 for negative+positive)
    #shape_No => 7,#total number of generated structures for a case changing the cell shape
    #lmp_path => "/opt/lammps-mpich-3.4.2/lmp_20210915",
    #QE_path => "/opt/QEGCC_MPICH3.4.2/bin/pw.x",
    #read_type => "vc-relax",
    #read_type => "scf",#vcrelax,relax,scf
    read_file => "$currentPath/input_path.dat",#indicating where to find files
    output_folder => "$currentPath/output",# where to dump your converted files
    main_dir => "$mainPath",# upper folder of scripts folder
    current_dir => "$currentPath"
);

sub sys_setting{
    return (\%deform,\%sys_para);
}
1;               # Loaded successfully
