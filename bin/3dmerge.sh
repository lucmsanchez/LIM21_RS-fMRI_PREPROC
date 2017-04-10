#!/usr/bin/env bash

 3dmerge \
    -1blur_fwhm "$blur" \
    -doall \
    -prefix ${out[$j]} \
    ${in[$j]} &>> preproc.${ID[j]}.log 
