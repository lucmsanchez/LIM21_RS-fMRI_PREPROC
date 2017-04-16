#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
out=$3		# image HEAD 
out[1]=$4	# image BRIK
out[2]=$5	# image HEAD
out[3]=$6	# image BRIK

#fsl5=fsl5.0-

3dAFNItoNIFTI -prefix ${in%%+*}.nii ${in%%.*}

${fsl5}fast \
    -o seg_${in%%+*} \
    -S 1 \
    -t 1 \
    -n 3 \
    ${in%%+*}.nii

3dcalc \
    -a seg_${in%%+*}_pve_0.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out%%.*} 

3dcalc \
    -a seg_${in%%+*}_pve_2.nii.gz \
    -expr 'equals(a,1)' \
    -prefix ${out[2]%%.*}

#rm seg.${ID[j]}* 
