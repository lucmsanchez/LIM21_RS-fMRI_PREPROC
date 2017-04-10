#!/usr/bin/env bash

( 3dAFNItoNIFTI unifize.T1.${ID[j]}+orig unifize.T1.${ID[j]}.nii
  fsl5.0-overlay 1 0 -c unifize.T1.${ID[j]}.nii -a mask.T1.${ID[j]}.nii.gz 0 1 over.SS.T1.${ID[j]}

  m=0
  for n in $(seq 0.10 0.01 0.90); do
  m=$((m + 1))
  fsl5.0-slicer over.SS.T1.${ID[j]}.nii.gz -s 2 -x $n slicex-$m.png -y $n slicey-$m.png -z $n slicez-$m.png 
  done
  for q in x y z;do
  avconv -f image2 -y -i slice$q-%d.png -filter:v "setpts=10*PTS" -r 20 m.over$q.T1.${ID[j]}.mp4
  rm slice$q*
  done

for n in 0.15 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85; do
fsl5.0-slicer unifize.T1.${ID[j]}.nii mask.T1.${ID[j]}.nii.gz -s 2 -x $n im.x-$n.png -y $n im.y-$n.png -z $n im.z-$n.png 
done

  convert -append im.x*.png imx.SS.T1.${ID[j]}.png
  convert -append im.y*.png imy.SS.T1.${ID[j]}.png
  convert -append im.z*.png imz.SS.T1.${ID[j]}.png
  convert +append imx.* imy.* imz.* m.over.SS.T1.${ID[j]}.png
 
rm im* ) &>> preproc.${ID[j]}.log 

read -r -d '' textf <<EOF
<h2 id="qc4">QC4 - T1 vs. SS mask</h2>
<p>&nbsp;</p>
<h3>Vídeo axial</h3>
<p><video controls="controls" width="100%" height="100%">
<source src="m.overz.T1.${ID[j]}.mp4" /></video></p>
<p>&nbsp;</p>
<h3>Vídeo sagital</h3>
<p><video controls="controls" width="100%" height="100%">
<source src="m.overy.T1.${ID[j]}.mp4" /></video></p>
<p>&nbsp;</p>
<h3>Vídeo coronal</h3>
<p><video controls="controls" width="100%" height="100%">
<source src="m.overx.T1.${ID[j]}.mp4" /></video></p>
<p>&nbsp;</p>
<h3>Imagens de 3 cortes</h3>
<p><img src="m.over.SS.T1.${ID[j]}.png" alt="" style="width:1000px;height:800px%"/></p>
<p>&nbsp;</p>
<hr>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC4-->.*<!--QC5-->/<!--QC4-->\n $ENV{textf} \n<!--QC5-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

