#!/usr/bin/env bash

    3dresample \
    -orient "$orient" \
    -prefix ${out[$j]} \
    -inset ${in[$j]} &>> preproc.${ID[j]}.log
