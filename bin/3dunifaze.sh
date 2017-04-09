#!/usr/bin/env bash

    3dUnifize \
    -prefix ${out[$j]} \
    -input ${in[$j]} &>> preproc.${ID[j]}.log 
