#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Coregister fmri e T1 às imagens =========="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

align_epi_anat.py \
-anat SS_T1_"$i"+orig \
-epi rpdrt_RS_"$i"_shft+orig \
-epi_base 100 \
-anat_has_skull no \
-volreg off \
-tshift off \
-deoblique off


echo
echo
done 
