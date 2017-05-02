#!/usr/bin/env bash
set -x
printf "\n\n==============================================\n\n"
echo $0

# Inputs and outputs
in=$1 		# 1D volreg file
in[1]=$2	# 1D power censor
out=		# enorm_file		
out[1]=     # jpg - original volreg
out[2]=		# jpg - volreg + censor
out[3]=		# jpg
out[4]=		# jpg
out[5]=		# jpg
out[6]=		# jpg
out[7]=		# all variables (.1D)



## MOTION PARAMETERS
# First caculate and create needed files
# Calculate euclidean norm of motion parameters
1d_tool.py -infile ${in} -derivative  -collapse_cols euclidean_norm -write ${out}

# Censored TRs percent
ntr_censor=`cat ${in[1]}  | grep 0 | wc -l`
tt=`cat ${in[1]}  | wc -l`
frac=`ccalc $ntr_censor/$tt*100`
echo "TRs censored              : $ntr_censor"
echo "censor fraction           : $frac"

# average motion (per TR)
mmean=`3dTstat -prefix - -nzmean ${out}\\' 2> /dev/null | tail -n 1 `
echo "average motion (per TR)   : $mmean"

1deval -a ${out} -b ${in[1]} -expr 'a*b' > rm.ec.1D
cmean=`3dTstat -prefix - -nzmean rm.ec.1D\\' 2> /dev/null | tail -n 1`
rm -f rm.ec*
echo "average censored motion   : $cmean"

disp=`1d_tool.py -infile ${in} -show_max_displace -verb 0`
echo "max motion displacement   : $disp"

# compute the maximum motion displacement over all TR pairs
cdisp=`1d_tool.py -infile ${in} -show_max_displace -censor_infile ${in[1]} -verb 0`
echo "max censored displacement : $cdisp"

# num TRs above mot limit
lcount=`1deval -a ${out} -expr "step(a-0.3)"| awk '$1 != 0 {print}' | wc -l`
echo "TRs above motion limit :$lcount"

# PLOTS

# volreg plot separeted
1dplot -jpg "${out[1]}" -volreg ${in}
1dplot -jpg "${out[2]}" -volreg -censor ${in[1]} ${in}
# enorm plot separated
1dplot -jpg "${out[3]}" ${out}
1dplot -jpg "${out[4]}" -censor ${in[1]} ${out}
# com linha limite
1dplot -jpg "${out[5]}" -one '1D: 200@0.3' ${in}
1dplot -jpg "${out[6]}" -one '1D: 200@0.3' ${out}

echo "$ntr_censor;$frac;$mmean;$cmean;$disp;$cdisp;$lcount" > ${out[7]}

exit

