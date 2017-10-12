#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# image HEAD
in[3]=$4	# image BRIK
out[0]=$5   # jpg 1

over=${in[2]%%.*}
under=${in%%.*}

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
