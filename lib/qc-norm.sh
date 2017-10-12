#!/usr/bin/env bash

set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# image HEAD
in[3]=$4	# image BRIK
in[4]=$5	# template
in[5]=$6	# template
out=$7		# jpg 
out[1]=$8	# jpg 
out[2]=$9	# jpg 

cp ${in[4]} c_${in[4]##*/}
cp ${in[5]} c_${in[5]##*/}

temp=${in[5]##*/}

### FIRST IMAGE

overa=${in%%.*}
undera=${in[2]%%.*}

under=$undera
over=$overa

3dAFNItoNIFTI $under[100] -verb -prefix ${under%%+*}.nii
3dAFNItoNIFTI $over -verb -prefix ${over%%+*}.nii

under=${under%%+*}.nii
over=${over%%+*}.nii

3dresample -master $over -inset ${under} -prefix r_${under}

${fsl5}slicer r_$under $over -x 0.4 x1.ppm -y 0.45 y1.ppm -z 0.45 z1.ppm
${fsl5}slicer r_$under $over -x 0.5 x2.ppm -y 0.5 y2.ppm -z 0.5 z2.ppm
${fsl5}slicer r_$under $over -x 0.6 x3.ppm -y 0.55 y3.ppm -z 0.55 z3.ppm

convert -append x3* x2* x1* x.ppm
convert -append y* y.ppm
convert -append z3* z2* z1* z.ppm
convert +append z.ppm y.ppm x.ppm $out

rm x* y* z* r_* $under $over

## SECOND IMAGE

overb=c_${temp%%.*}
underb=${in[2]%%.*}

under=$underb
over=$overb

3dAFNItoNIFTI $under[100] -verb -prefix ${under%%+*}.nii
3dAFNItoNIFTI $over -verb -prefix ${over%%+*}.nii

under=${under%%+*}.nii
over=${over%%+*}.nii

3dresample -master $over -inset ${under} -prefix r_${under}

${fsl5}slicer r_$under $over -x 0.4 x1.ppm -y 0.45 y1.ppm -z 0.45 z1.ppm
${fsl5}slicer r_$under $over -x 0.5 x2.ppm -y 0.5 y2.ppm -z 0.5 z2.ppm
${fsl5}slicer r_$under $over -x 0.6 x3.ppm -y 0.55 y3.ppm -z 0.55 z3.ppm

convert -append x3* x2* x1* x.ppm
convert -append y* y.ppm
convert -append z3* z2* z1* z.ppm
convert +append z.ppm y.ppm x.ppm ${out[1]}

rm x* y* z* r_* $under $over

## THIRD IMAGE


overc=c_${temp%%.*}
underc=${in%%.*}


under=$underc
over=$overc

3dAFNItoNIFTI $under[100] -verb -prefix ${under%%+*}.nii
3dAFNItoNIFTI $over -verb -prefix ${over%%+*}.nii

under=${under%%+*}.nii
over=${over%%+*}.nii

3dresample -master $over -inset ${under} -prefix r_${under}

${fsl5}slicer r_$under $over -x 0.4 x1.ppm -y 0.45 y1.ppm -z 0.45 z1.ppm
${fsl5}slicer r_$under $over -x 0.5 x2.ppm -y 0.5 y2.ppm -z 0.5 z2.ppm
${fsl5}slicer r_$under $over -x 0.6 x3.ppm -y 0.55 y3.ppm -z 0.55 z3.ppm

convert -append x3* x2* x1* x.ppm
convert -append y* y.ppm
convert -append z3* z2* z1* z.ppm
convert +append z.ppm y.ppm x.ppm ${out[2]}

rm x* y* z* r_* $under $over


