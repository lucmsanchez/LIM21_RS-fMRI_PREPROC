#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
ho "=========== Aplicando etapa Reorient to templete às imagens =========="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

# Reorient T1
3dresample \
-orient "$orient" \
-prefix rd_T1_"$i" \
-inset d_T1_"$i"+orig
# Reorient fMRI
3dresample \
-orient "$orient" \
-prefix rpdrt_RS_"$i" \
-inset pdrt_RS_"$i"+orig

echo
echo
done 
