#!/usr/bin/env bash

   3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort ${in_2[$j]} \
  -ort ${in_3[$j]} \
  -ort ${in_4[$j]} \
  -prefix ${out[$j]} \
  -input ${in[$j]} &>> preproc.${ID[j]}.log
