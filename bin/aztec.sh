#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1  		# RS image
in[1]=$2 	# Log file
out=$3  	# aztec_RS image HEAD
out[1]=$4	# aztec_RS image BRIK
out[2]=$5	# Matlab data

  
# create temporary matlab script
read -r -d '' textf <<EOF
try
ORI=1 / 128;
logfile='${in[1]}';
funcfiles=spm_select('FPList','3d','3d.*');
funcfiles=cellstr(funcfiles);
FS_Phys = 500;
TR = 2;
only_retroicor=0;
output_dir='3d';

[filenames, mean_HR, range_HR, aztecX]=aztec(logfile, funcfiles, FS_Phys, TR, only_retroicor, ORI, output_dir)

dlmwrite('${out[2]}',aztecX);
dlmwrite('meanHR.1D',mean_HR);
dlmwrite('rangeHR.1D',range_HR);
catch
end
quit
EOF
printf "$textf" > scriptaztec.m

# Create folder for 3d images
if [ ! -d "3d" ]; then mkdir 3d; fi

# Split 4d image to 3d images
fsl5.0-fslsplit ${in} 3d/3d_${in}- -t && \
gunzip -f 3d/3d_${in}-*.nii.gz

# Run aztec script
matlab -nodisplay -nodesktop -r "run scriptaztec.m"  

# Compact 3d images to 4d image
3dTcat -prefix ${out%%.*} -TR 2 3d/aztec*3d*

# Adjust cordinate system 
3drefit -view orig ${out%%+*}+tlrc

# Delete intemediate files
rm -r 3d
rm script*


