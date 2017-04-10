#!/usr/bin/env bash

( 3dvolreg \
    -prefix ${out[$j]} \
    -base 100 \
    -zpad 2 \
    -twopass \
    -Fourier \
    -1Dfile ${out_2[$j]} \
    ${in[$j]}  ) &>> preproc.${ID[j]}.log
