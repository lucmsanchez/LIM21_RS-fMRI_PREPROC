#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# template
out=$4		# image HEAD 
out[1]=$5   # image BRIK
out[2]=$6	# WARP HEAD
out[3]=$7	# WARP BRIK
out[4]=$8	# Allin
out[5]=$9	# Allin 1D

3dQwarp \
	  -prefix ${out%%+*} \
      -blur 0 3 \
      -base ${in[2]} \
      -allineate \
      -source ${in%%.*} 

