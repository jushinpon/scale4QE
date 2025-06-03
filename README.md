You need to use the following scripts to scale your systems.
1. data_collect4Scale.pl --> The last data file with the lowest Temperature will be picked
2. data2deform.pl  --> -0.25 ~ 0.25 21 cases. (not change the range)
3. data2QE.pl  --> convert all data files into QE input.
4. make_slurm_sh.pl
5. submit_allslurm_sh.pl