#!/usr/bin/env tcsh

# created by uber_subject.py: version 0.36 (April 5, 2013)
# creation date: Tue Nov 29 09:50:08 2016

# set data directories
set top_dir   = /home/brain/Desktop/PROJETO_CIRCOS/PREPROCESSING/DATA/

# set subject and group identifiers
set subj      = C000917
set group_id  = CTRL

# run afni_proc.py to create a single subject processing script
afni_proc.py -subj_id $subj                                        \
        -script proc.$subj -scr_overwrite                          \
        -check_afni_version yes                                    \
        -check_results_dir yes                                     \
        -blocks tshift volreg                                      \
        -copy_anat $top_dir/$subj/T1_${subj}.nii                   \
        -dsets $top_dir/$subj/RS_T000328.nii                       \
        -test_for_dsets yes                                        \
        -outlier_count yes                                         \ #QC
        -radial_correlate yes                                      \ #QC
        -anat_has_skull no                                         \
        #RICOR
                -ricor_regress_method per-run                      \
                -ricor_regress_solver OLSQ                         \
                -ricor_regs REG1                                   \
        #tshift
                -tshift_interp -Fourier                            \
                -tshift_opts_ts -tpattern seq+z                    \
        #volreg
                -volreg_interp -Fourier                            \
                -volreg_opts_vr -twopass -base 100 -1Dfile mc.${subj}.1d \
                -volreg_zpad 2                                     \
        -anat_uniform_method unifaze                               \
        -tlrc_base MNI_avg152T1+tlrc                               \ 
        -volreg_align_to third                                     \
        -volreg_align_e2a                                          \
        -volreg_tlrc_warp                                          \
        -blur_size 4.0                                             \
        -regress_censor_motion 0.2                                 \
        -regress_bandpass 0.01 0.1                                 \
        -regress_apply_mot_types demean deriv                      \
        -regress_est_blur_errts                                    \
        -regress_run_clustsim no                                   \
        -bash

