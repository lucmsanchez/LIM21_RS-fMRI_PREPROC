#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# image HEAD
in[3]=$4	# image BRIK
in[4]=$5	# template
out=$6		# image HEAD 


3dNwarpApply \
    -source ${in%%.*} \
    -nwarp ${in[2]%%.*} \
    -master ${in[4]} \
    -newgrid 3 \
    -prefix ${out%%.*} 
