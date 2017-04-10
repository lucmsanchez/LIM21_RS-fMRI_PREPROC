#!/usr/bin/env bash

    3dNwarpApply \
    -source ${in[$j]} \
    -nwarp ${in_2[$j]} \
    -master "$template" \
    -newgrid 3 \
    -prefix ${out[$j]} &>> preproc.${ID[j]}.log
