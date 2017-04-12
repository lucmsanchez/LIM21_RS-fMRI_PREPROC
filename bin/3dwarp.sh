#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2 	# image BRIK
out=$3 		# image HEAD
out[1]=$4	# image BRIK

3dWarp \
    -deoblique \
    -prefix  ${out%%.*} \
    ${in%%.*} 
