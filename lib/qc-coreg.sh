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


over2=${in%%.*}
under=${in[2]%%.*}

export AFNI_NOSPLASH=YES
export AFNI_SPLASH_MELT=NO

Xvfb :1 -screen 0 1200x800x24 &


DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=5 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=5 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=5 mont=1x3:20 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over2" \
-com "SET_DICOM_XYZ A 0 30 40" \
-com "SET_PBAR_NUMBER A.15" \
-com "SAVE_JPEG A.axialimage imx2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.${in%%.*}.jpg" \
-com "QUIT"

sleep 40


convert +append imx2.* imy2.* imz2.* ${out}

rm im*  
