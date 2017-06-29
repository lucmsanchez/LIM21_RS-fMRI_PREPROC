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
out[3]=${10}	# jpg 
out[4]=${11} # jpg 
out[5]=${12} # jpg 

temp=${in[5]##*/}
temp_e=e_${in[5]##*/}

cp ${in[4]} c_${in[4]##*/}
cp ${in[5]} c_${in[5]##*/}

3dedge3 -input ${in%%.*} -prefix e_${in%%.*}
3dedge3 -input c_${in[4]##*/} -prefix ${temp_e%%.*}
  
overa2=${in%%.*}
overa=e_${in%%.*}
undera=${in[2]%%.*}

underb=${in[2]%%.*}
overb=${temp_e%%.*}
overb2=c_${temp%%.*}

underc=c_${temp%%.*}
overc=e_${in%%.*}
overc2=${in%%.*}

 export AFNI_NOSPLASH=YES
 export AFNI_SPLASH_MELT=NO

Xvfb :1 -screen 0 1200x800x24 &

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.a.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa2" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SET_PBAR_NUMBER A.15" \
-com "SAVE_JPEG A.axialimage imx2.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.a.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.a.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.b.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb2" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SAVE_JPEG A.axialimage imx2.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.b.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.b.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.c.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=5 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc2" \
-com "SET_DICOM_XYZ A 0 22 15" \
-com "SET_PBAR_NUMBER A.15" \
-com "SAVE_JPEG A.axialimage imx2.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.c.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.c.${in%%.*}.jpg" \
-com "QUIT"

sleep 40

convert +append imx.a.* imy.a.* imz.a.* ${out}
convert +append imx2.a.* imy2.a.* imz2.a.* ${out[1]}

convert +append imx.b.* imy.b.* imz.b.* ${out[2]}
convert +append imx2.b.* imy2.b.* imz2.b.* ${out[3]}

convert +append imx.c.* imy.c.* imz.c.* ${out[4]}
convert +append imx2.c.* imy2.c.* imz2.c.* ${out[5]}

rm im* e_* c_*  



