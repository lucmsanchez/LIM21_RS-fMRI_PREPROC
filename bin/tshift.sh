#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# aztec_RS image HEAD
in[1]=$2 	# aztec_RS image BRIK
out=$3 		# tshift_RS image HEAD
out[1]=$4	# tshift_RS image BRIK

3dTshift \
	-tpattern seq+z \
      	-prefix ${out%%.*} \
      	-Fourier \
      	${in%%.*}


