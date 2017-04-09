#!/usr/bin/env bash

( over2=${ID[j]}.WM+orig
over=${ID[j]}.CSF+orig
under=SS.T1.${ID[j]}_al+orig

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
-com "SAVE_JPEG A.axialimage imx.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.${ID[j]}.jpg" \
-com "QUIT"

sleep 5

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:10 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $under" \
-com "SWITCH_OVERLAY $over2" \
-com "SET_DICOM_XYZ A 10 40 45" \
-com "SAVE_JPEG A.axialimage imx2.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.${ID[j]}.jpg" \
-com "QUIT"

sleep 5

killall Xvfb

convert +append imx.* imy.* imz.* m.over.seg.${ID[j]}.jpg
convert +append imx2.* imy2.* imz2.* m.over2.seg.${ID[j]}.jpg

rm im*  ) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc7">QC7 - Checagem de segmentação</h2>
<p>&nbsp;</p>
<h3>Grade 3 x 3 - CSF</h3>
<p><img src="m.over.seg.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<h3>Grade 3 x 3 - WM</h3>
<p><img src="m.over2.seg.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<hr>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC7-->.*<!--QC8-->/<!--QC7-->\n $ENV{textf} \n<!--QC8-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

