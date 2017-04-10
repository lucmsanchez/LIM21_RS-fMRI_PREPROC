#!/usr/bin/env bash

   ( align_epi_anat.py \
    -anat ${in_2[$j]} \
    -epi  ${in[$j]} \
    -epi_base 100 \
    -anat_has_skull no \
    -volreg off \
    -tshift off \
    -deoblique off \
    -cost $cost ) &>> preproc.${ID[j]}.log
