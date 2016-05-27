#!bin/bash

source config
lista=(`cat "$pathpi"/subs.txt`)	

cd "$pathpi"
# Slice timing correction
echo
echo "===================================================================="
echo "=========== Aplicando Slice Timing Correction às imagens ==========="
echo "===================================================================="
echo
for i in "${lista[@]}"
do
echo "Aplicando STC em $i..."

	3dTshift \
	-tpattern "$ssa" \
	-prefix t_RS_$i \
	-TR 2s \
	-Fourier \
	RS_$i.nii
echo
echo
done 
