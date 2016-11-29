#!/usr/bin/env tcsh

# created by uber_subject.py: version 0.36 (April 5, 2013)
# creation date: Tue Nov 29 09:50:08 2016

# set data directories
set top_dir   = /home/brain/Desktop/PROJETO_CIRCOS/PREPROCESSING/DATA/T000328

# set subject and group identifiers
set subj      = T000328
set group_id  = CTRL

# run afni_proc.py to create a single subject processing script
afni_proc.py -subj_id $subj                                        \
        -script proc.$subj -scr_overwrite                          \
        -blocks despike tshift align tlrc volreg blur mask regress \
        -copy_anat $top_dir/T1_T000328.nii                         \
        -tcat_remove_first_trs 0                                   \
        -dsets $top_dir/RS_T000328.nii                             \
        -tlrc_base MNI_avg152T1+tlrc                               \
        -volreg_align_to third                                     \
        -volreg_align_e2a                                          \
        -volreg_tlrc_warp                                          \
        -blur_size 4.0                                             \
        -regress_censor_motion 0.2                                 \
        -regress_bandpass 0.01 0.1                                 \
        -regress_apply_mot_types demean deriv                      \
        -regress_est_blur_errts                                    \
        -regress_run_clustsim no

