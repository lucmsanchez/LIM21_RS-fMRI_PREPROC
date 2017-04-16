#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# image HEAD
in[3]=$4	# image BRIK
out=$5		# image HEAD 
out[1]=$6   # image BRIK 
out[2]=$7	# 1D file

align_epi_anat.py \
    -anat ${in[2]%%.*} \
    -epi  ${in%%.*} \
    -epi_base 100 \
    -anat_has_skull no \
    -volreg off \
    -tshift off \
    -deoblique off 

