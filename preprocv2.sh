#!/usr/bin/env tcsh

# created by uber_subject.py: version 0.36 (April 5, 2013)
# creation date: Tue Nov 29 09:50:08 2016

# set data directories
set top_dir   = /media/sf_SHARED/PROJETO_CIRCOS/PREPROCESSING/DATA

# set subject and group identifiers
set subj      = C000917
set group_id  = CTRL

# run afni_proc.py to create a single subject processing script
afni_proc.py -subj_id $subj                                        \
        -script proc.$subj -scr_overwrite                          \
        -check_afni_version yes                                    \
        -check_results_dir yes                                     \
        -blocks despike tshift align tlrc volreg blur mask regress \                           \
        -copy_anat $top_dir/$subj/T1_${subj}.nii                   \
        -dsets $top_dir/$subj/RS_${subj}.nii                       \
        -test_for_dsets yes                                        \
        -outlier_count yes                                         \
        -anat_has_skull no                                         \
        -anat_uniform_method unifize                               \
        #tshift \
                -tshift_interp -Fourier                            \
                -tshift_opts_ts -tpattern seq+z                    \
        #align \
                -align_opts_aea -giant_move                        \
        #trlc \
                -tlrc_base MNI_avg152T1+tlrc                       \
                -tlrc_opts_at -init_xform AUTO_CENTER              \
                -tlrc_NL_warp                                      \
        #volreg \
                -volreg_interp -Fourier                            \
                -volreg_opts_vr -twopass -base 100                 \
                -volreg_zpad 2                                     \
                -volreg_align_to first                             \
                -volreg_tlrc_warp                                  \
                -volreg_align_e2a                                  \
        #blur \
                -blur_size 6.0                                     \
        #mask \
                -mask_segment_anat yes                             \
                -mask_segment_erode yes                            \
        #regress \
                -regress_censor_motion 0.2                          \
                -regress_censor_outliers 0.1                        \
                -regress_bandpass 0.01 0.08                         \
                -regress_apply_mot_types basic                      \
                -regress_ROI WMe                                    \
                -regress_est_blur_errts                             \
                -regress_run_clustsim no                            \
        -bash

