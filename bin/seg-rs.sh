#!/usr/bin/env bash

   ### resample CSF mask
   ( 3dresample \
    -master ${in[$j]} \
    -inset ${in_2[$j]} \
    -prefix "${ID[j]}"_CSF_resampled+orig 
    ### resample WM mask
    3dresample \
    -master ${in[$j]} \
    -inset ${in_3[$j]} \
    -prefix "${ID[j]}"_WM_resampled+orig 
    ### first, mean CSF signal
    3dmaskave \
    -quiet \
    -mask "${ID[j]}"_CSF_resampled+orig \
    ${in[$j]} \
    > ${out[$j]} 
    ### now, mean WM signal
    3dmaskave \
    -quiet \
    -mask "${ID[j]}"_WM_resampled+orig \
    ${in[$j]} \
    > ${out_2[$j]} ) &>> preproc.${ID[j]}.log
    rm "${ID[j]}"_CSF_resampled* "${ID[j]}"_WM_resampled* &>> preproc.${ID[j]}.log
