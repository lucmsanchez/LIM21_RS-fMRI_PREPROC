#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando etapa Normalize T1 to template às imagens ======"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

3dQwarp \
-prefix MNI_T1_"$i" \
-blur 0 3 \
-base "$template" \
-allineate \
-source SS_T1_"$i"_al+orig


echo
echo
done 
