#!/usr/bin/env bash


( 3dedge3 -input resample.RS.${ID[j]}_shft+orig -prefix e.resample.RS.${ID[j]}_shft+orig

over2=resample.RS.${ID[j]}_shft+orig
over=e.resample.RS.${ID[j]}_shft+orig
under=SS.T1.${ID[j]}_al+orig

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
-com "SAVE_JPEG A.axialimage imx.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:20 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over2" \
-com "SET_DICOM_XYZ A 0 30 40" \
-com "SAVE_JPEG A.axialimage imx2.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

killall Xvfb

convert +append imx.* imy.* imz.* m.over.SS.T1.${ID[j]}_al.jpg
convert +append imx2.* imy2.* imz2.* m.over2.SS.T1.${ID[j]}_al.jpg

rm im*  ) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc5">QC5 - Checagem de alinhamento T1 vs. RS</h2>
<p>&nbsp;</p>
<h3>Grade 3 x 3</h3>
<p><img src="m.over.SS.T1.${ID[j]}_al.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<p><img src="m.over2.SS.T1.${ID[j]}_al.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<hr>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC5-->.*<!--QC6-->/<!--QC5-->\n $ENV{textf} \n<!--QC6-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

