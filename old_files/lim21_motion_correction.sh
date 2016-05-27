#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando Motion Correction às imagens ==========="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando MC em $i..."

3dvolreg \
-prefix rt_RS_"$i" \
-base "$vr" \
-zpad 2 \
-twopass \
-Fourier \
-1Dfile motioncorrection_"$i".1d \
./t_RS_"$i"+orig

echo
echo
done 
