#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# image HEAD
in[1]=$2	# image BRIK
in[2]=$3	# image HEAD
in[3]=$4	# image BRIK
out=$5		# image HEAD 
out[1]=$6   # jpg 1
out[2]=$7	# jpg 2

3dedge3 -input ${in%%.*} -prefix e_${in%%.*}

over2=${in%%.*}
over=e_${in%%.*}
under=${in[2]%%.*}

 Xvfb :1 -screen 0 1200x800x24 &

 export AFNI_NOSPLASH=YES
 export AFNI_SPLASH_MELT=NO

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:20 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over" \
-com "SET_DICOM_XYZ A 0 30 40" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over2" \
-com "SET_DICOM_XYZ A 0 30 40" \
-com "SAVE_JPEG A.axialimage imx2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

killall Xvfb

convert +append imx.* imy.* imz.* ${out}
convert +append imx2.* imy2.* imz2.* ${out[1]}

rm im*  
