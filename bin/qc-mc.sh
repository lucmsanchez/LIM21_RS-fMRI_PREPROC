#!/usr/bin/env bash

text1="<pre>$(3dinfo ${out[$j]} 2> /dev/null)</pre>"
 echo $text1 > m.final.txt
read -r -d '' textf <<EOF
<h2 id="qc8">QC8 - Imagem RS final</h2>
<p>&nbsp;</p>
</center>
$text1
<center>
<p>&nbsp;</p>
<hr>
<p>&nbsp;</p>
EOF

export textf
perl -pe 'BEGIN{undef $/;} s/<!--QC8-->.*<!--QC9-->/<!--QC8-->\n $ENV{textf} \n<!--QC9-->/smg' report.${ID[j]}.html > rename.report.${ID[j]}.html
mv rename.report.${ID[j]}.html report.${ID[j]}.html

