#!/usr/bin/env bash

  @Align_Centers \
    -cm \
    -base ${in_2[$j]} \
    -dset ${in[$j]} &>> preproc.${ID[j]}.log 
