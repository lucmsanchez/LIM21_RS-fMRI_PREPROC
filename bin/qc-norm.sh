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
out=$6		# jpg 
out[1]=$7	# jpg 
out[2]=$8	# jpg 
out[3]=$9	# jpg 
out[4]=${10} # jpg 
out[5]=${11} # jpg 

3dedge3 -input ${in%%.*} -prefix e_${in%%.*}
3dedge3 -input ${in[4]} -prefix e_${in[4]}
  
overa2=${in%%.*}
overa=e_${in%%.*}
undera=${in[2]%%.*}

underb=${in[2]%%.*}
overb=e_${in[4]}
overb2=${in[4]}

underc=${in[4]}
overc=e_${in%%.*}
overc2=${in%%.*}

 Xvfb :9 -screen 0 1200x800x24 &

 export AFNI_NOSPLASH=YES
 export AFNI_SPLASH_MELT=NO

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.a.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.a.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.b.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.b.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.c.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

DISPLAY=:9 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.c.${in%%.*}.jpg" \
-com "QUIT"

sleep 20

killall Xvfb

convert +append imx.a.* imy.a.* imz.a.* ${out}
convert +append imx2.a.* imy2.a.* imz2.a.* ${out[1]}

convert +append imx.b.* imy.b.* imz.b.* ${out[2]}
convert +append imx2.b.* imy2.b.* imz2.b.* ${out[3]}

convert +append imx.c.* imy.c.* imz.c.* ${out[4]}
convert +append imx2.c.* imy2.c.* imz2.c.* ${out[5]}

rm im* e_*  



