#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# Template
out=$4		# image HEAD 
out[1]=$5   # image BRIK 
out[2]=$6	# 1D

    @Align_Centers \
    -base ${in[2]} \
    -dset ${in%%.*} 
