#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "====== Aplicando etapa Align center of fmri to T1 às imagens ======="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

@Align_Centers \
-cm \
-base SS_T1_"$i"+orig \
-dset rpdrt_RS_"$i"+orig

echo
echo
done 
