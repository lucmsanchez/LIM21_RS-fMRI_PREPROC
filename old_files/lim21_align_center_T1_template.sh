#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "==== Aplicando etapa Align center of T1 to template às imagens ====="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

@Align_Centers \
-base "$template" \
-dset rd_T1_"$i"+orig

echo
echo
done 
