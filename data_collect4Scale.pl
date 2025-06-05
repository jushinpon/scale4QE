#!/usr/bin/perl
=b
my %deform = (
    scale_1da => ["a",-0.1,0.1],#negative direction, positive direction
    scale_2dab => ["a",-0.1,0.1,"b",-0.1,0.1],
    scale_3d => ["a",-0.1,0.1,"b",-0.1,0.1,"c",-0.1,0.1],#for the same format
    #if no shape change, you may remove the following
    shape => ["alpha",5.0,"beta",5.0,"gamma",5.0]#angle range for random change
); 
=cut
use strict;
use Cwd;
use Data::Dumper;
use JSON::PP;
use Data::Dumper;
use List::Util qw(min max);
use Cwd;
use POSIX;
use Parallel::ForkManager;

my %dir4scale;
#for a orthogonal cell, a->x, b->y, and c->z
#This script also works for non-orthogonal cell
## IMPORTANT!! You need to make sure no data file name is identical within the scaling folders (scale_2dab, scale_3d...)
#$dir4scale{scale_1da} = ();

$dir4scale{scale_2dab} = [
   "/home/shihtsao/MS_Relax2Md_QE_from_MatCld/QEall_set_for_Scale/" #better to do vc-md or ve-relax first
];

#"/home/jsp/SnPbTe_alloys/QE_from_MatCld/cif2data/  only use materials project strutures
#under QEall_set, you need to provide the data_files folder  
# $dir4scale{scale_3d} = [
    #"/home/jsp/SnPbTe_alloys/QE_from_MatCld/cif2data/",
#     "/home/jsp/SnPbTe_alloys/make_B2_related_data/QEall_set/"
# ];

`rm -rf data4scale`;
`mkdir -p data4scale`;

###parameters to set first
my $currentPath = getcwd();# dir for all scripts
chdir("..");
my $mainPath = getcwd();# main path of Perl4dpgen dir
chdir("$currentPath");

for my $type (sort keys %dir4scale){#scaling type
    `rm -rf ./data4scale/$type`;
    `mkdir -p ./data4scale/$type`;

    print "**Scaling type: $type\n";
    my @temp_dirs = @{$dir4scale{$type}};
    
    for my $p (@temp_dirs){# all source dirs
        my @datafiles = `find -L $p -type d -name "data_files"`;#Find all data_files directories
        map { s/^\s+|\s+$//g; } @datafiles;
        die "No data_files folder under $p!\n" unless(@datafiles);
        
        my %lowest_temp;#get the lowest temperature for each prefix
        
        for my $path (@datafiles) {
            if ($path =~ m|(.*)/([^/]+)-T(\d+)-P\d+/data_files|) {
                my ($dir, $prefix, $temp) = ($1, $2, $3);
                if (!exists $lowest_temp{$prefix} or $temp < $lowest_temp{$prefix}{temp}) {
                    $lowest_temp{$prefix} = { dir => $dir, folder => "$prefix-T$temp-P0"};
                }
            }
        }
        #begin to collect the lowest temperature data files
        for my $prefix (keys %lowest_temp) {
            #print "Lowest temperature folder for $prefix:\n";
            my $dir = $lowest_temp{$prefix}{dir};
            my $folder = $lowest_temp{$prefix}{folder};
            my $QEin = "$dir/$folder/$folder.in";
            `mkdir -p ./data4scale/$type/$folder`;
            #copy the QE input file for kpoints
            die "No QE input file for $QEin\n" unless(-e $QEin);
            `cp  $QEin ./data4scale/$type/$folder/ori.in`;
            
            #copy the last data file of vc-md or md for the base structure
            my @data_file = glob("$dir/$folder/data_files/*.data");#get all data files under the lowest temperature folder
            map { s/^\s+|\s+$//g; } @data_file;
            @data_file = sort @data_file;
            die "No data files under $dir/$folder/data_files!\n" unless(@data_file);
            my $data = pop @data_file;#get the last data file
            `cp $data ./data4scale/$type/$folder/$folder.data`;
            `cp $data ./data4scale/$type/$folder/$folder.lmp`;#for atomsk
            system("atomsk ./data4scale/$type/$folder/$folder.lmp ./data4scale/$type/$folder/ori.cif");            
        }
    }#all data_files
}#all scaling types


