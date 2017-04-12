#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# t1
out=$2 		# mask

FSLDIR=/usr/share/fsl
fsl5=fsl5.0-

"$fsl5"bet ${in} mask_s1_${in} -B -f 0.15 && \
"$fsl5"flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in mask_s1_${in} -omat mask_s2_${in%%.*}.mat -out mask_s2_${in} -searchrx -30 30 -searchry -30 30 -searchrz -30 30 && \
"$fsl5"fnirt --in=${in} --aff=mask_s2_${in%%.*}.mat --cout=mask_s3_${in} --config=T1_2_MNI152_2mm && \
"$fsl5"applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=${in} --warp=mask_s3_${in} --out=mask_s4_${in} && \
"$fsl5"invwarp -w mask_s3_${in%%.*}.nii.gz -o mask_s5_${in%%.*}.nii.gz -r mask_s1_${in%%.*}.nii.gz && \
"$fsl5"applywarp --ref=${in} --in=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz --warp=mask_s5_${in%%.*}.nii.gz --out=mask_s6_${in%%.*}.nii.gz --interp=nn && \
"$fsl5"fslmaths mask_s6_${in%%.*}.nii.gz -bin invmask_${in%%.*}.nii.gz && \
"$fsl5"fslmaths invmask_${in%%.*}.nii.gz -mul -1 -add 1 ${out[$j]} 

rm invmask* mask_s* *_to_MNI152_T1_2mm.log 
