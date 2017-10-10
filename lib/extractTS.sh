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
out[8]=${11}
out[9]=${12}
out[10]=${13}
out[11]=${14}
out[12]=${15}
out[13]=${16}
out[14]=${17}
out[15]=${18}
atlas=${19}
atlas[1]=${20}
atlas[2]=${21}
atlas[3]=${22}
atlas[4]=${23}
atlas[5]=${24}
atlas[6]=${25}
atlas[7]=${26}

a=0
b=8
for t in ${atlas[@]}; do

	echo Atlas $t

	3dresample -master ${in%%.*} -prefix ${out[$b]} -inset ../../template/${t}

	3dROIstats -quiet -mask ${out[$b]} ${in%%.*} > ${out[$a]}
	
	b=$((b+1))
	a=$((a+1))
done


