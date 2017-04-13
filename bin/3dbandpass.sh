#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

in=MNI_${file_rs2}+tlrc.HEAD
in[1]=MNI_${file_rs2}+tlrc.BRIK
in[2]=volreg_${file_rs2}.1D
in[3]=CSF_${file_t12}.signal.1D
in[4]=WM_${file_t12}.signal.1D
out=bandpass_${file_rs2}+tlrc.HEAD
out[1]=bandpass_${file_rs2}+tlrc.BRIK

3dBandpass \
  -band 0.01 0.08 \
  -despike \
  -ort ${in[2]} \
  -ort ${in[3]} \
  -ort ${in[4]} \
  -prefix ${out%%.*} \
  -input ${in%%.*} 
