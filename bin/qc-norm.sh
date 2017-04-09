
#!/usr/bin/env bash

( 3dedge3 -input MNI.RS.${ID[j]}+tlrc -prefix e.MNI.RS.${ID[j]}+tlrc
  3dedge3 -input $template -prefix e.$template
  
overa2=MNI.RS.${ID[j]}+tlrc
overa=e.MNI.RS.${ID[j]}+tlrc
undera=MNI.T1.${ID[j]}+tlrc

underb=MNI.T1.${ID[j]}+tlrc
overb=e.$template
overb2=$template

underc=$template
overc=e.MNI.RS.${ID[j]}+tlrc
overc2=MNI.RS.${ID[j]}+tlrc

 Xvfb :1 -screen 0 1200x800x24 &

 export AFNI_NOSPLASH=YES
 export AFNI_SPLASH_MELT=NO

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.a.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.a.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.a.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $undera" \
-com "SWITCH_OVERLAY $overa2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.a.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.a.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.a.${ID[j]}.jpg" \
-com "QUIT"

sleep 5

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.b.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.b.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.b.${ID[j]}.jpg" \
-com "QUIT"

sleep 5

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underb" \
-com "SWITCH_OVERLAY $overb2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.b.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.b.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.b.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SET_THRESHOLD A.3500 3" \
-com "SAVE_JPEG A.axialimage imx.c.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy.c.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz.c.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

DISPLAY=:1 afni -com "OPEN_WINDOW A.axialimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.sagitalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "OPEN_WINDOW A.coronalimage opacity=6 mont=1x3:25 geom=1200x800" \
-com "SET_XHAIRS OFF" \
-com "SWITCH_UNDERLAY $underc" \
-com "SWITCH_OVERLAY $overc2" \
-com "SET_DICOM_XYZ A 0 20 15" \
-com "SAVE_JPEG A.axialimage imx2.c.${ID[j]}.jpg" \
-com "SAVE_JPEG A.sagitalimage imy2.c.${ID[j]}.jpg" \
-com "SAVE_JPEG A.coronalimage imz2.c.${ID[j]}.jpg" \
-com "QUIT"

sleep 10

killall Xvfb

convert +append imx.a.* imy.a.* imz.a.* m.overa.MNI.${ID[j]}.jpg
convert +append imx2.a.* imy2.a.* imz2.a.* m.overa2.MNI.${ID[j]}.jpg

convert +append imx.b.* imy.b.* imz.b.* m.overb.MNI.${ID[j]}.jpg
convert +append imx2.b.* imy2.b.* imz2.b.* m.overb2.MNI.${ID[j]}.jpg

convert +append imx.c.* imy.c.* imz.c.* m.overc.MNI.${ID[j]}.jpg
convert +append imx2.c.* imy2.c.* imz2.c.* m.overc2.MNI.${ID[j]}.jpg

rm im*  

) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc6">QC6 - Checagem de normalização T1 e RS vs. MNI</h2>
<p>&nbsp;</p>
<h3>T1 vs. RS (MNI)</h3>
<p><img src="m.overa.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<p><img src="m.overa2.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<h3>T1 vs. MNI</h3>
<p><img src="m.overb.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<p><img src="m.overb2.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<h3>MNI vs. RS</h3>
<p><img src="m.overc.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<p><img src="m.overc2.MNI.${ID[j]}.jpg" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<hr>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC6-->.*<!--QC7-->/<!--QC6-->\n $ENV{textf} \n<!--QC7-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

