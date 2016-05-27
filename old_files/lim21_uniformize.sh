#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
echo
echo "===================================================================="
echo "=========== Aplicando etapa Uniformize T1 às imagens =============="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando em $i..."

3dUnifize \
-prefix urd_T1_"$i" \
-input rd_T1_"$i"_shft+orig

echo
echo
done 





