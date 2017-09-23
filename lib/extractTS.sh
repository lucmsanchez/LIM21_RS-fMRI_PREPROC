#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

in=$1
in[1]=$2
out=$3
out[1]=$4
out[2]=$5
out[3]=$6
out[4]=$7
out[5]=$8
out[6]=$9
out[7]=${10}
atlas=${11}
atlas[1]=${12}
atlas[2]=${13}
atlas[3]=${14}
atlas[4]=${15}
atlas[5]=${16}
atlas[6]=${17}
atlas[7]=${18}

a=0
for t in ${atlas[@]}; do

	echo Atlas $t

	3dresample -master ${in%%.*} -prefix resampled_${t%%.*}+tlrc -inset ../../template/${t}

	3dROIstats -quiet -mask resampled_${t%%.*}+tlrc ${in%%.*} > ${out[$a]}

	a=$((a+1))
done



