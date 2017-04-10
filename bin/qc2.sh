#!/usr/bin/env bash

text1="<pre>$(3dinfo T1.${ID[j]}.nii 2> /dev/null)</pre>"
( m=0
  for n in $(seq 0.10 0.01 0.90); do
  m=$((m + 1))
  fsl5.0-slicer T1.${ID[j]}.nii -s 2 -y $n slice-$m.png
  convert slice-$m.png -rotate -90 slice-$m.png
  done

  avconv -f image2 -y -i slice-%d.png -filter:v "setpts=10*PTS" -r 20 m.slices.T1.${ID[j]}.mp4
  rm slice* ) &>> preproc.${ID[j]}.log
 
( for s in 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85; do
  fsl5.0-slicer T1.${ID[j]}.nii -x $s im.T1.${ID[j]}.x.$s.png
  convert im.T1.${ID[j]}.x.$s.png -rotate 90 im.T1.${ID[j]}.x.$s.png
  done
  
  for s in 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85; do
  fsl5.0-slicer T1.${ID[j]}.nii -y $s im.T1.${ID[j]}.y.$s.png
  convert im.T1.${ID[j]}.y.$s.png -rotate -90 im.T1.${ID[j]}.y.$s.png
  done

  for s in 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85; do
  fsl5.0-slicer T1.${ID[j]}.nii -z $s im.T1.${ID[j]}.z.$s.png
  convert im.T1.${ID[j]}.z.$s.png -rotate 180 im.T1.${ID[j]}.z.$s.png
  done  

  convert -append im.T1.${ID[j]}.x.*.png imx.T1.${ID[j]}.png
  convert -append im.T1.${ID[j]}.y.*.png imy.T1.${ID[j]}.png
  convert -append im.T1.${ID[j]}.z.*.png imz.T1.${ID[j]}.png
  convert +append imx.T1* imy.T1* imz.T1* m.slices.T1.${ID[j]}.png
 
  rm im* ) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc2">QC2 - Imagem T1 raw</h2>
</center>
$text1
<center>
<p>&nbsp;</p>
<h3>Vídeo axial</h3>
<p><video controls="controls" width="100%" height="100%">
<source src="m.slices.T1.${ID[j]}.mp4" /></video></p>
<p>&nbsp;</p>
<h3>Imagens de 3 cortes</h3>
<p><img src="m.slices.T1.${ID[j]}.png" alt=""/></p>
<p>&nbsp;</p>
<hr>
<p>&nbsp;</p>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC2-->.*<!--QC3-->/<!--QC2-->\n $ENV{textf} \n<!--QC3-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

