#!/usr/bin/env bash
 
   ( 1dplot \
    -jpg "m.mcplot.${ID[j]}.jpg" \
    -volreg -dx $TR \
    -xlabel Time \
    -thick \
    ${out_2[$j]} ) &>> preproc.${ID[j]}.log

read -r -d '' textf <<EOF
<h2 id="qc3">QC3 - RS Motion Correction</h2>
<p>&nbsp;</p>
<h3>Gráfico de Correções realizadas pelo volreg</h3>
<p><img src="m.mcplot.${ID[j]}.jpg" alt=""/></p>
<p>&nbsp;</p>
<hr>
<p>&nbsp;</p>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC3-->.*<!--QC4-->/<!--QC3-->\n $ENV{textf} \n<!--QC4-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html
