#!/usr/bin/env bash

 3dQwarp \
      -prefix ${out[$j]} \
      -blur 0 3 \
      -base $template \
      -allineate \
      -source ${in[$j]} &>> preproc.${ID[j]}.log
    rm MNI.T1.${ID[j]}_Allin* &>> preproc.${ID[j]}.log
