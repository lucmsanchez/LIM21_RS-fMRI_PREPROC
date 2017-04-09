#!/usr/bin/env bash

    (  3dAFNItoNIFTI ${in[$j]} unifize.T1.${ID[j]}.nii
      "$fsl5"bet unifize.T1.${ID[j]}.nii ${ID[j]}_step1 -B -f $betf && \
      "$fsl5"flirt -ref ${FSLDIR}/data/standard/MNI152_T1_2mm_brain -in ${ID[j]}_step1.nii.gz -omat ${ID[j]}_step2.mat -out ${ID[j]}_step2 -searchrx -30 30 -searchry -30 30 -searchrz -30 30 && \
      "$fsl5"fnirt --in=unifize.T1.${ID[j]}.nii --aff=${ID[j]}_step2.mat --cout=${ID[j]}_step3 --config=T1_2_MNI152_2mm && \
      "$fsl5"applywarp --ref=${FSLDIR}/data/standard/MNI152_T1_2mm --in=unifize.T1.${ID[j]}.nii --warp=${ID[j]}_step3 --out=${ID[j]}_step4 && \
      "$fsl5"invwarp -w ${ID[j]}_step3.nii.gz -o ${ID[j]}_step5.nii.gz -r ${ID[j]}_step1.nii.gz && \
      "$fsl5"applywarp --ref=unifize.T1.${ID[j]}.nii --in=${FSLDIR}/data/standard/MNI152_T1_1mm_brain_mask.nii.gz --warp=${ID[j]}_step5.nii.gz --out=${ID[j]}_step6 --interp=nn && \
      "$fsl5"fslmaths ${ID[j]}_step6.nii.gz -bin invmask_${ID[j]}.nii.gz && \
      "$fsl5"fslmaths invmask_${ID[j]}.nii.gz -mul -1 -add 1 ${out[$j]} )  &>> preproc.${ID[j]}.log
       rm invmask_${ID[j]}.nii.gz ${ID[j]}_step1.nii.gz ${ID[j]}_step1_mask.nii.gz ${ID[j]}_step2.nii.gz ${ID[j]}_step2.mat ${ID[j]}_step3.nii.gz ${ID[j]}_step4.nii.gz ${ID[j]}_step5.nii.gz ${ID[j]}_step6.nii.gz *_to_MNI152_T1_2mm.log 2> /dev/null
