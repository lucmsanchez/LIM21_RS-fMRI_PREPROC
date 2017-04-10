#!/usr/bin/env bash

    @Align_Centers \
    -base "$template" \
    -dset ${in[$j]} &>> preproc.${ID[j]}.log 
