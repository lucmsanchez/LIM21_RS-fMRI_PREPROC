#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# 1D file from correction
out=$2      # jpg

1dplot \
    -jpg "${out}" \
    -volreg -dx 2 \
    -xlabel Time \
    -thick \
    ${in}


