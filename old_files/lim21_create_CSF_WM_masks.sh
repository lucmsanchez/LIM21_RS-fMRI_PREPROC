#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Create CSF and WM Masks às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
	echo "Aplicando em $i..."

	3dAFNItoNIFTI SS_T1_"$i"_al+orig

	echo "Segmentando as imagens usando FSL-FAST"
	echo
	fsl5.0-fast \
	-o seg_"$i" \
	-S 1 \
	-t 1 \
	-n 3 \
	SS_T1_"$i"_al.nii

	#Explained: -o = output name; -S = number of channels (1, because only T1 image); -t = type of image (1 for T1); -n = number of tissue-type classes
	#This gives three output files: seg_"$lista"_pve_0.nii.gz (CSF), seg_"$lista"_pve_1.nii.gz (GM) and seg_"$lista"_pve_3.nii.gz (WM).

	# Binarize the segmented images
	echo 
	echo "Binarizando as imagens segmentadas"
	echo
	# first, the CSF
	3dcalc \
	-a seg_"$i"_pve_0.nii.gz \
	-expr 'equals(a,1)' \
	-prefix "$i"_CSF
	# now, the WM
	3dcalc \
	-a seg_"$i"_pve_2.nii.gz \
	-expr 'equals(a,1)' \
	-prefix "$i"_WM

	echo 
	echo "Aplicando Resample às imagens"
	echo
	# resample CSF mask
	3dresample \
	-master rpdrt_RS_"$i"_shft+orig \
	-inset "$i"_CSF+orig \
	-prefix "$i"_CSF_resampled+orig
	# resample WM mask
	3dresample \
	-master rpdrt_RS_"$i"_shft+orig \
	-inset "$i"_WM+orig \
	-prefix "$i"_WM_resampled+orig

	echo
	echo "Calculando CSF e WM mean signal"
	echo
	# first, mean CSF signal
	3dmaskave \
	-mask "$i"_CSF_resampled+orig \
	-quiet \
	rpdrt_RS_"$i"_shft+orig \
	> "$i"_CSF_signal.1d
	# now, mean WM signal
	3dmaskave \
	-mask "$i"_WM_resampled+orig \
	-quiet \
	rpdrt_RS_"$l"_shft+orig \
	> "$i"_WM_signal.1d

	echo
	echo "Aplicando 3dBandpass para correção de movimentos"
	echo
	3dBandpass \
	-band 0.01 0.08 \
	-despike \
	-ort motioncorrection_"$i".1d \
	-ort "$i"_CSF_signal.1d \
	-ort "$i"_WM_signal.1d \
	-prefix frpdrt_RS_MNI_"$i" \
	-input rpdrt_RS_MNI_"$i"+tlrc

	echo
	echo
done 
