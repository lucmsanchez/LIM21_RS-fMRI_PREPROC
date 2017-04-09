#!/usr/bin/env bash

( 3dToutcount -automask -fraction -polort 3 -legendre ${out[$j]} > outcount.${ID[j]}.1D
  1dplot -jpg m.outcount.${ID[j]}.jpg -xlabel Time outcount.${ID[j]}.1D ) &>> preproc.${ID[j]}.log
  text1="<pre>$(3dinfo RS.${ID[j]}.nii 2> /dev/null)</pre>"

( if [ ! -d "3d" ]; then mkdir 3d; fi
  fsl5.0-fslsplit RS.${ID[j]}.nii 3d/3d.${ID[j]}- -t && \
  gunzip -f 3d/3d.${ID[j]}-*.nii.gz
  w=0
  for q in 3d/3d.${ID[j]}-*; do
  fsl5.0-slicer $q -s 4 -a ${q/.nii}.png
  done ) &>> preproc.${ID[j]}.log

( cd 3d
  avconv -f image2 -y -i 3d.${ID[j]}-%04d.png -r 20 m.3d.${ID[j]}.mp4
  rm *.png 
  cd ..
  mv 3d/m.* . ) &>> preproc.${ID[j]}.log

( for d in x y z; do
  for s in 0.20 0.25 0.30 0.35 0.40 0.45 0.50 0.55 0.60 0.65 0.70 0.75 0.80 0.85; do
  fsl5.0-slicer RS.${ID[j]}.nii -s 3 -$d $s im.RS.${ID[j]}.$d.$s.png
  done
  done 

  convert -append im.RS.${ID[j]}.x.*.png imx.RS.${ID[j]}.png
  convert -append im.RS.${ID[j]}.y.*.png imy.RS.${ID[j]}.png
  convert -append im.RS.${ID[j]}.z.*.png imz.RS.${ID[j]}.png
  convert +append imx.RS* imy.RS* imz.RS* m.slices.RS.${ID[j]}.png

  fsl5.0-slicer RS.${ID[j]}.nii -s 3 -A 1000 m.axial.RS.${ID[j]}.png

 rm im* ) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc1">QC1 - Imagem RS raw</h2>
</center>
$text1
<center>
<h3>Gráfico de outliers por TS</h3>
<p><img src="m.outcount.${ID[j]}.jpg" alt="" style="width:716px;height:548px%";/></p>
<p>&nbsp;</p>
<h3>Vídeo de 3 cortes ao longo dos TS</h3>
<p><video controls="controls" width="100%" height="100%">
<source src="m.3d.${ID[j]}.mp4" /></video></p>
<p>&nbsp;</p>
<h3>Imagens de 3 cortes</h3>
<p><img src="m.slices.RS.${ID[j]}.png" alt=""/></p>
<p>&nbsp;</p>
<h3>Todo os cortes axiais</h3>
<p><img src="m.axial.RS.${ID[j]}.png" alt=""/></p>
<p>&nbsp;</p>
<hr>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC1-->.*<!--QC2-->/<!--QC1-->\n $ENV{textf} \n<!--QC2-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

