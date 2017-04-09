#!/usr/bin/env bash

    3dZeropad \
    -RL "$gRL" \
    -AP "$gAP" \
    -IS "$gIS" \
    -prefix ${out[$j]} \
    ${in[$j]} &>> preproc.${ID[j]}.log
