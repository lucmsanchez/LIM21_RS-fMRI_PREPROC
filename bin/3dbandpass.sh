#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

in=$1
in[1]=$2
in[2]=$3
in[3]=$4
in[4]=$5
out=$6
out[1]=$7

3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort ${in[2]} \
  -ort ${in[3]} \
  -ort ${in[4]} \
  -prefix ${out%%.*} \
  -input ${in%%.*} 
