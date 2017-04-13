#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=unifize_${file_t12}_al+orig.HEAD
in[1]=unifize_${file_t12}_al+orig.BRIK
in[2]= CSF_${file_t12}+orig.HEAD
in[3]= CSF_${file_t12}+orig.BRIK
in[4]= WM_${file_t12}+orig.HEAD
in[5]= WM_${file_t12}+orig.BRIK
out=m1_qc4_${file_t12}.jpg
out[1]=m2_qc4_${file_t12}.jpg


over2=${in[4]%%.*}
over=${in[2]%%.*}
under=${in%%.*}

 Xvfb :1 -screen 0 1200x800x24 &

 export AFNI_NOSPLASH=YES
 export AFNI_SPLASH_MELT=NO

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:10 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over" \
-com "SET_DICOM_XYZ A 10 40 45" \
-com "SAVE_JPEG A.axialimage imx.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.${in%%.*}.jpg" \
-com "QUIT"

sleep 5

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over2" \
-com "SET_DICOM_XYZ A 10 40 45" \
-com "SAVE_JPEG A.axialimage imx2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.${in%%.*}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.${in%%.*}.jpg" \
-com "QUIT"

sleep 5

killall Xvfb

convert +append imx.* imy.* imz.* ${out}
convert +append imx2.* imy2.* imz2.* ${out}

rm im*  
