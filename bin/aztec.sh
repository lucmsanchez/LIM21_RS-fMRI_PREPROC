read -r -d '' textf <<EOF
try
ORI=1 / 128;
logfile='${in_2[j]}';
funcfiles=spm_select('FPList','3d','3d.*');
funcfiles=cellstr(funcfiles);
FS_Phys = 500;
TR = $TR;
only_retroicor=0;
output_dir='3d';

[filenames, mean_HR, range_HR, aztecX]=aztec(logfile, funcfiles, FS_Phys, TR, only_retroicor, ORI, output_dir)

dlmwrite('aztecX.1D',aztecX);
dlmwrite('meanHR.1D',mean_HR);
dlmwrite('rangeHR.1D',range_HR);
catch
end
quit
EOF

   printf "$textf" > scriptaztec.m
  
 ( if [ ! -d "3d" ]; then mkdir 3d; fi
   fsl5.0-fslsplit ${in[j]} 3d/3d.${ID[j]}- -t && \
   gunzip -f 3d/3d.${ID[j]}-*.nii.gz
 
   matlab -nodisplay -nodesktop -r "run scriptaztec.m" 
   #  
   
   3dTcat -prefix aztec.RS.${ID[j]} -TR $TR 3d/aztec*3d* 
   3drefit -view orig aztec.RS.${ID[j]}+tlrc
   rm -r 3d
   rm script*
   
   ) &>> preproc.${ID[j]}.log

