#!/usr/bin/env bash

( 3dAFNItoNIFTI -prefix SS.T1.${ID[j]}_al.nii ${in[j]}
    ${fsl5}fast \
    -o seg.${ID[j]} \
    -S 1 \
    -t 1 \
    -n 3 \
    SS.T1.${ID[j]}_al.nii 
    3dcalc \
    -a seg.${ID[j]}_pve_0.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out[$j]} 
    ### now, the WM
    3dcalc \
    -a seg.${ID[j]}_pve_2.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out_2[$j]} ) &>> preproc.${ID[j]}.log
    rm seg.${ID[j]} &>> preproc.${ID[j]}.log
