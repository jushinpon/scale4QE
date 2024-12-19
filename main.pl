#!/usr/bin/perl
=b
1. structures need to do vc-relax, and the optimized structures will be used later (scale, or deform with random perturbation).
You need to get the optimized qe structure from vc-relax (last structure in sout),
convert it to data file and then to QE input file for this script.

2. structures from materials project for scaling only (with random perturbation ).

=cut
use strict;
use warnings;
use Cwd;
use lib '.';#also find local module
use system_setting;#parameters for system setting
#get system parameters first
require './qein2data.pl';
require './deform.pl';

my ($deform_hr,$sys_para_hr) = 
&system_setting::sys_setting();

#folder to put generated files
`rm -rf $sys_para_hr->{output_folder}`;
`mkdir -p $sys_para_hr->{output_folder}`;
#make an reference data file in output folder for deforming
&qein2data($sys_para_hr);
#deforming cell 
&deform($deform_hr,$sys_para_hr);