#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# tshift_RS image HEAD
in[1]=$2 	# tshift_RS image BRIK
out=$3 		# volreg_RS image HEAD
out[1]=$4	# volreg_RS image BRIK
out[2]=$5	# 1D file from correction

3dvolreg \
    -prefix ${out%%.*} \
    -base 100 \
    -zpad 2 \
    -twopass \
    -Fourier \
    -1Dfile ${out[2]} \
    ${in%%.*}  
