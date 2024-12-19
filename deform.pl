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

sub deform{

my ($deform_hr,$sys_para_hr) = @_;

my $ori_data = "$sys_para_hr->{output_folder}/ori.lmp";#original data file
die "no ori.lmp file in $sys_para_hr->{output_folder}" unless(-e $ori_data);
#make ori.cif
my $cif_ref = "$sys_para_hr->{output_folder}/ori.cif";
`rm -f $cif_ref`;
`atomsk $ori_data $cif_ref`;
my $a_ref =  `grep "_cell_length_a" $cif_ref| awk '{print \$2}'`;
my $b_ref =  `grep "_cell_length_b" $cif_ref| awk '{print \$2}'`;
my $c_ref =  `grep "_cell_length_c" $cif_ref| awk '{print \$2}'`;
my $alpha_ref =  `grep "_cell_angle_alpha" $cif_ref| awk '{print \$2}'`;
my $beta_ref =  `grep "_cell_angle_beta" $cif_ref| awk '{print \$2}'`;
my $gamma_ref =  `grep "_cell_angle_gamma" $cif_ref| awk '{print \$2}'`;
chomp ($a_ref,$b_ref,$c_ref,$alpha_ref,$beta_ref,$gamma_ref);

my @temp = sort keys %{$deform_hr};
my @deform = grep {$_ ne "shape"} @temp;#change cell shape or not for all length deform
chomp @deform;
#print "$deform_hr->{shape}->[0]\n";
#print "keys,@deform\n";
#begin deform
my $scaleNo = $sys_para_hr->{scale_No};#scale number for negative or positive side (X2 + 1 for total)
my $total = 2 * $scaleNo;# neg + pos 

for my $dtype (@deform){#loop over all deform types
    my @temp = @{$deform_hr->{$dtype}};
    my $temp = @temp; #for getting deform set (a,0.05,0.05)
    my $set = int($temp/3);
    my %axis;#axis to be deformed
	#my @deform_array;
    for (0..$set-1){
        my $id = $_ * 3;#starting id of a set
        my $temp_axis = $temp[$id];
        #negative direction
        my $neg_max =  $temp[$id + 1];#(a,0.05,0.05): second one is negative 
		my $neg_incr = $neg_max/$scaleNo;
        for my $nu (0..$scaleNo - 1){
            my $temp = 1.0 + ($neg_max - $neg_incr * $nu);
		    push @{$axis{$temp_axis}},$temp;#scale values for an axis
        }
        
        #positive direction
        my $pos_max =  $temp[$id + 2];#(a,0.05,0.05): second one is negative 
		my $pos_incr = $pos_max/$scaleNo;
        for my $nu (1..$scaleNo){
            my $temp = 1.0 + ($pos_incr * $nu);
		    push @{$axis{$temp_axis}},$temp;#scale values for an axis
        }
    }
    #each axis hash is the ref for scale value array
    my @axiskeys = sort keys %axis;

    for my $k (0 .. $total -1){#loop over scale array
        my $prefix = sprintf("%02d",$k);
        my $output = "$dtype" . "_" . "$prefix";#for atomsk output lmp file 
        #my @scale = @{$axis{$k}};
        #adjsut cell length
        for my $ax (@axiskeys){
           chomp $ax;
           my $keyword = "_cell_length_$ax";
           my $ref_len = '$'."$ax"."_ref";
           my $scale = $axis{$ax}->[$k];
           my $adjusted = eval($ref_len) * $scale;#get the value of a symbol
           system("sed -i -e \"s|$keyword.*|$keyword  $adjusted|\" $cif_ref");
        }
        if($sys_para_hr->{shape_deform} eq "yes"){#change box shape
           my $alpha_range = $deform_hr->{shape}->[1]; 
           my $alpha_adjusted = $alpha_ref + (2.0 * rand() - 1.0)*$alpha_range;
           system("sed -i -e \"s|_cell_angle_alpha.*|_cell_angle_alpha  $alpha_adjusted|\" $cif_ref");

           my $beta_range = $deform_hr->{shape}->[3]; 
           my $beta_adjusted = $beta_ref + (2.0 * rand() - 1.0)*$beta_range;
           system("sed -i -e \"s|_cell_angle_beta.*|_cell_angle_beta  $beta_adjusted|\" $cif_ref");

           my $gamma_range = $deform_hr->{shape}->[5]; 
           my $gamma_adjusted = $gamma_ref + (2.0 * rand() - 1.0)*$gamma_range;
           system("sed -i -e \"s|_cell_angle_gamma.*|_cell_angle_gamma  $gamma_adjusted|\" $cif_ref");
        }
        my $output_folder = $sys_para_hr->{output_folder};
       `atomsk $cif_ref -disturb $sys_para_hr->{rand_range} -wrap -unskew $output_folder/$dtype-$prefix.lmp`;
       # system("atomsk $cif_ref -disturb $sys_para_hr->{rand_range} -wrap -unskew $output_folder/$dtype-$prefix.lmp");
        `mv $output_folder/$dtype-$prefix.lmp $output_folder/$dtype-$prefix.data`;
    }
}

}# end sub
1;