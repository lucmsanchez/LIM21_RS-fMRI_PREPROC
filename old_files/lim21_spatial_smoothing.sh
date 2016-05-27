#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Spatial Smoothing às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
	echo "Aplicando em $i..."


	3dmerge \
	-1blur_fwhm "$blur" \
	-doall \
	-prefix bfrpdrt_RS_MNI_"$i" \
	frpdrt_RS_MNI_"$i"+tlrc

	echo
	echo
done 
