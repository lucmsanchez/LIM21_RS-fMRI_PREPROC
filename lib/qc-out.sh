#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# raw RS nii
out=$2		# out raw 1D		
out[1]=$3		# jpg - out raw
out[2]=$4

## OUTLIERS
# raw ouliers
3dToutcount -automask -fraction -polort 3 -legendre ${in} > ${out}


rcount=`1deval -a ${out} -expr "step(a-0.1)" | awk '$1 != 0 {print}' | wc -l`
echo "num TRs above out limit   : $rcount"


1dplot -jpg ${out[1]} -one '1D: 200@0.1' ${out}

echo "$rcount" > ${out[2]}

exit

