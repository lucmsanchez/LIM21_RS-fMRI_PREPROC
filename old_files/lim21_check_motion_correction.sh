#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando Check Motion Correction às imagens ==========="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando CMC em $i..."

1dplot motioncorrection_"$i".1d
echo
echo
#read -p "Aperte enter para continuar..."
echo
echo
done 
