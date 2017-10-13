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

undera=${in%%.*}
overa=${in[2]%%.*}

under=$undera
over=$overa

3dAFNItoNIFTI $under -verb -prefix ${under%%+*}.nii
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

## SECOND IMAGE

overb=c_${temp%%.*}
underb=${in[2]%%.*}

under=$underb
over=$overb

3dAFNItoNIFTI $under -verb -prefix ${under%%+*}.nii
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
convert +append img_z.ppm img_y.ppm img_x.ppm ${out[1]}

rm img_* r_* $under $over

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

${fsl5}slicer r_$under $over -x 0.4 img_x1.ppm -y 0.45 img_y1.ppm -z 0.45 img_z1.ppm
${fsl5}slicer r_$under $over -x 0.5 img_x2.ppm -y 0.5 img_y2.ppm -z 0.5 img_z2.ppm
${fsl5}slicer r_$under $over -x 0.6 img_x3.ppm -y 0.55 img_y3.ppm -z 0.55 img_z3.ppm

convert -append img_x3* img_x2* img_x1* img_x.ppm
convert -append img_y* img_y.ppm
convert -append img_z3* img_z2* img_z1* img_z.ppm
convert +append img_z.ppm img_y.ppm img_x.ppm ${out[2]}

rm img_* r_* $under $over


