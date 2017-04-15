#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# t1
in[1]=$2	# mask
out=$3		# image HEAD 
out[1]=$4   # image BRIK 


3dcalc \
	-verbose \
    -a        ${in} \
    -b        ${in[1]} \
    -expr     'a*abs(b-1)' \
    -prefix   ${out%%.*}
