#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

in=$1
in[1]=$2
out=$3
out[1]=$4

3dmerge \
    -1blur_fwhm 6 \
    -doall \
    -prefix ${out%%.*} \
    ${in%%.*}
