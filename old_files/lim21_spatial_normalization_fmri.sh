#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Spatial Normalization fmri às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

3drename MNI_T1_"$i"_WARP+tlrc MNI_T1_WARP

3dNwarpApply \
-source rpdrt_RS_"$i"_shft+orig \
-nwarp 'MNI_T1_WARP+tlrc' \
-master "$template" \
-newgrid 3 \
-prefix rpdrt_RS_MNI_"$i"

3drename MNI_T1_WARP+tlrc MNI_T1_"$i"_WARP


echo
echo
done 
