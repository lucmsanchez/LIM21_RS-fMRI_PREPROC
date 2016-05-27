#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "========= Aplicando estapa Deoblique T1 e fmri às imagens ========"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

# Deoblique T1
3dWarp \
-deoblique \
-prefix  d_T1_"$i" \
T1_"$i".nii
# Deoblique fMRI
3dWarp \
-deoblique \
-prefix  drt_RS_"$i" \
rt_RS_"$i"+orig

echo
echo
done 
