#!/usr/bin/env bash

    3dcalc \
    -a        ${in_2[$j]} \
    -b        ${in[$j]} \
    -expr     'a*abs(b-1)' \
    -prefix   ${out[$j]} &>> preproc.${ID[j]}.log 
