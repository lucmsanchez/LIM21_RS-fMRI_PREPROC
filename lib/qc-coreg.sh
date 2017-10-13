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

${fsl5}slicer r_$under $over -x 0.4 img_x1.ppm -y 0.45 img_y1.ppm -z 0.45 img_z1.ppm
${fsl5}slicer r_$under $over -x 0.5 img_x2.ppm -y 0.5 img_y2.ppm -z 0.5 img_z2.ppm
${fsl5}slicer r_$under $over -x 0.6 img_x3.ppm -y 0.55 img_y3.ppm -z 0.55 img_z3.ppm

convert -append img_x3* img_x2* img_x1* img_x.ppm
convert -append img_y* img_y.ppm
convert -append img_z3* img_z2* img_z1* img_z.ppm
convert +append img_z.ppm img_y.ppm img_x.ppm ${out}

rm img_* r_* $under $over
