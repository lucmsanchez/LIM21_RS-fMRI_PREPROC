#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando etapa Homogenize Grid às imagens ============"
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

3dZeropad \
-RL "$gRL" \
-AP "$gAP" \
-IS "$gIS" \
-prefix pdrt_RS_"$i" \
drt_RS_"$i"+orig

echo
echo
done 
