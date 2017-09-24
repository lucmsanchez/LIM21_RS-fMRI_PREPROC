#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# 1D volreg file
out=$2

# create temporary matlab script
read -r -d '' textf <<EOF
try
in = fopen('${in}');
motion = textscan(in, '%%f %%f %%f %%f %%f %%f');
fclose(in);

names = 'roll pitch yaw dS  dL  dP';

mot = zeros(200,6);
mot(:,1) = motion{1};
mot(:,2) = motion{2};
mot(:,3) = motion{3};
mot(:,4) = motion{4};
mot(:,5) = motion{5};
mot(:,6) = motion{6};

delt = abs(min(mot)) + max(mot);

out = fopen('${out}','w');
fprintf(out, '%%f;%%f;%%f;%%f;%%f;%%f', delt );
fclose(out);
catch me
me.message
end
quit
EOF
printf "$textf" > scriptmotion.m

# Run aztec script
matlab -nodisplay -nodesktop -r "run scriptmotion.m"  

rm script*



