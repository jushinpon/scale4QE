=b
original files from read-in sout folder
ori.lmp
ori.sout
ori.in

=cut
use warnings;
use strict;
use JSON::PP;
use Data::Dumper;
use Cwd;
use POSIX;

my $currentPath = getcwd();# dir for all scripts
chdir("..");
my $mainPath = getcwd();# main path of Perl4dpgen dir
chdir("$currentPath");

`rm -rf deformed_data`;
`mkdir -p deformed_data`;

#for cubic cell, a, b, and c are x, y, and z axises
my $max = 0.2;
my $min = -0.2;

my %deform = (
    scale_1da => ["a",$min,0.35],#negative direction, positive direction
    scale_2dab => ["a",-$max,$max,"b",-$max,$max],
    scale_3d => ["a",-$max,$max,"b",-$max,$max,"c",-$max,$max],#for the same format
    #if no shape change, you may remove the following
    shape => ["alpha",5.0,"beta",5.0,"gamma",5.0]#angle range for random change
); 
my %sys_para = (
    shape_deform => "no",#yes if you want to change box shape
    rand_range => 0.05,#range for random shift of each atom in unit of A
    scale_No => 3,#total number of generated structures for a scale case (should be x2 for negative+positive)
    #shape_No => 7,#total number of generated structures for a case changing the cell shape
);

my $total = 2 * $sys_para{scale_No} + 1;# neg + pos + ori.cif

my @cif4data = `find -L ./data4scale -type f -name "ori.cif"`;#find all data files
map { s/^\s+|\s+$//g; } @cif4data;
die "no ori.cif under ./data4scale\n" unless(@cif4data);

for my $cif_ref (@cif4data){
    $cif_ref =~ m|/(scale_[^/]+)/|;
    my $deform_type = $1;
    $cif_ref =~ m|/scale_[^/]+/(.+)/ori.cif|;
    my $str_type = $1;
   # print "$cif_ref,\n$deform_type,\n$str_type\n";
    my $output_dir = "./deformed_data/$deform_type/$str_type";
    `mkdir -p $output_dir`;
    `cp $cif_ref $output_dir`;

    my $path_QEin = `dirname $cif_ref`;
    $path_QEin =~ s/^\s+|\s+$//g;
    die "No QE input for $cif_ref\n" unless($path_QEin);
    `cp $path_QEin/ori.in $output_dir`;
    #die;
    #get cell info
    my $a_ref =  `grep "_cell_length_a" $cif_ref| awk '{print \$2}'`;
    my $b_ref =  `grep "_cell_length_b" $cif_ref| awk '{print \$2}'`;
    my $c_ref =  `grep "_cell_length_c" $cif_ref| awk '{print \$2}'`;
    my $alpha_ref =  `grep "_cell_angle_alpha" $cif_ref| awk '{print \$2}'`;
    my $beta_ref =  `grep "_cell_angle_beta" $cif_ref| awk '{print \$2}'`;
    my $gamma_ref =  `grep "_cell_angle_gamma" $cif_ref| awk '{print \$2}'`;
    chomp ($a_ref,$b_ref,$c_ref,$alpha_ref,$beta_ref,$gamma_ref);
    #print "$cif_ref:\n";
    #print "$a_ref,$b_ref,$c_ref,$alpha_ref,$beta_ref,$gamma_ref\n";
    my @temp = @{$deform{$deform_type}};
    #for my $d (@temp){
    #    print "$d\n";
    #}
    #die;
    my $temp = @temp; #for getting deform set (a,0.05,0.05)
    my $set = int($temp/3);
    die "no deform setting for $cif_ref!!!\n" unless(@temp or $temp or $set);
    my %axis;#axis to be deformed
#	#my @deform_array;
    for (0..$set-1){
        my $id = $_ * 3;#starting id of a set
        my $temp_axis = $temp[$id];#deformed axis
        #negative direction
        my $neg_max =  $temp[$id + 1];#(a,0.05,0.05): second one is negative 
        #print "\$sys_para{scale_No}:$sys_para{scale_No}\n";
		my $neg_incr = $neg_max/$sys_para{scale_No};
        for my $nu (0 .. $sys_para{scale_No} - 1){# no ref.cif length
            my $temp = 1.0 + ($neg_max - $neg_incr * $nu);
		    push @{$axis{$temp_axis}},$temp;#scale values for an axis, value from left to right
        }
        
        #positive direction with ref cif (0 .. $scale_No)
        my $pos_max =  $temp[$id + 2];#(a,0.05,0.05): second one is negative 
		my $pos_incr = $pos_max/$sys_para{scale_No};
        for my $nu (0 .. $sys_para{scale_No}){
            my $temp = 1.0 + ($pos_incr * $nu);
		    push @{$axis{$temp_axis}},$temp;#scale values for an axis
        }
    }
    #each axis hash is the ref for scale value array
    my @axiskeys = sort keys %axis;

    for my $k (0 .. $total -1){#loop over scale array
        my $prefix = sprintf("%02d",$k);
        my $output = "$deform_type" . "_" . "$prefix";#for atomsk output lmp file 
        #my @scale = @{$axis{$k}};
        #adjsut cell length
        print "Scale time: $k\n";
        for my $ax (@axiskeys){
           chomp $ax;
           my $keyword = "_cell_length_$ax";
           my $ref_len = '$'."$ax"."_ref";
           my $scale = $axis{$ax}->[$k];
           my $adjusted = eval($ref_len) * $scale;#get the value of a symbol
           print "axis: $ax, adjusted: $adjusted\n";
           system("sed -i -e \"s|$keyword.*|$keyword  $adjusted|\" $output_dir/ori.cif");
        }
        #if($sys_para_hr->{shape_deform} eq "yes"){#change box shape
        #   my $alpha_range = $deform_hr->{shape}->[1]; 
        #   my $alpha_adjusted = $alpha_ref + (2.0 * rand() - 1.0)*$alpha_range;
        #   system("sed -i -e \"s|_cell_angle_alpha.*|_cell_angle_alpha  $alpha_adjusted|\" $cif_ref");
#
        #   my $beta_range = $deform_hr->{shape}->[3]; 
        #   my $beta_adjusted = $beta_ref + (2.0 * rand() - 1.0)*$beta_range;
        #   system("sed -i -e \"s|_cell_angle_beta.*|_cell_angle_beta  $beta_adjusted|\" $cif_ref");
#
        #   my $gamma_range = $deform_hr->{shape}->[5]; 
        #   my $gamma_adjusted = $gamma_ref + (2.0 * rand() - 1.0)*$gamma_range;
        #   system("sed -i -e \"s|_cell_angle_gamma.*|_cell_angle_gamma  $gamma_adjusted|\" $cif_ref");
        #}
        system("atomsk $output_dir/ori.cif -disturb $sys_para{rand_range} -wrap -unskew $output_dir/$output.lmp");
        `mv $output_dir/$output.lmp $output_dir/$output.data`;
    }
        #die;
}