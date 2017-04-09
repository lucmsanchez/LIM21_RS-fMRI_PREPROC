#!/usr/bin/env bash

    3dWarp \
    -deoblique \
    -prefix  ${out[$j]} \
    ${in[$j]} &>> preproc.${ID[j]}.log
