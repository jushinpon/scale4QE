#!/usr/bin/perl
=b
If you want to deform many cases at a time, you may use this script.
You need to modify $source_folder where you store all your source folders
=cut
use strict;
use warnings;
use Cwd;

#clean old folders first
my @temp = `ls`;
chomp @temp;
for (@temp){
    if(-d $_){print "$_\n";`rm -rf $_`;}
}

my $source_folder = "/home/jsp1/dpgen_preprocessor/examples/Al2O3_1000442";#all cases you want to work on
#input_path.dat
my @files = `find $source_folder -type f -name "*.in"`;#keep element info`;
chomp @files;
for my $f (@files){ 

    `rm -f ./input_path.dat`;
    `touch ./input_path.dat`;
    `echo $f >> ./input_path.dat`;
    system("cat ./input_path.dat");
    my $base = `basename $f`;
    chomp $base;
    $base =~ s/^\s+|\s+$//;
    print "basename: $base\n";  
    
    my $dir = `dirname $f`;#get path
    chomp $dir;
    print "dirname: $dir\n";

    my $rebase = `basename $dir`;#the upper parent folder name
    chomp $rebase;
    $rebase =~ s/^\s+|\s+$//;
    print "rebasename: $rebase\n";
    system("perl ./main.pl");
    sleep(1);

    system("rm -rf $rebase");
    system("mv output $rebase");

}
