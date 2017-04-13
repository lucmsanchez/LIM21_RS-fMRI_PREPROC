#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1		# RS HEAD
in[1]=$2	# RS BRIK
in[2]=$3	# CSF HEAD
in[3]=$4	# CSF BRIK
in[4]=$5	# WM HEAD
in[5]=$6	# WM BRIK
out=$7		# CSF 1D
out[1]=$8	# WM 1D


### resample CSF mask
3dresample \
    -master ${in%%.*} \
    -inset ${in[2]%%.*} \
    -prefix ${in%%.*}_CSF_resampled+orig 

### resample WM mask
3dresample \
    -master ${in%%.*} \
    -inset ${in[4]%%.*} \
    -prefix ${in%%.*}_WM_resampled+orig 

### first, mean CSF signal
3dmaskave \
    -quiet \
    -mask ${in%%.*}_CSF_resampled+orig \
    ${in%%.*} \
    > ${out} 

### now, mean WM signal
3dmaskave \
    -quiet \
    -mask ${in%%.*}_WM_resampled+orig \
    ${in%%.*} \
    > ${out[1]} 
   
rm ${in%%.*}_CSF_resampled* ${in%%.*}_WM_resampled*
