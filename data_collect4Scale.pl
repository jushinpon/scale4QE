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
    "/home/jsp/SnPbTe_alloys/make_surface_20240919/add_vacuum/" #better to do vc-md or ve-relax first
];

#"/home/jsp/SnPbTe_alloys/QE_from_MatCld/cif2data/  only use materials project strutures
#under QEall_set, you need to provide the data_files folder  
$dir4scale{scale_3d} = [
    "/home/jsp/SnPbTe_alloys/QE_from_MatCld/cif2data/",
    "/home/jsp/SnPbTe_alloys/make_B2_related_data/QEall_set/"
];

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
        #my $dir = `dirname $p`;
        #$dir = s/^\s+|\s+$//g;
        #print "\$p: $p, \$dir: $dir\n";

        if($p =~ m|.+/QEall_set/.*|){
            my @datafiles = `find -L $p -type f -name "*.data"`;#find all data files
            map { s/^\s+|\s+$//g; } @datafiles;
            die "No data files to collect under $p!\n" unless(@datafiles);
            #get the last MD data file at the lowest temperature for scaling
            my %Str_minT;
            my %Str_path;
            for my $data (reverse sort @datafiles){#get the data file with the largest index
                $data =~ m|.+/([^/]+)-T(\d+)-P\d+/data_files/.+\.data|;
                die "No formula or temperature is captured for $data\n" unless($1 or $2);
                #print "**$data\n";
                #print "$QEin\n";
                #print "$data\n";
                if(exists $Str_minT{$1}){
                    if($Str_minT{$1} > $2){$Str_minT{$1} = $2;$Str_path{$1} = $data;}
                }
                else{
                    $Str_minT{$1} = $2;
                    $Str_path{$1} = $data;
                }
            }
        #get the lowest temperature

            for my $key (keys %Str_minT){
               # print "$key, $Str_minT{$key}\n";
                #print "$key, $Str_path{$key}\n";
                my $temp = "$key"."_T$Str_minT{$key}";
                `mkdir -p ./data4scale/$type/$temp`;
                #my $qein = /data_files/099.data;
                print "\$Str_path{$key}:$Str_path{$key}\n";
                #get the corresponding QE input
                $Str_path{$key} =~ m|(.+/[^/]+-T\d+-P\d+)/data_files/.+\.data|;                
                die "No QE input for $Str_path{$key}\n" unless($1);
                #my $QEin_dir = $1;
                my $QEin = `ls $1/*.in`;
                $QEin =~ s/^\s+|\s+$//g;        

                `cp $QEin ./data4scale/$type/$temp/ori.in`;
                `cp $Str_path{$key} ./data4scale/$type/$temp/$temp.data`;
                `cd ./data4scale/$type/$temp/;perl $currentPath/Mod_data_eleType.pl $temp.data`;
                `mv ./data4scale/$type/$temp/output.data ./data4scale/$type/$temp/$temp.lmp`;
                system("atomsk ./data4scale/$type/$temp/$temp.lmp ./data4scale/$type/$temp/ori.cif");
            }

        }
        else{#No /QEall_set/ (for scf only)
            my @datafiles = `find -L $p -type f -name "*.data"`;#find all data files
            map { s/^\s+|\s+$//g; } @datafiles;
            die "No data files to collect under $p!\n" unless(@datafiles);
            #get the last MD data file at the lowest temperature for scaling
            for my $data (@datafiles){
                #print "$data\n";
                my $temp = `basename $data\n`;
                $temp =~ s/^\s+|\s+$//g;
                $temp =~ s/\.data$//;
                
                $data =~ m|/(QE_from_MatCld)/|;
                if($1){
                    $data =~ m|(.*?)/[^/]+/[^/]+$|;
                    print "\$data: $data\n";
                    my $temp_dir = $1;
                    die "No Qe input for $data\n" unless($temp_dir);
                    my $QEin = `ls $temp_dir/QE_trimmed/$temp.in`;
                    $QEin =~ s/^\s+|\s+$//g;
                    die "No QE input of $data\n" unless($QEin);    
                    `mkdir -p ./data4scale/$type/$temp`;
                    `cp $QEin ./data4scale/$type/$temp/ori.in`;
                }
                else{
                    $data =~ m|(.*?)/[^/]+/[^/]+$|;
                    #print "\$data: $data\n";
                    my $temp_dir = $1;
                    die "No Qe input for $data\n" unless($temp_dir);
                    my $QEin = `ls $temp_dir/QE_trimmed/$temp/$temp.in`;
                    $QEin =~ s/^\s+|\s+$//g;
                    die "No QE input of $data\n" unless($QEin);    
                    `mkdir -p ./data4scale/$type/$temp`;
                    `cp $QEin ./data4scale/$type/$temp/ori.in`;
                }
                `cp $data ./data4scale/$type/$temp/$temp.data`;
                #`cp $data ./data4scale/$type/$temp/$temp.lmp`;
                `cd ./data4scale/$type/$temp/;perl $currentPath/Mod_data_eleType.pl $temp.data`;
                `mv ./data4scale/$type/$temp/output.data ./data4scale/$type/$temp/$temp.lmp`;
                
                #need to modify lmp with proper atom type number
                
                system("atomsk ./data4scale/$type/$temp/$temp.lmp ./data4scale/$type/$temp/ori.cif");

                #$data =~ m|.+/([^/]+)-T(\d+)-P\d+/data_files/.+\.data|;
            }

        }

    }

}


